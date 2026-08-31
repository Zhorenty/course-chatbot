part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersAdminCatalog on PrivateHandlers {
  bool _isCatalogStep(PrivateFlowStep? step) {
    return step == PrivateFlowStep.adminCatalogMenu ||
        step == PrivateFlowStep.adminCatalogCreateTitle ||
        step == PrivateFlowStep.adminCatalogCreateCode ||
        step == PrivateFlowStep.adminCatalogCreatePrice ||
        step == PrivateFlowStep.adminCatalogCreateDeposit ||
        step == PrivateFlowStep.adminCatalogCreateDepositDue ||
        step == PrivateFlowStep.adminCatalogCreateStart ||
        step == PrivateFlowStep.adminCatalogCreateChannel ||
        step == PrivateFlowStep.adminCatalogCreateActive ||
        step == PrivateFlowStep.adminCatalogCreateConfirm ||
        step == PrivateFlowStep.adminCatalogEditValue;
  }

  Future<bool> _openCatalogFromMenu(PrivateMessageContext context) {
    return _showCatalogList(context, pinKeyboard: true);
  }

  Future<bool> _cancelCatalog(PrivateMessageContext context) async {
    _flowByUserId[context.userId!] = const PrivateFlowState(step: PrivateFlowStep.idle);
    return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
  }

  Future<bool> _showCatalogList(PrivateMessageContext context, {bool pinKeyboard = false}) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final admin = _catalogAdmin;
    if (admin == null) {
      _flowByUserId[context.userId!] = const PrivateFlowState(step: PrivateFlowStep.idle);
      return _send(
        context,
        _templates.adminSheetsDisabled(),
        replyMarkup: _templates.adminMenuKeyboard(),
      );
    }
    _flowByUserId[context.userId!] = const PrivateFlowState(step: PrivateFlowStep.adminCatalogMenu);
    if (pinKeyboard) {
      await _send(
        context,
        _templates.adminCatalogOpened(),
        replyMarkup: _templates.adminCatalogFlowKeyboard(),
      );
    }
    final launches = _course.listLaunches();
    return _send(
      context,
      _templates.adminCatalogList(launches),
      replyMarkup: _templates.adminCatalogListKeyboard(launches),
    );
  }

  Future<bool> _showCatalogCard(PrivateMessageContext context, int? launchId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || launchId == null) {
      return false;
    }
    if (_catalogAdmin == null) {
      return _send(
        context,
        _templates.adminSheetsDisabled(),
        replyMarkup: _templates.adminMenuKeyboard(),
      );
    }
    final launch = _course.getLaunch(launchId);
    if (launch == null) {
      return _showCatalogList(context);
    }
    _flowByUserId[context.userId!] = const PrivateFlowState(step: PrivateFlowStep.adminCatalogMenu);
    return _send(
      context,
      _templates.adminCatalogCard(launch),
      replyMarkup: _templates.adminCatalogCardKeyboard(launch),
    );
  }

  Future<bool> _startCatalogCreate(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    if (_catalogAdmin == null) {
      return _send(
        context,
        _templates.adminSheetsDisabled(),
        replyMarkup: _templates.adminMenuKeyboard(),
      );
    }
    _flowByUserId[context.userId!] = const PrivateFlowState(
      step: PrivateFlowStep.adminCatalogCreateTitle,
      catalogDraft: CatalogWizardDraft(),
    );
    return _send(
      context,
      _templates.adminCatalogAskTitle(),
      replyMarkup: _templates.adminCatalogFlowKeyboard(),
    );
  }

  Future<bool> _captureCatalog(PrivateMessageContext context) async {
    final flow = _flowByUserId[context.userId!];
    final step = flow?.step;
    if (step == PrivateFlowStep.adminCatalogEditValue) {
      return _captureCatalogEdit(context);
    }
    if (step == PrivateFlowStep.adminCatalogCreateActive ||
        step == PrivateFlowStep.adminCatalogCreateConfirm) {
      return true;
    }
    final text = context.text?.trim() ?? '';
    final draft = flow?.catalogDraft ?? const CatalogWizardDraft();
    switch (step) {
      case PrivateFlowStep.adminCatalogCreateTitle:
        final error = LaunchCatalogAdminService.validateTitle(text);
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        final suggested = CoursesSheetParser.suggestLaunchCode(
          text,
          existing: _catalogAdmin?.takenLaunchCodes() ?? const <String>{},
        );
        _flowByUserId[context.userId!] = PrivateFlowState(
          step: PrivateFlowStep.adminCatalogCreateCode,
          catalogDraft: draft.copyWith(title: text, code: suggested),
        );
        return _send(context, _templates.adminCatalogAskCode(suggested));
      case PrivateFlowStep.adminCatalogCreateCode:
        final raw = text.isEmpty ? (draft.code ?? '') : text;
        final error = LaunchCatalogAdminService.validateCode(
          raw,
          taken: _catalogAdmin?.takenLaunchCodes() ?? const <String>{},
        );
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        _flowByUserId[context.userId!] = PrivateFlowState(
          step: PrivateFlowStep.adminCatalogCreatePrice,
          catalogDraft: draft.copyWith(code: raw.trim()),
        );
        return _send(context, _templates.adminCatalogAskPrice());
      case PrivateFlowStep.adminCatalogCreatePrice:
        final error = LaunchCatalogAdminService.validatePrice(text);
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        _flowByUserId[context.userId!] = PrivateFlowState(
          step: PrivateFlowStep.adminCatalogCreateDeposit,
          catalogDraft: draft.copyWith(priceKopecks: CoursesSheetParser.parsePriceKopecks(text)),
        );
        return _send(context, _templates.adminCatalogAskDeposit());
      case PrivateFlowStep.adminCatalogCreateDeposit:
        final price = draft.priceKopecks ?? 0;
        final error = LaunchCatalogAdminService.validateDeposit(text, priceKopecks: price);
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        final deposit = text.isEmpty ? 0 : (CoursesSheetParser.parsePriceKopecks(text) ?? 0);
        final next = draft.copyWith(depositKopecks: deposit, depositDueAt: null);
        if (deposit > 0) {
          _flowByUserId[context.userId!] = PrivateFlowState(
            step: PrivateFlowStep.adminCatalogCreateDepositDue,
            catalogDraft: next,
          );
          return _send(context, _templates.adminCatalogAskDepositDue());
        }
        _flowByUserId[context.userId!] = PrivateFlowState(
          step: PrivateFlowStep.adminCatalogCreateStart,
          catalogDraft: next,
        );
        return _send(context, _templates.adminCatalogAskStart());
      case PrivateFlowStep.adminCatalogCreateDepositDue:
        final error = LaunchCatalogAdminService.validateDueDate(text);
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        _flowByUserId[context.userId!] = PrivateFlowState(
          step: PrivateFlowStep.adminCatalogCreateStart,
          catalogDraft: draft.copyWith(
            depositDueAt: CoursesSheetParser.parseDateEndOfDay(
              text,
              timezoneOffsetHours: CoursesSheet.defaultTimezoneOffsetHours,
            ),
          ),
        );
        return _send(context, _templates.adminCatalogAskStart());
      case PrivateFlowStep.adminCatalogCreateStart:
        final error = LaunchCatalogAdminService.validateStartDate(text);
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        _flowByUserId[context.userId!] = PrivateFlowState(
          step: PrivateFlowStep.adminCatalogCreateChannel,
          catalogDraft: draft.copyWith(courseStartAt: CoursesSheetParser.parseDate(text)),
        );
        return _send(context, _templates.adminCatalogAskChannel());
      case PrivateFlowStep.adminCatalogCreateChannel:
        final error = LaunchCatalogAdminService.validateChannel(text);
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        final skipped = text.isEmpty || text == '-' || text == '—';
        _flowByUserId[context.userId!] = PrivateFlowState(
          step: PrivateFlowStep.adminCatalogCreateActive,
          catalogDraft: draft.copyWith(
            channelId: skipped ? null : CoursesSheetParser.parseChannelId(text),
            channelSkipped: skipped,
          ),
        );
        return _send(
          context,
          _templates.adminCatalogAskActive(),
          replyMarkup: _templates.adminCatalogActiveKeyboard(),
        );
      default:
        return false;
    }
  }

  Future<bool> _setCatalogCreateActive(PrivateMessageContext context, bool isActive) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final draft = _flowByUserId[context.userId!]?.catalogDraft;
    if (draft == null) {
      return _startCatalogCreate(context);
    }
    _flowByUserId[context.userId!] = PrivateFlowState(
      step: PrivateFlowStep.adminCatalogCreateConfirm,
      catalogDraft: draft.copyWith(isActive: isActive),
    );
    final built = _wizardToDraft(draft.copyWith(isActive: isActive));
    if (built == null) {
      return _startCatalogCreate(context);
    }
    return _send(
      context,
      _templates.adminCatalogPreview(built),
      replyMarkup: _templates.adminCatalogConfirmCreateKeyboard(),
    );
  }

  Future<bool> _confirmCatalogCreate(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final admin = _catalogAdmin;
    if (admin == null) {
      return _send(
        context,
        _templates.adminSheetsDisabled(),
        replyMarkup: _templates.adminMenuKeyboard(),
      );
    }
    final built = _wizardToDraft(_flowByUserId[context.userId!]?.catalogDraft);
    if (built == null) {
      return _startCatalogCreate(context);
    }
    return _runCatalogWrite(context, () => admin.create(built), thenCode: built.launchCode);
  }

  Future<bool> _showCatalogFields(PrivateMessageContext context, int? launchId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || launchId == null) {
      return false;
    }
    final launch = _course.getLaunch(launchId);
    if (launch == null) {
      return _showCatalogList(context);
    }
    _flowByUserId[context.userId!] = const PrivateFlowState(step: PrivateFlowStep.adminCatalogMenu);
    return _send(
      context,
      _templates.adminCatalogPickField(),
      replyMarkup: _templates.adminCatalogFieldsKeyboard(launchId),
    );
  }

  Future<bool> _askCatalogEditField(
    PrivateMessageContext context,
    int? launchId,
    CatalogLaunchField? field,
  ) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || launchId == null || field == null) {
      return false;
    }
    if (_course.getLaunch(launchId) == null) {
      return _showCatalogList(context);
    }
    _flowByUserId[context.userId!] = PrivateFlowState(
      step: PrivateFlowStep.adminCatalogEditValue,
      catalogDraft: CatalogWizardDraft(editLaunchId: launchId, editField: field),
    );
    return _send(
      context,
      _templates.adminCatalogAskField(field),
      replyMarkup: _templates.adminCatalogFlowKeyboard(),
    );
  }

  Future<bool> _captureCatalogEdit(PrivateMessageContext context) async {
    final admin = _catalogAdmin;
    final flow = _flowByUserId[context.userId!]?.catalogDraft;
    final launchId = flow?.editLaunchId;
    final field = flow?.editField;
    final launch = launchId == null ? null : _course.getLaunch(launchId);
    if (admin == null || launch == null || field == null) {
      return _showCatalogList(context);
    }
    final text = context.text?.trim() ?? '';
    var overlay = admin.draftFromLaunch(launch);
    switch (field) {
      case CatalogLaunchField.title:
        final error = LaunchCatalogAdminService.validateTitle(text);
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        overlay = overlay.copyWith(launchTitle: text);
      case CatalogLaunchField.code:
        final error = LaunchCatalogAdminService.validateCode(
          text,
          currentCode: launch.code,
          taken: admin.takenLaunchCodes(except: launch.code),
        );
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        overlay = overlay.copyWith(launchCode: text.trim());
      case CatalogLaunchField.price:
        final error = LaunchCatalogAdminService.validatePrice(text);
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        overlay = overlay.copyWith(priceFullKopecks: CoursesSheetParser.parsePriceKopecks(text));
      case CatalogLaunchField.deposit:
        final error = LaunchCatalogAdminService.validateDeposit(
          text,
          priceKopecks: overlay.priceFullKopecks,
        );
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        final deposit = text.isEmpty ? 0 : (CoursesSheetParser.parsePriceKopecks(text) ?? 0);
        overlay = overlay.copyWith(
          depositKopecks: deposit,
          depositDueAt: deposit > 0 ? overlay.depositDueAt : null,
        );
        if (deposit > 0 && overlay.depositDueAt == null) {
          _flowByUserId[context.userId!] = PrivateFlowState(
            step: PrivateFlowStep.adminCatalogEditValue,
            catalogDraft: CatalogWizardDraft(
              editLaunchId: launchId,
              editField: CatalogLaunchField.depositDue,
            ),
          );
          return _send(context, _templates.adminCatalogAskField(CatalogLaunchField.depositDue));
        }
      case CatalogLaunchField.depositDue:
        final error = LaunchCatalogAdminService.validateDueDate(text);
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        overlay = overlay.copyWith(depositDueAt: CoursesSheetParser.parseDateEndOfDay(text));
      case CatalogLaunchField.start:
        final error = LaunchCatalogAdminService.validateStartDate(text);
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        overlay = overlay.copyWith(courseStartAt: CoursesSheetParser.parseDate(text));
      case CatalogLaunchField.channel:
        final error = LaunchCatalogAdminService.validateChannel(text);
        if (error != null) {
          return _send(context, _templates.adminCatalogFieldError(error));
        }
        final skipped = text.isEmpty || text == '-' || text == '—';
        if (!skipped) {
          overlay = overlay.copyWith(channelId: CoursesSheetParser.parseChannelId(text));
        }
    }
    return _runCatalogWrite(
      context,
      () => admin.update(currentCode: launch.code, draft: overlay),
      thenCardId: launchId,
    );
  }

  Future<bool> _activateCatalogLaunch(PrivateMessageContext context, int? launchId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || launchId == null) {
      return false;
    }
    final admin = _catalogAdmin;
    final launch = _course.getLaunch(launchId);
    if (admin == null || launch == null) {
      return _showCatalogList(context);
    }
    return _runCatalogWrite(context, () => admin.activate(launch.code), thenCardId: launchId);
  }

  Future<bool> _askCatalogDelete(PrivateMessageContext context, int? launchId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || launchId == null) {
      return false;
    }
    final launch = _course.getLaunch(launchId);
    if (launch == null) {
      return _showCatalogList(context);
    }
    return _send(
      context,
      _templates.adminCatalogConfirmDelete(launch),
      replyMarkup: _templates.adminConfirmKeyboard(
        yesData: '${MessageTemplates.cbCatalogDeleteYes}$launchId',
        noData: '${MessageTemplates.cbCatalogOpen}$launchId',
      ),
    );
  }

  Future<bool> _confirmCatalogDelete(PrivateMessageContext context, int? launchId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || launchId == null) {
      return false;
    }
    final admin = _catalogAdmin;
    final launch = _course.getLaunch(launchId);
    if (admin == null || launch == null) {
      return _showCatalogList(context);
    }
    final title = launch.title;
    final code = launch.code;
    final result = await _runCatalogOp(context, () => admin.delete(code));
    if (!result) {
      return true;
    }
    await _send(context, _templates.adminCatalogDeleted(title, code));
    return _showCatalogList(context);
  }

  Future<bool> _runCatalogWrite(
    PrivateMessageContext context,
    Future<CatalogAdminResult> Function() action, {
    int? thenCardId,
    String? thenCode,
  }) async {
    final ok = await _runCatalogOp(context, action);
    if (!ok) {
      return true;
    }
    final launch = thenCardId != null
        ? _course.getLaunch(thenCardId)
        : (thenCode == null ? null : _course.launchByCode(thenCode));
    if (launch != null) {
      await _send(context, _templates.adminCatalogSaved(launch));
      return _showCatalogCard(context, launch.id);
    }
    return _showCatalogList(context);
  }

  Future<bool> _runCatalogOp(
    PrivateMessageContext context,
    Future<CatalogAdminResult> Function() action,
  ) async {
    final progressId = await _sendProgress(context, _templates.adminCatalogWriting());
    CatalogAdminResult result;
    try {
      result = await action();
    } on Object catch (error, stackTrace) {
      l.w('Admin COURSES catalog write failed: $error', stackTrace);
      result = CatalogAdminResult.fail(CatalogAdminFailure.writeFailed, detail: '$error');
    } finally {
      await _deleteProgress(context, progressId);
    }
    if (result.ok) {
      return true;
    }
    if (result.fieldError != null) {
      await _send(context, _templates.adminCatalogFieldError(result.fieldError!));
      return false;
    }
    await _send(
      context,
      _templates.adminCatalogFailure(
        result.failure ?? CatalogAdminFailure.writeFailed,
        detail: result.detail,
      ),
    );
    return false;
  }

  CatalogLaunchDraft? _wizardToDraft(CatalogWizardDraft? draft) {
    final title = draft?.title?.trim();
    final code = draft?.code?.trim();
    final price = draft?.priceKopecks;
    final start = draft?.courseStartAt;
    if (title == null ||
        title.isEmpty ||
        code == null ||
        code.isEmpty ||
        price == null ||
        start == null) {
      return null;
    }
    final deposit = draft?.depositKopecks ?? 0;
    return CatalogLaunchDraft(
      productCode: CoursesSheet.seedProductCode,
      productTitle: CoursesSheet.seedProductTitle,
      launchCode: code,
      launchTitle: title,
      isActive: draft?.isActive ?? false,
      priceFullKopecks: price,
      depositKopecks: deposit,
      depositDueDays: CoursesSheet.defaultDepositDueDays,
      depositDueAt: deposit > 0 ? draft?.depositDueAt : null,
      courseStartAt: start,
      channelId: draft?.channelSkipped == true ? null : draft?.channelId,
    );
  }
}
