part of 'package:course_chatbot/src/messages/message_templates.dart';

extension MessageTemplateKeyboards on MessageTemplates {
  Map<String, Object?> userMenuKeyboard({required bool showCourseStatus}) {
    return replyKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        if (showCourseStatus)
          <String, String>{'text': MessageTemplates.buttonCourseStatus}
        else
          <String, String>{'text': MessageTemplates.buttonEnroll},
        <String, String>{'text': MessageTemplates.buttonGuide},
      ],
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonHelp},
      ],
    ], inputFieldPlaceholder: 'Если застрял — напиши сюда');
  }

  Map<String, Object?> adminMenuKeyboard() {
    return replyKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminSearch},
        <String, String>{'text': MessageTemplates.buttonAdminSheetsHub},
      ],
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminBroadcast},
      ],
      // TODO(mvp-reset): remove this row after the first live launch.
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminClearFunnel},
      ],
    ]);
  }

  Map<String, Object?> adminSheetsHubKeyboard() {
    return replyKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminCatalog},
        <String, String>{'text': MessageTemplates.buttonAdminLinks},
      ],
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminSheets},
      ],
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminBack},
      ],
    ]);
  }

  Map<String, Object?> helpKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonOptOut,
          'callback_data': MessageTemplates.cbOptOut,
        },
      ],
    ]);
  }

  Map<String, Object?> enrollKeyboard(Launch launch) {
    final rows = <List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonPayFull,
          'callback_data': MessageTemplates.cbPayFull,
        },
      ],
    ];
    final extra = <Map<String, String>>[
      if (launch.hasDepositOption)
        <String, String>{
          'text': MessageTemplates.buttonPayDeposit,
          'callback_data': MessageTemplates.cbPayDeposit,
        },
      <String, String>{
        'text': MessageTemplates.buttonPayInstallment,
        'callback_data': MessageTemplates.cbPayInstallment,
      },
    ];
    rows.add(extra);
    return inlineKeyboard(rows);
  }

  Map<String, Object?> offerKeyboard({required bool accepted}) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': _checkbox(accepted, MessageTemplates.buttonAcceptConsent),
          'callback_data': MessageTemplates.cbToggleOffer,
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonGoToPay,
          'callback_data': MessageTemplates.cbGoToPay,
        },
      ],
    ]);
  }

  String _checkbox(bool checked, String label) => '${checked ? '☑️' : '☐'} $label';

  Map<String, Object?> payUrlKeyboard(String url) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonGoToPay, 'url': url},
      ],
    ]);
  }

  Map<String, Object?> continuePayKeyboard(int orderId) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonContinuePay,
          'callback_data': '${MessageTemplates.cbContinuePay}$orderId',
        },
      ],
    ]);
  }

  Map<String, Object?> remainderKeyboard(int orderId) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonPayRemainder,
          'callback_data': '${MessageTemplates.cbPayRemainder}$orderId',
        },
      ],
    ]);
  }

  Map<String, Object?> unjoinedInviteKeyboard(String link) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonOpenInvite, 'url': link},
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
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
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
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminDm,
          'callback_data': '${MessageTemplates.cbAdminDm}$userId',
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminChangeStatus,
          'callback_data': '${MessageTemplates.cbAdminStatusMenu}$userId',
        },
      ],
      if (status.canIssueChannelInvite)
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonAdminReinvite,
            'callback_data': '${MessageTemplates.cbAdminInvite}$userId',
          },
        ],
      if (status.canRemoveFromCourse(inChannel: inChannel))
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonAdminCancel,
            'callback_data': '${MessageTemplates.cbAdminCancel}$userId',
          },
        ],
    ]);
  }

  Map<String, Object?> adminStatusKeyboard(int userId, AdminPaymentStatus current) {
    final rows = <List<Map<String, String>>>[
      for (final status in AdminPaymentStatus.values)
        if (status != current)
          <Map<String, String>>[
            <String, String>{
              'text': adminStatusButton(status),
              'callback_data': MessageTemplates.adminStatusSetData(status, userId),
            },
          ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminStatusBack,
          'callback_data': '${MessageTemplates.cbAdminCard}$userId',
        },
      ],
    ];
    return inlineKeyboard(rows);
  }

  Map<String, Object?> adminConfirmKeyboard({required String yesData, required String noData}) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminConfirmYes, 'callback_data': yesData},
        <String, String>{'text': MessageTemplates.buttonAdminConfirmNo, 'callback_data': noData},
      ],
    ]);
  }

  Map<String, Object?> adminSearchMatchesKeyboard(List<UserProfile> users) {
    return inlineKeyboard(<List<Map<String, String>>>[
      for (final user in users.take(8))
        <Map<String, String>>[
          <String, String>{
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
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
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
    final rows = <List<Map<String, String>>>[
      for (final segment in BroadcastSegment.values)
        <Map<String, String>>[
          <String, String>{
            'text': broadcastSegmentButton(
              segment,
              counts[segment] ?? 0,
              selected: selected.contains(segment),
            ),
            'callback_data': '${MessageTemplates.cbBroadcastSegment}${segment.code}',
          },
        ],
      if (selected.isNotEmpty)
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonAdminBroadcastContinue,
            'callback_data': MessageTemplates.cbBroadcastSegmentsDone,
          },
        ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminBroadcastCancel,
          'callback_data': MessageTemplates.cbBroadcastCancel,
        },
      ],
    ];
    return inlineKeyboard(rows);
  }

  Map<String, Object?> broadcastConfirmKeyboard({bool excludeOptOut = false}) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminBroadcastSend,
          'callback_data': MessageTemplates.cbBroadcastSend,
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': excludeOptOut
              ? MessageTemplates.buttonAdminBroadcastIncludeOptOut
              : MessageTemplates.buttonAdminBroadcastSkipOptOut,
          'callback_data': MessageTemplates.cbBroadcastToggleOptOut,
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminBroadcastOtherSegment,
          'callback_data': MessageTemplates.cbBroadcastOtherSegment,
        },
        <String, String>{
          'text': MessageTemplates.buttonAdminBroadcastCancel,
          'callback_data': MessageTemplates.cbBroadcastCancel,
        },
      ],
    ]);
  }

  Map<String, Object?> guideConfirmKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminGuideSave,
          'callback_data': MessageTemplates.cbGuideSave,
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminGuideDiscard,
          'callback_data': MessageTemplates.cbGuideDiscard,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogListKeyboard(List<Launch> launches) {
    return inlineKeyboard(<List<Map<String, String>>>[
      for (final launch in launches.take(12))
        <Map<String, String>>[
          <String, String>{
            'text': adminCatalogListButton(launch),
            'callback_data': '${MessageTemplates.cbCatalogOpen}${launch.id}',
          },
        ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminCatalogNew,
          'callback_data': MessageTemplates.cbCatalogNew,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogCardKeyboard(Launch launch) {
    final rows = <List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminCatalogEdit,
          'callback_data': '${MessageTemplates.cbCatalogEdit}${launch.id}',
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': adminCatalogGuideButton(launch),
          'callback_data': MessageTemplates.catalogFieldData(launch.id, CatalogLaunchField.guide),
        },
      ],
      if (!launch.isActive)
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonAdminCatalogActivate,
            'callback_data': '${MessageTemplates.cbCatalogActivate}${launch.id}',
          },
        ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminCatalogDelete,
          'callback_data': '${MessageTemplates.cbCatalogDelete}${launch.id}',
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminCatalogBack,
          'callback_data': MessageTemplates.cbCatalogMenu,
        },
      ],
    ];
    return inlineKeyboard(rows);
  }

  Map<String, Object?> adminCatalogFieldsKeyboard(int launchId) {
    return inlineKeyboard(<List<Map<String, String>>>[
      for (final field in CatalogLaunchField.values)
        <Map<String, String>>[
          <String, String>{
            'text': adminCatalogFieldLabel(field),
            'callback_data': MessageTemplates.catalogFieldData(launchId, field),
          },
        ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminCatalogBack,
          'callback_data': '${MessageTemplates.cbCatalogOpen}$launchId',
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogKeepCodeKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminCatalogKeepCode,
          'callback_data': MessageTemplates.cbCatalogKeepCode,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogBackToCardKeyboard(int launchId) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminCatalogBack,
          'callback_data': '${MessageTemplates.cbCatalogOpen}$launchId',
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogSkipChannelKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminCatalogSkipChannel,
          'callback_data': MessageTemplates.cbCatalogSkipChannel,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogClearInlineKeyboard() {
    return inlineKeyboard(const <List<Map<String, String>>>[]);
  }

  Map<String, Object?> adminCatalogActiveKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminCatalogYes,
          'callback_data': MessageTemplates.cbCatalogActiveYes,
        },
        <String, String>{
          'text': MessageTemplates.buttonAdminCatalogNo,
          'callback_data': MessageTemplates.cbCatalogActiveNo,
        },
      ],
    ]);
  }

  Map<String, Object?> adminCatalogConfirmCreateKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminCatalogSave,
          'callback_data': MessageTemplates.cbCatalogCreateYes,
        },
        <String, String>{
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
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminCatalogYes, 'callback_data': yesData},
        <String, String>{'text': MessageTemplates.buttonAdminCatalogNo, 'callback_data': noData},
      ],
    ]);
  }

  Map<String, Object?> adminLinksListKeyboard(
    List<AcquisitionLink> links, {
    required bool canWrite,
  }) {
    return inlineKeyboard(<List<Map<String, String>>>[
      for (var i = 0; i < links.length && i < 12; i++)
        <Map<String, String>>[
          <String, String>{
            'text': adminLinksListButton(links[i]),
            'callback_data': '${MessageTemplates.cbLinksOpen}$i',
          },
        ],
      if (canWrite)
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonAdminLinksNew,
            'callback_data': MessageTemplates.cbLinksNew,
          },
        ],
    ]);
  }

  Map<String, Object?> adminLinksCardKeyboard(int index, {required bool canWrite}) {
    final rows = <List<Map<String, String>>>[
      if (canWrite)
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonAdminLinksEdit,
            'callback_data': '${MessageTemplates.cbLinksEdit}$index',
          },
        ],
      if (canWrite)
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonAdminLinksDelete,
            'callback_data': '${MessageTemplates.cbLinksDelete}$index',
          },
        ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminLinksBack,
          'callback_data': MessageTemplates.cbLinksMenu,
        },
      ],
    ];
    return inlineKeyboard(rows);
  }

  Map<String, Object?> adminLinksFieldsKeyboard(int index) {
    return inlineKeyboard(<List<Map<String, String>>>[
      for (final field in CatalogLinkField.values)
        <Map<String, String>>[
          <String, String>{
            'text': adminLinksFieldLabel(field),
            'callback_data': MessageTemplates.linksFieldData(index, field),
          },
        ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminLinksBack,
          'callback_data': '${MessageTemplates.cbLinksOpen}$index',
        },
      ],
    ]);
  }

  Map<String, Object?> adminLinksDestinationKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminLinksDestGuide,
          'callback_data': MessageTemplates.cbLinksDestGuide,
        },
        <String, String>{
          'text': MessageTemplates.buttonAdminLinksDestCourse,
          'callback_data': MessageTemplates.cbLinksDestCourse,
        },
      ],
    ]);
  }

  Map<String, Object?> adminLinksLaunchKeyboard(List<Launch> launches) {
    return inlineKeyboard(<List<Map<String, String>>>[
      for (final launch in launches.take(12))
        <Map<String, String>>[
          <String, String>{
            'text': adminLinksLaunchButton(launch),
            'callback_data': '${MessageTemplates.cbLinksPickLaunch}${launch.id}',
          },
        ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminLinksSkipLaunch,
          'callback_data': MessageTemplates.cbLinksSkipLaunch,
        },
      ],
    ]);
  }

  Map<String, Object?> adminLinksConfirmCreateKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminLinksSave,
          'callback_data': MessageTemplates.cbLinksCreateYes,
        },
        <String, String>{
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
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminCatalogYes, 'callback_data': yesData},
        <String, String>{'text': MessageTemplates.buttonAdminCatalogNo, 'callback_data': noData},
      ],
    ]);
  }
}
