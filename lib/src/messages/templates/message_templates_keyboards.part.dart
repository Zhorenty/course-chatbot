part of 'package:course_chatbot/src/messages/message_templates.dart';

extension MessageTemplateKeyboards on MessageTemplates {
  Map<String, Object?> userMenuKeyboard({required bool isAdmin, required bool hasAccess}) {
    final rows = <List<Map<String, String>>>[
      <Map<String, String>>[
        if (!hasAccess) <String, String>{'text': MessageTemplates.buttonEnroll},
        <String, String>{'text': MessageTemplates.buttonGuide},
      ],
      <Map<String, String>>[
        <String, String>{'text': MessageTemplates.buttonMenu},
        <String, String>{'text': MessageTemplates.buttonHelp},
      ],
    ];
    if (isAdmin) {
      rows.add(
        <Map<String, String>>[
          <String, String>{'text': MessageTemplates.buttonAdminMenu},
        ],
      );
    }
    return replyKeyboard(rows);
  }

  Map<String, Object?> adminMenuKeyboard() {
    return replyKeyboard(
      <List<Map<String, String>>>[
        <Map<String, String>>[
          <String, String>{'text': MessageTemplates.buttonAdminSearch},
          <String, String>{'text': MessageTemplates.buttonAdminBroadcast},
        ],
        <Map<String, String>>[
          <String, String>{'text': MessageTemplates.buttonMenu},
        ],
      ],
    );
  }

  Map<String, Object?> guideOfferKeyboard({required bool showEnroll}) {
    return inlineKeyboard(
      <List<Map<String, String>>>[
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
      ],
    );
  }

  Map<String, Object?> warmupKeyboard({required bool showEnroll}) {
    return inlineKeyboard(
      <List<Map<String, String>>>[
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
      ],
    );
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
      rows.add(
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonPayDeposit,
            'callback_data': MessageTemplates.cbPayDeposit,
          },
        ],
      );
    }
    rows.add(
      <Map<String, String>>[
        <String, String>{
          'text': MessageTemplates.buttonPayInstallment,
          'callback_data': MessageTemplates.cbPayInstallment,
        },
      ],
    );
    return inlineKeyboard(rows);
  }

  Map<String, Object?> payUrlKeyboard(String url) {
    return inlineKeyboard(
      <List<Map<String, String>>>[
        <Map<String, String>>[
          <String, String>{'text': 'Оплатить', 'url': url},
        ],
      ],
    );
  }

  Map<String, Object?> continuePayKeyboard(int orderId) {
    return inlineKeyboard(
      <List<Map<String, String>>>[
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonContinuePay,
            'callback_data': '${MessageTemplates.cbContinuePay}$orderId',
          },
        ],
      ],
    );
  }

  Map<String, Object?> remainderKeyboard() {
    return inlineKeyboard(
      <List<Map<String, String>>>[
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonPayRemainder,
            'callback_data': MessageTemplates.cbPayRemainder,
          },
        ],
      ],
    );
  }

  Map<String, Object?> accessKeyboard() {
    return inlineKeyboard(
      <List<Map<String, String>>>[
        <Map<String, String>>[
          <String, String>{
            'text': MessageTemplates.buttonNewInvite,
            'callback_data': MessageTemplates.cbNewInvite,
          },
        ],
      ],
    );
  }

  Map<String, Object?> adminCardKeyboard(int userId) {
    return inlineKeyboard(
      <List<Map<String, String>>>[
        <Map<String, String>>[
          <String, String>{
            'text': 'Отметить оплаченным',
            'callback_data': '${MessageTemplates.cbAdminPaid}$userId',
          },
        ],
        <Map<String, String>>[
          <String, String>{
            'text': 'Предоплата',
            'callback_data': '${MessageTemplates.cbAdminDeposit}$userId',
          },
        ],
        <Map<String, String>>[
          <String, String>{
            'text': 'Отмена / возврат',
            'callback_data': '${MessageTemplates.cbAdminCancel}$userId',
          },
          <String, String>{
            'text': 'Новый invite',
            'callback_data': '${MessageTemplates.cbAdminInvite}$userId',
          },
        ],
      ],
    );
  }

  Map<String, Object?> broadcastConfirmKeyboard() {
    return inlineKeyboard(
      <List<Map<String, String>>>[
        <Map<String, String>>[
          <String, String>{
            'text': 'Гайд, не купили',
            'callback_data': MessageTemplates.cbBroadcastGuide,
          },
        ],
        <Map<String, String>>[
          <String, String>{
            'text': 'Отмена',
            'callback_data': MessageTemplates.cbBroadcastCancel,
          },
        ],
      ],
    );
  }
}
