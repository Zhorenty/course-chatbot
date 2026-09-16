import 'dart:io';

import 'package:course_chatbot/src/telegram/input_rich_message.dart';

/// Bundled Drive images from the customer copy sheet «Тексты бота».
///
/// Missing files are skipped so tests and a bot without assets still send text.
abstract final class FunnelMedia {
  static const String start = 'start';
  static const String paid = 'paid';
  static const String defaultRoot = 'assets/funnel';

  static const Map<String, List<String>> _stems = <String, List<String>>{
    start: <String>['welcome'],
    'warmup_0': <String>['masterclass'],
    'webinar_24h': <String>['masterclass'],
    'webinar_next': <String>['post_1', 'post_2'],
    'sales_open': <String>['post_1', 'post_2'],
    paid: <String>['paid'],
    'dozhim_d1': <String>[
      'dozhim1_01',
      'dozhim1_02',
      'dozhim1_03',
      'dozhim1_04',
      'dozhim1_05',
      'dozhim1_06',
      'dozhim1_07',
      'dozhim1_08',
      'dozhim1_09',
    ],
    'dozhim_d2': <String>['dozhim2'],
    'dozhim_d3': <String>['dozhim3_01', 'dozhim3_02', 'dozhim3_03', 'dozhim3_04', 'dozhim3_05'],
    'dozhim_d4': <String>['dozhim4'],
  };

  static const List<String> _extensions = <String>['jpg', 'jpeg', 'png', 'webp'];

  static List<String> pathsFor(String key, {String root = defaultRoot}) {
    final stems = _stems[key];
    if (stems == null) {
      return const <String>[];
    }
    final found = <String>[];
    for (final stem in stems) {
      final path = _existing(root, stem);
      if (path != null) {
        found.add(path);
      }
    }
    return found;
  }

  static String? _existing(String root, String stem) {
    for (final ext in _extensions) {
      final path = '$root/$stem.$ext';
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  static List<InputRichMessageMedia> richMedia(String key, {String root = defaultRoot}) {
    final paths = pathsFor(key, root: root);
    return <InputRichMessageMedia>[
      for (var i = 0; i < paths.length; i++)
        InputRichMessageMedia.photo(
          id: 'p$i',
          document: InputRichDocument.file(localPath: paths[i]),
        ),
    ];
  }
}
