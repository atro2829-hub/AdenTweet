import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/profile_model.dart';
import '../../../models/tweet_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/tweet_provider.dart';

/// The core tweet display widget.
///
/// Renders a single tweet with author info, content, media grid, and
/// interaction action bar. Wraps everything in RTL [Directionality].
class TweetCard extends ConsumerStatefulWidget {
  final TweetModel tweet;
  final bool showActions;
  final VoidCallback? onDeleted;

  const TweetCard({
    super.key,
    required this.tweet,
    this.showActions = true,
    this.onDeleted,
  });

  @override
  ConsumerState<TweetCard> createState() => _TweetCardState();
}

class _TweetCardState extends ConsumerState<TweetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.8,
      upperBound: 1.1,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_scaleController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _scaleController.reverse();
        }
      });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _bounce() {
    _scaleController.forward(from: 0.8);
  }

  Future<void> _toggleLike() async {
    _bounce();
    try {
      await ref.read(likeTweetProvider({
        'tweetId': widget.tweet.id,
        'currentCount': widget.tweet.likesCount,
        'isLiked': widget.tweet.isLiked,
      }).future);
      ref.invalidate(tweetFeedProvider);
    } catch (_) {}
  }

  Future<void> _toggleRetweet() async {
    _bounce();
    try {
      await ref.read(retweetProvider({
        'tweetId': widget.tweet.id,
        'currentCount': widget.tweet.retweetsCount,
        'isRetweeted': widget.tweet.isRetweeted,
      }).future);
      ref.invalidate(tweetFeedProvider);
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    _bounce();
    try {
      await ref.read(bookmarkProvider({
        'tweetId': widget.tweet.id,
        'currentCount': widget.tweet.bookmarksCount,
        'isBookmarked': widget.tweet.isBookmarked,
      }).future);
      ref.invalidate(tweetFeedProvider);
    } catch (_) {}
  }

  Future<void> _deleteTweet() async {
    try {
      await ref.read(deleteTweetProvider({
        'tweetId': widget.tweet.id,
        'userId': widget.tweet.userId,
      }).future);
      widget.onDeleted?.call();
      ref.invalidate(tweetFeedProvider);
    } catch (_) {}
  }

  void _showMoreOptions(BuildContext context) {
    final currentUserId = ref.read(currentProfileProvider)?.id;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.tweet.userId == currentUserId)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.likeRed),
                title: const Text(
                  'حذف التغريدة',
                  style: TextStyle(color: AppTheme.likeRed),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteTweet();
                },
              ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline,
                  color: AppTheme.primaryText),
              title: const Text('إضافة إلى المفضلة'),
              onTap: () {
                Navigator.pop(ctx);
                _toggleBookmark();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined,
                  color: AppTheme.primaryText),
              title: const Text('مشاركة'),
              onTap: () {
                Navigator.pop(ctx);
                // Share functionality can be added later
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tweet = widget.tweet;
    final author = tweet.author;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: () => context.push('/tweet/${tweet.id}'),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      if (author != null) {
                        context.push('/profile/${author.id}');
                      }
                    },
                    child: _buildAvatar(author),
                  ),
                  const SizedBox(width: 12),
                  // Content column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row
                        _buildNameRow(author),
                        const SizedBox(height: 4),
                        // Reply indicator
                        if (tweet.replyToId != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'رد على @${author?.username ?? ''}',
                              style: const TextStyle(
                                color: AppTheme.accentBlue,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        // Content
                        if (tweet.content.isNotEmpty)
                          SelectableText(
                            tweet.content,
                            style: const TextStyle(
                              color: AppTheme.primaryText,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        // Media grid
                        if (tweet.mediaUrls.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildMediaGrid(tweet.mediaUrls),
                        ],
                        // Action bar
                        if (widget.showActions) ...[
                          const SizedBox(height: 8),
                          _buildActionBar(tweet),
                        ],
                      ],
                    ),
                  ),
                  // More options
                  if (widget.showActions)
                    GestureDetector(
                      onTap: () => _showMoreOptions(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.more_horiz,
                          color: AppTheme.secondaryText,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 0.5, color: AppTheme.borderColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ProfileModel? author) {
    final hasAvatar = author != null && author.avatarUrl.isNotEmpty;
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.borderColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? CachedNetworkImage(
              imageUrl: author.avatarUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildAvatarPlaceholder(author),
              errorWidget: (_, __, ___) => _buildAvatarPlaceholder(author),
            )
          : _buildAvatarPlaceholder(author),
    );
  }

  Widget _buildAvatarPlaceholder(ProfileModel? author) {
    final letter = (author?.displayName.isNotEmpty ?? false)
        ? author!.displayName[0]
        : '?';
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: AppTheme.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNameRow(ProfileModel? author) {
    return Row(
      children: [
        Flexible(
          child: Text(
            author?.displayName ?? '',
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (author?.isVerified == true) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.verified,
            color: AppTheme.accentBlue,
            size: 18,
          ),
        ],
        const SizedBox(width: 6),
        Text(
          '@${author?.username ?? ''}',
          style: const TextStyle(
            color: AppTheme.secondaryText,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '·',
          style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          DateFormatter.formatRelative(widget.tweet.createdAt, locale: 'ar'),
          style: const TextStyle(
            color: AppTheme.secondaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaGrid(List<String> urls) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: urls[0],
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: 200,
            color: AppTheme.cardSurface,
          ),
          errorWidget: (_, __, ___) => Container(
            height: 200,
            color: AppTheme.cardSurface,
            child: const Icon(Icons.broken_image,
                color: AppTheme.secondaryText, size: 40),
          ),
        ),
      );
    }

    if (urls.length == 2) {
      return Row(
        children: [
          Expanded(child: _mediaItem(urls[0])),
          const SizedBox(width: 4),
          Expanded(child: _mediaItem(urls[1])),
        ],
      );
    }

    // For 3+ images, show a 2x2 grid (max 4)
    final displayUrls = urls.take(4).toList();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.5,
      children: displayUrls.map((url) => _mediaItem(url)).toList(),
    );
  }

  Widget _mediaItem(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppTheme.cardSurface),
        errorWidget: (_, __, ___) => Container(
          color: AppTheme.cardSurface,
          child: const Icon(Icons.broken_image, color: AppTheme.secondaryText),
        ),
      ),
    );
  }

  Widget _buildActionBar(TweetModel tweet) {
    return Row(
      children: [
        // Reply / Comment
        _actionButton(
          icon: Icons.comment_outlined,
          count: tweet.repliesCount,
          color: AppTheme.secondaryText,
          onTap: () => context.push('/tweet/${tweet.id}'),
        ),
        const Spacer(),
        // Retweet
        _actionButton(
          icon: Icons.repeat,
          count: tweet.retweetsCount,
          color:
              tweet.isRetweeted ? AppTheme.retweetGreen : AppTheme.secondaryText,
          onTap: _toggleRetweet,
          isActive: tweet.isRetweeted,
        ),
        const Spacer(),
        // Like with bounce animation
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: _actionButton(
            icon: tweet.isLiked ? Icons.favorite : Icons.favorite_border,
            count: tweet.likesCount,
            color: tweet.isLiked ? AppTheme.likeRed : AppTheme.secondaryText,
            onTap: _toggleLike,
            isActive: tweet.isLiked,
          ),
        ),
        const Spacer(),
        // Bookmark
        _actionButton(
          icon:
              tweet.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          count: tweet.bookmarksCount,
          color: tweet.isBookmarked
              ? AppTheme.accentBlue
              : AppTheme.secondaryText,
          onTap: _toggleBookmark,
          isActive: tweet.isBookmarked,
        ),
        const Spacer(),
        // Share
        _actionButton(
          icon: Icons.share,
          count: 0,
          color: AppTheme.secondaryText,
          onTap: () {
            // Share functionality
          },
          showCount: false,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
    bool showCount = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            if (showCount && count > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: TextStyle(color: color, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}م';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}ك';
    return count.toString();
  }
}