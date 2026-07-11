import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    await ref.read(authStateProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          displayName: _displayNameController.text.trim(),
        );

    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go('/home');
    } else if (authState.errorMessage != null) {
      setState(() => _isSubmitting = false);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading || _isSubmitting;
    final errorMessage = authState.errorMessage;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // Title
                    Center(
                      child: Text(
                        'إنشاء حساب',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontSize: 28,
                            ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: Text(
                        'انضم إلى AdenTweet اليوم',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.secondaryText,
                              fontSize: 15,
                            ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Display name field
                    TextFormField(
                      controller: _displayNameController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'الاسم المعروض',
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.secondaryText),
                        hintStyle: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الاسم المعروض';
                        }
                        if (value.trim().length < 2) {
                          return 'الاسم يجب أن يكون حرفين على الأقل';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        ref.read(authStateProvider.notifier).clearError();
                      },
                    ),

                    const SizedBox(height: 14),

                    // Username field with @ prefix
                    TextFormField(
                      controller: _usernameController,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.alternate_email, color: AppTheme.secondaryText),
                        hintStyle: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال اسم المستخدم';
                        }
                        if (value.trim().length < 3) {
                          return 'اسم المستخدم يجب أن يكون ٣ أحرف على الأقل';
                        }
                        // Only allow alphanumeric and underscores
                        final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
                        if (!usernameRegex.hasMatch(value.trim())) {
                          return 'اسم المستخدم يجب أن يحتوي على أحرف إنجليزية وأرقام فقط';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        ref.read(authStateProvider.notifier).clearError();
                      },
                    ),

                    const SizedBox(height: 14),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.secondaryText),
                        hintStyle: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال البريد الإلكتروني';
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'صيغة البريد الإلكتروني غير صحيحة';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        ref.read(authStateProvider.notifier).clearError();
                      },
                    ),

                    const SizedBox(height: 14),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'كلمة المرور',
                        hintStyle: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 16,
                        ),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.secondaryText),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.secondaryText,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور يجب أن تكون ٦ أحرف على الأقل';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        ref.read(authStateProvider.notifier).clearError();
                      },
                    ),

                    const SizedBox(height: 14),

                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'تأكيد كلمة المرور',
                        hintStyle: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 16,
                        ),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.secondaryText),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.secondaryText,
                          ),
                          onPressed: () {
                            setState(() =>
                                _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى تأكيد كلمة المرور';
                        }
                        if (value != _passwordController.text) {
                          return 'كلمتا المرور غير متطابقتين';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        ref.read(authStateProvider.notifier).clearError();
                      },
                      onFieldSubmitted: (_) => _handleRegister(),
                    ),

                    const SizedBox(height: 24),

                    // Error message
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: AppTheme.likeRed,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Register button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentBlue,
                          disabledBackgroundColor: AppTheme.accentBlue.withOpacity(0.5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'إنشاء الحساب',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Login link
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'لديك حساب؟',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              'سجّل الدخول',
                              style: TextStyle(
                                color: AppTheme.accentBlue,
                                fontSize: 15,
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
            ),
          ),
        ),
      ),
    );
  }
}