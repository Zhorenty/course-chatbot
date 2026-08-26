import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/channel_access.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/funnel_analytics.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/domain/warmup.dart';

abstract interface class CourseRepository {
  Future<void> init();

  T transaction<T>(T Function() action);

  Future<Launch> upsertActiveLaunch({
    required String productCode,
    required String productTitle,
    required String launchCode,
    required String launchTitle,
    required int priceFullKopecks,
    required int depositKopecks,
    required int depositDueDays,
    int? channelId,
    String? offerUrl,
    String? leadMagnetFileId,
    String? leadMagnetUrl,
  });

  Launch? activeLaunch();

  Future<void> setLeadMagnetFileId(String fileId);

  Future<UserProfile> ensureUser({
    required int userId,
    String? username,
    String? firstName,
    String? source,
    required DateTime now,
  });

  UserProfile? getUser(int userId);

  Future<void> touchUser({
    required int userId,
    String? username,
    String? firstName,
    required DateTime now,
  });

  void setFunnelPhase({
    required int userId,
    required FunnelPhase phase,
    DateTime? magnetIssuedAt,
  });

  void setWarmupOptOut({required int userId, required bool optOut});

  void setBotBlocked({required int userId, required bool blocked});

  UserProfile? findUserByUsername(String username);

  List<UserProfile> searchUsers(String query, {int limit = 10});

  List<int> listBroadcastUserIds({required BroadcastSegment segment});

  CourseOrder createOrder({
    required int userId,
    required int launchId,
    required PaymentKind kind,
    required int priceFullKopecks,
    required int amountDueKopecks,
    required DateTime now,
    DateTime? dueAt,
  });

  CourseOrder? getOrder(int orderId);

  CourseOrder? latestOpenOrder(int userId);

  CourseOrder? latestOrder(int userId);

  List<CourseOrder> listOrdersForUser(int userId, {int limit = 10});

  void updateOrder(CourseOrder order);

  PaymentRecord insertPayment({
    required int orderId,
    required String provider,
    required PaymentKind kind,
    required int amountKopecks,
    required DateTime now,
    String? providerPaymentId,
    String? confirmationUrl,
    PaymentRecordStatus status = PaymentRecordStatus.pending,
  });

  PaymentRecord? getPayment(int paymentId);

  PaymentRecord? findPaymentByProviderId({
    required String provider,
    required String providerPaymentId,
  });

  PaymentRecord? latestPendingPayment(int orderId);

  void updatePayment(PaymentRecord payment);

  ChannelAccess? accessFor({required int userId, required int launchId});

  ChannelAccess upsertAccess({
    required int userId,
    required int launchId,
    required int orderId,
    String? inviteLink,
    DateTime? inviteCreatedAt,
    DateTime? joinedAt,
    DateTime? revokedAt,
  });

  void markJoined({
    required int userId,
    required int launchId,
    required DateTime joinedAt,
  });

  List<WarmupStep> listWarmupSteps();

  void seedDefaultWarmupSteps();

  bool hasWarmupBeenSent({required int userId, required String stepKey});

  void recordWarmupSent({
    required int userId,
    required String stepKey,
    required DateTime sentAt,
  });

  List<WarmupCandidate> listWarmupCandidates({required DateTime now, int limit = 100});

  List<CourseOrder> listAbandonedCheckout({
    required DateTime now,
    required Duration minAge,
    int limit = 100,
  });

  List<CourseOrder> listRemainderDue({
    required DateTime now,
    int limit = 100,
  });

  FunnelAnalytics funnelAnalytics({required DateTime now});

  Future<void> appendConversation({
    required ConversationDirection direction,
    required int peerUserId,
    String? peerUsername,
    required int chatId,
    int? telegramMessageId,
    required ConversationContentType contentType,
    String? textPreview,
  });

  List<ConversationLogEntry> dialogForUser(int userId, {int limit = 30});
}

enum BroadcastSegment {
  guideNotPaid,
  allStarted,
}
