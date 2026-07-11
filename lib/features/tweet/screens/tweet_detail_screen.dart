import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/tweet_provider.dart';
import '../../tweet/widgets/tweet_card.dart';

/// Screen showing the full detail of a single tweet with its replies
/// and a reply input bar at the bottom.
class TweetDetailScreen extends ConsumerStatefulWidget {
  final String tweetId;

  const TweetDetailScreen({super.key, required this.tweetId});

  @override
  ConsumerState<TweetDetailScreen> createState() => _TweetDetailScreenState();
}

class _TweetDetailScreenState extends ConsumerState<TweetDetailScreen> {
  final _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;

    setState(() => _isReplying = true);

    try {
      // Extract mentions and hashtags
      final mentions = RegExp(r'@(\w+)')
          .allMatches(content)
          .map((m) => m.group(1)!)
          .toList();
      final hashtags = RegExp(r'#(\w+)')
          .allMatches(content)
          .map((m) => m.group(1)!)
          .toList();

      // Insert the reply tweet
      await ref.read(createTweetProvider({
        'content': content,
        'mediaUrls': <String>[],
        'mentions': mentions,
        'hashtags': hashtags,
        'replyToId': widget.tweetId,
      }).future);

      _replyController.clear();
      // Refresh the tweet and replies
      ref.invalidate(singleTweetProvider(widget.tweetId));
      ref.invalidate(tweetRepliesProvider(widget.tweetId));
      ref.invalidate(tweetFeedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نشر الرد بنجاح'),
            backgroundColor: AppTheme.retweetGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل نشر الرد: $e'),
            backgroundColor: AppTheme.likeRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tweetAsync = ref.watch(singleTweetProvider(widget.tweetId));
    final repliesAsync = ref.watch(tweetRepliesProvider(widget.tweetId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('التغريدة'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Main tweet
            Expanded(
              child: tweetAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.accentBlue,
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.secondaryText, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'تعذر تحميل التغريدة',
                        style: TextStyle(color: AppTheme.secondaryText),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(singleTweetProvider(widget.tweetId)),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
                data: (tweet) {
                  return RefreshIndicator(
                    color: AppTheme.accentBlue,
                    backgroundColor: AppTheme.cardSurface,
                    onRefresh: () async {
                      ref.invalidate(singleTweetProvider(widget.tweetId));
                      ref.invalidate(tweetRepliesProvider(widget.tweetId));
                      await ref.read(singleTweetProvider(widget.tweetId).future);
                    },
                    child: CustomScrollView(
                      slivers: [
                        // Main tweet card (no border divider at bottom)
                        SliverToBoxAdapter(
                          child: TweetCard(
                            tweet: tweet,
                            showActions: true,
                            onDeleted: () => context.pop(),
                          ),
                        ),
                        // Replies header
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: AppTheme.borderColor, width: 0.5),
                              ),
                            ),
                            child: Text(
                              'الردود (${tweet.repliesCount})',
                              style: const TextStyle(
                                color: AppTheme.primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Replies list
                        repliesAsync.when(
                          loading: () => SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.accentBlue,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          error: (error, _) => SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'تعذر تحميل الردود',
                                  style: TextStyle(
                                      color: AppTheme.secondaryText),
                                ),
                              ),
                            ),
                          ),
                          data: (replies) {
                            if (replies.isEmpty) {
                              return SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 48),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.chat_bubble_outline,
                                            color: AppTheme.secondaryText
                                                .withOpacity(0.5),
                                            size: 48),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'كن أول من يرد على هذه التغريدة',
                                          style: TextStyle(
                                            color: AppTheme.secondaryText,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => TweetCard(
                                  tweet: replies[index],
                                  showActions: true,
                                ),
                                childCount: replies.length,
                              ),
                            );
                          },
                        ),
                        // Bottom padding for reply input bar
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 64),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Reply input bar
            _buildReplyBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBar() {
    final profile = ref.watch(currentProfileProvider);
    final canReply =
        _replyController.text.trim().isNotEmpty && !_isReplying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.borderColor,
            backgroundImage: (profile != null && profile.avatarUrl.isNotEmpty)
                ? NetworkImage(profile.avatarUrl)
                : null,
            child: (profile == null || profile.avatarUrl.isEmpty)
                ? Text(
                    profile?.displayName.isNotEmpty ?? false
                        ? profile!.displayName[0]
                        : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Reply text field
          Expanded(
            child: TextField(
              controller: _replyController,
              maxLines: null,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.primaryText,
                fontSize: 15,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'اكتب ردك...',
                hintStyle: TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 15,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          IconButton(
            icon: _isReplying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentBlue,
                    ),
                  )
                : Icon(
                    Icons.send,
                    color: canReply
                        ? AppTheme.accentBlue
                        : AppTheme.secondaryText,
                    size: 22,
                  ),
            onPressed: canReply ? _submitReply : null,
          ),
        ],
      ),
    );
  }
}