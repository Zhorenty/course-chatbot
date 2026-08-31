import 'package:course_chatbot/src/data/catalog_repository.dart';
import 'package:course_chatbot/src/data/google_sheets_catalog_sync.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/catalog_admin.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';

final class CatalogAdminResult {
  const CatalogAdminResult._({
    required this.ok,
    this.failure,
    this.fieldError,
    this.launch,
    this.detail,
  });

  const CatalogAdminResult.ok({Launch? launch}) : this._(ok: true, launch: launch);

  const CatalogAdminResult.fail(CatalogAdminFailure failure, {String? detail, Launch? launch})
    : this._(ok: false, failure: failure, detail: detail, launch: launch);

  const CatalogAdminResult.invalid(CatalogFieldError fieldError)
    : this._(ok: false, fieldError: fieldError);

  final bool ok;
  final CatalogAdminFailure? failure;
  final CatalogFieldError? fieldError;
  final Launch? launch;
  final String? detail;
}

final class LaunchCatalogAdminService {
  LaunchCatalogAdminService({
    required GoogleSheetsCatalogSync sync,
    required CatalogRepository catalog,
  }) : _sync = sync,
       _catalog = catalog;

  final GoogleSheetsCatalogSync _sync;
  final CatalogRepository _catalog;

  static CatalogFieldError? validateTitle(String raw) {
    return raw.trim().isEmpty ? CatalogFieldError.emptyTitle : null;
  }

  static CatalogFieldError? validateCode(
    String raw, {
    String? currentCode,
    Set<String> taken = const <String>{},
  }) {
    final code = raw.trim();
    if (!CoursesSheetParser.isValidLaunchCode(code)) {
      return CatalogFieldError.badCode;
    }
    if (currentCode != null && currentCode.trim() == code) {
      return null;
    }
    if (taken.contains(code)) {
      return CatalogFieldError.codeTaken;
    }
    return null;
  }

  static CatalogFieldError? validatePrice(String raw) {
    final kopecks = CoursesSheetParser.parsePriceKopecks(raw);
    if (kopecks == null || kopecks <= 0) {
      return CatalogFieldError.badPrice;
    }
    return null;
  }

  static CatalogFieldError? validateDeposit(String raw, {required int priceKopecks}) {
    final text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    final kopecks = CoursesSheetParser.parsePriceKopecks(text);
    if (kopecks == null || kopecks < 0 || kopecks >= priceKopecks) {
      return CatalogFieldError.badDeposit;
    }
    return null;
  }

  static CatalogFieldError? validateDueDate(String raw) {
    if (CoursesSheetParser.parseDate(raw) == null) {
      return CatalogFieldError.badDate;
    }
    return null;
  }

  static CatalogFieldError? validateStartDate(String raw) {
    if (CoursesSheetParser.parseDate(raw) == null) {
      return CatalogFieldError.badDate;
    }
    return null;
  }

  static CatalogFieldError? validateChannel(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '-' || text == '—') {
      return null;
    }
    final id = CoursesSheetParser.parseChannelId(text);
    if (id == null || id >= 0) {
      return CatalogFieldError.badChannel;
    }
    return null;
  }

  CatalogLaunchDraft draftFromLaunch(Launch launch) {
    return CatalogLaunchDraft(
      productCode: CoursesSheet.seedProductCode,
      productTitle: CoursesSheet.seedProductTitle,
      launchCode: launch.code,
      launchTitle: launch.title,
      isActive: launch.isActive,
      priceFullKopecks: launch.priceFullKopecks,
      depositKopecks: launch.depositKopecks,
      depositDueDays: CoursesSheet.defaultDepositDueDays,
      depositDueAt: launch.depositDueAt,
      courseStartAt: launch.courseStartAt,
      channelId: launch.channelId,
      offerUrl: launch.offerUrl,
      leadMagnetFileId: launch.leadMagnetFileId,
      leadMagnetUrl: launch.leadMagnetUrl,
    );
  }

  Set<String> takenLaunchCodes({String? except}) {
    return <String>{
      for (final launch in _catalog.listLaunches())
        if (except == null || launch.code != except) launch.code,
    };
  }

  Future<CatalogAdminResult> create(CatalogLaunchDraft draft) async {
    final error = _validateComplete(draft, currentCode: null);
    if (error != null) {
      return CatalogAdminResult.invalid(error);
    }
    if (_catalog.launchByCode(draft.launchCode) != null) {
      return const CatalogAdminResult.invalid(CatalogFieldError.codeTaken);
    }
    return _write(draft: draft);
  }

  Future<CatalogAdminResult> update({
    required String currentCode,
    required CatalogLaunchDraft draft,
  }) async {
    final existing = _catalog.launchByCode(currentCode);
    if (existing == null) {
      return const CatalogAdminResult.fail(CatalogAdminFailure.notFound);
    }
    final error = _validateComplete(draft, currentCode: currentCode);
    if (error != null) {
      return CatalogAdminResult.invalid(error);
    }
    if (draft.launchCode != currentCode && _catalog.launchByCode(draft.launchCode) != null) {
      return const CatalogAdminResult.invalid(CatalogFieldError.codeTaken);
    }
    if (draft.launchCode != currentCode) {
      try {
        _catalog.renameLaunchCode(from: currentCode, to: draft.launchCode);
      } on Object catch (error) {
        return CatalogAdminResult.fail(CatalogAdminFailure.codeTaken, detail: '$error');
      }
    }
    final written = await _write(draft: draft, previousLaunchCode: currentCode);
    if (!written.ok && draft.launchCode != currentCode) {
      try {
        _catalog.renameLaunchCode(from: draft.launchCode, to: currentCode);
      } on Object catch (_) {}
    }
    return written;
  }

  Future<CatalogAdminResult> activate(String launchCode) async {
    final launch = _catalog.launchByCode(launchCode);
    if (launch == null) {
      return const CatalogAdminResult.fail(CatalogAdminFailure.notFound);
    }
    return _write(
      draft: draftFromLaunch(launch).copyWith(isActive: true),
      previousLaunchCode: launchCode,
    );
  }

  Future<CatalogAdminResult> delete(String launchCode) async {
    final launch = _catalog.launchByCode(launchCode);
    if (launch == null) {
      return const CatalogAdminResult.fail(CatalogAdminFailure.notFound);
    }
    final others = _catalog.listLaunches().where((row) => row.code != launchCode).toList();
    if (others.isEmpty) {
      return const CatalogAdminResult.fail(CatalogAdminFailure.lastLaunch);
    }
    if (launch.isActive) {
      return const CatalogAdminResult.fail(CatalogAdminFailure.activeLaunch);
    }
    if (_catalog.launchUsage(launch.id).hasPeople) {
      return const CatalogAdminResult.fail(CatalogAdminFailure.hasPeople);
    }
    try {
      await _sync.deleteCourseRow(launchCode: launchCode);
      _catalog.tryDeleteLaunch(launch.id);
      final synced = await _sync.sync();
      if (!synced.ok) {
        return CatalogAdminResult.fail(
          CatalogAdminFailure.writeFailed,
          detail: synced.error,
          launch: synced.launch,
        );
      }
      return CatalogAdminResult.ok(launch: synced.launch);
    } on Object catch (error) {
      return CatalogAdminResult.fail(CatalogAdminFailure.writeFailed, detail: '$error');
    }
  }

  CatalogFieldError? _validateComplete(CatalogLaunchDraft draft, {required String? currentCode}) {
    final titleError = validateTitle(draft.launchTitle);
    if (titleError != null) {
      return titleError;
    }
    final codeError = validateCode(
      draft.launchCode,
      currentCode: currentCode,
      taken: takenLaunchCodes(except: currentCode),
    );
    if (codeError != null) {
      return codeError;
    }
    if (draft.priceFullKopecks <= 0) {
      return CatalogFieldError.badPrice;
    }
    if (draft.depositKopecks < 0 || draft.depositKopecks >= draft.priceFullKopecks) {
      return CatalogFieldError.badDeposit;
    }
    if (draft.depositKopecks > 0 && draft.depositDueAt == null) {
      return CatalogFieldError.needDueDate;
    }
    if (draft.courseStartAt == null) {
      return CatalogFieldError.badDate;
    }
    return null;
  }

  Future<CatalogAdminResult> _write({
    required CatalogLaunchDraft draft,
    String? previousLaunchCode,
  }) async {
    try {
      await _sync.upsertCourseRow(draft: draft, previousLaunchCode: previousLaunchCode);
      final synced = await _sync.sync();
      if (!synced.ok) {
        return CatalogAdminResult.fail(
          CatalogAdminFailure.writeFailed,
          detail: synced.error,
          launch: synced.launch,
        );
      }
      return CatalogAdminResult.ok(
        launch: _catalog.launchByCode(draft.launchCode) ?? synced.launch,
      );
    } on Object catch (error) {
      final text = '$error';
      if (text.contains('already exists')) {
        return const CatalogAdminResult.invalid(CatalogFieldError.codeTaken);
      }
      return CatalogAdminResult.fail(CatalogAdminFailure.writeFailed, detail: text);
    }
  }
}
