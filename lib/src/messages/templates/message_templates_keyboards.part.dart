part of 'package:course_chatbot/src/messages/message_templates.dart';

extension MessageTemplateKeyboards on MessageTemplates {
  Map<String, Object?> userMenuKeyboard({required bool showCourseStatus}) {
    return replyKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{'text': MessageTemplates.buttonGuide},
        if (showCourseStatus)
          <String, Object?>{'text': MessageTemplates.buttonCourseStatus}
        else
          <String, Object?>{'text': MessageTemplates.buttonEnroll},
      ],
      <Map<String, Object?>>[
        <String, Object?>{'text': MessageTemplates.buttonHelp},
      ],
    ], inputFieldPlaceholder: 'Если застрял — напиши сюда');
  }

  Map<String, Object?> adminMenuKeyboard() {
    return replyKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{'text': MessageTemplates.buttonAdminSearch},
        <String, Object?>{'text': MessageTemplates.buttonAdminSheetsHub},
      ],
      <Map<String, Object?>>[
        <String, Object?>{'text': MessageTemplates.buttonAdminFunnelLogic},
        <String, Object?>{'text': MessageTemplates.buttonAdminBroadcast},
      ],
      // TODO(mvp-reset): remove this row after the first live launch.
      <Map<String, Object?>>[
        <String, Object?>{'text': MessageTemplates.buttonAdminClearFunnel},
      ],
    ]);
  }

  Map<String, Object?> adminSheetsHubKeyboard() {
    return replyKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{'text': MessageTemplates.buttonAdminCatalog},
        <String, Object?>{'text': MessageTemplates.buttonAdminLinks},
      ],
      <Map<String, Object?>>[
        <String, Object?>{'text': MessageTemplates.buttonAdminSheets},
      ],
      <Map<String, Object?>>[
        <String, Object?>{'text': MessageTemplates.buttonAdminBack},
      ],
    ]);
  }

  Map<String, Object?> helpKeyboard() {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonOptOut,
          'callback_data': MessageTemplates.cbOptOut,
          'style': 'danger',
        },
      ],
    ]);
  }

  Map<String, Object?> enrollKeyboard(
    Launch launch, {
    required SalesQuote quote,
    bool rsvpOpen = true,
    bool webinarStarted = false,
    int? continueOrderId,
  }) {
    final rows = <List<Map<String, Object?>>>[];
    if (!quote.rsvp && rsvpOpen) {
      rows.add(<Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonRsvpEnroll,
          'callback_data': MessageTemplates.cbRsvp,
          'style': 'success',
        },
      ]);
    }
    if (!quote.checkoutOpen) {
      final liveUrl = launch.resolvedWebinarUrl;
      if (quote.rsvp && webinarStarted && liveUrl != null) {
        return webinarLinkKeyboard(liveUrl);
      }
      if (continueOrderId != null) {
        return continuePayKeyboard(continueOrderId);
      }
      return rows.isEmpty ? const <String, Object?>{} : inlineKeyboard(rows);
    }
    rows.add(<Map<String, Object?>>[
      <String, Object?>{
        'text': payFullButtonLabel(quote),
        'callback_data': MessageTemplates.cbPayFull,
        'style': 'primary',
      },
    ]);
    final showDeposit =
        !quote.promoPriceApplies && launch.hasDepositOptionFor(quote.payableKopecks);
    if (showDeposit) {
      rows.add(<Map<String, Object?>>[
        <String, Object?>{
          'text': payDepositButtonLabel(launch.depositKopecks),
          'callback_data': MessageTemplates.cbPayDeposit,
        },
      ]);
    }
    return inlineKeyboard(rows);
  }

  Map<String, Object?>? warmupKeyboard(
    String stepKey, {
    required Launch launch,
    required bool rsvp,
    bool rsvpOpen = true,
    bool checkoutOpen = false,
  }) {
    if (stepKey == 'webinar_live') {
      final url = launch.resolvedWebinarUrl;
      if (url != null) {
        return webinarLinkKeyboard(url);
      }
      return null;
    }
    const rsvpSteps = <String>{'warmup_0', 'webinar_24h', 'webinar_10m'};
    if (rsvpSteps.contains(stepKey) && !rsvp && rsvpOpen) {
      return inlineKeyboard(<List<Map<String, Object?>>>[
        <Map<String, Object?>>[
          <String, Object?>{
            'text': MessageTemplates.buttonRsvp,
            'callback_data': MessageTemplates.cbRsvp,
            'style': 'success',
          },
        ],
      ]);
    }
    final sellingEnroll =
        stepKey == 'webinar_next' ||
        stepKey == 'sales_open' ||
        stepKey == 'sales_regular' ||
        stepKey == 'enroll_d1' ||
        stepKey == 'enroll_d3' ||
        stepKey == WarmupStep.lastWagonKey ||
        WarmupStep.isBuiltinDozhim(stepKey) ||
        WarmupStep.isCustomDozhim(stepKey) ||
        (rsvpSteps.contains(stepKey) && !rsvpOpen && checkoutOpen);
    if (sellingEnroll) {
      return inlineKeyboard(<List<Map<String, Object?>>>[
        <Map<String, Object?>>[
          <String, Object?>{
            'text': MessageTemplates.buttonEnrollInline,
            'callback_data': MessageTemplates.cbEnroll,
            'style': 'primary',
          },
        ],
      ]);
    }
    return null;
  }

  Map<String, Object?> webinarLinkKeyboard(String url) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonJoinWebinar,
          'url': url,
          'style': 'primary',
        },
      ],
    ]);
  }

  Map<String, Object?> payUrlKeyboard(String url) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{'text': MessageTemplates.buttonGoToPay, 'url': url, 'style': 'primary'},
      ],
    ]);
  }

  Map<String, Object?> continuePayKeyboard(int orderId) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonContinuePay,
          'callback_data': '${MessageTemplates.cbContinuePay}$orderId',
          'style': 'primary',
        },
      ],
    ]);
  }

  Map<String, Object?> remainderKeyboard(int orderId, {bool immediate = false}) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': immediate
              ? MessageTemplates.buttonPayRemainderNow
              : MessageTemplates.buttonPayRemainder,
          'callback_data': '${MessageTemplates.cbPayRemainder}$orderId',
          'style': 'primary',
        },
      ],
    ]);
  }

  Map<String, Object?> unjoinedInviteKeyboard(String link) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonOpenInvite,
          'url': link,
          'style': 'primary',
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonCopyInvite,
          'copy_text': <String, String>{'text': link},
        },
      ],
    ]);
  }

  Map<String, Object?>? courseStatusKeyboard({CourseOrder? order, ChannelAccess? access}) {
    if (order != null && order.hasRemainder) {
      return remainderKeyboard(order.id);
    }
    final link = access?.inviteLink?.trim();
    if (access != null &&
        access.revokedAt == null &&
        !access.hasJoined &&
        link != null &&
        link.isNotEmpty) {
      return unjoinedInviteKeyboard(link);
    }
    return null;
  }

  Map<String, Object?> adminIncomingKeyboard(int userId) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminOpenCard,
          'callback_data': '${MessageTemplates.cbAdminCard}$userId',
        },
      ],
    ]);
  }

  Map<String, Object?> adminCardKeyboard(
    int userId, {
    required AdminPaymentStatus status,
    bool inChannel = false,
  }) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminDm,
          'callback_data': '${MessageTemplates.cbAdminDm}$userId',
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminChangeStatus,
          'callback_data': '${MessageTemplates.cbAdminStatusMenu}$userId',
        },
      ],
      if (status.canIssueChannelInvite)
        <Map<String, Object?>>[
          <String, Object?>{
            'text': MessageTemplates.buttonAdminReinvite,
            'callback_data': '${MessageTemplates.cbAdminInvite}$userId',
          },
        ],
      if (status.canRemoveFromCourse(inChannel: inChannel))
        <Map<String, Object?>>[
          <String, Object?>{
            'text': MessageTemplates.buttonAdminCancel,
            'callback_data': '${MessageTemplates.cbAdminCancel}$userId',
            'style': 'danger',
          },
        ],
    ]);
  }

  Map<String, Object?> adminStatusKeyboard(int userId, AdminPaymentStatus current) {
    final rows = <List<Map<String, Object?>>>[
      for (final status in AdminPaymentStatus.values)
        if (status != current)
          <Map<String, Object?>>[
            <String, Object?>{
              'text': adminStatusButton(status),
              'callback_data': MessageTemplates.adminStatusSetData(status, userId),
            },
          ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminStatusBack,
          'callback_data': '${MessageTemplates.cbAdminCard}$userId',
        },
      ],
    ];
    return inlineKeyboard(rows);
  }

  Map<String, Object?> adminConfirmKeyboard({
    required String yesData,
    required String noData,
    String? yesText,
    String? noText,
    String? yesStyle,
  }) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': yesText ?? MessageTemplates.buttonAdminConfirmYes,
          'callback_data': yesData,
          'style': yesStyle ?? 'danger',
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': noText ?? MessageTemplates.buttonAdminConfirmNo,
          'callback_data': noData,
        },
      ],
    ]);
  }

  Map<String, Object?> adminSearchMatchesKeyboard(List<UserProfile> users) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      for (final user in users.take(8))
        <Map<String, Object?>>[
          <String, Object?>{
            'text': _searchMatchLabel(user),
            'callback_data': '${MessageTemplates.cbAdminCard}${user.userId}',
          },
        ],
    ]);
  }

  String _searchMatchLabel(UserProfile user) {
    final handle = user.username?.trim();
    if (handle != null && handle.isNotEmpty) {
      return '@$handle';
    }
    final name = user.firstName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return '${user.userId}';
  }

  Map<String, Object?> adminCreateUserKeyboard(int userId) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCreateUser,
          'callback_data': '${MessageTemplates.cbAdminCreate}$userId',
        },
      ],
    ]);
  }

  Map<String, Object?> broadcastSegmentKeyboard(
    Map<BroadcastSegment, int> counts, {
    Set<BroadcastSegment> selected = const <BroadcastSegment>{},
  }) {
    final allSelected = BroadcastSegment.coversAll(selected);
    final rows = <List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': allSelected
              ? MessageTemplates.buttonAdminBroadcastClearAll
              : MessageTemplates.buttonAdminBroadcastSelectAll,
          'callback_data': MessageTemplates.cbBroadcastSelectAll,
        },
      ],
      for (final segment in BroadcastSegment.values)
        <Map<String, Object?>>[
          <String, Object?>{
            'text': broadcastSegmentButton(
              segment,
              counts[segment] ?? 0,
              selected: selected.contains(segment),
            ),
            'callback_data': '${MessageTemplates.cbBroadcastSegment}${segment.code}',
          },
        ],
      if (selected.isNotEmpty)
        <Map<String, Object?>>[
          <String, Object?>{
            'text': MessageTemplates.buttonAdminBroadcastContinue,
            'callback_data': MessageTemplates.cbBroadcastSegmentsDone,
          },
        ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminBroadcastCancel,
          'callback_data': MessageTemplates.cbBroadcastCancel,
        },
      ],
    ];
    return inlineKeyboard(rows);
  }

  Map<String, Object?> broadcastConfirmKeyboard({bool excludeOptOut = false}) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminBroadcastSend,
          'callback_data': MessageTemplates.cbBroadcastSend,
          'style': 'success',
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': excludeOptOut
              ? MessageTemplates.buttonAdminBroadcastIncludeOptOut
              : MessageTemplates.buttonAdminBroadcastSkipOptOut,
          'callback_data': MessageTemplates.cbBroadcastToggleOptOut,
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminBroadcastOtherSegment,
          'callback_data': MessageTemplates.cbBroadcastOtherSegment,
        },
        <String, Object?>{
          'text': MessageTemplates.buttonAdminBroadcastCancel,
          'callback_data': MessageTemplates.cbBroadcastCancel,
        },
      ],
    ]);
  }

  Map<String, Object?> guideConfirmKeyboard() {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminGuideSave,
          'callback_data': MessageTemplates.cbGuideSave,
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminGuideDiscard,
          'callback_data': MessageTemplates.cbGuideDiscard,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogListKeyboard(List<Launch> launches) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      for (final launch in launches.take(12))
        <Map<String, Object?>>[
          <String, Object?>{
            'text': adminCatalogListButton(launch),
            'callback_data': '${MessageTemplates.cbCatalogOpen}${launch.id}',
          },
        ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogNew,
          'callback_data': MessageTemplates.cbCatalogNew,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogCardKeyboard(Launch launch, {int dozhimCount = 0}) {
    final rows = <List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogEdit,
          'callback_data': '${MessageTemplates.cbCatalogEdit}${launch.id}',
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': adminCatalogGuideButton(launch),
          'callback_data': MessageTemplates.catalogFieldData(launch.id, CatalogLaunchField.guide),
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': adminCatalogDozhimButton(dozhimCount),
          'callback_data': '${MessageTemplates.cbCatalogDozhim}${launch.id}',
        },
      ],
      if (!launch.isActive)
        <Map<String, Object?>>[
          <String, Object?>{
            'text': MessageTemplates.buttonAdminCatalogActivate,
            'callback_data': '${MessageTemplates.cbCatalogActivate}${launch.id}',
          },
        ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogDelete,
          'callback_data': '${MessageTemplates.cbCatalogDelete}${launch.id}',
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogBack,
          'callback_data': MessageTemplates.cbCatalogMenu,
        },
      ],
    ];
    return inlineKeyboard(rows);
  }

  Map<String, Object?> adminCatalogFieldsKeyboard(int launchId) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      for (final field in CatalogLaunchField.values)
        <Map<String, Object?>>[
          <String, Object?>{
            'text': adminCatalogFieldLabel(field),
            'callback_data': MessageTemplates.catalogFieldData(launchId, field),
          },
        ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogBack,
          'callback_data': '${MessageTemplates.cbCatalogOpen}$launchId',
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogKeepCodeKeyboard() {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogKeepCode,
          'callback_data': MessageTemplates.cbCatalogKeepCode,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogKeepSuggestedKeyboard() {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogKeepSuggested,
          'callback_data': MessageTemplates.cbCatalogKeepCode,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogBackToCardKeyboard(int launchId) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogBack,
          'callback_data': '${MessageTemplates.cbCatalogOpen}$launchId',
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogDozhimListKeyboard(
    int launchId,
    List<LaunchDozhimMessage> messages,
  ) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      for (final message in messages.take(20))
        <Map<String, Object?>>[
          <String, Object?>{
            'text': adminCatalogDozhimDayButton(message),
            'callback_data': MessageTemplates.catalogDozhimItemData(
              MessageTemplates.cbCatalogDozhimOpen,
              launchId,
              message.id,
            ),
          },
        ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogDozhimAdd,
          'callback_data': '${MessageTemplates.cbCatalogDozhimAdd}$launchId',
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogBack,
          'callback_data': '${MessageTemplates.cbCatalogOpen}$launchId',
        },
      ],
    ]);
  }

  String adminCatalogDozhimDayButton(LaunchDozhimMessage message) {
    final kind = broadcastContentKindLabel(message.contentKind);
    final label = 'День ${message.dayIndex} · $kind';
    if (label.length <= 64) {
      return label;
    }
    return '${label.substring(0, 63)}…';
  }

  Map<String, Object?> adminCatalogDozhimItemKeyboard(int launchId, int messageId) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogDozhimReplace,
          'callback_data': MessageTemplates.catalogDozhimItemData(
            MessageTemplates.cbCatalogDozhimReplace,
            launchId,
            messageId,
          ),
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogDozhimDelete,
          'callback_data': MessageTemplates.catalogDozhimItemData(
            MessageTemplates.cbCatalogDozhimDelete,
            launchId,
            messageId,
          ),
        },
      ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogBack,
          'callback_data': '${MessageTemplates.cbCatalogDozhim}$launchId',
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogDozhimComposeKeyboard(int launchId) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogBack,
          'callback_data': '${MessageTemplates.cbCatalogDozhim}$launchId',
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogSkipChannelKeyboard() {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogSkipChannel,
          'callback_data': MessageTemplates.cbCatalogSkipChannel,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogSkipOptionalKeyboard() {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogSkip,
          'callback_data': MessageTemplates.cbCatalogSkipOptional,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogClearInlineKeyboard() {
    return inlineKeyboard(const <List<Map<String, Object?>>>[]);
  }

  Map<String, Object?> adminCatalogActiveKeyboard() {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogYes,
          'callback_data': MessageTemplates.cbCatalogActiveYes,
        },
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogNo,
          'callback_data': MessageTemplates.cbCatalogActiveNo,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogConfirmCreateKeyboard() {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogSave,
          'callback_data': MessageTemplates.cbCatalogCreateYes,
        },
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogNo,
          'callback_data': MessageTemplates.cbCatalogCreateNo,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogConfirmKeyboard({
    required String yesData,
    required String noData,
  }) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{'text': MessageTemplates.buttonAdminCatalogYes, 'callback_data': yesData},
        <String, Object?>{'text': MessageTemplates.buttonAdminCatalogNo, 'callback_data': noData},
      ],
    ]);
  }

  Map<String, Object?> adminLinksListKeyboard(
    List<AcquisitionLink> links, {
    required bool canWrite,
  }) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      for (var i = 0; i < links.length && i < 12; i++)
        <Map<String, Object?>>[
          <String, Object?>{
            'text': adminLinksListButton(links[i]),
            'callback_data': '${MessageTemplates.cbLinksOpen}$i',
          },
        ],
      if (canWrite)
        <Map<String, Object?>>[
          <String, Object?>{
            'text': MessageTemplates.buttonAdminLinksNew,
            'callback_data': MessageTemplates.cbLinksNew,
          },
        ],
    ]);
  }

  Map<String, Object?> adminLinksCardKeyboard(int index, {required bool canWrite}) {
    final rows = <List<Map<String, Object?>>>[
      if (canWrite)
        <Map<String, Object?>>[
          <String, Object?>{
            'text': MessageTemplates.buttonAdminLinksEdit,
            'callback_data': '${MessageTemplates.cbLinksEdit}$index',
          },
        ],
      if (canWrite)
        <Map<String, Object?>>[
          <String, Object?>{
            'text': MessageTemplates.buttonAdminLinksDelete,
            'callback_data': '${MessageTemplates.cbLinksDelete}$index',
          },
        ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminLinksBack,
          'callback_data': MessageTemplates.cbLinksMenu,
        },
      ],
    ];
    return inlineKeyboard(rows);
  }

  Map<String, Object?> adminLinksFieldsKeyboard(int index) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      for (final field in CatalogLinkField.values)
        <Map<String, Object?>>[
          <String, Object?>{
            'text': adminLinksFieldLabel(field),
            'callback_data': MessageTemplates.linksFieldData(index, field),
          },
        ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminLinksBack,
          'callback_data': '${MessageTemplates.cbLinksOpen}$index',
        },
      ],
    ]);
  }

  Map<String, Object?> adminLinksDestinationKeyboard() {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminLinksDestGuide,
          'callback_data': MessageTemplates.cbLinksDestGuide,
        },
        <String, Object?>{
          'text': MessageTemplates.buttonAdminLinksDestCourse,
          'callback_data': MessageTemplates.cbLinksDestCourse,
        },
      ],
    ]);
  }

  Map<String, Object?> adminLinksLaunchKeyboard(List<Launch> launches) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      for (final launch in launches.take(12))
        <Map<String, Object?>>[
          <String, Object?>{
            'text': adminLinksLaunchButton(launch),
            'callback_data': '${MessageTemplates.cbLinksPickLaunch}${launch.id}',
          },
        ],
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminLinksSkipLaunch,
          'callback_data': MessageTemplates.cbLinksSkipLaunch,
        },
      ],
    ]);
  }

  Map<String, Object?> adminLinksConfirmCreateKeyboard() {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{
          'text': MessageTemplates.buttonAdminLinksSave,
          'callback_data': MessageTemplates.cbLinksCreateYes,
        },
        <String, Object?>{
          'text': MessageTemplates.buttonAdminCatalogNo,
          'callback_data': MessageTemplates.cbLinksCreateNo,
        },
      ],
    ]);
  }

  Map<String, Object?> adminLinksConfirmKeyboard({
    required String yesData,
    required String noData,
  }) {
    return inlineKeyboard(<List<Map<String, Object?>>>[
      <Map<String, Object?>>[
        <String, Object?>{'text': MessageTemplates.buttonAdminCatalogYes, 'callback_data': yesData},
        <String, Object?>{'text': MessageTemplates.buttonAdminCatalogNo, 'callback_data': noData},
      ],
    ]);
  }
}
