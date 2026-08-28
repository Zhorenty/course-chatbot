part of 'package:course_chatbot/src/messages/message_templates.dart';

extension MessageTemplateKeyboards on MessageTemplates {
  Map<String, Object?> userMenuKeyboard({required bool hasAccess}) {
    return replyKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        if (!hasAccess) <String, String>{'text': MessageTemplates.buttonEnroll},
        <String, String>{'text': MessageTemplates.buttonGuide},
      ],
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonHelp},
      ],
    ]);
  }

  Map<String, Object?> adminMenuKeyboard() {
    return replyKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminSearch},
        <String, String>{'text': MessageTemplates.buttonAdminAddUser},
      ],
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminLinks},
        <String, String>{'text': MessageTemplates.buttonAdminSheets},
      ],
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminBroadcast},
      ],
    ]);
  }

  Map<String, Object?> guideOfferKeyboard({required bool showEnroll}) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonGuide,
          'callback_data': MessageTemplates.cbGuide,
        },
      ],
      if (showEnroll)
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonEnroll,
            'callback_data': MessageTemplates.cbEnroll,
          },
        ],
      _supportRow(showGuide: false),
    ]);
  }

  Map<String, Object?> courseCardKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonEnroll,
          'callback_data': MessageTemplates.cbEnroll,
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonGuide,
          'callback_data': MessageTemplates.cbGuide,
        },
      ],
      _supportRow(showGuide: false),
    ]);
  }

  Map<String, Object?> warmupKeyboard({required bool showEnroll, bool showGuide = true}) {
    return inlineKeyboard(<List<Map<String, String>>>[
      if (showEnroll)
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonEnroll,
            'callback_data': MessageTemplates.cbEnroll,
          },
        ],
      if (showGuide)
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonGuide,
            'callback_data': MessageTemplates.cbGuide,
          },
        ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonOptOut,
          'callback_data': MessageTemplates.cbOptOut,
        },
      ],
      _supportRow(showGuide: false),
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
    rows.add(_supportRow());
    return inlineKeyboard(rows);
  }

  Map<String, Object?> offerKeyboard({
    required bool acceptedOffer,
    required bool acceptedPersonalData,
  }) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': _checkbox(acceptedOffer, MessageTemplates.buttonAcceptOffer),
          'callback_data': MessageTemplates.cbToggleOffer,
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': _checkbox(acceptedPersonalData, MessageTemplates.buttonAcceptPersonalData),
          'callback_data': MessageTemplates.cbTogglePersonalData,
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
      _supportRow(),
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
      _supportRow(),
    ]);
  }

  Map<String, Object?> remainderKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonPayRemainder,
          'callback_data': MessageTemplates.cbPayRemainder,
        },
      ],
      _supportRow(),
    ]);
  }

  Map<String, Object?> unjoinedInviteKeyboard(String link) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonOpenInvite, 'url': link},
      ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonNewInvite,
          'callback_data': MessageTemplates.cbNewInvite,
        },
      ],
      _supportRow(),
    ]);
  }

  Map<String, Object?> accessKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonNewInvite,
          'callback_data': MessageTemplates.cbNewInvite,
        },
      ],
      _supportRow(),
    ]);
  }

  List<Map<String, String>> _supportRow({bool showGuide = true}) {
    return <Map<String, String>>[
      if (showGuide)
        <String, String>{
          'text': MessageTemplates.buttonGuide,
          'callback_data': MessageTemplates.cbGuide,
        },
      <String, String>{
        'text': MessageTemplates.buttonHelp,
        'callback_data': MessageTemplates.cbHelp,
      },
    ];
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

  Map<String, Object?> adminCardKeyboard(int userId) {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminDm,
          'callback_data': '${MessageTemplates.cbAdminDm}$userId',
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminMarkPaid,
          'callback_data': '${MessageTemplates.cbAdminPaid}$userId',
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminMarkDeposit,
          'callback_data': '${MessageTemplates.cbAdminDeposit}$userId',
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminReinvite,
          'callback_data': '${MessageTemplates.cbAdminInvite}$userId',
        },
      ],
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminCancel,
          'callback_data': '${MessageTemplates.cbAdminCancel}$userId',
        },
      ],
    ]);
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

  Map<String, Object?> broadcastSegmentKeyboard(Map<BroadcastSegment, int> counts) {
    final rows = <List<Map<String, String>>>[
      for (final segment in BroadcastSegment.values)
        <Map<String, String>>[
          <String, String>{
            'text': broadcastSegmentButton(segment, counts[segment] ?? 0),
            'callback_data': '${MessageTemplates.cbBroadcastSegment}${segment.code}',
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
}
