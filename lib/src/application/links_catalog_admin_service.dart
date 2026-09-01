import 'package:course_chatbot/src/data/catalog_repository.dart';
import 'package:course_chatbot/src/data/google_sheets_catalog_sync.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/catalog_admin.dart';
import 'package:course_chatbot/src/domain/funnel.dart';

final class LinksAdminResult {
  const LinksAdminResult._({
    required this.ok,
    this.failure,
    this.fieldError,
    this.link,
    this.detail,
  });

  const LinksAdminResult.ok({AcquisitionLink? link}) : this._(ok: true, link: link);

  const LinksAdminResult.fail(CatalogAdminFailure failure, {String? detail, AcquisitionLink? link})
    : this._(ok: false, failure: failure, detail: detail, link: link);

  const LinksAdminResult.invalid(CatalogLinkFieldError fieldError)
    : this._(ok: false, fieldError: fieldError);

  final bool ok;
  final CatalogAdminFailure? failure;
  final CatalogLinkFieldError? fieldError;
  final AcquisitionLink? link;
  final String? detail;
}

final class LinksCatalogAdminService {
  LinksCatalogAdminService({
    required GoogleSheetsCatalogSync sync,
    required AcquisitionLinkCatalog links,
    required CatalogRepository catalog,
  }) : _sync = sync,
       _links = links,
       _catalog = catalog;

  final GoogleSheetsCatalogSync _sync;
  final AcquisitionLinkCatalog _links;
  final CatalogRepository _catalog;

  static CatalogLinkFieldError? validateOrigin(String raw) {
    return raw.trim().isEmpty ? CatalogLinkFieldError.emptyOrigin : null;
  }

  static CatalogLinkFieldError? validatePayload(
    String raw, {
    String? currentPayload,
    Set<String> taken = const <String>{},
  }) {
    final normalized = AcquisitionSource.normalize(raw);
    if (normalized == null) {
      return CatalogLinkFieldError.badPayload;
    }
    if (currentPayload != null && AcquisitionSource.normalize(currentPayload) == normalized) {
      return null;
    }
    if (taken.contains(normalized)) {
      return CatalogLinkFieldError.payloadTaken;
    }
    return null;
  }

  CatalogLinkFieldError? validateLaunch(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    if (_catalog.launchByCode(text) != null || _catalog.launchByTitle(text) != null) {
      return null;
    }
    return CatalogLinkFieldError.badLaunch;
  }

  String? resolveLaunchLabel(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final launch = _catalog.launchByCode(text) ?? _catalog.launchByTitle(text);
    return launch?.title ?? text;
  }

  Set<String> takenPayloads({String? except}) {
    final skip = AcquisitionSource.normalize(except);
    return <String>{
      for (final link in _links.entries)
        if (skip == null || link.payload != skip) link.payload,
    };
  }

  List<AcquisitionLink> listVisibleLinks() => _links.entries;

  AcquisitionLink? byIndex(int index) {
    final entries = _links.entries;
    if (index < 0 || index >= entries.length) {
      return null;
    }
    return entries[index];
  }

  AcquisitionLink? byPayload(String? payload) => _links.byPayload(payload);

  Future<LinksAdminResult> create(AcquisitionLink link) async {
    final error = _validateComplete(link, currentPayload: null);
    if (error != null) {
      return LinksAdminResult.invalid(error);
    }
    if (_links.byPayload(link.payload) != null) {
      return const LinksAdminResult.invalid(CatalogLinkFieldError.payloadTaken);
    }
    return _write(link: link, insertOnly: true);
  }

  Future<LinksAdminResult> update({
    required String currentPayload,
    required AcquisitionLink link,
  }) async {
    final existing = _links.byPayload(currentPayload);
    if (existing == null) {
      return const LinksAdminResult.fail(CatalogAdminFailure.notFound);
    }
    final error = _validateComplete(link, currentPayload: currentPayload);
    if (error != null) {
      return LinksAdminResult.invalid(error);
    }
    final renamed = AcquisitionSource.normalize(link.payload);
    if (renamed != existing.payload && _links.byPayload(renamed) != null) {
      return const LinksAdminResult.invalid(CatalogLinkFieldError.payloadTaken);
    }
    return _write(link: link, previousPayload: currentPayload);
  }

  Future<LinksAdminResult> delete(String payload) async {
    final existing = _links.byPayload(payload);
    if (existing == null) {
      return const LinksAdminResult.fail(CatalogAdminFailure.notFound);
    }
    if (_links.entries.length <= 1) {
      return const LinksAdminResult.fail(CatalogAdminFailure.lastLink);
    }
    try {
      await _sync.deleteLinkRow(payload: payload);
      await _sync.syncLinks();
      return const LinksAdminResult.ok();
    } on Object catch (error) {
      return LinksAdminResult.fail(CatalogAdminFailure.writeFailed, detail: '$error');
    }
  }

  CatalogLinkFieldError? _validateComplete(
    AcquisitionLink link, {
    required String? currentPayload,
  }) {
    final originError = validateOrigin(link.origin);
    if (originError != null) {
      return originError;
    }
    final payloadError = validatePayload(
      link.payload,
      currentPayload: currentPayload,
      taken: takenPayloads(except: currentPayload),
    );
    if (payloadError != null) {
      return payloadError;
    }
    return validateLaunch(link.launchCode ?? '');
  }

  Future<LinksAdminResult> _write({
    required AcquisitionLink link,
    String? previousPayload,
    bool insertOnly = false,
  }) async {
    try {
      await _sync.upsertLinkRow(
        link: link,
        previousPayload: previousPayload,
        insertOnly: insertOnly,
      );
      await _sync.syncLinks();
      return LinksAdminResult.ok(link: _links.byPayload(link.payload) ?? link);
    } on Object catch (error) {
      final text = '$error';
      if (text.contains('already exists')) {
        return const LinksAdminResult.invalid(CatalogLinkFieldError.payloadTaken);
      }
      return LinksAdminResult.fail(CatalogAdminFailure.writeFailed, detail: text);
    }
  }
}
