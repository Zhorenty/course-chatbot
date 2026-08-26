import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/sqlite/sqlite_database_handle.dart';
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

final class SqliteCourseRepository implements CourseRepository {
  static const int _previewMaxLength = 400;

  SqliteCourseRepository({
    required SqliteDatabaseHandle databaseHandle,
    DateTime Function()? nowProvider,
  })  : _handle = databaseHandle,
        _nowProvider = nowProvider ?? DateTime.now;

  final SqliteDatabaseHandle _handle;
  final DateTime Function() _nowProvider;

  Database get _db => _handle.database;

  @override
  Future<void> init() async {
    _handle.ensureCourseSchema();
    seedDefaultWarmupSteps();
  }

  @override
  T transaction<T>(T Function() action) => _handle.transaction(action);

  @override
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
  }) async {
    _db.execute(
      '''
      INSERT INTO products (code, title) VALUES (?, ?)
      ON CONFLICT(code) DO UPDATE SET title = excluded.title;
      ''',
      <Object?>[productCode, productTitle],
    );
    final productId = _db.select(
      'SELECT id FROM products WHERE code = ?;',
      <Object?>[productCode],
    ).first['id'] as int;
    _db.execute(
      '''
      INSERT INTO launches (
        product_id, code, title, channel_id, price_full_kopecks, deposit_kopecks,
        deposit_due_days, offer_url, lead_magnet_file_id, lead_magnet_url
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(code) DO UPDATE SET
        title = excluded.title,
        channel_id = COALESCE(excluded.channel_id, launches.channel_id),
        price_full_kopecks = excluded.price_full_kopecks,
        deposit_kopecks = excluded.deposit_kopecks,
        deposit_due_days = excluded.deposit_due_days,
        offer_url = COALESCE(excluded.offer_url, launches.offer_url),
        lead_magnet_file_id = COALESCE(excluded.lead_magnet_file_id, launches.lead_magnet_file_id),
        lead_magnet_url = COALESCE(excluded.lead_magnet_url, launches.lead_magnet_url);
      ''',
      <Object?>[
        productId,
        launchCode,
        launchTitle,
        channelId,
        priceFullKopecks,
        depositKopecks,
        depositDueDays,
        offerUrl,
        leadMagnetFileId,
        leadMagnetUrl,
      ],
    );
    return activeLaunch()!;
  }

  @override
  Launch? activeLaunch() {
    final rows = _db.select('SELECT * FROM launches ORDER BY id DESC LIMIT 1;');
    if (rows.isEmpty) {
      return null;
    }
    return _mapLaunch(rows.first);
  }

  @override
  Future<void> setLeadMagnetFileId(String fileId) async {
    final launch = activeLaunch();
    if (launch == null) {
      return;
    }
    _db.execute(
      'UPDATE launches SET lead_magnet_file_id = ? WHERE id = ?;',
      <Object?>[fileId, launch.id],
    );
  }

  @override
  Future<UserProfile> ensureUser({
    required int userId,
    String? username,
    String? firstName,
    String? source,
    required DateTime now,
  }) async {
    final existing = getUser(userId);
    final nowIso = now.toUtc().toIso8601String();
    final normalized = normalizeTelegramUsername(username);
    if (existing == null) {
      _db.execute(
        '''
        INSERT INTO telegram_users (
          user_id, username, first_name, source, funnel_phase, warmup_opt_out,
          bot_blocked, first_started_at, last_seen_at, updated_at
        ) VALUES (?, ?, ?, ?, 'lead', 0, 0, ?, ?, ?);
        ''',
        <Object?>[userId, normalized, firstName, source, nowIso, nowIso, nowIso],
      );
      return getUser(userId)!;
    }
    _db.execute(
      '''
      UPDATE telegram_users
      SET username = COALESCE(?, username),
          first_name = COALESCE(?, first_name),
          last_seen_at = ?,
          updated_at = ?,
          bot_blocked = 0
      WHERE user_id = ?;
      ''',
      <Object?>[normalized, firstName, nowIso, nowIso, userId],
    );
    if ((existing.source == null || existing.source!.isEmpty) &&
        source != null &&
        source.isNotEmpty) {
      _db.execute(
        'UPDATE telegram_users SET source = ? WHERE user_id = ?;',
        <Object?>[source, userId],
      );
    }
    return getUser(userId)!;
  }

  @override
  UserProfile? getUser(int userId) {
    final rows = _db.select(
      'SELECT * FROM telegram_users WHERE user_id = ?;',
      <Object?>[userId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapUser(rows.first);
  }

  @override
  Future<void> touchUser({
    required int userId,
    String? username,
    String? firstName,
    required DateTime now,
  }) async {
    await ensureUser(
      userId: userId,
      username: username,
      firstName: firstName,
      now: now,
    );
  }

  @override
  void setFunnelPhase({
    required int userId,
    required FunnelPhase phase,
    DateTime? magnetIssuedAt,
  }) {
    if (magnetIssuedAt != null) {
      _db.execute(
        '''
        UPDATE telegram_users
        SET funnel_phase = ?, magnet_issued_at = COALESCE(magnet_issued_at, ?), updated_at = ?
        WHERE user_id = ?;
        ''',
        <Object?>[
          phase.storageValue,
          magnetIssuedAt.toUtc().toIso8601String(),
          _nowProvider().toUtc().toIso8601String(),
          userId,
        ],
      );
      return;
    }
    _db.execute(
      '''
      UPDATE telegram_users
      SET funnel_phase = ?, updated_at = ?
      WHERE user_id = ?;
      ''',
      <Object?>[phase.storageValue, _nowProvider().toUtc().toIso8601String(), userId],
    );
  }

  @override
  void setWarmupOptOut({required int userId, required bool optOut}) {
    _db.execute(
      'UPDATE telegram_users SET warmup_opt_out = ?, updated_at = ? WHERE user_id = ?;',
      <Object?>[optOut ? 1 : 0, _nowProvider().toUtc().toIso8601String(), userId],
    );
  }

  @override
  void setBotBlocked({required int userId, required bool blocked}) {
    _db.execute(
      'UPDATE telegram_users SET bot_blocked = ?, updated_at = ? WHERE user_id = ?;',
      <Object?>[blocked ? 1 : 0, _nowProvider().toUtc().toIso8601String(), userId],
    );
  }

  @override
  UserProfile? findUserByUsername(String username) {
    final normalized = normalizeTelegramUsername(username);
    if (normalized == null) {
      return null;
    }
    final rows = _db.select(
      '''
      SELECT * FROM telegram_users
      WHERE username = ? COLLATE NOCASE
      ORDER BY updated_at DESC LIMIT 1;
      ''',
      <Object?>[normalized],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapUser(rows.first);
  }

  @override
  List<UserProfile> searchUsers(String query, {int limit = 10}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <UserProfile>[];
    }
    final asId = int.tryParse(trimmed);
    if (asId != null) {
      final user = getUser(asId);
      return user == null ? const <UserProfile>[] : <UserProfile>[user];
    }
    final normalized = normalizeTelegramUsername(trimmed) ?? trimmed.toLowerCase();
    final rows = _db.select(
      '''
      SELECT * FROM telegram_users
      WHERE username LIKE ? COLLATE NOCASE OR CAST(user_id AS TEXT) = ?
      ORDER BY updated_at DESC
      LIMIT ?;
      ''',
      <Object?>['%$normalized%', trimmed, limit],
    );
    return rows.map(_mapUser).toList(growable: false);
  }

  @override
  List<int> listBroadcastUserIds({required BroadcastSegment segment}) {
    final sql = switch (segment) {
      BroadcastSegment.allStarted => '''
        SELECT user_id FROM telegram_users
        WHERE bot_blocked = 0
        ORDER BY user_id;
      ''',
      BroadcastSegment.guideNotPaid => '''
        SELECT user_id FROM telegram_users
        WHERE bot_blocked = 0
          AND magnet_issued_at IS NOT NULL
          AND funnel_phase NOT IN ('paid', 'access_granted', 'cancelled', 'deposit_paid')
        ORDER BY user_id;
      ''',
    };
    return _db.select(sql).map((row) => row['user_id'] as int).toList(growable: false);
  }

  @override
  CourseOrder createOrder({
    required int userId,
    required int launchId,
    required PaymentKind kind,
    required int priceFullKopecks,
    required int amountDueKopecks,
    required DateTime now,
    DateTime? dueAt,
  }) {
    _db.execute(
      '''
      INSERT INTO orders (
        user_id, launch_id, status, kind, price_full_kopecks, amount_paid_kopecks,
        amount_due_kopecks, due_at, checkout_started_at, access_granted
      ) VALUES (?, ?, ?, ?, ?, 0, ?, ?, ?, 0);
      ''',
      <Object?>[
        userId,
        launchId,
        OrderStatus.checkoutStarted.storageValue,
        kind.storageValue,
        priceFullKopecks,
        amountDueKopecks,
        dueAt?.toUtc().toIso8601String(),
        now.toUtc().toIso8601String(),
      ],
    );
    final id = _db.select('SELECT last_insert_rowid() AS id;').first['id'] as int;
    return getOrder(id)!;
  }

  @override
  CourseOrder? getOrder(int orderId) {
    final rows = _db.select('SELECT * FROM orders WHERE id = ?;', <Object?>[orderId]);
    if (rows.isEmpty) {
      return null;
    }
    return _mapOrder(rows.first);
  }

  @override
  CourseOrder? latestOpenOrder(int userId) {
    final rows = _db.select(
      '''
      SELECT * FROM orders
      WHERE user_id = ? AND status IN ('checkout_started', 'awaiting_payment', 'deposit_paid')
      ORDER BY id DESC LIMIT 1;
      ''',
      <Object?>[userId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapOrder(rows.first);
  }

  @override
  CourseOrder? latestOrder(int userId) {
    final rows = _db.select(
      'SELECT * FROM orders WHERE user_id = ? ORDER BY id DESC LIMIT 1;',
      <Object?>[userId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapOrder(rows.first);
  }

  @override
  List<CourseOrder> listOrdersForUser(int userId, {int limit = 10}) {
    final rows = _db.select(
      'SELECT * FROM orders WHERE user_id = ? ORDER BY id DESC LIMIT ?;',
      <Object?>[userId, limit],
    );
    return rows.map(_mapOrder).toList(growable: false);
  }

  @override
  void updateOrder(CourseOrder order) {
    _db.execute(
      '''
      UPDATE orders SET
        status = ?, kind = ?, amount_paid_kopecks = ?, amount_due_kopecks = ?,
        due_at = ?, paid_at = ?, cancelled_at = ?, access_granted = ?
      WHERE id = ?;
      ''',
      <Object?>[
        order.status.storageValue,
        order.kind.storageValue,
        order.amountPaidKopecks,
        order.amountDueKopecks,
        order.dueAt?.toUtc().toIso8601String(),
        order.paidAt?.toUtc().toIso8601String(),
        order.cancelledAt?.toUtc().toIso8601String(),
        order.accessGranted ? 1 : 0,
        order.id,
      ],
    );
  }

  @override
  PaymentRecord insertPayment({
    required int orderId,
    required String provider,
    required PaymentKind kind,
    required int amountKopecks,
    required DateTime now,
    String? providerPaymentId,
    String? confirmationUrl,
    PaymentRecordStatus status = PaymentRecordStatus.pending,
  }) {
    _db.execute(
      '''
      INSERT INTO payments (
        order_id, provider, provider_payment_id, kind, amount_kopecks,
        status, confirmation_url, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      <Object?>[
        orderId,
        provider,
        providerPaymentId,
        kind.storageValue,
        amountKopecks,
        status.storageValue,
        confirmationUrl,
        now.toUtc().toIso8601String(),
      ],
    );
    final id = _db.select('SELECT last_insert_rowid() AS id;').first['id'] as int;
    return getPayment(id)!;
  }

  @override
  PaymentRecord? getPayment(int paymentId) {
    final rows = _db.select('SELECT * FROM payments WHERE id = ?;', <Object?>[paymentId]);
    if (rows.isEmpty) {
      return null;
    }
    return _mapPayment(rows.first);
  }

  @override
  PaymentRecord? findPaymentByProviderId({
    required String provider,
    required String providerPaymentId,
  }) {
    final rows = _db.select(
      '''
      SELECT * FROM payments
      WHERE provider = ? AND provider_payment_id = ?
      ORDER BY id DESC LIMIT 1;
      ''',
      <Object?>[provider, providerPaymentId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapPayment(rows.first);
  }

  @override
  PaymentRecord? latestPendingPayment(int orderId) {
    final rows = _db.select(
      '''
      SELECT * FROM payments
      WHERE order_id = ? AND status = 'pending'
      ORDER BY id DESC LIMIT 1;
      ''',
      <Object?>[orderId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapPayment(rows.first);
  }

  @override
  void updatePayment(PaymentRecord payment) {
    _db.execute(
      '''
      UPDATE payments SET
        provider_payment_id = ?, status = ?, confirmation_url = ?, succeeded_at = ?
      WHERE id = ?;
      ''',
      <Object?>[
        payment.providerPaymentId,
        payment.status.storageValue,
        payment.confirmationUrl,
        payment.succeededAt?.toUtc().toIso8601String(),
        payment.id,
      ],
    );
  }

  @override
  ChannelAccess? accessFor({required int userId, required int launchId}) {
    final rows = _db.select(
      'SELECT * FROM channel_access WHERE user_id = ? AND launch_id = ?;',
      <Object?>[userId, launchId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapAccess(rows.first);
  }

  @override
  ChannelAccess upsertAccess({
    required int userId,
    required int launchId,
    required int orderId,
    String? inviteLink,
    DateTime? inviteCreatedAt,
    DateTime? joinedAt,
    DateTime? revokedAt,
  }) {
    _db.execute(
      '''
      INSERT INTO channel_access (
        user_id, launch_id, order_id, invite_link, invite_created_at, joined_at, revoked_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(user_id, launch_id) DO UPDATE SET
        order_id = excluded.order_id,
        invite_link = excluded.invite_link,
        invite_created_at = excluded.invite_created_at,
        joined_at = COALESCE(excluded.joined_at, channel_access.joined_at),
        revoked_at = excluded.revoked_at;
      ''',
      <Object?>[
        userId,
        launchId,
        orderId,
        inviteLink,
        inviteCreatedAt?.toUtc().toIso8601String(),
        joinedAt?.toUtc().toIso8601String(),
        revokedAt?.toUtc().toIso8601String(),
      ],
    );
    return accessFor(userId: userId, launchId: launchId)!;
  }

  @override
  void markJoined({
    required int userId,
    required int launchId,
    required DateTime joinedAt,
  }) {
    _db.execute(
      '''
      UPDATE channel_access
      SET joined_at = COALESCE(joined_at, ?)
      WHERE user_id = ? AND launch_id = ?;
      ''',
      <Object?>[joinedAt.toUtc().toIso8601String(), userId, launchId],
    );
  }

  @override
  List<WarmupStep> listWarmupSteps() {
    final rows = _db.select(
      'SELECT * FROM warmup_steps WHERE enabled = 1 ORDER BY sort_order, step_key;',
    );
    return rows
        .map(
          (row) => WarmupStep(
            stepKey: row['step_key'] as String,
            delay: Duration(seconds: row['delay_seconds'] as int),
            sortOrder: row['sort_order'] as int,
            enabled: (row['enabled'] as int) == 1,
          ),
        )
        .toList(growable: false);
  }

  @override
  void seedDefaultWarmupSteps() {
    final existing = _db.select('SELECT COUNT(*) AS c FROM warmup_steps;');
    if ((existing.first['c'] as int) > 0) {
      return;
    }
    const steps = <(String, int, int)>[
      ('warmup_0', 0, 0),
      ('warmup_d1', 86400, 1),
      ('warmup_d3', 259200, 2),
    ];
    for (final step in steps) {
      _db.execute(
        '''
        INSERT INTO warmup_steps (step_key, delay_seconds, sort_order, enabled)
        VALUES (?, ?, ?, 1);
        ''',
        <Object?>[step.$1, step.$2, step.$3],
      );
    }
  }

  @override
  bool hasWarmupBeenSent({required int userId, required String stepKey}) {
    final rows = _db.select(
      'SELECT 1 FROM warmup_sent WHERE user_id = ? AND step_key = ? LIMIT 1;',
      <Object?>[userId, stepKey],
    );
    return rows.isNotEmpty;
  }

  @override
  void recordWarmupSent({
    required int userId,
    required String stepKey,
    required DateTime sentAt,
  }) {
    _db.execute(
      '''
      INSERT OR IGNORE INTO warmup_sent (user_id, step_key, sent_at)
      VALUES (?, ?, ?);
      ''',
      <Object?>[userId, stepKey, sentAt.toUtc().toIso8601String()],
    );
  }

  @override
  List<WarmupCandidate> listWarmupCandidates({required DateTime now, int limit = 100}) {
    final rows = _db.select(
      '''
      SELECT user_id, magnet_issued_at, first_started_at
      FROM telegram_users
      WHERE bot_blocked = 0
        AND warmup_opt_out = 0
        AND funnel_phase IN ('magnet_issued', 'warming')
      ORDER BY first_started_at
      LIMIT ?;
      ''',
      <Object?>[limit],
    );
    return [
      for (final row in rows)
        WarmupCandidate(
          userId: row['user_id'] as int,
          anchorAt: DateTime.parse(
            (row['magnet_issued_at'] as String?) ?? (row['first_started_at'] as String),
          ),
          sentKeys: _sentKeys(row['user_id'] as int),
        ),
    ];
  }

  Set<String> _sentKeys(int userId) {
    final rows = _db.select(
      'SELECT step_key FROM warmup_sent WHERE user_id = ?;',
      <Object?>[userId],
    );
    return rows.map((row) => row['step_key'] as String).toSet();
  }

  @override
  List<CourseOrder> listAbandonedCheckout({
    required DateTime now,
    required Duration minAge,
    int limit = 100,
  }) {
    final threshold = now.toUtc().subtract(minAge).toIso8601String();
    final rows = _db.select(
      '''
      SELECT o.*
      FROM orders o
      JOIN telegram_users u ON u.user_id = o.user_id
      WHERE o.status = 'awaiting_payment'
        AND o.checkout_started_at <= ?
        AND u.bot_blocked = 0
      ORDER BY o.id
      LIMIT ?;
      ''',
      <Object?>[threshold, limit],
    );
    return rows.map(_mapOrder).toList(growable: false);
  }

  @override
  List<CourseOrder> listRemainderDue({
    required DateTime now,
    int limit = 100,
  }) {
    final nowIso = now.toUtc().toIso8601String();
    final rows = _db.select(
      '''
      SELECT o.*
      FROM orders o
      JOIN telegram_users u ON u.user_id = o.user_id
      WHERE o.status = 'deposit_paid'
        AND o.due_at IS NOT NULL
        AND o.due_at <= ?
        AND u.bot_blocked = 0
      ORDER BY o.due_at
      LIMIT ?;
      ''',
      <Object?>[nowIso, limit],
    );
    return rows.map(_mapOrder).toList(growable: false);
  }

  @override
  FunnelAnalytics funnelAnalytics({required DateTime now}) {
    final nowUtc = now.toUtc();
    final d7 = nowUtc.subtract(const Duration(days: 7)).toIso8601String();
    final d30 = nowUtc.subtract(const Duration(days: 30)).toIso8601String();
    int scalar(String sql, [List<Object?> params = const <Object?>[]]) {
      return _db.select(sql, params).first['c'] as int;
    }

    Map<String, int> grouped(String sql) {
      final map = <String, int>{};
      for (final row in _db.select(sql)) {
        map[row['k']?.toString() ?? 'unknown'] = row['c'] as int;
      }
      return map;
    }

    return FunnelAnalytics(
      generatedAt: nowUtc,
      startedUsersTotal: scalar('SELECT COUNT(*) AS c FROM telegram_users;'),
      funnelUsers: scalar(
        '''
        SELECT COUNT(*) AS c FROM telegram_users
        WHERE funnel_phase NOT IN ('cancelled');
        ''',
      ),
      guideTaken: scalar(
        'SELECT COUNT(*) AS c FROM telegram_users WHERE magnet_issued_at IS NOT NULL;',
      ),
      checkoutStarted: scalar(
        '''
        SELECT COUNT(DISTINCT user_id) AS c FROM orders;
        ''',
      ),
      paidUsers: scalar(
        '''
        SELECT COUNT(*) AS c FROM telegram_users
        WHERE funnel_phase IN ('paid', 'access_granted');
        ''',
      ),
      startedLast7Days: scalar(
        'SELECT COUNT(*) AS c FROM telegram_users WHERE first_started_at >= ?;',
        <Object?>[d7],
      ),
      startedLast30Days: scalar(
        'SELECT COUNT(*) AS c FROM telegram_users WHERE first_started_at >= ?;',
        <Object?>[d30],
      ),
      paidLast7Days: scalar(
        '''
        SELECT COUNT(*) AS c FROM orders
        WHERE status = 'paid' AND paid_at >= ?;
        ''',
        <Object?>[d7],
      ),
      paidLast30Days: scalar(
        '''
        SELECT COUNT(*) AS c FROM orders
        WHERE status = 'paid' AND paid_at >= ?;
        ''',
        <Object?>[d30],
      ),
      phaseCounts: grouped(
        'SELECT funnel_phase AS k, COUNT(*) AS c FROM telegram_users GROUP BY funnel_phase;',
      ),
      sourceCounts: grouped(
        '''
        SELECT COALESCE(source, 'unknown') AS k, COUNT(*) AS c
        FROM telegram_users GROUP BY COALESCE(source, 'unknown');
        ''',
      ),
    );
  }

  @override
  Future<void> appendConversation({
    required ConversationDirection direction,
    required int peerUserId,
    String? peerUsername,
    required int chatId,
    int? telegramMessageId,
    required ConversationContentType contentType,
    String? textPreview,
  }) async {
    if (peerUserId <= 0 || chatId <= 0) {
      return;
    }
    final normalized = normalizeTelegramUsername(peerUsername);
    _db.execute(
      '''
      INSERT INTO conversation_log (
        occurred_at, direction, peer_user_id, peer_username, chat_id,
        telegram_message_id, content_type, text_preview
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      <Object?>[
        _nowProvider().toUtc().toIso8601String(),
        direction.name,
        peerUserId,
        normalized,
        chatId,
        telegramMessageId,
        contentType.name,
        _truncatePreview(textPreview),
      ],
    );
  }

  @override
  List<ConversationLogEntry> dialogForUser(int userId, {int limit = 30}) {
    final rows = _db.select(
      '''
      SELECT * FROM conversation_log
      WHERE peer_user_id = ?
      ORDER BY occurred_at DESC, id DESC
      LIMIT ?;
      ''',
      <Object?>[userId, limit],
    );
    return rows.map(_mapLog).toList().reversed.toList(growable: false);
  }

  UserProfile _mapUser(Row row) {
    return UserProfile(
      userId: row['user_id'] as int,
      username: row['username'] as String?,
      firstName: row['first_name'] as String?,
      source: row['source'] as String?,
      funnelPhase: FunnelPhaseX.parse(row['funnel_phase'] as String?),
      warmupOptOut: (row['warmup_opt_out'] as int) == 1,
      botBlocked: (row['bot_blocked'] as int) == 1,
      magnetIssuedAt: _parseTime(row['magnet_issued_at'] as String?),
      firstStartedAt: DateTime.parse(row['first_started_at'] as String),
      lastSeenAt: DateTime.parse(row['last_seen_at'] as String),
    );
  }

  CourseOrder _mapOrder(Row row) {
    return CourseOrder(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      launchId: row['launch_id'] as int,
      status: OrderStatusX.parse(row['status'] as String?),
      kind: PaymentKindX.parse(row['kind'] as String?),
      priceFullKopecks: row['price_full_kopecks'] as int,
      amountPaidKopecks: row['amount_paid_kopecks'] as int,
      amountDueKopecks: row['amount_due_kopecks'] as int,
      dueAt: _parseTime(row['due_at'] as String?),
      checkoutStartedAt: DateTime.parse(row['checkout_started_at'] as String),
      paidAt: _parseTime(row['paid_at'] as String?),
      cancelledAt: _parseTime(row['cancelled_at'] as String?),
      accessGranted: (row['access_granted'] as int) == 1,
    );
  }

  PaymentRecord _mapPayment(Row row) {
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
      succeededAt: _parseTime(row['succeeded_at'] as String?),
    );
  }

  ChannelAccess _mapAccess(Row row) {
    return ChannelAccess(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      launchId: row['launch_id'] as int,
      orderId: row['order_id'] as int,
      inviteLink: row['invite_link'] as String?,
      inviteCreatedAt: _parseTime(row['invite_created_at'] as String?),
      joinedAt: _parseTime(row['joined_at'] as String?),
      revokedAt: _parseTime(row['revoked_at'] as String?),
    );
  }

  Launch _mapLaunch(Row row) {
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

  ConversationLogEntry _mapLog(Row row) {
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

  DateTime? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.parse(raw);
  }

  String? _truncatePreview(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final plain = trimmed.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (plain.isEmpty) {
      return null;
    }
    if (plain.runes.length <= _previewMaxLength) {
      return plain;
    }
    return '${String.fromCharCodes(plain.runes.take(_previewMaxLength))}…';
  }
}
