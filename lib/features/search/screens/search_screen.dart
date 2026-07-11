import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/supabase_client.dart';
import '../../../models/profile_model.dart';
import '../../profile/providers/profile_provider.dart';

/// Debounced search query state.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Search results provider.
final searchResultsProvider =
    FutureProvider<List<ProfileModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _hasText = false;

  void _onSearchChanged(String query) {
    setState(() => _hasText = query.isNotEmpty);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = query;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = ref.watch(searchQueryProvider).trim().isNotEmpty;
    final resultsAsync = ref.watch(searchResultsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                      color: AppTheme.primaryText, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'بحث',
                    hintStyle:
                        const TextStyle(color: AppTheme.secondaryText),
                    prefixIcon: const Icon(Icons.search,
                        color: AppTheme.secondaryText),
                    suffixIcon: _hasText
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                color: AppTheme.secondaryText, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _hasText = false);
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.cardSurface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: hasQuery
                    ? resultsAsync.when(
                        data: (results) {
                          if (results.isEmpty) {
                            return const Center(
                              child: Text(
                                'لا توجد نتائج',
                                style: TextStyle(
                                    color: AppTheme.secondaryText,
                                    fontSize: 15),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              return _buildUserTile(results[index]);
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.accentBlue),
                        ),
                        error: (_, __) => const Center(
                          child: Text(
                            'حدث خطأ في البحث',
                            style: TextStyle(color: AppTheme.secondaryText),
                          ),
                        ),
                      )
                    : _buildTrendingSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(ProfileModel profile) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: () => context.push('/profile/${profile.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
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
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (profile.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              color: AppTheme.accentBlue, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${profile.username}',
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                    if (profile.bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Follow button
              Consumer(
                builder: (context, ref, _) {
                  final isFollowingAsync =
                      ref.watch(isFollowingProvider(profile.id));
                  final isFollowing =
                      isFollowingAsync.valueOrNull ?? false;

                  return SizedBox(
                    height: 32,
                    child: isFollowingAsync.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentBlue),
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
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 0),
                            ),
                            child: Text(
                              isFollowing ? 'إلغاء المتابعة' : 'متابعة',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'الأكثر رواجاً',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              5,
              (index) => Column(
                children: [
                  _trendingItem(
                    category: 'تقنية · رائج',
                    topic: '#أدنتويت',
                    tweets: '${1200 + index * 300} تغريدة',
                  ),
                  const Divider(color: AppTheme.borderColor, height: 0.5),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _trendingItem(
              category: 'رياضة · رائج',
              topic: '#كرة_القدم',
              tweets: '٥.٤٣٢ تغريدة',
            ),
            const Divider(color: AppTheme.borderColor, height: 0.5),
            _trendingItem(
              category: 'ترند في اليمن',
              topic: '#عدن',
              tweets: '٣.٨٩١ تغريدة',
            ),
            const Divider(color: AppTheme.borderColor, height: 0.5),
            _trendingItem(
              category: 'أخبار · رائج',
              topic: '#تقنية',
              tweets: '٢.١٠٠ تغريدة',
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendingItem({
    required String category,
    required String topic,
    required String tweets,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            topic,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tweets,
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 13,
            ),
          ),
        ],
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