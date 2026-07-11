import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/supabase_client.dart';
import '../../../models/message_model.dart';
import '../../../models/profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/message_provider.dart';

/// Simple provider to hold the other user info in a conversation.
final conversationOtherUserProvider =
    FutureProvider.family<ProfileModel, String>((ref, conversationId) async {
  try {
    final myId = ref.read(currentUserProvider)?.id;
    if (myId == null) throw Exception('غير مسجل الدخول');

    final response = await supabase
        .from('conversation_participants')
        .select('user:profiles!conversation_participants_user_id_fkey(*)')
        .eq('conversation_id', conversationId)
        .neq('user_id', myId)
        .single();

    return ProfileModel.fromJson(response['user'] as Map<String, dynamic>);
  } catch (e) {
    throw Exception('فشل تحميل بيانات المستخدم');
  }
});

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ConversationScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      await ref.read(sendMessageProvider)(
        conversationId: widget.conversationId,
        content: content,
      );
      ref.invalidate(messagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
      _scrollToBottom();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final otherUserAsync =
        ref.watch(conversationOtherUserProvider(widget.conversationId));
    final messagesAsync =
        ref.watch(messagesProvider(widget.conversationId));
    final myId = ref.watch(currentUserProvider)?.id;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () => context.pop(),
          ),
          title: otherUserAsync.when(
            data: (user) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.borderColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: user.avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _avatarPlaceholder(user),
                        )
                      : _avatarPlaceholder(user),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const Text(
              'محادثة',
              style: TextStyle(color: AppTheme.primaryText),
            ),
            error: (_, __) => const Text(
              'محادثة',
              style: TextStyle(color: AppTheme.primaryText),
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  // Scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'ابدأ المحادثة! 💬',
                        style: TextStyle(
                          color: AppTheme.secondaryText.withOpacity(0.6),
                          fontSize: 15,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(
                          messages[index], myId ?? '');
                    },
                  );
                },
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.accentBlue),
                ),
                error: (_, __) => const Center(
                  child: Text(
                    'حدث خطأ في تحميل الرسائل',
                    style: TextStyle(color: AppTheme.secondaryText),
                  ),
                ),
              ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.borderColor, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                          color: AppTheme.primaryText, fontSize: 15),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        hintStyle: const TextStyle(
                            color: AppTheme.secondaryText),
                        filled: true,
                        fillColor: AppTheme.cardSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppTheme.accentBlue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentBlue,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, String myId) {
    final isMine = message.senderId == myId;
    final timeStr = DateFormatter.formatRelative(
      message.createdAt,
      locale: 'ar',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMine
                ? AppTheme.accentBlue
                : AppTheme.cardSurface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMine ? Radius.zero : const Radius.circular(20),
              bottomRight: isMine ? const Radius.circular(20) : Radius.zero,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Show sender name if needed
              if (!isMine && message.sender != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.sender!.displayName,
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(
                  color: isMine ? Colors.white : AppTheme.primaryText,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(
                  color: isMine
                      ? Colors.white.withOpacity(0.7)
                      : AppTheme.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(ProfileModel profile) {
    final letter = profile.displayName.isNotEmpty ? profile.displayName[0] : '?';
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: AppTheme.primaryText,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}