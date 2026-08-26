import 'dart:async';

import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:l/l.dart';

const int outboundBatchSize = 50;
const Duration outboundBatchPause = Duration(seconds: 1);

Future<void> paceOutboundBatch(int sentCount) async {
  if (sentCount > 0 && sentCount % outboundBatchSize == 0) {
    await Future<void>.delayed(outboundBatchPause);
  }
}

Future<void> sendClaimedBatch<T>({
  required Iterable<T> items,
  required String Function(T item) claimKey,
  required JobDedupeRepository dedupe,
  required Future<void> Function(T item) send,
  required String Function(T item) errorLabel,
}) async {
  var sent = 0;
  for (final item in items) {
    final key = claimKey(item);
    if (!dedupe.tryClaim(key)) {
      continue;
    }
    try {
      await send(item);
      sent++;
      await paceOutboundBatch(sent);
    } on Object catch (error, stackTrace) {
      dedupe.release(key);
      l.w('${errorLabel(item)}: $error', stackTrace);
    }
  }
}
