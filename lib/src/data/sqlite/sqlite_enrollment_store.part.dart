part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteEnrollmentStore on _SqliteCatalogStore
    implements EnrollmentRepository, AttributionRepository {
  @override
  UserEnrollment ensureEnrollment({
    required int userId,
    required int launchId,
    required DateTime now,
  }) {
    final existing = getEnrollment(userId: userId, launchId: launchId);
    if (existing != null) {
      return existing;
    }
    final nowIso = now.toUtc().toIso8601String();
    _db.execute(
      '''
      INSERT OR IGNORE INTO user_enrollments (
        user_id, launch_id, funnel_phase, warmup_opt_out, magnet_issued_at, started_at, updated_at
      ) VALUES (?, ?, 'lead', 0, NULL, ?, ?);
      ''',
      <Object?>[userId, launchId, nowIso, nowIso],
    );
    return getEnrollment(userId: userId, launchId: launchId)!;
  }

  @override
  UserEnrollment? getEnrollment({required int userId, required int launchId}) {
    final rows = _db.select(
      'SELECT * FROM user_enrollments WHERE user_id = ? AND launch_id = ?;',
      <Object?>[userId, launchId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return mapEnrollment(rows.first);
  }

  void writeEnrollmentPhase({
    required int userId,
    required int launchId,
    required FunnelPhase phase,
    DateTime? magnetIssuedAt,
  }) {
    ensureEnrollment(userId: userId, launchId: launchId, now: _nowProvider());
    final existing = getEnrollment(userId: userId, launchId: launchId);
    final nextPhase = existing == null || existing.funnelPhase.canTransitionTo(phase)
        ? phase
        : existing.funnelPhase;
    if (magnetIssuedAt != null) {
      _db.execute(
        '''
        UPDATE user_enrollments
        SET funnel_phase = ?, magnet_issued_at = COALESCE(magnet_issued_at, ?), updated_at = ?
        WHERE user_id = ? AND launch_id = ?;
        ''',
        <Object?>[
          nextPhase.storageValue,
          magnetIssuedAt.toUtc().toIso8601String(),
          _nowProvider().toUtc().toIso8601String(),
          userId,
          launchId,
        ],
      );
      return;
    }
    if (existing != null && !existing.funnelPhase.canTransitionTo(phase)) {
      return;
    }
    _db.execute(
      '''
      UPDATE user_enrollments
      SET funnel_phase = ?, updated_at = ?
      WHERE user_id = ? AND launch_id = ?;
      ''',
      <Object?>[nextPhase.storageValue, _nowProvider().toUtc().toIso8601String(), userId, launchId],
    );
  }

  @override
  void setEnrollmentWarmupOptOut({
    required int userId,
    required int launchId,
    required bool optOut,
  }) {
    ensureEnrollment(userId: userId, launchId: launchId, now: _nowProvider());
    _db.execute(
      '''
      UPDATE user_enrollments
      SET warmup_opt_out = ?, updated_at = ?
      WHERE user_id = ? AND launch_id = ?;
      ''',
      <Object?>[optOut ? 1 : 0, _nowProvider().toUtc().toIso8601String(), userId, launchId],
    );
  }

  int? resolveEnrollmentLaunchId(int? launchId) {
    return launchId ?? activeLaunch()?.id;
  }

  bool isActiveLaunchId(int launchId) {
    return activeLaunch()?.id == launchId;
  }

  @override
  void recordAcquisitionEvent({
    required int userId,
    required String payload,
    required DateTime occurredAt,
    AcquisitionDestination? destination,
    int? productId,
    int? launchId,
  }) {
    _db.execute(
      '''
      INSERT INTO acquisition_events (
        user_id, payload, destination, product_id, launch_id, occurred_at
      ) VALUES (?, ?, ?, ?, ?, ?);
      ''',
      <Object?>[
        userId,
        payload,
        destination?.name,
        productId,
        launchId,
        occurredAt.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  List<AcquisitionEvent> listAcquisitionEvents(int userId, {int limit = 20}) {
    final rows = _db.select(
      '''
      SELECT * FROM acquisition_events
      WHERE user_id = ?
      ORDER BY occurred_at DESC, id DESC
      LIMIT ?;
      ''',
      <Object?>[userId, limit],
    );
    return rows.map(mapAcquisitionEvent).toList(growable: false);
  }
}
