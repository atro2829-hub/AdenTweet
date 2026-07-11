import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/conversation_model.dart';
import '../../../models/profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/message_provider.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  bool _showNewMessage = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBackground,
          elevation: 0,
          title: const Text(
            'الرسائل',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_square, size: 20),
              onPressed: () {
                setState(() => _showNewMessage = !_showNewMessage);
              },
            ),
          ],
        ),
        body: _showNewMessage
            ? _buildNewMessagePanel()
            : conversationsAsync.when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    color: AppTheme.accentBlue,
                    onRefresh: () async {
                      ref.invalidate(conversationsProvider);
                    },
                    child: ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        return _buildConversationTile(conversations[index]);
                      },
                    ),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 64,
            color: AppTheme.secondaryText.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد محادثات بعد',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ConversationModel conversation) {
    // Get the other participant (not current user)
    final myId = ref.read(currentUserProvider)?.id;
    final other = conversation.participants
        .where((p) => p.id != myId)
        .firstOrNull;

    if (other == null) return const SizedBox.shrink();

    final lastMessage = conversation.lastMessage;
    final timeStr = lastMessage != null
        ? DateFormatter.formatRelative(lastMessage.createdAt, locale: 'ar')
        : '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: () {
          context.push('/conversation/${conversation.id}');
        },
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.borderColor,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: other.avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: other.avatarUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _avatarPlaceholder(other),
                          )
                        : _avatarPlaceholder(other),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          other.displayName,
                          style: const TextStyle(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (lastMessage != null)
                          Text(
                            lastMessage.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: lastMessage.senderId == myId
                                  ? AppTheme.secondaryText
                                  : AppTheme.primaryText,
                              fontSize: 14,
                            ),
                          )
                        else
                          const Text(
                            'ابدأ المحادثة',
                            style: TextStyle(
                                color: AppTheme.secondaryText, fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.borderColor, height: 0.5),
          ],
        ),
      ),
    );
  }

  Widget _buildNewMessagePanel() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                ref.invalidate(searchUsersProvider(query));
              },
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'ابحث عن مستخدم...',
                hintStyle:
                    const TextStyle(color: AppTheme.secondaryText),
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.secondaryText),
                filled: true,
                fillColor: AppTheme.cardSurface,
              ),
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final query = _searchController.text.trim();
                if (query.isEmpty) {
                  return const Center(
                    child: Text(
                      'ابحث عن شخص لإرسال رسالة',
                      style:
                          TextStyle(color: AppTheme.secondaryText, fontSize: 15),
                    ),
                  );
                }

                final usersAsync = ref.watch(searchUsersProvider(query));
                return usersAsync.when(
                  data: (users) {
                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                              color: AppTheme.secondaryText, fontSize: 15),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return _buildNewMessageUserTile(users[index]);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.accentBlue),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewMessageUserTile(ProfileModel profile) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: () async {
          try {
            final convId = await ref.read(
              createOrGetConversationProvider(profile.id).future,
            );
            if (mounted) {
              setState(() => _showNewMessage = false);
              context.push('/conversation/$convId');
            }
          } catch (_) {}
        },
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.borderColor,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: profile.avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profile.avatarUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _avatarPlaceholder(profile),
                          )
                        : _avatarPlaceholder(profile),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${profile.username}',
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.borderColor, height: 0.5),
          ],
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
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}