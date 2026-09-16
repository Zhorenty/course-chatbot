import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/stored_telegram_message.dart';
import 'package:course_chatbot/src/messages/telegram_html.dart';
import 'package:course_chatbot/src/telegram/telegram_message_snapshot.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

void main() {
  test('telegram entities become HTML tags', () {
    expect(
      telegramEntitiesToHtml('Привет', <Map<String, Object?>>[
        <String, Object?>{'type': 'bold', 'offset': 0, 'length': 6},
      ]),
      '<b>Привет</b>',
    );
    expect(
      telegramEntitiesToHtml('a & b', <Map<String, Object?>>[
        <String, Object?>{'type': 'italic', 'offset': 0, 'length': 5},
      ]),
      '<i>a &amp; b</i>',
    );
    expect(
      telegramEntitiesToHtml('сайт', <Map<String, Object?>>[
        <String, Object?>{'type': 'text_link', 'offset': 0, 'length': 4, 'url': 'https://ex.com'},
      ]),
      '<a href="https://ex.com">сайт</a>',
    );
  });

  test('telegram text message keeps bold, italic and line breaks', () {
    expect(
      telegramTextMessageToHtml(
        privateMessageUpdate(
              chatId: 1,
              userId: 1,
              text: 'Первый абзац\nвторой',
              entities: <Map<String, dynamic>>[
                <String, dynamic>{'type': 'bold', 'offset': 0, 'length': 12},
                <String, dynamic>{'type': 'italic', 'offset': 13, 'length': 6},
              ],
            )['message']
            as Map<String, dynamic>,
      ),
      '<b>Первый абзац</b>\n<i>второй</i>',
    );
    expect(telegramTextMessageToHtml(<String, dynamic>{'text': '   '}), isNull);
    expect(storedTelegramTextToHtml('a < b'), 'a &lt; b');
    expect(storedTelegramTextToHtml('<b>Цвет</b>\nи практика'), '<b>Цвет</b>\nи практика');
    expect(
      storedTelegramTextToHtml('абзац\n\tпункт  1'),
      'абзац\n&nbsp;&nbsp;&nbsp;&nbsp;пункт &nbsp;1',
    );
    expect(
      storedTelegramTextToHtml('<blockquote>цитата</blockquote>'),
      '<blockquote>цитата</blockquote>',
    );
  });

  test('snapshot keeps photo file_id so the original message can be deleted', () {
    final snapshot = snapshotTelegramMessage(
      privatePhotoUpdate(chatId: 1, userId: 1, caption: 'кейс')['message'] as Map<String, dynamic>,
    );
    expect(snapshot, isNotNull);
    expect(snapshot!.canReplay, isTrue);
    expect(snapshot.kind, BroadcastContentKind.photo);
    expect(snapshot.media.single.fileId, 'photo-large');
    expect(snapshot.html, 'кейс');
    expect(StoredTelegramMessage.fromJson(snapshot.toJson())?.media.single.fileId, 'photo-large');
  });

  test('album parts merge into one stored payload', () {
    final first = snapshotTelegramMessage(
      privatePhotoUpdate(
            chatId: 1,
            userId: 1,
            messageId: 41,
            mediaGroupId: 'g',
            caption: 'до/после',
          )['message']
          as Map<String, dynamic>,
    )!;
    final second = snapshotTelegramMessage(
      privatePhotoUpdate(chatId: 1, userId: 1, messageId: 42, mediaGroupId: 'g')['message']
          as Map<String, dynamic>,
    )!;
    final merged = mergeAlbumSnapshots(<StoredTelegramMessage>[first, second]);
    expect(merged.kind, BroadcastContentKind.album);
    expect(merged.canReplay, isTrue);
    expect(merged.media, hasLength(2));
    expect(merged.captionHtml, 'до/после');
  });
}
