import 'package:course_chatbot/src/bot/handlers/private_handlers.dart';
import 'package:course_chatbot/src/messages/html_escaper.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

void main() {
  test('escapeHtml encodes markup', () {
    expect(escapeHtml('<b>a&b</b>'), '&lt;b&gt;a&amp;b&lt;/b&gt;');
  });

  test('/start without payload replies in private chat', () async {
    final sender = FakeMessageSender();
    final handlers = PrivateHandlers(sender: sender);

    final handled = await handlers.handle(_privateStart('/start'));

    expect(handled, isTrue);
    expect(sender.messages, hasLength(1));
    expect(sender.messages.single.text, contains('без метки источника'));
  });

  test('/start with deep link payload is echoed escaped', () async {
    final sender = FakeMessageSender();
    final handlers = PrivateHandlers(sender: sender);

    final handled = await handlers.handle(_privateStart('/start ig_reels_guide'));

    expect(handled, isTrue);
    expect(sender.messages.single.text, contains('ig_reels_guide'));
  });

  test('group messages are ignored', () async {
    final sender = FakeMessageSender();
    final handlers = PrivateHandlers(sender: sender);

    final handled = await handlers.handle(<String, dynamic>{
      'message': <String, dynamic>{
        'chat': <String, dynamic>{'id': -100, 'type': 'supergroup'},
        'text': '/start',
      },
    });

    expect(handled, isFalse);
    expect(sender.messages, isEmpty);
  });
}

Map<String, dynamic> _privateStart(String text) {
  return <String, dynamic>{
    'message': <String, dynamic>{
      'chat': <String, dynamic>{'id': 42, 'type': 'private'},
      'from': <String, dynamic>{'id': 42},
      'text': text,
    },
  };
}
