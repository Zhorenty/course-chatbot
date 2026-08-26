import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:course_chatbot/src/telegram/channel_api.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';

final class FakeMessageSender implements MessageSender {
  final List<SentMessage> messages = <SentMessage>[];
  final List<String> documents = <String>[];

  @override
  Future<int> sendMessage(
    int chatId,
    String text, {
    bool disableNotification = true,
    bool disableWebPagePreview = true,
    Map<String, Object?>? replyMarkup,
    String? parseMode,
  }) async {
    messages.add(
      SentMessage(
        chatId: chatId,
        text: text,
        parseMode: parseMode,
        replyMarkup: replyMarkup,
      ),
    );
    return messages.length;
  }

  @override
  Future<int> sendDocument(
    int chatId, {
    required String document,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) async {
    documents.add(document);
    return 100 + documents.length;
  }

  @override
  Future<int> sendVideo(
    int chatId, {
    required String video,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) async {
    return 0;
  }

  @override
  Future<int> sendVideoNote(
    int chatId, {
    required String videoNote,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) async {
    return 0;
  }

  @override
  Future<int> copyMessage(
    int chatId, {
    required int fromChatId,
    required int messageId,
    bool disableNotification = true,
  }) async {
    return 0;
  }

  @override
  Future<void> deleteMessage(
    int chatId, {
    required int messageId,
  }) async {}

  @override
  Future<void> answerCallbackQuery(
    String callbackQueryId, {
    String? text,
    bool showAlert = false,
  }) async {}

  @override
  Future<void> editMessageReplyMarkup(
    int chatId, {
    required int messageId,
    Map<String, Object?>? replyMarkup,
  }) async {}
}

final class SentMessage {
  const SentMessage({
    required this.chatId,
    required this.text,
    this.parseMode,
    this.replyMarkup,
  });

  final int chatId;
  final String text;
  final String? parseMode;
  final Map<String, Object?>? replyMarkup;
}

final class FakePaymentGateway implements PaymentGateway {
  FakePaymentGateway({this.url = 'https://pay.example/checkout'});

  final String? url;
  int creates = 0;

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
    creates += 1;
    return CheckoutSession(
      provider: providerId,
      providerPaymentId: 'fake-$paymentDbId',
      confirmationUrl: url,
    );
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
}

final class FakeChannelApi implements ChannelApi {
  final List<String> created = <String>[];
  final List<String> revoked = <String>[];
  int _n = 0;

  @override
  Future<String> createChatInviteLink({
    required int chatId,
    int memberLimit = 1,
    String? name,
    int? expireDate,
  }) async {
    _n += 1;
    final link = 'https://t.me/+invite$_n';
    created.add(link);
    return link;
  }

  @override
  Future<void> revokeChatInviteLink({
    required int chatId,
    required String inviteLink,
  }) async {
    revoked.add(inviteLink);
  }

  @override
  Future<void> banChatMember(
    int chatId, {
    required int userId,
    bool revokeMessages = true,
  }) async {}

  @override
  Future<void> unbanChatMember(
    int chatId, {
    required int userId,
    bool onlyIfBanned = true,
  }) async {}
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
        'chat': <String, dynamic>{'id': chatId, 'type': 'private'},
      },
      'data': data,
    },
  };
}
