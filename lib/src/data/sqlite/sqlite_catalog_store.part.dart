part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteCatalogStore on _SqliteCourseStore implements CatalogRepository {
  @override
  Launch upsertLaunch({
    required String productCode,
    required String productTitle,
    required String launchCode,
    required String launchTitle,
    required int priceFullKopecks,
    required int depositKopecks,
    required int depositDueDays,
    DateTime? depositDueAt,
    DateTime? courseStartAt,
    int? channelId,
    String? offerUrl,
    String? leadMagnetFileId,
    String? leadMagnetUrl,
    bool activate = false,
  }) {
    _db.execute(
      '''
      INSERT INTO products (code, title) VALUES (?, ?)
      ON CONFLICT(code) DO UPDATE SET title = excluded.title;
      ''',
      <Object?>[productCode, productTitle],
    );
    final productId =
        _db.select('SELECT id FROM products WHERE code = ?;', <Object?>[productCode]).first['id']
            as int;
    _db.execute(
      '''
      INSERT INTO launches (
        product_id, code, title, channel_id, price_full_kopecks, deposit_kopecks,
        deposit_due_days, deposit_due_at, course_start_at, offer_url,
        lead_magnet_file_id, lead_magnet_url, is_active
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
      ON CONFLICT(code) DO UPDATE SET
        title = excluded.title,
        channel_id = COALESCE(excluded.channel_id, launches.channel_id),
        price_full_kopecks = excluded.price_full_kopecks,
        deposit_kopecks = excluded.deposit_kopecks,
        deposit_due_days = excluded.deposit_due_days,
        deposit_due_at = excluded.deposit_due_at,
        course_start_at = excluded.course_start_at,
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
        depositDueAt?.toUtc().toIso8601String(),
        courseStartAt?.toUtc().toIso8601String(),
        offerUrl,
        leadMagnetFileId,
        leadMagnetUrl,
      ],
    );
    if (activate) {
      setActiveLaunch(launchCode);
    }
    return launchByCode(launchCode)!;
  }

  @override
  Launch upsertActiveLaunch({
    required String productCode,
    required String productTitle,
    required String launchCode,
    required String launchTitle,
    required int priceFullKopecks,
    required int depositKopecks,
    required int depositDueDays,
    DateTime? depositDueAt,
    DateTime? courseStartAt,
    int? channelId,
    String? offerUrl,
    String? leadMagnetFileId,
    String? leadMagnetUrl,
  }) {
    return upsertLaunch(
      productCode: productCode,
      productTitle: productTitle,
      launchCode: launchCode,
      launchTitle: launchTitle,
      priceFullKopecks: priceFullKopecks,
      depositKopecks: depositKopecks,
      depositDueDays: depositDueDays,
      depositDueAt: depositDueAt,
      courseStartAt: courseStartAt,
      channelId: channelId,
      offerUrl: offerUrl,
      leadMagnetFileId: leadMagnetFileId,
      leadMagnetUrl: leadMagnetUrl,
      activate: true,
    );
  }

  @override
  void setActiveLaunch(String launchCode) {
    _db.execute('UPDATE launches SET is_active = 0;');
    _db.execute('UPDATE launches SET is_active = 1 WHERE code = ?;', <Object?>[launchCode]);
  }

  @override
  Launch? activeLaunch() {
    final active = _db.select(
      'SELECT * FROM launches WHERE is_active = 1 ORDER BY id DESC LIMIT 1;',
    );
    if (active.isNotEmpty) {
      return mapLaunch(active.first);
    }
    final rows = _db.select('SELECT * FROM launches ORDER BY id DESC LIMIT 1;');
    if (rows.isEmpty) {
      return null;
    }
    return mapLaunch(rows.first);
  }

  @override
  Launch? getLaunch(int id) {
    final rows = _db.select('SELECT * FROM launches WHERE id = ?;', <Object?>[id]);
    if (rows.isEmpty) {
      return null;
    }
    return mapLaunch(rows.first);
  }

  @override
  Launch? launchByCode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final rows = _db.select('SELECT * FROM launches WHERE code = ?;', <Object?>[trimmed]);
    if (rows.isEmpty) {
      return null;
    }
    return mapLaunch(rows.first);
  }

  @override
  Launch? launchByTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final rows = _db.select(
      '''
      SELECT * FROM launches
      WHERE title = ?
      ORDER BY is_active DESC, id DESC
      LIMIT 1;
      ''',
      <Object?>[trimmed],
    );
    if (rows.isEmpty) {
      return null;
    }
    return mapLaunch(rows.first);
  }

  @override
  Launch? launchByChannelId(int channelId) {
    final rows = _db.select(
      '''
      SELECT * FROM launches
      WHERE channel_id = ?
      ORDER BY is_active DESC, id DESC
      LIMIT 1;
      ''',
      <Object?>[channelId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return mapLaunch(rows.first);
  }

  @override
  List<Launch> listLaunches() {
    final rows = _db.select('SELECT * FROM launches ORDER BY is_active DESC, id ASC;');
    return <Launch>[for (final row in rows) mapLaunch(row)];
  }

  @override
  LaunchUsage launchUsage(int launchId) {
    int count(String table) {
      final rows = _db.select('SELECT COUNT(*) AS c FROM $table WHERE launch_id = ?;', <Object?>[
        launchId,
      ]);
      return (rows.first['c'] as int?) ?? 0;
    }

    return LaunchUsage(
      enrollments: count('user_enrollments'),
      orders: count('orders'),
      channelAccess: count('channel_access'),
      acquisitionEvents: count('acquisition_events'),
      warmupSent: count('warmup_sent'),
    );
  }

  @override
  void renameLaunchCode({required String from, required String to}) {
    final previous = from.trim();
    final next = to.trim();
    if (previous.isEmpty || next.isEmpty || previous == next) {
      return;
    }
    final taken = launchByCode(next);
    if (taken != null) {
      throw StateError('launch code "$next" is taken');
    }
    _db.execute('UPDATE launches SET code = ? WHERE code = ?;', <Object?>[next, previous]);
  }

  @override
  bool tryDeleteLaunch(int id) {
    if (launchUsage(id).hasPeople) {
      return false;
    }
    _db.execute('DELETE FROM launches WHERE id = ?;', <Object?>[id]);
    return true;
  }

  @override
  void setLeadMagnetFileId(String fileId, {int? launchId}) {
    final id = launchId ?? activeLaunch()?.id;
    if (id == null) {
      return;
    }
    _db.execute('UPDATE launches SET lead_magnet_file_id = ? WHERE id = ?;', <Object?>[fileId, id]);
  }
}
