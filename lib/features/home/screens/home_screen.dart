import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../tweet/widgets/tweet_card.dart';
import '../providers/tweet_provider.dart';

/// Main home feed screen.
///
/// Displays a list of tweets from the user's timeline with pull-to-refresh,
/// shimmer loading placeholder, and an empty state.
class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(tweetFeedProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الرئيسية'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined),
              onPressed: () => context.push('/notifications'),
            ),
          ],
        ),
        body: feedAsync.when(
          loading: () => _buildShimmerList(),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppTheme.secondaryText, size: 48),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ في تحميل التغريدات',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(tweetFeedProvider),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
          data: (tweets) {
            if (tweets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.feed_outlined,
                        color: AppTheme.secondaryText.withOpacity(0.5), size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد تغريدات بعد',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppTheme.accentBlue,
              backgroundColor: AppTheme.cardSurface,
              onRefresh: () async {
                ref.invalidate(tweetFeedProvider);
                // Wait for the provider to complete
                await ref.read(tweetFeedProvider.future);
              },
              child: ListView.builder(
                itemCount: tweets.length,
                itemBuilder: (context, index) {
                  return TweetCard(
                    tweet: tweets[index],
                    onDeleted: () {
                      // Trigger a rebuild by invalidating the feed
                      ref.invalidate(tweetFeedProvider);
                    },
                  );
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await context.push('/compose');
            if (result == true) {
              ref.invalidate(tweetFeedProvider);
            }
          },
          backgroundColor: AppTheme.accentBlue,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  /// Builds a shimmer loading placeholder that mimics the tweet card layout.
  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) => _ShimmerTweetCard(),
    );
  }
}

/// A single shimmer placeholder card that mimics a [TweetCard] layout.
class _ShimmerTweetCard extends StatefulWidget {
  @override
  State<_ShimmerTweetCard> createState() => _ShimmerTweetCardState();
}

class _ShimmerTweetCardState extends State<_ShimmerTweetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = (0.5 + 0.5 * _controller.value) * 0.15;
        return Opacity(
          opacity: 0.6 + 0.4 * (0.5 + 0.5 * _controller.value),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar shimmer
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor.withOpacity(
                            0.3 + offset),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content shimmer
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Container(
                            width: 120,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor
                                  .withOpacity(0.3 + offset),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Username
                          Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor
                                  .withOpacity(0.2 + offset),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Content lines
                          Container(
                            width: double.infinity,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor
                                  .withOpacity(0.2 + offset),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity * 0.7,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor
                                  .withOpacity(0.2 + offset),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Action bar shimmer
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              4,
                              (_) => Container(
                                width: 40,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppTheme.borderColor
                                      .withOpacity(0.2 + offset),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0.5, color: AppTheme.borderColor),
            ],
          ),
        );
      },
    );
  }
}