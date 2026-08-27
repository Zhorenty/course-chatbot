import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/data/google_sheets_writer.dart';
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
      SentMessage(chatId: chatId, text: text, parseMode: parseMode, replyMarkup: replyMarkup),
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
  const SentMessage({required this.chatId, required this.text, this.parseMode, this.replyMarkup});

  final int chatId;
  final String text;
  final String? parseMode;
  final Map<String, Object?>? replyMarkup;
}

final class FakePaymentGateway implements PaymentGateway {
  FakePaymentGateway({this.url = 'https://pay.example/checkout', this.createError});

  final String? url;
  Object? createError;
  int creates = 0;
  Future<void> Function(CheckoutSession session, int paymentDbId)? onCreated;

  @override
  String get providerId => 'fake';

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

  @override
  Future<void> banChatMember(int chatId, {required int userId, bool revokeMessages = true}) async {}

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

Map<String, dynamic> privateMessageUpdate({
  required int chatId,
  required int userId,
  required String text,
  String? username,
}) {
  return <String, dynamic>{
    'update_id': 1,
    'message': <String, dynamic>{
      'message_id': 10,
      'chat': <String, dynamic>{'id': chatId, 'type': 'private'},
      'from': <String, dynamic>{
        'id': userId,
        if (username != null) 'username': username,
        'first_name': 'Test',
      },
      'text': text,
    },
  };
}

Map<String, dynamic> privateCallbackUpdate({
  required String callbackId,
  required int chatId,
  required int userId,
  required String data,
}) {
  return <String, dynamic>{
    'update_id': 2,
    'callback_query': <String, dynamic>{
      'id': callbackId,
      'from': <String, dynamic>{'id': userId, 'first_name': 'Test'},
      'message': <String, dynamic>{
        'message_id': 20,
        'chat': <String, dynamic>{'id': chatId, 'type': 'private'},
      },
      'data': data,
    },
  };
}
