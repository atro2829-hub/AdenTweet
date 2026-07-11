import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';

/// Screen for editing the current user's profile.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

// Image file upload disabled for this build
  String _currentAvatarUrl = '';
  String _currentCoverUrl = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      _displayNameController.text = profile.displayName;
      _usernameController.text = profile.username;
      _bioController.text = profile.bio;
      _locationController.text = profile.location;
      _websiteController.text = profile.website;
      _currentAvatarUrl = profile.avatarUrl;
      _currentCoverUrl = profile.coverUrl;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    // Image picker not available in this build
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('اختيار الصورة غير متاح حالياً')),
    );
  }

  Future<void> _pickCover() async {
    // Image picker not available in this build
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('اختيار الصورة غير متاح حالياً')),
    );
  }

  Future<String?> _uploadImage(String bucket, String path) async {
    return null; // Image upload not available
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String avatarUrl = _currentAvatarUrl;
      String coverUrl = _currentCoverUrl;

      // Image upload disabled in this build

      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      await supabase.from('profiles').update({
        'display_name': _displayNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
        'avatar_url': avatarUrl,
        'cover_url': coverUrl,
      }).eq('id', userId);

      // Refresh profile
      ref.invalidate(authStateProvider);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حفظ التعديلات')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Text(
              'إلغاء',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 16,
              ),
            ),
            onPressed: () => context.pop(),
          ),
          centerTitle: true,
          title: const Text(
            'تعديل الملف الشخصي',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: SizedBox(
                  width: 80,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      disabledBackgroundColor:
                          AppTheme.accentBlue.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'حفظ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Cover image
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: _pickCover,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[900],
                      child: _currentCoverUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: _currentCoverUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _coverPlaceholder(),
                                )
                              : _coverPlaceholder(),
                    ),
                  ),
                  // Camera icon on cover
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  // Avatar
                  Positioned(
                    bottom: -32,
                    right: 16,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.scaffoldBackground, width: 4),
                          color: AppTheme.cardSurface,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _currentAvatarUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _currentAvatarUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        _avatarPlaceholder(),
                                    errorWidget: (_, __, ___) =>
                                        _avatarPlaceholder(),
                                  )
                                : _avatarPlaceholder(),
                      ),
                    ),
                  ),
                  // Camera icon on avatar
                  Positioned(
                    bottom: 22,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Display name
                      _buildTextField(
                        controller: _displayNameController,
                        label: 'الاسم المعروض',
                        maxLength: 50,
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),

                      // Username
                      _buildTextField(
                        controller: _usernameController,
                        label: '@اسم المستخدم',
                        prefix: const Text(
                          '@',
                          style: TextStyle(color: AppTheme.secondaryText),
                        ),
                        maxLength: 30,
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),

                      // Bio
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _bioController,
                            maxLength: 160,
                            maxLines: 4,
                            minLines: 3,
                            style: const TextStyle(
                                color: AppTheme.primaryText, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'نبذة عنك',
                              counterStyle: const TextStyle(
                                  color: AppTheme.secondaryText),
                              filled: false,
                              border: const UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppTheme.borderColor),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppTheme.borderColor),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppTheme.accentBlue),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Location
                      _buildTextField(
                        controller: _locationController,
                        label: 'الموقع',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Website
                      _buildTextField(
                        controller: _websiteController,
                        label: 'الموقع الإلكتروني',
                        icon: Icons.link,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int? maxLength,
    Widget? prefix,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      style: const TextStyle(color: AppTheme.primaryText, fontSize: 16),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: AppTheme.secondaryText) : null,
        prefix: prefix,
        labelStyle: const TextStyle(color: AppTheme.secondaryText),
        counterStyle: const TextStyle(color: AppTheme.secondaryText),
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.accentBlue, width: 2),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: AppTheme.cardSurface,
      child: const Center(
        child: Icon(Icons.person, size: 32, color: AppTheme.secondaryText),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.image, size: 40, color: AppTheme.secondaryText),
      ),
    );
  }
}