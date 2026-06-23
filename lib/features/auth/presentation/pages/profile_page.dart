import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';

Uint8List? _getAvatarBytes(String? base64Str) {
  if (base64Str == null || base64Str.isEmpty) return null;
  try {
    String cleaned = base64Str;
    if (base64Str.contains(',')) {
      cleaned = base64Str.split(',').last;
    }
    return base64Decode(cleaned);
  } catch (e) {
    return null;
  }
}

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  void _pickAndUploadImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _processImage(context, ImageSource.gallery);
                },
              ),
              const Divider(color: AppColors.divider, height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.secondary),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _processImage(context, ImageSource.camera);
                },
              ),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImage(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (context.mounted) {
        context.read<AuthBloc>().add(UpdateAvatarRequested(base64Image: base64Image));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      },
      builder: (context, state) {
        final User currentUser = state is AuthAuthenticated ? state.user : user;
        final bool isDoctor = currentUser.role.toLowerCase() == 'doctor';
        final Uint8List? avatarBytes = _getAvatarBytes(currentUser.avatar);
        final bool isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // 1. Premium User Card Header
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: isLoading ? null : () => _pickAndUploadImage(context),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 38,
                                backgroundColor: AppColors.primarySoft,
                                backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes) : null,
                                child: avatarBytes == null
                                    ? Text(
                                        currentUser.name.trim().isNotEmpty
                                            ? currentUser.name.trim()[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              if (isLoading)
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              if (!isLoading)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      isDoctor ? 'Dr. ${currentUser.name}' : currentUser.name,
                                      style: AppTypography.h1.copyWith(
                                        fontSize: 22,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isDoctor) ...[
                                    const SizedBox(width: 6),
                                    const VerifiedBadge(size: 20),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              StatusBadge(
                                text: currentUser.role,
                                color: isDoctor ? AppColors.primary : AppColors.secondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Personal Information Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text('PERSONAL INFORMATION', style: AppTypography.labelLarge),
                    ),
                  ),

                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.phone_android_rounded,
                          label: 'Phone Number',
                          value: currentUser.phone,
                        ),
                        const Divider(color: AppColors.divider, height: 1),
                        _InfoRow(
                          icon: Icons.alternate_email_rounded,
                          label: 'Email Address',
                          value: currentUser.email,
                        ),
                        const Divider(color: AppColors.divider, height: 1),
                        _InfoRow(
                          icon: Icons.fingerprint_rounded,
                          label: 'Account ID',
                          value: currentUser.id.length > 10 ? '${currentUser.id.substring(0, 10)}...' : currentUser.id,
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Settings & Options Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text('APP CONFIGURATION', style: AppTypography.labelLarge),
                ),
              ),

              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.notifications_active_outlined,
                      color: AppColors.primary,
                      title: 'Notification Settings',
                      subtitle: 'Alerts, sound & vibrates',
                      onTap: () {},
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _SettingTile(
                      icon: Icons.g_translate_outlined,
                      color: AppColors.secondary,
                      title: 'App Language',
                      subtitle: 'English / Nepali',
                      onTap: () {},
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _SettingTile(
                      icon: Icons.shield_outlined,
                      color: AppColors.reportCard,
                      title: 'Privacy Policy',
                      subtitle: 'How we guard your health data',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // 4. Premium Logout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: const Text(
                    'Log Out Securely',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 28),
              SizedBox(width: 12),
              Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to securely log out of your Hamro Doctor account?',
            style: TextStyle(fontSize: 15),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog first

                // 1. Dispatch LogoutRequested to auth bloc
                context.read<AuthBloc>().add(LogoutRequested());

                // 2. Safely wipe all history and transition to LoginPage
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = value == null || value!.trim().isEmpty;
    final String displayValue = isEmpty ? 'Not Provided' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 22),
          const SizedBox(width: 16),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            displayValue,
            style: AppTypography.titleMedium.copyWith(
              color: isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
              fontWeight: isEmpty ? FontWeight.normal : FontWeight.bold,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
