import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../models/profile_model.dart';
import '../../../models/tweet_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tweet/widgets/tweet_card.dart';
import '../providers/profile_provider.dart';

/// Profile view screen for any user (own or other).
class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isOwnProfile {
    final currentUser = ref.read(currentUserProvider);
    return currentUser?.id == widget.userId;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync =
        ref.watch(userProfileProvider(widget.userId));
    final isFollowingAsync =
        ref.watch(isFollowingProvider(widget.userId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: RefreshIndicator(
          color: AppTheme.accentBlue,
          onRefresh: () async {
            ref.invalidate(userProfileProvider(widget.userId));
            ref.invalidate(userTweetsProvider(widget.userId));
            ref.invalidate(userRepliesProvider(widget.userId));
            ref.invalidate(userLikesProvider(widget.userId));
            ref.invalidate(isFollowingProvider(widget.userId));
          },
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                backgroundColor: AppTheme.scaffoldBackground,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: () => context.pop(),
                ),
                title: const Text(
                  'الملف الشخصي',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
                actions: [
                  if (_isOwnProfile)
                    IconButton(
                      icon: const Icon(Icons.settings, size: 20),
                      onPressed: () => context.push('/settings'),
                    ),
                ],
              ),

              // Profile content
              profileAsync.when(
                data: (profile) => _buildProfileContent(
                  context,
                  profile,
                  isFollowingAsync,
                ),
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ),
                error: (_, __) => const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'فشل تحميل الملف الشخصي',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    ProfileModel profile,
    AsyncValue<bool> isFollowingAsync,
  ) {
    final isFollowing =
        _isOwnProfile ? false : (isFollowingAsync.valueOrNull ?? false);

    return SliverList(
      delegate: SliverChildListDelegate([
        // Cover image
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[900],
              child: profile.coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: profile.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey[900]),
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.grey[900]),
                    )
                  : null,
            ),
            // Avatar overlapping cover
            Positioned(
              bottom: -32,
              right: 16,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppTheme.scaffoldBackground, width: 4),
                  color: AppTheme.cardSurface,
                ),
                clipBehavior: Clip.antiAlias,
                child: profile.avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profile.avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _avatarPlaceholder(profile),
                        errorWidget: (_, __, ___) =>
                            _avatarPlaceholder(profile),
                      )
                    : _avatarPlaceholder(profile),
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

        // Name, username, and action button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Display name + verified badge
                  Flexible(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.displayName,
                            style: const TextStyle(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: AppTheme.accentBlue,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit / Follow button
                  if (_isOwnProfile)
                    OutlinedButton(
                      onPressed: () => context.push('/edit-profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryText,
                        side: const BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                      ),
                      child: const Text(
                        'تعديل الملف',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    )
                  else
                    SizedBox(
                      height: 36,
                      child: isFollowingAsync.isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.accentBlue,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(toggleFollowProvider)(profile.id);
                                  ref.invalidate(
                                      isFollowingProvider(profile.id));
                                  ref.invalidate(
                                      userProfileProvider(profile.id));
                                } catch (_) {}
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? Colors.transparent
                                    : AppTheme.accentBlue,
                                foregroundColor: isFollowing
                                    ? AppTheme.primaryText
                                    : Colors.white,
                                side: BorderSide(
                                  color: isFollowing
                                      ? AppTheme.borderColor
                                      : Colors.transparent,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 0),
                              ),
                              child: Text(
                                isFollowing ? 'إلغاء المتابعة' : 'متابعة',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              // Username
              Text(
                '@${profile.username}',
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 15,
                ),
              ),

              // Bio
              if (profile.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  profile.bio,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],

              // Location and website
              if (profile.location.isNotEmpty || profile.website.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (profile.location.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppTheme.secondaryText),
                          const SizedBox(width: 4),
                          Text(
                            profile.location,
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    if (profile.website.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link,
                              size: 14, color: AppTheme.secondaryText),
                          const SizedBox(width: 4),
                          Text(
                            profile.website,
                            style: const TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _statItem(profile.tweetsCount, 'التغريدات'),
                  const SizedBox(width: 20),
                  _statItem(profile.followingCount, 'يتابع'),
                  const SizedBox(width: 20),
                  _statItem(profile.followersCount, 'متابعين'),
                ],
              ),

              // Tab bar
              const SizedBox(height: 8),
              const Divider(color: AppTheme.borderColor, height: 0.5),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryText,
                unselectedLabelColor: AppTheme.secondaryText,
                indicatorColor: AppTheme.accentBlue,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
                tabs: const [
                  Tab(text: 'التغريدات'),
                  Tab(text: 'الردود'),
                  Tab(text: 'الإعجابات'),
                ],
              ),
            ],
          ),
        ),

        // Tab content
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTweetList(ref.watch(userTweetsProvider(widget.userId))),
              _buildTweetList(ref.watch(userRepliesProvider(widget.userId))),
              _buildTweetList(ref.watch(userLikesProvider(widget.userId))),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildTweetList(AsyncValue<List<TweetModel>> tweetsAsync) {
    return tweetsAsync.when(
      data: (tweets) {
        if (tweets.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد تغريدات بعد',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 15),
            ),
          );
        }
        return ListView.builder(
          itemCount: tweets.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return TweetCard(tweet: tweets[index]);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accentBlue),
      ),
      error: (_, __) => const Center(
        child: Text(
          'حدث خطأ',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
      ),
    );
  }

  Widget _statItem(int count, String label) {
    return Row(
      children: [
        Text(
          _formatCount(count),
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.secondaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}م';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}ك';
    return count.toString();
  }

  Widget _avatarPlaceholder(ProfileModel profile) {
    final letter = profile.displayName.isNotEmpty ? profile.displayName[0] : '?';
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: AppTheme.primaryText,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}