import 'package:course_chatbot/src/data/access_repository.dart';
import 'package:course_chatbot/src/data/catalog_repository.dart';
import 'package:course_chatbot/src/data/funnel_analytics_repository.dart';
import 'package:course_chatbot/src/data/order_repository.dart';
import 'package:course_chatbot/src/data/user_repository.dart';
import 'package:course_chatbot/src/data/warmup_repository.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';

export 'package:course_chatbot/src/domain/broadcast.dart';

abstract interface class CourseRepository
    implements
        CatalogRepository,
        UserRepository,
        OrderRepository,
        ChannelAccessRepository,
        WarmupRepository,
        FunnelAnalyticsRepository {
  void init();

  T transaction<T>(T Function() action);

  void appendConversation({
    required ConversationDirection direction,
    required int peerUserId,
    String? peerUsername,
    required int chatId,
    int? telegramMessageId,
    required ConversationContentType contentType,
    String? textPreview,
  });

  List<ConversationLogEntry> dialogForUser(int userId, {int limit = 30});

  void pruneConversationLog({required DateTime olderThan, int keepPerUser = 200});
}
