import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/tweet_provider.dart';

/// Screen for composing a new tweet.
///
/// Provides a multiline text field with a 280-character limit, media
/// attachment icons, character counter, and a post button.
class ComposeTweetScreen extends ConsumerStatefulWidget {
  final String? replyToId;

  const ComposeTweetScreen({super.key, this.replyToId});

  @override
  ConsumerState<ComposeTweetScreen> createState() => _ComposeTweetScreenState();
}

class _ComposeTweetScreenState extends ConsumerState<ComposeTweetScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isPosting = false;
  final List<String> _mediaUrls = [];

  static const int _maxLength = 280;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Extracts @mentions from the tweet content.
  List<String> _extractMentions(String text) {
    final regex = RegExp(r'@(\w+)');
    return regex
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toList();
  }

  /// Extracts #hashtags from the tweet content.
  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'#(\w+)');
    return regex
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toList();
  }

  Future<void> _postTweet() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      await ref.read(createTweetProvider({
        'content': content,
        'mediaUrls': _mediaUrls,
        'mentions': _extractMentions(content),
        'hashtags': _extractHashtags(content),
      }).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نشر التغريدة بنجاح'),
            backgroundColor: AppTheme.retweetGreen,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل نشر التغريدة: $e'),
            backgroundColor: AppTheme.likeRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final charCount = _controller.text.length;
    final isNearLimit = charCount > _maxLength - 20;
    final isOverLimit = charCount > _maxLength;
    final canPost = charCount > 0 && !isOverLimit && !_isPosting;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          title: const Text('تغريدة جديدة'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: ElevatedButton(
                onPressed: canPost ? _postTweet : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canPost ? AppTheme.accentBlue : AppTheme.borderColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.borderColor,
                  disabledForegroundColor: AppTheme.secondaryText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'نشر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Tweet input area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current user avatar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.borderColor,
                      backgroundImage: (profile != null &&
                              profile.avatarUrl.isNotEmpty)
                          ? NetworkImage(profile.avatarUrl)
                          : null,
                      child: (profile == null ||
                              profile.avatarUrl.isEmpty)
                          ? Text(
                              profile?.displayName.isNotEmpty ?? false
                                  ? profile!.displayName[0]
                                  : '?',
                              style: const TextStyle(
                                color: AppTheme.primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLength: _maxLength,
                      maxLines: null,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 17,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'ما الذي يحدث؟',
                        hintStyle: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 17,
                        ),
                        counterText: '',
                        contentPadding: EdgeInsets.only(top: 16, bottom: 8),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // Media attachments & character counter bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.borderColor, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  // Media attachment icons
                  _mediaButton(
                    icon: Icons.camera_alt_outlined,
                    onTap: () {
                      // Camera pick functionality
                    },
                  ),
                  const SizedBox(width: 16),
                  _mediaButton(
                    icon: Icons.image_outlined,
                    onTap: () {
                      // Image pick functionality
                    },
                  ),
                  const SizedBox(width: 16),
                  _mediaButton(
                    icon: Icons.gif_box_outlined,
                    onTap: () {
                      // GIF pick functionality
                    },
                  ),
                  const Spacer(),
                  // Character counter
                  if (charCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOverLimit
                            ? AppTheme.likeRed.withOpacity(0.15)
                            : isNearLimit
                                ? AppTheme.likeRed.withOpacity(0.1)
                                : Colors.transparent,
                      ),
                      child: Text(
                        '$_maxLength',
                        style: TextStyle(
                          color: isOverLimit
                              ? AppTheme.likeRed
                              : isNearLimit
                                  ? AppTheme.likeRed
                                  : AppTheme.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(width: 20),
                  // Circular progress indicator
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          value: charCount / _maxLength,
                          backgroundColor: AppTheme.borderColor,
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOverLimit
                                ? AppTheme.likeRed
                                : isNearLimit
                                    ? Colors.orange
                                    : AppTheme.accentBlue,
                          ),
                        ),
                        Center(
                          child: Text(
                            '$_charCount',
                            style: TextStyle(
                              color: isOverLimit
                                  ? AppTheme.likeRed
                                  : isNearLimit
                                      ? AppTheme.likeRed
                                      : AppTheme.secondaryText,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  int get _charCount => _controller.text.length;

  Widget _mediaButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: AppTheme.accentBlue, size: 22),
      ),
    );
  }
}