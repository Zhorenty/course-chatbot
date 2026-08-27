part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteCatalogStore on _SqliteCourseStore implements CatalogRepository {
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
    _db.execute('UPDATE launches SET is_active = 0;');
    _db.execute(
      'UPDATE launches SET is_active = 1 WHERE code = ?;',
      <Object?>[launchCode],
    );
    return activeLaunch()!;
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
  void setLeadMagnetFileId(String fileId) {
    final launch = activeLaunch();
    if (launch == null) {
      return;
    }
    _db.execute(
      'UPDATE launches SET lead_magnet_file_id = ? WHERE id = ?;',
      <Object?>[fileId, launch.id],
    );
  }
}
