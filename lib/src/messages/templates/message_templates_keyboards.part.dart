part of 'package:course_chatbot/src/messages/message_templates.dart';

extension MessageTemplateKeyboards on MessageTemplates {
  Map<String, Object?> userMenuKeyboard({required bool hasAccess}) {
    return replyKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        if (!hasAccess) <String, String>{'text': MessageTemplates.buttonEnroll},
        <String, String>{'text': MessageTemplates.buttonGuide},
      ],
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonMenu},
        <String, String>{'text': MessageTemplates.buttonHelp},
      ],
    ]);
  }

  Map<String, Object?> adminMenuKeyboard() {
    return replyKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminSearch},
        <String, String>{'text': MessageTemplates.buttonAdminBroadcast},
      ],
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonAdminSheets},
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
    ]);
  }

  Map<String, Object?> warmupKeyboard({required bool showEnroll}) {
    return inlineKeyboard(<List<Map<String, String>>>[
      if (showEnroll)
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonEnroll,
            'callback_data': MessageTemplates.cbEnroll,
          },
        ],
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
    if (launch.hasDepositOption) {
      rows.add(<Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonPayDeposit,
          'callback_data': MessageTemplates.cbPayDeposit,
        },
      ]);
    }
    rows.add(<Map<String, String>>[
      <String, String>{
        'text': MessageTemplates.buttonPayInstallment,
        'callback_data': MessageTemplates.cbPayInstallment,
      },
    ]);
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

  Map<String, Object?> remainderKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonPayRemainder,
          'callback_data': MessageTemplates.cbPayRemainder,
        },
      ],
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
    ]);
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
          'text': MessageTemplates.buttonAdminCancel,
          'callback_data': '${MessageTemplates.cbAdminCancel}$userId',
        },
        <String, String>{
          'text': MessageTemplates.buttonAdminReinvite,
          'callback_data': '${MessageTemplates.cbAdminInvite}$userId',
        },
      ],
    ]);
  }

  Map<String, Object?> broadcastConfirmKeyboard() {
    return inlineKeyboard(<List<Map<String, String>>>[
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonAdminBroadcastGuide,
          'callback_data': MessageTemplates.cbBroadcastGuide,
        },
      ],
      <Map<String, String>>[
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
