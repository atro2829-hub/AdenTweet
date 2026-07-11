import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/supabase_client.dart';
import '../../../models/conversation_model.dart';
import '../../../models/message_model.dart';
import '../../../models/profile_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Fetches conversations for the current user with participants and last message.
final conversationsProvider =
    FutureProvider<List<ConversationModel>>((ref) async {
  final myId = ref.read(currentUserProvider)?.id;
  if (myId == null) return [];

  try {
    // Fetch conversation participants
    final participantsResponse = await supabase
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', myId);

    final conversationIds = (participantsResponse as List)
        .map((e) => e['conversation_id'] as String)
        .toList();

    if (conversationIds.isEmpty) return [];

    // Fetch conversations
    final conversationsResponse = await supabase
        .from('conversations')
        .select()
        .inFilter('id', conversationIds)
        .order('updated_at', ascending: false);

    final conversations = <ConversationModel>[];

    for (final conv in conversationsResponse as List) {
      // Fetch participants for each conversation
      final convParticipantsResponse = await supabase
          .from('conversation_participants')
          .select('user_id, user:profiles!conversation_participants_user_id_fkey(*)')
          .eq('conversation_id', conv['id']);

      final participants = (convParticipantsResponse as List)
          .map((e) => ProfileModel.fromJson(
              e['user'] as Map<String, dynamic>))
          .toList();

      // Fetch last message
      final lastMessageResponse = await supabase
          .from('messages')
          .select('*, sender:profiles!messages_sender_id_fkey(*)')
          .eq('conversation_id', conv['id'])
          .order('created_at', ascending: false)
          .limit(1);

      MessageModel? lastMessage;
      if ((lastMessageResponse as List).isNotEmpty) {
        lastMessage = MessageModel.fromJson(
            lastMessageResponse[0] as Map<String, dynamic>);
      }

      conversations.add(ConversationModel(
        id: conv['id'] as String,
        createdAt: DateTime.parse(conv['created_at'] as String),
        updatedAt: DateTime.parse(conv['updated_at'] as String),
        participants: participants,
        lastMessage: lastMessage,
      ));
    }

    return conversations;
  } catch (e) {
    return [];
  }
});

/// Fetches messages for a specific [conversationId].
final messagesProvider =
    FutureProvider.family<List<MessageModel>, String>(
        (ref, conversationId) async {
  try {
    final response = await supabase
        .from('messages')
        .select('*, sender:profiles!messages_sender_id_fkey(*)')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(50);

    return (response as List)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Sends a message to a conversation.
final sendMessageProvider = Provider<
    Future<void> Function({
      required String conversationId,
      required String content,
    })>((ref) {
  return ({
    required String conversationId,
    required String content,
  }) async {
    final myId = ref.read(currentUserProvider)?.id;
    if (myId == null) return;

    try {
      await supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': myId,
        'content': content,
        'message_type': 'text',
        'media_url': '',
        'is_read': false,
      });

      // Update conversation's updated_at
      await supabase
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);
    } catch (e) {
      rethrow;
    }
  };
});

/// Checks if a conversation exists between current user and [otherUserId],
/// and creates one if not. Returns the conversation ID.
final createOrGetConversationProvider =
    FutureProvider.family<String, String>((ref, otherUserId) async {
  final myId = ref.read(currentUserProvider)?.id;
  if (myId == null) throw Exception('غير مسجل الدخول');

  try {
    // Check for existing conversation between the two users
    final myConversations = await supabase
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', myId);

    final myConvIds = (myConversations as List)
        .map((e) => e['conversation_id'] as String)
        .toList();

    if (myConvIds.isNotEmpty) {
      final otherConversations = await supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', otherUserId)
          .inFilter('conversation_id', myConvIds);

      final sharedIds = (otherConversations as List)
          .map((e) => e['conversation_id'] as String)
          .toList();

      if (sharedIds.isNotEmpty) {
        return sharedIds.first;
      }
    }

    // Create new conversation
    final convResponse = await supabase.from('conversations').insert({
      'updated_at': DateTime.now().toIso8601String(),
    }).select().single();

    final convId = convResponse['id'] as String;

    // Add both participants
    await supabase.from('conversation_participants').insert([
      {'conversation_id': convId, 'user_id': myId},
      {'conversation_id': convId, 'user_id': otherUserId},
    ]);

    return convId;
  } catch (e) {
    throw Exception('فشل إنشاء المحادثة');
  }
});

/// Search users for new message.
final searchUsersProvider =
    FutureProvider.family<List<ProfileModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  try {
    final response = await supabase
        .from('profiles')
        .select()
        .or('username.ilike.%$query%,display_name.ilike.%$query%')
        .limit(20);

    return (response as List)
        .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});