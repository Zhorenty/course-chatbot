import 'package:course_chatbot/src/telegram/input_rich_message.dart';
import 'package:course_chatbot/src/telegram/prefer_rich_send.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

void main() {
  test('local photos stay inside the rich message', () async {
    final sender = FakeMessageSender();
    await sendPreferRich(
      sender,
      42,
      '<b>Для начала</b> и <u>подчёркивание</u>',
      media: <InputRichMessageMedia>[
        InputRichMessageMedia.photo(
          id: 'p0',
          document: InputRichDocument.file(localPath: 'assets/funnel/welcome.jpg'),
        ),
      ],
    );

    expect(sender.photoBatches, isEmpty);
    expect(sender.documents, <String>['assets/funnel/welcome.jpg']);
    expect(sender.messages, hasLength(1));
    expect(sender.messages.single.isRich, isTrue);
    expect(sender.messages.single.text, contains('<figure>'));
    expect(sender.messages.single.text, contains('<img src="tg://photo?id=p0"/>'));
    expect(
      sender.messages.single.text,
      contains('<figcaption><b>Для начала</b> и <u>подчёркивание</u></figcaption>'),
    );
    expect(sender.messages.single.text, isNot(contains('<p>')));
  });

  test('classic fallback sends photo and caption as one message', () async {
    final sender = FakeMessageSender()..throwOnRich = StateError('rich unavailable');
    final markup = <String, Object?>{
      'inline_keyboard': <List<Map<String, Object?>>>[
        <Map<String, Object?>>[
          <String, Object?>{'text': 'Оплатить', 'callback_data': 'pay'},
        ],
      ],
    };
    await sendPreferRich(
      sender,
      7,
      'Только текст',
      media: <InputRichMessageMedia>[
        InputRichMessageMedia.photo(
          id: 'p0',
          document: InputRichDocument.file(localPath: 'assets/funnel/paid.jpg'),
        ),
      ],
      replyMarkup: markup,
    );

    expect(sender.photoBatches, <List<String>>[
      <String>['assets/funnel/paid.jpg'],
    ]);
    expect(sender.messages, hasLength(1));
    expect(sender.messages.single.text, 'Только текст');
    expect(sender.messages.single.parseMode, 'HTML');
    expect(sender.messages.single.replyMarkup, markup);
    expect(sender.messages.single.isRich, isFalse);
  });

  test('classic fallback album keeps the caption on the first photo', () async {
    final sender = FakeMessageSender()..throwOnRich = StateError('rich unavailable');
    await sendPreferRich(
      sender,
      7,
      'Два кадра',
      media: <InputRichMessageMedia>[
        InputRichMessageMedia.photo(
          id: 'p0',
          document: InputRichDocument.file(localPath: 'assets/funnel/post_1.jpg'),
        ),
        InputRichMessageMedia.photo(
          id: 'p1',
          document: InputRichDocument.file(localPath: 'assets/funnel/post_2.jpg'),
        ),
      ],
    );

    expect(sender.photoBatches, <List<String>>[
      <String>['assets/funnel/post_1.jpg', 'assets/funnel/post_2.jpg'],
    ]);
    expect(sender.messages.first.text, 'Два кадра');
    expect(sender.messages, hasLength(2));
  });

  test('album rich payload keeps caption formatting', () async {
    final sender = FakeMessageSender();
    await sendPreferRich(
      sender,
      7,
      '<b>Два кадра</b>\n<u>подпись</u>',
      media: <InputRichMessageMedia>[
        InputRichMessageMedia.photo(
          id: 'p0',
          document: InputRichDocument.file(localPath: 'assets/funnel/post_1.jpg'),
        ),
        InputRichMessageMedia.photo(
          id: 'p1',
          document: InputRichDocument.file(localPath: 'assets/funnel/post_2.jpg'),
        ),
      ],
    );

    expect(sender.photoBatches, isEmpty);
    expect(sender.messages.single.isRich, isTrue);
    expect(sender.messages.single.text, startsWith('<tg-slideshow>'));
    expect(
      sender.messages.single.text,
      contains('<figcaption><b>Два кадра</b><br><u>подпись</u></figcaption>'),
    );
  });

  test('file_id photos stay inside the rich payload', () async {
    final sender = FakeMessageSender();
    await sendPreferRich(
      sender,
      1,
      'Подпись',
      media: <InputRichMessageMedia>[
        InputRichMessageMedia.photo(id: 'p0', document: InputRichDocument.fileId('AgAD-photo')),
      ],
    );

    expect(sender.photoBatches, isEmpty);
    expect(sender.documents, <String>['AgAD-photo']);
    expect(sender.messages.single.text, contains('<figure>'));
    expect(sender.messages.single.text, contains('<img src="tg://photo?id=p0"/>'));
    expect(sender.messages.single.text, contains('<figcaption>Подпись</figcaption>'));
  });
}
