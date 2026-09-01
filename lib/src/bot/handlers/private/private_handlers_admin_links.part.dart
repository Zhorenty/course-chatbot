part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersAdminLinks on PrivateHandlers {
  bool _isLinksStep(PrivateFlowStep? step) {
    return step == PrivateFlowStep.adminLinksMenu ||
        step == PrivateFlowStep.adminLinksCreateOrigin ||
        step == PrivateFlowStep.adminLinksCreateDestination ||
        step == PrivateFlowStep.adminLinksCreatePayload ||
        step == PrivateFlowStep.adminLinksCreateLaunch ||
        step == PrivateFlowStep.adminLinksCreateConfirm ||
        step == PrivateFlowStep.adminLinksEditValue;
  }

  bool _canWriteLinks() => _linksAdmin != null;

  Future<bool> _openLinksFromMenu(PrivateMessageContext context) async {
    await _deleteInboundMessage(context);
    await _ensureSheetsHubPinned(context);
    return _showLinksList(context, refresh: _catalogSync != null);
  }

  Future<bool> _showLinksList(PrivateMessageContext context, {bool refresh = false}) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    if (refresh) {
      _setLinksFlow(context.userId!, PrivateFlowStep.adminLinksMenu, clearDraft: true);
      await _presentCatalog(context, _templates.adminLinksRefreshing());
      final notice = await _refreshLinksFromSheets();
      _setLinksFlow(context.userId!, PrivateFlowStep.adminLinksMenu, clearDraft: true);
      final links = _funnel.links.entries;
      return _presentCatalog(
        context,
        _templates.adminLinksList(links, notice: notice),
        replyMarkup: _templates.adminLinksListKeyboard(links, canWrite: _canWriteLinks()),
      );
    }
    _setLinksFlow(context.userId!, PrivateFlowStep.adminLinksMenu, clearDraft: true);
    final links = _funnel.links.entries;
    return _presentCatalog(
      context,
      _templates.adminLinksList(links),
      replyMarkup: _templates.adminLinksListKeyboard(links, canWrite: _canWriteLinks()),
    );
  }

  Future<bool> _showLinksCard(PrivateMessageContext context, int? index) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || index == null) {
      return false;
    }
    final link = _linkAt(index);
    if (link == null) {
      return _showLinksList(context);
    }
    _setLinksFlow(
      context.userId!,
      PrivateFlowStep.adminLinksMenu,
      linksDraft: LinksWizardDraft(editPayload: link.payload, editIndex: index),
    );
    return _presentCatalog(
      context,
      _templates.adminLinksCard(link),
      replyMarkup: _templates.adminLinksCardKeyboard(index, canWrite: _canWriteLinks()),
    );
  }

  Future<bool> _startLinksCreate(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    if (!_canWriteLinks()) {
      return _presentCatalog(context, _templates.adminSheetsDisabled());
    }
    _setLinksFlow(
      context.userId!,
      PrivateFlowStep.adminLinksCreateOrigin,
      linksDraft: const LinksWizardDraft(),
    );
    return _presentCatalog(context, _templates.adminLinksAskOrigin());
  }

  Future<bool> _captureLinks(PrivateMessageContext context) async {
    await _deleteInboundMessage(context);
    final flow = _flowByUserId[context.userId!];
    final step = flow?.step;
    if (step == PrivateFlowStep.adminLinksEditValue) {
      return _captureLinksEdit(context);
    }
    if (step == PrivateFlowStep.adminLinksMenu ||
        step == PrivateFlowStep.adminLinksCreateDestination ||
        step == PrivateFlowStep.adminLinksCreateLaunch ||
        step == PrivateFlowStep.adminLinksCreateConfirm) {
      return true;
    }
    final text = context.text?.trim() ?? '';
    final draft = flow?.linksDraft ?? const LinksWizardDraft();
    switch (step) {
      case PrivateFlowStep.adminLinksCreateOrigin:
        final error = LinksCatalogAdminService.validateOrigin(text);
        if (error != null) {
          return _presentCatalog(
            context,
            _templates.adminLinksAskWithError(error, _templates.adminLinksAskOrigin()),
          );
        }
        _setLinksFlow(
          context.userId!,
          PrivateFlowStep.adminLinksCreateDestination,
          linksDraft: draft.copyWith(origin: text),
        );
        return _presentCatalog(
          context,
          _templates.adminLinksAskDestination(),
          replyMarkup: _templates.adminLinksDestinationKeyboard(),
        );
      case PrivateFlowStep.adminLinksCreatePayload:
        return _acceptLinksCreatePayload(context, text);
      default:
        return true;
    }
  }

  Future<bool> _setLinksCreateDestination(
    PrivateMessageContext context,
    AcquisitionDestination destination,
  ) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final flow = _flowByUserId[context.userId!];
    if (flow?.step == PrivateFlowStep.adminLinksEditValue &&
        flow?.linksDraft?.editField == CatalogLinkField.destination) {
      return _captureLinksEdit(context, destinationOverride: destination);
    }
    if (flow?.step != PrivateFlowStep.adminLinksCreateDestination) {
      return true;
    }
    final draft = flow?.linksDraft ?? const LinksWizardDraft();
    _setLinksFlow(
      context.userId!,
      PrivateFlowStep.adminLinksCreatePayload,
      linksDraft: draft.copyWith(destination: destination),
    );
    return _presentCatalog(context, _templates.adminLinksAskPayload());
  }

  Future<bool> _acceptLinksCreatePayload(PrivateMessageContext context, String raw) async {
    final draft = _flowByUserId[context.userId!]?.linksDraft ?? const LinksWizardDraft();
    final error = LinksCatalogAdminService.validatePayload(
      raw,
      taken: _linksAdmin?.takenPayloads() ?? _takenPayloads(),
    );
    if (error != null) {
      return _presentCatalog(
        context,
        _templates.adminLinksAskWithError(error, _templates.adminLinksAskPayload()),
      );
    }
    _setLinksFlow(
      context.userId!,
      PrivateFlowStep.adminLinksCreateLaunch,
      linksDraft: draft.copyWith(payload: AcquisitionSource.normalize(raw)),
    );
    return _presentLinksAskLaunch(context);
  }

  Future<bool> _presentLinksAskLaunch(
    PrivateMessageContext context, {
    CatalogLinkFieldError? error,
  }) {
    final ask = _templates.adminLinksAskLaunch();
    return _presentCatalog(
      context,
      error == null ? ask : _templates.adminLinksAskWithError(error, ask),
      replyMarkup: _templates.adminLinksLaunchKeyboard(_visibleLaunches()),
    );
  }

  Future<bool> _setLinksCreateLaunch(
    PrivateMessageContext context, {
    int? launchId,
    bool skip = false,
  }) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final flow = _flowByUserId[context.userId!];
    if (flow?.step == PrivateFlowStep.adminLinksEditValue &&
        flow?.linksDraft?.editField == CatalogLinkField.launch) {
      return _captureLinksEdit(context, launchIdOverride: launchId, skipLaunch: skip);
    }
    if (flow?.step != PrivateFlowStep.adminLinksCreateLaunch) {
      return true;
    }
    final draft = flow?.linksDraft ?? const LinksWizardDraft();
    String? label;
    if (!skip) {
      final launch = launchId == null ? null : _course.getLaunch(launchId);
      if (launch == null) {
        return _presentLinksAskLaunch(context, error: CatalogLinkFieldError.badLaunch);
      }
      label = launch.title;
    }
    _setLinksFlow(
      context.userId!,
      PrivateFlowStep.adminLinksCreateConfirm,
      linksDraft: draft.copyWith(launchCode: label, launchSkipped: skip),
    );
    final built = _wizardToLink(draft.copyWith(launchCode: label, launchSkipped: skip));
    if (built == null) {
      return _startLinksCreate(context);
    }
    return _presentCatalog(
      context,
      _templates.adminLinksPreview(built),
      replyMarkup: _templates.adminLinksConfirmCreateKeyboard(),
    );
  }

  Future<bool> _confirmLinksCreate(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final admin = _linksAdmin;
    if (admin == null) {
      return _presentCatalog(context, _templates.adminSheetsDisabled());
    }
    final built = _wizardToLink(_flowByUserId[context.userId!]?.linksDraft);
    if (built == null) {
      return _startLinksCreate(context);
    }
    return _runLinksWrite(context, () => admin.create(built), thenPayload: built.payload);
  }

  Future<bool> _showLinksFields(PrivateMessageContext context, int? index) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || index == null) {
      return false;
    }
    if (!_canWriteLinks()) {
      return _presentCatalog(context, _templates.adminSheetsDisabled());
    }
    final link = _linkAt(index);
    if (link == null) {
      return _showLinksList(context);
    }
    _setLinksFlow(
      context.userId!,
      PrivateFlowStep.adminLinksMenu,
      linksDraft: LinksWizardDraft(editPayload: link.payload, editIndex: index),
    );
    return _presentCatalog(
      context,
      _templates.adminLinksPickField(),
      replyMarkup: _templates.adminLinksFieldsKeyboard(index),
    );
  }

  Future<bool> _askLinksEditField(
    PrivateMessageContext context,
    int? index,
    CatalogLinkField? field,
  ) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || index == null || field == null) {
      return false;
    }
    if (!_canWriteLinks()) {
      return _presentCatalog(context, _templates.adminSheetsDisabled());
    }
    final link = _linkAt(index);
    if (link == null) {
      return _showLinksList(context);
    }
    _setLinksFlow(
      context.userId!,
      PrivateFlowStep.adminLinksEditValue,
      linksDraft: LinksWizardDraft(editPayload: link.payload, editIndex: index, editField: field),
    );
    final markup = switch (field) {
      CatalogLinkField.destination => _templates.adminLinksDestinationKeyboard(),
      CatalogLinkField.launch => _templates.adminLinksLaunchKeyboard(_visibleLaunches()),
      _ => null,
    };
    return _presentCatalog(context, _templates.adminLinksAskField(field), replyMarkup: markup);
  }

  Future<bool> _captureLinksEdit(
    PrivateMessageContext context, {
    AcquisitionDestination? destinationOverride,
    int? launchIdOverride,
    bool skipLaunch = false,
  }) async {
    final admin = _linksAdmin;
    final flow = _flowByUserId[context.userId!]?.linksDraft;
    final payload = flow?.editPayload;
    final field = flow?.editField;
    final current = payload == null ? null : _funnel.links.byPayload(payload);
    if (admin == null || current == null || field == null) {
      return _showLinksList(context);
    }
    var next = current;
    switch (field) {
      case CatalogLinkField.origin:
        final text = context.text?.trim() ?? '';
        final error = LinksCatalogAdminService.validateOrigin(text);
        if (error != null) {
          return _presentCatalog(
            context,
            _templates.adminLinksAskWithError(error, _templates.adminLinksAskField(field)),
          );
        }
        next = next.copyWith(origin: text);
      case CatalogLinkField.destination:
        if (destinationOverride == null) {
          return true;
        }
        next = next.copyWith(destination: destinationOverride);
      case CatalogLinkField.payload:
        final text = context.text?.trim() ?? '';
        final error = LinksCatalogAdminService.validatePayload(
          text,
          currentPayload: current.payload,
          taken: admin.takenPayloads(except: current.payload),
        );
        if (error != null) {
          return _presentCatalog(
            context,
            _templates.adminLinksAskWithError(error, _templates.adminLinksAskField(field)),
          );
        }
        next = next.copyWith(payload: AcquisitionSource.normalize(text));
      case CatalogLinkField.launch:
        if (skipLaunch) {
          next = next.copyWith(launchCode: null);
        } else {
          final launch = launchIdOverride == null ? null : _course.getLaunch(launchIdOverride);
          if (launch == null) {
            return _presentCatalog(
              context,
              _templates.adminLinksAskWithError(
                CatalogLinkFieldError.badLaunch,
                _templates.adminLinksAskField(field),
              ),
              replyMarkup: _templates.adminLinksLaunchKeyboard(_visibleLaunches()),
            );
          }
          next = next.copyWith(launchCode: launch.title);
        }
    }
    return _runLinksWrite(
      context,
      () => admin.update(currentPayload: current.payload, link: next),
      thenPayload: next.payload,
    );
  }

  Future<bool> _askLinksDelete(PrivateMessageContext context, int? index) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || index == null) {
      return false;
    }
    if (!_canWriteLinks()) {
      return _presentCatalog(context, _templates.adminSheetsDisabled());
    }
    final link = _linkAt(index);
    if (link == null) {
      return _showLinksList(context);
    }
    return _presentCatalog(
      context,
      _templates.adminLinksConfirmDelete(link),
      replyMarkup: _templates.adminLinksConfirmKeyboard(
        yesData: '${MessageTemplates.cbLinksDeleteYes}$index',
        noData: '${MessageTemplates.cbLinksOpen}$index',
      ),
    );
  }

  Future<bool> _confirmLinksDelete(PrivateMessageContext context, int? index) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || index == null) {
      return false;
    }
    final admin = _linksAdmin;
    final link = _linkAt(index);
    if (admin == null || link == null) {
      return _showLinksList(context);
    }
    final result = await _runLinksOp(context, () => admin.delete(link.payload));
    if (!result) {
      return true;
    }
    return _showLinksList(context);
  }

  Future<bool> _runLinksWrite(
    PrivateMessageContext context,
    Future<LinksAdminResult> Function() action, {
    String? thenPayload,
  }) async {
    final ok = await _runLinksOp(context, action);
    if (!ok) {
      return true;
    }
    final entries = _funnel.links.entries;
    final index = thenPayload == null
        ? -1
        : entries.indexWhere((link) => link.payload == AcquisitionSource.normalize(thenPayload));
    if (index >= 0) {
      return _showLinksCard(context, index);
    }
    return _showLinksList(context);
  }

  Future<bool> _runLinksOp(
    PrivateMessageContext context,
    Future<LinksAdminResult> Function() action,
  ) async {
    await _presentCatalog(context, _templates.adminLinksWriting());
    LinksAdminResult result;
    try {
      result = await action();
    } on Object catch (error, stackTrace) {
      l.w('Admin ССЫЛКИ catalog write failed: $error', stackTrace);
      result = LinksAdminResult.fail(CatalogAdminFailure.writeFailed, detail: '$error');
    }
    if (result.ok) {
      return true;
    }
    if (result.fieldError != null) {
      await _presentCatalog(context, _templates.adminLinksFieldError(result.fieldError!));
      return false;
    }
    await _presentCatalog(
      context,
      _templates.adminLinksFailure(
        result.failure ?? CatalogAdminFailure.writeFailed,
        detail: result.detail,
      ),
    );
    return false;
  }

  Future<String?> _refreshLinksFromSheets() async {
    final sync = _catalogSync;
    if (sync == null) {
      return null;
    }
    try {
      await sync.syncLinks();
    } on Object catch (error, stackTrace) {
      l.w('Admin ССЫЛКИ catalog refresh failed: $error', stackTrace);
      return _templates.adminLinksRefreshFailed('$error');
    }
    return null;
  }

  void _setLinksFlow(
    int userId,
    PrivateFlowStep step, {
    LinksWizardDraft? linksDraft,
    bool clearDraft = false,
  }) {
    final current = _flowByUserId[userId];
    _flowByUserId[userId] = PrivateFlowState(
      step: step,
      linksDraft: clearDraft ? null : (linksDraft ?? current?.linksDraft),
      catalogMessageId: current?.catalogMessageId,
      catalogPinMessageId: current?.catalogPinMessageId,
    );
  }

  AcquisitionLink? _linkAt(int index) {
    final fromAdmin = _linksAdmin?.byIndex(index);
    if (fromAdmin != null) {
      return fromAdmin;
    }
    final entries = _funnel.links.entries;
    if (index < 0 || index >= entries.length) {
      return null;
    }
    return entries[index];
  }

  Set<String> _takenPayloads() {
    return <String>{for (final link in _funnel.links.entries) link.payload};
  }

  List<Launch> _visibleLaunches() {
    final listed = _catalogAdmin?.listVisibleLaunches() ?? const <Launch>[];
    if (listed.isNotEmpty) {
      return listed;
    }
    return _course.listLaunches();
  }

  AcquisitionLink? _wizardToLink(LinksWizardDraft? draft) {
    final origin = draft?.origin?.trim();
    final destination = draft?.destination;
    final payload = AcquisitionSource.normalize(draft?.payload);
    if (origin == null || origin.isEmpty || destination == null || payload == null) {
      return null;
    }
    final launch = draft?.launchSkipped == true ? null : draft?.launchCode?.trim();
    return AcquisitionLink(
      origin: origin,
      destination: destination,
      payload: payload,
      launchCode: launch == null || launch.isEmpty ? null : launch,
    );
  }
}
