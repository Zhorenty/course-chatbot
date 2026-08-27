import 'dart:convert';
import 'dart:io';

import 'package:course_chatbot/src/telegram/channel_api.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/retry.dart';
import 'package:course_chatbot/src/telegram/telegram_api_exception.dart';
import 'package:http/http.dart' as http;

final class TelegramClient implements MessageSender, ChannelApi {
  static const int _maxTelegramMessageLength = 4096;

  TelegramClient({required String token, http.Client? httpClient})
    : _baseUri = Uri.parse('https://api.telegram.org/bot$token'),
      _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _httpClient;

  Uri _methodUri(String method) => _baseUri.replace(path: '${_baseUri.path}/$method');

  Future<Map<String, dynamic>> _post(
    String method, {
    required Map<String, Object?> body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await retry(
      () => _httpClient
          .post(
            _methodUri(method),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout),
      shouldRetry: (error) => error is! TelegramApiException || error.statusCode == 429,
      delayForError: (error, currentDelay) {
        if (error is TelegramApiException && error.retryAfterSeconds != null) {
          final wait = Duration(seconds: error.retryAfterSeconds!);
          return wait > currentDelay ? wait : currentDelay;
        }
        return currentDelay;
      },
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _postMultipart(
    String method, {
    required Map<String, String> fields,
    required Future<List<http.MultipartFile>> Function() files,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final response = await retry(
      () async {
        final request = http.MultipartRequest('POST', _methodUri(method));
        request.fields.addAll(fields);
        request.files.addAll(await files());
        final streamed = await _httpClient.send(request).timeout(timeout);
        return http.Response.fromStream(streamed);
      },
      shouldRetry: (error) => error is! TelegramApiException || error.statusCode == 429,
      delayForError: (error, currentDelay) {
        if (error is TelegramApiException && error.retryAfterSeconds != null) {
          final wait = Duration(seconds: error.retryAfterSeconds!);
          return wait > currentDelay ? wait : currentDelay;
        }
        return currentDelay;
      },
    );
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw TelegramApiException(
        'Telegram API returned non-JSON response',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode != 200 || payload['ok'] != true) {
      final description =
          payload['description']?.toString() ??
          (response.statusCode != 200 ? 'HTTP error' : 'Telegram response is not ok');
      throw TelegramApiException(
        description,
        statusCode: response.statusCode,
        retryAfterSeconds: _retryAfterSeconds(payload),
      );
    }

    return payload;
  }

  int? _retryAfterSeconds(Map<String, dynamic> payload) {
    final parameters = payload['parameters'];
    if (parameters is! Map) {
      return null;
    }
    final raw = parameters['retry_after'];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString() ?? '');
  }

  Future<List<Map<String, dynamic>>> getUpdates({
    required int offset,
    required int timeoutSeconds,
    Set<String> allowedUpdates = const {'message'},
  }) async {
    final requestTimeout = Duration(seconds: timeoutSeconds + 10);
    final payload = await _post(
      'getUpdates',
      body: <String, Object?>{
        'offset': offset,
        'limit': 100,
        'timeout': timeoutSeconds,
        'allowed_updates': allowedUpdates.toList(growable: false),
      },
      timeout: requestTimeout,
    );

    final rawResult = payload['result'];
    if (rawResult is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawResult
        .whereType<Map<Object?, Object?>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<String?> getBotUsername() async {
    final payload = await _post('getMe', body: const <String, Object?>{});
    final result = payload['result'];
    if (result is! Map) {
      return null;
    }
    return result['username']?.toString();
  }

  Future<void> deleteWebhook({bool dropPendingUpdates = false}) async {
    final payload = await _post(
      'deleteWebhook',
      body: <String, Object?>{'drop_pending_updates': dropPendingUpdates},
    );
    final result = payload['result'];
    if (result != true) {
      throw const TelegramApiException('Telegram did not confirm webhook deletion');
    }
  }

  @override
  Future<int> sendMessage(
    int chatId,
    String text, {
    bool disableNotification = true,
    bool disableWebPagePreview = true,
    Map<String, Object?>? replyMarkup,
    String? parseMode,
  }) async {
    final chunks = _splitMessageText(text);
    var lastMessageId = 0;
    for (var index = 0; index < chunks.length; index++) {
      final isLastChunk = index == chunks.length - 1;
      lastMessageId = await _sendMessageChunk(
        chatId,
        chunks[index],
        disableNotification: disableNotification,
        disableWebPagePreview: disableWebPagePreview,
        replyMarkup: isLastChunk ? replyMarkup : null,
        parseMode: parseMode,
      );
    }
    return lastMessageId;
  }

  Future<int> _sendMessageChunk(
    int chatId,
    String text, {
    required bool disableNotification,
    required bool disableWebPagePreview,
    required Map<String, Object?>? replyMarkup,
    required String? parseMode,
  }) async {
    final body = <String, Object?>{
      'chat_id': chatId,
      'text': text,
      'disable_notification': disableNotification,
      'disable_web_page_preview': disableWebPagePreview,
    };
    if (replyMarkup != null) {
      body['reply_markup'] = replyMarkup;
    }
    if (parseMode != null) {
      body['parse_mode'] = parseMode;
    }

    final payload = await _post('sendMessage', body: body);

    final result = payload['result'];
    if (result is! Map || result['message_id'] is! int) {
      throw const TelegramApiException('Telegram did not return message_id');
    }

    return result['message_id'] as int;
  }

  List<String> _splitMessageText(String text) {
    return _splitBySeparators(
      text,
      separators: const <String>['\n\n', '\n'],
      maxLength: _maxTelegramMessageLength,
    );
  }

  List<String> _splitBySeparators(
    String text, {
    required List<String> separators,
    required int maxLength,
  }) {
    if (_textLength(text) <= maxLength) {
      return <String>[text];
    }
    if (separators.isEmpty) {
      return _hardSplit(text, maxLength);
    }

    final separator = separators.first;
    final nextSeparators = separators.sublist(1);
    final segments = text.split(separator);
    if (segments.length == 1) {
      return _splitBySeparators(text, separators: nextSeparators, maxLength: maxLength);
    }

    final chunks = <String>[];
    var current = '';
    for (final segment in segments) {
      final candidate = current.isEmpty ? segment : '$current$separator$segment';
      if (_textLength(candidate) <= maxLength) {
        current = candidate;
        continue;
      }
      if (current.isNotEmpty) {
        chunks.add(current);
      }
      if (_textLength(segment) <= maxLength) {
        current = segment;
        continue;
      }
      chunks.addAll(_splitBySeparators(segment, separators: nextSeparators, maxLength: maxLength));
      current = '';
    }
    if (current.isNotEmpty) {
      chunks.add(current);
    }

    return chunks.isEmpty ? _hardSplit(text, maxLength) : chunks;
  }

  List<String> _hardSplit(String text, int maxLength) {
    final codePoints = text.runes.toList(growable: false);
    final chunks = <String>[];
    for (var index = 0; index < codePoints.length; index += maxLength) {
      final end = (index + maxLength < codePoints.length) ? index + maxLength : codePoints.length;
      chunks.add(String.fromCharCodes(codePoints.sublist(index, end)));
    }
    return chunks.isEmpty ? <String>[text] : chunks;
  }

  int _textLength(String text) => text.runes.length;

  @override
  Future<SentTelegramDocument> sendDocument(
    int chatId, {
    required String document,
    String? filename,
    bool fromFile = false,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) {
    if (fromFile) {
      return _sendLocalDocument(
        chatId: chatId,
        path: document,
        filename: filename,
        disableNotification: disableNotification,
        replyMarkup: replyMarkup,
      );
    }
    return _sendFileMessage(
      method: 'sendDocument',
      chatId: chatId,
      fileField: 'document',
      fileId: document,
      disableNotification: disableNotification,
      replyMarkup: replyMarkup,
    );
  }

  Future<SentTelegramDocument> _sendLocalDocument({
    required int chatId,
    required String path,
    required String? filename,
    required bool disableNotification,
    required Map<String, Object?>? replyMarkup,
  }) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw TelegramApiException('Lead magnet file is missing: $path');
    }
    final fields = <String, String>{
      'chat_id': '$chatId',
      'disable_notification': '$disableNotification',
    };
    if (replyMarkup != null) {
      fields['reply_markup'] = jsonEncode(replyMarkup);
    }
    final payload = await _postMultipart(
      'sendDocument',
      fields: fields,
      files: () async {
        return <http.MultipartFile>[
          await http.MultipartFile.fromPath(
            'document',
            path,
            filename: filename ?? _basename(path),
          ),
        ];
      },
    );
    return _sentDocumentFromPayload(payload);
  }

  Future<SentTelegramDocument> _sendFileMessage({
    required String method,
    required int chatId,
    required String fileField,
    required String fileId,
    required bool disableNotification,
    required Map<String, Object?>? replyMarkup,
  }) async {
    final body = <String, Object?>{
      'chat_id': chatId,
      fileField: fileId,
      'disable_notification': disableNotification,
    };
    if (replyMarkup != null) {
      body['reply_markup'] = replyMarkup;
    }
    final payload = await _post(method, body: body);
    return _sentDocumentFromPayload(payload);
  }

  SentTelegramDocument _sentDocumentFromPayload(Map<String, dynamic> payload) {
    final result = payload['result'];
    if (result is! Map || result['message_id'] is! int) {
      throw const TelegramApiException('Telegram did not return message_id');
    }
    final document = result['document'];
    String? fileId;
    if (document is Map) {
      fileId = document['file_id']?.toString();
    }
    return SentTelegramDocument(
      messageId: result['message_id'] as int,
      fileId: fileId == null || fileId.isEmpty ? null : fileId,
    );
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final slash = normalized.lastIndexOf('/');
    return slash < 0 ? normalized : normalized.substring(slash + 1);
  }

  @override
  Future<String> createChatInviteLink({
    required int chatId,
    int memberLimit = 1,
    String? name,
    int? expireDate,
  }) async {
    final payload = await _post(
      'createChatInviteLink',
      body: <String, Object?>{
        'chat_id': chatId,
        'member_limit': memberLimit,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (expireDate != null) 'expire_date': expireDate,
      },
    );
    final result = payload['result'];
    if (result is! Map) {
      throw const TelegramApiException('Telegram did not return an invite link object');
    }
    final link = result['invite_link']?.toString();
    if (link == null || link.isEmpty) {
      throw const TelegramApiException('Telegram did not return invite_link');
    }
    return link;
  }

  @override
  Future<void> revokeChatInviteLink({required int chatId, required String inviteLink}) async {
    final payload = await _post(
      'revokeChatInviteLink',
      body: <String, Object?>{'chat_id': chatId, 'invite_link': inviteLink},
    );
    final result = payload['result'];
    if (result is! Map) {
      throw const TelegramApiException('Telegram did not confirm invite revoke');
    }
  }

  @override
  Future<void> unbanChatMember(int chatId, {required int userId, bool onlyIfBanned = true}) async {
    final payload = await _post(
      'unbanChatMember',
      body: <String, Object?>{'chat_id': chatId, 'user_id': userId, 'only_if_banned': onlyIfBanned},
    );
    final result = payload['result'];
    if (result != true) {
      throw const TelegramApiException('Telegram did not confirm chat member unban');
    }
  }

  @override
  Future<void> banChatMember(int chatId, {required int userId, bool revokeMessages = true}) async {
    final payload = await _post(
      'banChatMember',
      body: <String, Object?>{
        'chat_id': chatId,
        'user_id': userId,
        'revoke_messages': revokeMessages,
      },
    );
    final result = payload['result'];
    if (result != true) {
      throw const TelegramApiException('Telegram did not confirm chat member ban');
    }
  }

  @override
  Future<void> answerCallbackQuery(
    String callbackQueryId, {
    String? text,
    bool showAlert = false,
  }) async {
    final payload = await _post(
      'answerCallbackQuery',
      body: <String, Object?>{
        'callback_query_id': callbackQueryId,
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
        'show_alert': showAlert,
      },
    );
    final result = payload['result'];
    if (result != true) {
      throw const TelegramApiException('Telegram did not confirm callback answer');
    }
  }

  @override
  Future<void> editMessageReplyMarkup(
    int chatId, {
    required int messageId,
    Map<String, Object?>? replyMarkup,
  }) async {
    await _post(
      'editMessageReplyMarkup',
      body: <String, Object?>{
        'chat_id': chatId,
        'message_id': messageId,
        if (replyMarkup != null) 'reply_markup': replyMarkup,
      },
    );
  }

  void close() {
    _httpClient.close();
  }
}
