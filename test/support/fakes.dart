import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/application/payment_alert_notifier.dart';
import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/data/google_sheets_writer.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:course_chatbot/src/telegram/channel_api.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';

final class FakeMessageSender implements MessageSender {
  final List<SentMessage> messages = <SentMessage>[];
  final List<String> documents = <String>[];
  Object? throwOnSend;

  @override
  Future<int> sendMessage(
    int chatId,
    String text, {
    bool disableNotification = true,
    bool disableWebPagePreview = true,
    Map<String, Object?>? replyMarkup,
    String? parseMode,
  }) async {
    final error = throwOnSend;
    if (error != null) {
      throw error;
    }
    messages.add(
      SentMessage(
        chatId: chatId,
        text: text,
        parseMode: parseMode,
        replyMarkup: replyMarkup,
        disableNotification: disableNotification,
      ),
    );
    return messages.length;
  }

  @override
  Future<SentTelegramDocument> sendDocument(
    int chatId, {
    required String document,
    String? filename,
    bool fromFile = false,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) async {
    documents.add(document);
    return SentTelegramDocument(
      messageId: 100 + documents.length,
      fileId: fromFile ? 'cached-guide' : document,
    );
  }

  final List<CallbackAnswer> callbackAnswers = <CallbackAnswer>[];
  final List<MarkupEdit> markupEdits = <MarkupEdit>[];

  @override
  Future<void> answerCallbackQuery(
    String callbackQueryId, {
    String? text,
    bool showAlert = false,
  }) async {
    callbackAnswers.add(CallbackAnswer(id: callbackQueryId, text: text, showAlert: showAlert));
  }

  @override
  Future<void> editMessageReplyMarkup(
    int chatId, {
    required int messageId,
    Map<String, Object?>? replyMarkup,
  }) async {
    markupEdits.add(MarkupEdit(chatId: chatId, messageId: messageId, replyMarkup: replyMarkup));
  }

  final List<ForwardedMessage> forwards = <ForwardedMessage>[];
  Object? throwOnForward;

  @override
  Future<int> forwardMessage({
    required int chatId,
    required int fromChatId,
    required int messageId,
    bool disableNotification = true,
  }) async {
    final error = throwOnForward;
    if (error != null) {
      throw error;
    }
    forwards.add(
      ForwardedMessage(
        chatId: chatId,
        fromChatId: fromChatId,
        messageId: messageId,
        disableNotification: disableNotification,
      ),
    );
    return 1000 + forwards.length;
  }

  final List<CopiedMessage> copies = <CopiedMessage>[];
  Object? throwOnCopy;

  @override
  Future<int> copyMessage({
    required int chatId,
    required int fromChatId,
    required int messageId,
    bool disableNotification = true,
  }) async {
    final error = throwOnCopy;
    if (error != null) {
      throw error;
    }
    copies.add(
      CopiedMessage(
        chatId: chatId,
        fromChatId: fromChatId,
        messageId: messageId,
        disableNotification: disableNotification,
      ),
    );
    return 2000 + copies.length;
  }
}

final class CallbackAnswer {
  const CallbackAnswer({required this.id, this.text, this.showAlert = false});

  final String id;
  final String? text;
  final bool showAlert;
}

final class MarkupEdit {
  const MarkupEdit({required this.chatId, required this.messageId, this.replyMarkup});

  final int chatId;
  final int messageId;
  final Map<String, Object?>? replyMarkup;
}

final class SentMessage {
  const SentMessage({
    required this.chatId,
    required this.text,
    this.parseMode,
    this.replyMarkup,
    this.disableNotification = true,
  });

  final int chatId;
  final String text;
  final String? parseMode;
  final Map<String, Object?>? replyMarkup;
  final bool disableNotification;
}

final class ForwardedMessage {
  const ForwardedMessage({
    required this.chatId,
    required this.fromChatId,
    required this.messageId,
    this.disableNotification = true,
  });

  final int chatId;
  final int fromChatId;
  final int messageId;
  final bool disableNotification;
}

final class CopiedMessage {
  const CopiedMessage({
    required this.chatId,
    required this.fromChatId,
    required this.messageId,
    this.disableNotification = true,
  });

  final int chatId;
  final int fromChatId;
  final int messageId;
  final bool disableNotification;
}

final class FakePaymentGateway implements PaymentGateway {
  FakePaymentGateway({this.url = 'https://pay.example/checkout', this.createError});

  String? url;
  Object? createError;
  int creates = 0;
  bool available = true;
  Future<void> Function(CheckoutSession session, int paymentDbId)? onCreated;

  @override
  String get providerId => 'fake';

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<CheckoutSession> createPayment({
    required CourseOrder order,
    required PaymentKind kind,
    required int amountKopecks,
    required int paymentDbId,
    String? description,
    String? returnUrl,
  }) async {
    final error = createError;
    if (error != null) {
      throw error;
    }
    creates += 1;
    final session = CheckoutSession(
      provider: providerId,
      providerPaymentId: 'fake-$paymentDbId',
      confirmationUrl: url,
    );
    final hook = onCreated;
    if (hook != null) {
      await hook(session, paymentDbId);
    }
    return session;
  }

  @override
  PaymentCallback? parseCallback(Object payload) {
    if (payload is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(payload);
    final id = map['id']?.toString();
    if (id == null) {
      return null;
    }
    return PaymentCallback(
      provider: providerId,
      providerPaymentId: id,
      succeeded: map['succeeded'] == true,
      charged: map['charged'] != false,
      orderId: int.tryParse(map['order_id']?.toString() ?? ''),
      paymentDbId: int.tryParse(map['payment_db_id']?.toString() ?? ''),
      userId: int.tryParse(map['user_id']?.toString() ?? ''),
      kind: PaymentKindX.parse(map['kind']?.toString()),
      amountKopecks: int.tryParse(map['amount']?.toString() ?? ''),
    );
  }

  @override
  Future<PaymentCallback?> verifyCallback(PaymentCallback callback) async => callback;

  @override
  void close() {}
}

final class GatewayAlert {
  const GatewayAlert({
    required this.userId,
    required this.launchId,
    required this.kind,
    required this.provider,
    this.reason,
    this.username,
    this.firstName,
  });

  final int userId;
  final int launchId;
  final PaymentKind kind;
  final String provider;
  final String? reason;
  final String? username;
  final String? firstName;
}

final class FakePaymentGatewayAlertPort implements PaymentGatewayAlertPort, AdminAlertPort {
  final List<GatewayAlert> alerts = <GatewayAlert>[];
  final List<int> guideMissing = <int>[];

  @override
  Future<void> notifyGatewayUnavailable({
    required int userId,
    required int launchId,
    required PaymentKind kind,
    required String provider,
    String? reason,
    String? username,
    String? firstName,
  }) async {
    alerts.add(
      GatewayAlert(
        userId: userId,
        launchId: launchId,
        kind: kind,
        provider: provider,
        reason: reason,
        username: username,
        firstName: firstName,
      ),
    );
  }

  @override
  Future<void> notifyGuideMissing({required int userId}) async {
    guideMissing.add(userId);
  }
}

final class FakeChannelApi implements ChannelApi {
  final List<String> created = <String>[];
  final List<String> revoked = <String>[];
  int _n = 0;
  Object? createError;

  @override
  Future<String> createChatInviteLink({
    required int chatId,
    int memberLimit = 1,
    String? name,
    int? expireDate,
  }) async {
    final error = createError;
    if (error != null) {
      throw error;
    }
    _n += 1;
    final link = 'https://t.me/+invite$_n';
    created.add(link);
    return link;
  }

  @override
  Future<void> revokeChatInviteLink({required int chatId, required String inviteLink}) async {
    revoked.add(inviteLink);
  }

  final List<int> banned = <int>[];

  @override
  Future<void> banChatMember(int chatId, {required int userId, bool revokeMessages = true}) async {
    banned.add(userId);
  }

  @override
  Future<void> unbanChatMember(int chatId, {required int userId, bool onlyIfBanned = true}) async {}
}

final class FakeGoogleSheetsWriter implements GoogleSheetsWriter {
  int replaceDashboardCount = 0;
  Object? throwOnReplace;
  GoogleSheetsDashboard? lastDashboard;

  @override
  Future<void> replaceSheet({
    required String sheetTitle,
    required List<List<Object?>> rows,
  }) async {}

  @override
  Future<void> replaceDashboard(GoogleSheetsDashboard dashboard) async {
    final error = throwOnReplace;
    if (error != null) {
      throw error;
    }
    replaceDashboardCount += 1;
    lastDashboard = dashboard;
  }

  @override
  Future<void> close() async {}
}

final class FakeGoogleSheetsGateway implements GoogleSheetsSpreadsheetGateway {
  FakeGoogleSheetsGateway({
    List<GoogleSheetsSheetInfo>? sheets,
    Map<int, List<List<Object?>>>? valuesBySheetId,
    this.nextSheetId = 1,
  }) : sheets = List<GoogleSheetsSheetInfo>.from(
         sheets ??
             const <GoogleSheetsSheetInfo>[
               GoogleSheetsSheetInfo(title: 'Sheet1', sheetId: CoursesSheet.sheetId),
             ],
       ),
       valuesBySheetId = <int, List<List<Object?>>>{
         for (final entry in (valuesBySheetId ?? const <int, List<List<Object?>>>{}).entries)
           entry.key: _copyRows(entry.value),
       };

  List<GoogleSheetsSheetInfo> sheets;
  final Map<int, List<List<Object?>>> valuesBySheetId;
  int nextSheetId;
  final List<int> deletedSheetIds = <int>[];
  final List<int> renamedSheetIds = <int>[];
  final List<String> clearedRanges = <String>[];
  int updateValuesCount = 0;
  int applyLookCount = 0;
  GoogleSheetsDashboard? lastLook;
  final Map<int, GoogleSheetsDashboard> looksBySheetId = <int, GoogleSheetsDashboard>{};

  @override
  Future<Set<String>> listSheetTitles() async {
    return sheets.map((sheet) => sheet.title).toSet();
  }

  @override
  Future<List<GoogleSheetsSheetInfo>> describeSheets() async {
    return List<GoogleSheetsSheetInfo>.from(sheets);
  }

  @override
  Future<void> renameSheet({required int sheetId, required String title}) async {
    renamedSheetIds.add(sheetId);
    sheets = List<GoogleSheetsSheetInfo>.from(sheets);
    final index = sheets.indexWhere((sheet) => sheet.sheetId == sheetId);
    if (index < 0) {
      throw StateError('Sheet $sheetId is missing.');
    }
    if (sheets.any((sheet) => sheet.sheetId != sheetId && sheet.title == title)) {
      throw StateError('Sheet $title already exists.');
    }
    final previous = sheets[index];
    sheets[index] = GoogleSheetsSheetInfo(
      title: title,
      sheetId: previous.sheetId,
      chartIds: previous.chartIds,
    );
  }

  @override
  Future<void> deleteSheet(int sheetId) async {
    deletedSheetIds.add(sheetId);
    sheets = List<GoogleSheetsSheetInfo>.from(sheets)
      ..removeWhere((sheet) => sheet.sheetId == sheetId);
    valuesBySheetId.remove(sheetId);
  }

  @override
  Future<void> addSheet(String title) async {
    if (sheets.any((sheet) => sheet.title == title)) {
      throw StateError('Sheet $title already exists.');
    }
    final id = nextSheetId;
    nextSheetId += 1;
    if (nextSheetId == CoursesSheet.sheetId) {
      nextSheetId += 1;
    }
    sheets = List<GoogleSheetsSheetInfo>.from(sheets)
      ..add(GoogleSheetsSheetInfo(title: title, sheetId: id));
  }

  @override
  Future<void> clearRange(String a1Range) async {
    clearedRanges.add(a1Range);
    final title = _titleFromRange(a1Range);
    final sheet = _sheetByTitle(title);
    if (sheet != null) {
      valuesBySheetId[sheet.sheetId] = <List<Object?>>[];
    }
  }

  @override
  Future<void> updateValues({
    required String a1Range,
    required List<List<Object?>> rows,
    String valueInputOption = 'RAW',
  }) async {
    updateValuesCount += 1;
    final title = _titleFromRange(a1Range);
    final sheet = _sheetByTitle(title);
    if (sheet == null) {
      throw StateError('Sheet $title is missing.');
    }
    final start = _a1Start(a1Range);
    if (start == null || (start.row == 0 && start.col == 0)) {
      valuesBySheetId[sheet.sheetId] = _copyRows(rows);
      return;
    }
    final grid = _copyRows(valuesBySheetId[sheet.sheetId] ?? const <List<Object?>>[]);
    for (var r = 0; r < rows.length; r++) {
      final destRow = start.row + r;
      while (grid.length <= destRow) {
        grid.add(<Object?>[]);
      }
      final line = List<Object?>.from(grid[destRow]);
      for (var c = 0; c < rows[r].length; c++) {
        final destCol = start.col + c;
        while (line.length <= destCol) {
          line.add('');
        }
        line[destCol] = rows[r][c];
      }
      grid[destRow] = line;
    }
    valuesBySheetId[sheet.sheetId] = grid;
  }

  @override
  Future<List<List<Object?>>> getValues(String a1Range) async {
    final title = _titleFromRange(a1Range);
    final sheet = _sheetByTitle(title);
    if (sheet == null) {
      return const <List<Object?>>[];
    }
    return _copyRows(valuesBySheetId[sheet.sheetId] ?? const <List<Object?>>[]);
  }

  @override
  Future<void> deleteDimension({
    required int sheetId,
    required String dimension,
    required int startIndex,
    required int endIndex,
  }) async {}

  @override
  Future<void> applyDashboardLook({
    required int sheetId,
    required GoogleSheetsDashboard dashboard,
  }) async {
    applyLookCount += 1;
    lastLook = dashboard;
    looksBySheetId[sheetId] = dashboard;
  }

  @override
  Future<void> close() async {}

  GoogleSheetsSheetInfo? _sheetByTitle(String title) {
    for (final sheet in sheets) {
      if (sheet.title == title) {
        return sheet;
      }
    }
    return null;
  }

  static String _titleFromRange(String a1Range) {
    final bang = a1Range.lastIndexOf('!');
    final raw = bang <= 0 ? a1Range : a1Range.substring(0, bang);
    if (raw.startsWith("'") && raw.endsWith("'") && raw.length >= 2) {
      return raw.substring(1, raw.length - 1).replaceAll("''", "'");
    }
    return raw;
  }

  static ({int row, int col})? _a1Start(String a1Range) {
    final bang = a1Range.lastIndexOf('!');
    final cell = bang < 0 ? a1Range : a1Range.substring(bang + 1);
    final match = RegExp(r'^\$?([A-Za-z]+)\$?(\d+)').firstMatch(cell);
    if (match == null) {
      return null;
    }
    return (row: int.parse(match.group(2)!) - 1, col: _columnIndex(match.group(1)!));
  }

  static int _columnIndex(String letters) {
    var n = 0;
    for (final code in letters.toUpperCase().codeUnits) {
      n = n * 26 + (code - 64);
    }
    return n - 1;
  }

  static List<List<Object?>> _copyRows(List<List<Object?>> rows) {
    return <List<Object?>>[for (final row in rows) List<Object?>.from(row)];
  }
}

Map<String, dynamic> privateMessageUpdate({
  required int chatId,
  required int userId,
  required String text,
  String? username,
  int messageId = 10,
  Map<String, dynamic>? forwardFrom,
}) {
  return <String, dynamic>{
    'update_id': 1,
    'message': <String, dynamic>{
      'message_id': messageId,
      'chat': <String, dynamic>{'id': chatId, 'type': 'private'},
      'from': <String, dynamic>{
        'id': userId,
        if (username != null) 'username': username,
        'first_name': 'Test',
      },
      'text': text,
      if (forwardFrom != null) 'forward_from': forwardFrom,
    },
  };
}

Map<String, dynamic> privatePhotoUpdate({
  required int chatId,
  required int userId,
  String? caption,
  String? username,
  int messageId = 11,
  String? mediaGroupId,
}) {
  return <String, dynamic>{
    'update_id': 1,
    'message': <String, dynamic>{
      'message_id': messageId,
      'chat': <String, dynamic>{'id': chatId, 'type': 'private'},
      'from': <String, dynamic>{
        'id': userId,
        if (username != null) 'username': username,
        'first_name': 'Test',
      },
      'photo': <Map<String, dynamic>>[
        <String, dynamic>{'file_id': 'photo-small'},
        <String, dynamic>{'file_id': 'photo-large'},
      ],
      if (caption != null) 'caption': caption,
      if (mediaGroupId != null) 'media_group_id': mediaGroupId,
    },
  };
}

Map<String, dynamic> privateDocumentUpdate({
  required int chatId,
  required int userId,
  String fileId = 'doc-1',
  String? caption,
  String? username,
  int messageId = 12,
}) {
  return <String, dynamic>{
    'update_id': 1,
    'message': <String, dynamic>{
      'message_id': messageId,
      'chat': <String, dynamic>{'id': chatId, 'type': 'private'},
      'from': <String, dynamic>{
        'id': userId,
        if (username != null) 'username': username,
        'first_name': 'Test',
      },
      'document': <String, dynamic>{'file_id': fileId, 'file_name': 'file.pdf'},
      if (caption != null) 'caption': caption,
    },
  };
}

Map<String, dynamic> privateVideoUpdate({
  required int chatId,
  required int userId,
  String? caption,
  String? username,
  int messageId = 13,
}) {
  return <String, dynamic>{
    'update_id': 1,
    'message': <String, dynamic>{
      'message_id': messageId,
      'chat': <String, dynamic>{'id': chatId, 'type': 'private'},
      'from': <String, dynamic>{
        'id': userId,
        if (username != null) 'username': username,
        'first_name': 'Test',
      },
      'video': <String, dynamic>{'file_id': 'vid-1'},
      if (caption != null) 'caption': caption,
    },
  };
}

Map<String, dynamic> privateEmptyMessageUpdate({
  required int chatId,
  required int userId,
  String? username,
  int messageId = 14,
}) {
  return <String, dynamic>{
    'update_id': 1,
    'message': <String, dynamic>{
      'message_id': messageId,
      'chat': <String, dynamic>{'id': chatId, 'type': 'private'},
      'from': <String, dynamic>{
        'id': userId,
        if (username != null) 'username': username,
        'first_name': 'Test',
      },
    },
  };
}

Map<String, dynamic> privateCallbackUpdate({
  required String callbackId,
  required int chatId,
  required int userId,
  required String data,
  String? username,
}) {
  return <String, dynamic>{
    'update_id': 2,
    'callback_query': <String, dynamic>{
      'id': callbackId,
      'from': <String, dynamic>{
        'id': userId,
        if (username != null) 'username': username,
        'first_name': 'Test',
      },
      'message': <String, dynamic>{
        'message_id': 20,
        'chat': <String, dynamic>{'id': chatId, 'type': 'private'},
      },
      'data': data,
    },
  };
}
