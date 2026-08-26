import 'package:course_chatbot/src/data/access_repository.dart';
import 'package:course_chatbot/src/data/catalog_repository.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/funnel_analytics_repository.dart';
import 'package:course_chatbot/src/data/sqlite/sqlite_database_handle.dart';
import 'package:course_chatbot/src/data/user_repository.dart';
import 'package:course_chatbot/src/data/warmup_repository.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/channel_access.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/funnel_analytics.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/domain/telegram_username.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/domain/warmup.dart';
import 'package:sqlite3/sqlite3.dart';

part 'sqlite/sqlite_catalog_store.part.dart';
part 'sqlite/sqlite_users_store.part.dart';
part 'sqlite/sqlite_orders_store.part.dart';
part 'sqlite/sqlite_payments_store.part.dart';
part 'sqlite/sqlite_access_store.part.dart';
part 'sqlite/sqlite_warmup_store.part.dart';
part 'sqlite/sqlite_analytics_store.part.dart';
part 'sqlite/sqlite_conversation_store.part.dart';

final class SqliteCourseRepository extends _SqliteCourseStore
    with
        _SqliteCatalogStore,
        _SqliteUsersStore,
        _SqliteOrdersStore,
        _SqlitePaymentsStore,
        _SqliteAccessStore,
        _SqliteWarmupStore,
        _SqliteAnalyticsStore,
        _SqliteConversationStore
    implements CourseRepository {
  SqliteCourseRepository({
    required SqliteDatabaseHandle databaseHandle,
    DateTime Function()? nowProvider,
  }) : super(
          databaseHandle,
          nowProvider ?? DateTime.now,
        );

  @override
  void init() {
    _handle.ensureCourseSchema();
    seedDefaultWarmupSteps();
  }

  @override
  T transaction<T>(T Function() action) => _handle.transaction(action);
}

class _SqliteCourseStore {
  _SqliteCourseStore(this._handle, this._nowProvider);

  static const int previewMaxLength = 400;

  final SqliteDatabaseHandle _handle;
  final DateTime Function() _nowProvider;

  Database get _db => _handle.database;

  UserProfile mapUser(Row row) {
    return UserProfile(
      userId: row['user_id'] as int,
      username: row['username'] as String?,
      firstName: row['first_name'] as String?,
      source: row['source'] as String?,
      funnelPhase: FunnelPhaseX.parse(row['funnel_phase'] as String?),
      warmupOptOut: (row['warmup_opt_out'] as int) == 1,
      botBlocked: (row['bot_blocked'] as int) == 1,
      magnetIssuedAt: parseTime(row['magnet_issued_at'] as String?),
      firstStartedAt: DateTime.parse(row['first_started_at'] as String),
      lastSeenAt: DateTime.parse(row['last_seen_at'] as String),
    );
  }

  CourseOrder mapOrder(Row row) {
    return CourseOrder(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      launchId: row['launch_id'] as int,
      status: OrderStatusX.parse(row['status'] as String?),
      kind: PaymentKindX.parse(row['kind'] as String?),
      priceFullKopecks: row['price_full_kopecks'] as int,
      amountPaidKopecks: row['amount_paid_kopecks'] as int,
      amountDueKopecks: row['amount_due_kopecks'] as int,
      dueAt: parseTime(row['due_at'] as String?),
      checkoutStartedAt: DateTime.parse(row['checkout_started_at'] as String),
      paidAt: parseTime(row['paid_at'] as String?),
      cancelledAt: parseTime(row['cancelled_at'] as String?),
      accessGranted: (row['access_granted'] as int) == 1,
    );
  }

  PaymentRecord mapPayment(Row row) {
    return PaymentRecord(
      id: row['id'] as int,
      orderId: row['order_id'] as int,
      provider: row['provider'] as String,
      providerPaymentId: row['provider_payment_id'] as String?,
      kind: PaymentKindX.parse(row['kind'] as String?),
      amountKopecks: row['amount_kopecks'] as int,
      status: PaymentRecordStatusX.parse(row['status'] as String?),
      confirmationUrl: row['confirmation_url'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      succeededAt: parseTime(row['succeeded_at'] as String?),
    );
  }

  ChannelAccess mapAccess(Row row) {
    return ChannelAccess(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      launchId: row['launch_id'] as int,
      orderId: row['order_id'] as int,
      inviteLink: row['invite_link'] as String?,
      inviteCreatedAt: parseTime(row['invite_created_at'] as String?),
      joinedAt: parseTime(row['joined_at'] as String?),
      revokedAt: parseTime(row['revoked_at'] as String?),
    );
  }

  Launch mapLaunch(Row row) {
    return Launch(
      id: row['id'] as int,
      productId: row['product_id'] as int,
      code: row['code'] as String,
      title: row['title'] as String,
      channelId: row['channel_id'] as int?,
      priceFullKopecks: row['price_full_kopecks'] as int,
      depositKopecks: row['deposit_kopecks'] as int,
      depositDueDays: row['deposit_due_days'] as int,
      offerUrl: row['offer_url'] as String?,
      leadMagnetFileId: row['lead_magnet_file_id'] as String?,
      leadMagnetUrl: row['lead_magnet_url'] as String?,
    );
  }

  ConversationLogEntry mapLog(Row row) {
    return ConversationLogEntry(
      id: row['id'] as int,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      direction: ConversationDirection.values.byName(row['direction'] as String),
      peerUserId: row['peer_user_id'] as int,
      peerUsername: row['peer_username'] as String?,
      chatId: row['chat_id'] as int,
      telegramMessageId: row['telegram_message_id'] as int?,
      contentType: ConversationContentType.values.byName(row['content_type'] as String),
      textPreview: row['text_preview'] as String?,
    );
  }

  DateTime? parseTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.parse(raw);
  }
}
