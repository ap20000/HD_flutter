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
import 'package:hamro_doctor_mobile/features/consultation/presentation/pages/prescription_page.dart';

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

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _pickAndUploadImage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white24 : AppColors.textTertiary).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _processImage(context, ImageSource.gallery);
                },
              ),
              Divider(
                color: isDark ? AppColors.dividerDark : AppColors.divider,
                height: 1,
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.secondary.withOpacity(0.15) : AppColors.secondary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: isDark ? AppColors.darkAccent : AppColors.secondary,
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
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
        context.read<AuthBloc>().add(
          UpdateAvatarRequested(base64Image: base64Image),
        );
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

  void _showEditProfileModal(BuildContext context, User currentUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _EditProfileSheet(
          user: currentUser,
          authBloc: context.read<AuthBloc>(),
        );
      },
    );
  }

  Color _getBmiColor(double value) {
    if (value < 18.5) return AppColors.bmiUnderweight;
    if (value < 25.0) return AppColors.bmiHealthy;
    if (value < 30.0) return AppColors.bmiOverweight;
    return AppColors.bmiObese;
  }

  String _getBmiStatus(double value) {
    if (value < 18.5) return 'UNDERWEIGHT';
    if (value < 25.0) return 'HEALTHY';
    if (value < 30.0) return 'OVERWEIGHT';
    return 'OBESE';
  }

  Widget _buildAmbientGlows(BuildContext context, bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final secondaryColor = isDark ? AppColors.darkAccent : AppColors.secondary;
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(isDark ? 0.08 : 0.04),
            ),
          ),
        ),
        Positioned(
          top: 350,
          left: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: secondaryColor.withOpacity(isDark ? 0.06 : 0.03),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumCard({
    required Widget child,
    required Color cardColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
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
              content: Text('Profile updated successfully!'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      },
      builder: (context, state) {
        final User currentUser = state is AuthAuthenticated ? state.user : widget.user;
        final bool isDoctor = currentUser.role.toLowerCase() == 'doctor';
        final Uint8List? avatarBytes = _getAvatarBytes(currentUser.avatar);
        final bool isLoading = state is AuthLoading;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC);
        final cardColor = isDark ? AppColors.darkSurface : Colors.white;
        final textPrimaryColor = isDark ? AppColors.white : AppColors.textPrimary;
        final textSecondaryColor = isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary;
        final textTertiaryColor = isDark ? Colors.white38 : AppColors.textTertiary;
        final borderColor = isDark ? AppColors.dividerDark : const Color(0xFFEEF2F6);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textPrimaryColor,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
            actions: [
              _AnimatedInteractiveCard(
                scaleFactor: 0.90,
                onTap: () => _showEditProfileModal(context, currentUser),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: AppTypography.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              _buildAmbientGlows(context, isDark),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    _AnimatedEntrance(
                      animation: _entranceController,
                      delay: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                        child: Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: textPrimaryColor,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                      ),
                    ),

                    // Banner, Avatar, Name
                    _AnimatedEntrance(
                      animation: _entranceController,
                      delay: 1,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [AppColors.darkSurface, AppColors.darkBackground]
                                    : [const Color(0xFFE8F0FF), const Color(0xFFF1F5F9)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -45,
                            child: GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => _pickAndUploadImage(context),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _PulsingAvatarRing(
                                    child: Container(
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 46,
                                        backgroundColor: AppColors.primarySoft,
                                        backgroundImage: avatarBytes != null
                                            ? MemoryImage(avatarBytes)
                                            : null,
                                        child: avatarBytes == null
                                            ? Text(
                                                currentUser.name.trim().isNotEmpty
                                                    ? currentUser.name
                                                        .trim()[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                                  fontFamily: AppTypography.fontFamily,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (isLoading)
                                    Container(
                                      width: 100,
                                      height: 100,
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
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: cardColor,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 55),

                    // Name & ID
                    _AnimatedEntrance(
                      animation: _entranceController,
                      delay: 2,
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              isDoctor ? 'Dr. ${currentUser.name}' : currentUser.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: textPrimaryColor,
                                fontFamily: AppTypography.fontFamily,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primarySoft.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                isDoctor
                                    ? 'Doctor ID: #HD-${currentUser.id.length > 5 ? currentUser.id.substring(currentUser.id.length - 4).toUpperCase() : currentUser.id.toUpperCase()}'
                                    : 'Patient ID: #HD-${currentUser.id.length > 5 ? currentUser.id.substring(currentUser.id.length - 4).toUpperCase() : currentUser.id.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                  fontFamily: AppTypography.fontFamily,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Contact rows
                    _AnimatedEntrance(
                      animation: _entranceController,
                      delay: 3,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentUser.phone.isNotEmpty
                                    ? currentUser.phone
                                    : 'Not Provided',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondaryColor,
                                  fontFamily: AppTypography.fontFamily,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                color: Color(0xFF10B981),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentUser.email.isNotEmpty
                                    ? currentUser.email
                                    : 'Not Provided',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondaryColor,
                                  fontFamily: AppTypography.fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Account Details Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          _AnimatedEntrance(
                            animation: _entranceController,
                            delay: 4,
                            child: _buildPremiumCard(
                              cardColor: cardColor,
                              borderColor: borderColor,
                              isDark: isDark,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Details',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: textPrimaryColor,
                                      fontFamily: AppTypography.fontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDetailField(
                                          'FULL NAME',
                                          currentUser.name,
                                          textTertiaryColor,
                                          textPrimaryColor,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildDetailField(
                                          'ACCOUNT ROLE',
                                          currentUser.role.toUpperCase(),
                                          textTertiaryColor,
                                          textPrimaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDetailField(
                                          'GENDER',
                                          currentUser.gender ?? 'Not Provided',
                                          textTertiaryColor,
                                          textPrimaryColor,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildDetailField(
                                          'DATE OF BIRTH',
                                          currentUser.dob != null && currentUser.dob!.length >= 10
                                              ? currentUser.dob!.substring(0, 10)
                                              : (currentUser.dob ?? 'Not Provided'),
                                          textTertiaryColor,
                                          textPrimaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailField(
                                    'ADDRESS',
                                    currentUser.address ?? 'Not Provided',
                                    textTertiaryColor,
                                    textPrimaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Health Metrics Card (for Patient)
                          if (currentUser.role.toLowerCase() == 'patient' || currentUser.role.toLowerCase() == 'admin' || currentUser.role.toLowerCase() == 'nurse') ...[
                            const SizedBox(height: 20),
                            _AnimatedEntrance(
                              animation: _entranceController,
                              delay: 5,
                              child: _buildPremiumCard(
                                cardColor: cardColor,
                                borderColor: borderColor,
                                isDark: isDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Health Metrics (BMI)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: textPrimaryColor,
                                        fontFamily: AppTypography.fontFamily,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDetailField(
                                            'HEIGHT',
                                            currentUser.bmiHeight != null ? '${currentUser.bmiHeight!.toStringAsFixed(0)} cm' : 'Not Provided',
                                            textTertiaryColor,
                                            textPrimaryColor,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildDetailField(
                                            'WEIGHT',
                                            currentUser.bmiWeight != null ? '${currentUser.bmiWeight!.toStringAsFixed(1)} kg' : 'Not Provided',
                                            textTertiaryColor,
                                            textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (currentUser.bmiValue != null) ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'BMI VALUE',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: textTertiaryColor,
                                                    fontFamily: AppTypography.fontFamily,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      currentUser.bmiValue!.toStringAsFixed(1),
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w900,
                                                        color: _getBmiColor(currentUser.bmiValue!),
                                                        fontFamily: AppTypography.fontFamily,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: _getBmiColor(currentUser.bmiValue!).withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        _getBmiStatus(currentUser.bmiValue!),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: _getBmiColor(currentUser.bmiValue!),
                                                          fontFamily: AppTypography.fontFamily,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Professional Credentials Card (for Doctor)
                          if (isDoctor) ...[
                            const SizedBox(height: 20),
                            _AnimatedEntrance(
                              animation: _entranceController,
                              delay: 5,
                              child: _buildPremiumCard(
                                cardColor: cardColor,
                                borderColor: borderColor,
                                isDark: isDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Professional Credentials',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: textPrimaryColor,
                                        fontFamily: AppTypography.fontFamily,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDetailField(
                                            'SPECIALITY',
                                            currentUser.speciality != null && currentUser.speciality!.isNotEmpty
                                                ? currentUser.speciality!
                                                : 'Not Provided',
                                            textTertiaryColor,
                                            textPrimaryColor,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildDetailField(
                                            'NMC REGISTRATION NO.',
                                            currentUser.nmcNumber != null && currentUser.nmcNumber!.isNotEmpty
                                                ? currentUser.nmcNumber!
                                                : 'Not Provided',
                                            textTertiaryColor,
                                            textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDetailField(
                                            'QUALIFICATION',
                                            currentUser.qualification != null && currentUser.qualification!.isNotEmpty
                                                ? currentUser.qualification!
                                                : 'Not Provided',
                                            textTertiaryColor,
                                            textPrimaryColor,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildDetailField(
                                            'EXPERIENCE',
                                            currentUser.experience != null ? '${currentUser.experience} Years' : 'Not Provided',
                                            textTertiaryColor,
                                            textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (currentUser.bio != null && currentUser.bio!.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      _buildDetailField(
                                        'PROFESSIONAL BIO',
                                        currentUser.bio!,
                                        textTertiaryColor,
                                        textPrimaryColor,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Quick actions list items - ONLY keep real digital prescriptions!
                          _AnimatedEntrance(
                            animation: _entranceController,
                            delay: 6,
                            child: _buildQuickActionCard(
                              icon: Icons.favorite_border_rounded,
                              title: 'Digital Prescriptions',
                              subtitle: 'Access your official medical prescriptions.',
                              isDark: isDark,
                              cardColor: cardColor,
                              titleColor: textPrimaryColor,
                              subtitleColor: textTertiaryColor,
                              borderColor: borderColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PrescriptionPage(
                                      patientName: currentUser.name,
                                      isDoctor: isDoctor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Account Settings Card (Only real Log Out)
                          _AnimatedEntrance(
                            animation: _entranceController,
                            delay: 7,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: _buildLogoutRow(context, isDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Footer section
                          _AnimatedEntrance(
                            animation: _entranceController,
                            delay: 8,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurface : Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.local_hospital_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Hamro Doctor',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white38 : Colors.grey.shade600,
                                        fontFamily: AppTypography.fontFamily,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Version 1.0.0 (Beta)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white30 : Colors.grey.shade500,
                                    fontFamily: AppTypography.fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.error, size: 28),
              const SizedBox(width: 12),
              Text(
                'Log Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to securely log out of your Hamro Doctor account?',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(LogoutRequested());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
    required Color titleColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    return _AnimatedInteractiveCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary.withOpacity(0.15) : const Color(0xFFE8F0FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: subtitleColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutRow(BuildContext context, bool isDark) {
    return _AnimatedInteractiveCard(
      onTap: () => _showLogoutDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.error.withOpacity(0.15) : const Color(0xFFFFECEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Log out',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildDetailField(
  String label,
  String value,
  Color labelColor,
  Color valueColor, {
  bool isPlaceholder = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: labelColor,
          fontFamily: AppTypography.fontFamily,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isPlaceholder
              ? labelColor.withOpacity(0.7)
              : valueColor,
          fontFamily: AppTypography.fontFamily,
        ),
      ),
    ],
  );
}

// ── Edit Profile Form Sheet ──────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final User user;
  final AuthBloc authBloc;

  const _EditProfileSheet({required this.user, required this.authBloc});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  
  // Doctor details
  late TextEditingController _specialityController;
  late TextEditingController _qualificationController;
  late TextEditingController _nmcNumberController;
  late TextEditingController _experienceController;
  late TextEditingController _bioController;

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _addressController = TextEditingController(text: widget.user.address ?? '');
    
    String dobStr = '';
    if (widget.user.dob != null) {
      dobStr = widget.user.dob!.length >= 10 
          ? widget.user.dob!.substring(0, 10) 
          : widget.user.dob!;
    }
    _dobController = TextEditingController(text: dobStr);
    
    _heightController = TextEditingController(
      text: widget.user.bmiHeight != null ? widget.user.bmiHeight!.toStringAsFixed(0) : '',
    );
    _weightController = TextEditingController(
      text: widget.user.bmiWeight != null ? widget.user.bmiWeight!.toStringAsFixed(1) : '',
    );

    _selectedGender = widget.user.gender;
    if (_selectedGender == null || !['Male', 'Female', 'Other'].contains(_selectedGender)) {
      _selectedGender = 'Male';
    }

    _specialityController = TextEditingController(text: widget.user.speciality ?? '');
    _qualificationController = TextEditingController(text: widget.user.qualification ?? '');
    _nmcNumberController = TextEditingController(text: widget.user.nmcNumber ?? '');
    _experienceController = TextEditingController(
      text: widget.user.experience != null ? widget.user.experience!.toString() : '',
    );
    _bioController = TextEditingController(text: widget.user.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _specialityController.dispose();
    _qualificationController.dispose();
    _nmcNumberController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 25));
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dobController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.darkPrimary,
                    onPrimary: Colors.white,
                    surface: AppColors.darkSurface,
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.textPrimary,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDoctor = widget.user.role.toLowerCase() == 'doctor';
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    
    final labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white70 : AppColors.textPrimary,
      fontFamily: AppTypography.fontFamily,
    );

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: 24 + viewInsets,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white24 : AppColors.textTertiary).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Profile Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : AppColors.textTertiary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Basic details section
              Text(
                'Basic Info',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              // Full Name
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Email
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(val.trim())) return 'Invalid email address';
                  return null;
                },
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Row for Gender and DOB
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gender', style: labelStyle),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                            border: Border.all(
                              color: isDark ? AppColors.dividerDark : const Color(0xFFEEF2F6),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGender,
                              isExpanded: true,
                              dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedGender = newValue);
                                }
                              },
                              items: <String>['Male', 'Female', 'Other']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                      fontFamily: AppTypography.fontFamily,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date of Birth', style: labelStyle),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: _buildTextField(
                              controller: _dobController,
                              label: 'YYYY-MM-DD',
                              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // BMI section (If not doctor)
              if (!isDoctor) ...[
                Text(
                  'Health Metrics',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _heightController,
                        label: 'Height (cm)',
                        keyboardType: TextInputType.number,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Doctor specific section
              if (isDoctor) ...[
                Text(
                  'Professional Credentials',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _specialityController,
                  label: 'Speciality',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _qualificationController,
                        label: 'Qualification',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _experienceController,
                        label: 'Experience (Years)',
                        keyboardType: TextInputType.number,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nmcNumberController,
                  label: 'NMC Registration Number',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _bioController,
                  label: 'Professional Bio',
                  maxLines: 3,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
              ],

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      
                      final heightVal = double.tryParse(_heightController.text);
                      final weightVal = double.tryParse(_weightController.text);
                      final expVal = int.tryParse(_experienceController.text);

                      widget.authBloc.add(
                        UpdateProfileRequested(
                          name: _nameController.text.trim(),
                          email: _emailController.text.trim(),
                          gender: _selectedGender,
                          dob: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
                          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
                          bmiHeight: heightVal,
                          bmiWeight: weightVal,
                          speciality: isDoctor && _specialityController.text.trim().isNotEmpty ? _specialityController.text.trim() : null,
                          qualification: isDoctor && _qualificationController.text.trim().isNotEmpty ? _qualificationController.text.trim() : null,
                          nmcNumber: isDoctor && _nmcNumberController.text.trim().isNotEmpty ? _nmcNumberController.text.trim() : null,
                          experience: expVal,
                          bio: isDoctor && _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : AppColors.textPrimary,
            fontFamily: AppTypography.fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
            fontFamily: AppTypography.fontFamily,
          ),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.dividerDark : const Color(0xFFEEF2F6),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Staggered Entrance Animation Helper ───────────────────────────────────────

class _AnimatedEntrance extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final double delay;

  const _AnimatedEntrance({
    required this.child,
    required this.animation,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final start = delay * 0.12;
    final end = (delay * 0.12) + 0.45;
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: curvedAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1.0 - curvedAnimation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ── Interactive Spring Scaling Interaction Wrapper ───────────────────────────

class _AnimatedInteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;

  const _AnimatedInteractiveCard({
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.96,
  });

  @override
  State<_AnimatedInteractiveCard> createState() => _AnimatedInteractiveCardState();
}

class _AnimatedInteractiveCardState extends State<_AnimatedInteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// ── Pulsing Glow verified Border Ring ────────────────────────────────────────

class _PulsingAvatarRing extends StatefulWidget {
  final Widget child;
  const _PulsingAvatarRing({required this.child});

  @override
  State<_PulsingAvatarRing> createState() => _PulsingAvatarRingState();
}

class _PulsingAvatarRingState extends State<_PulsingAvatarRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final color = isDark ? AppColors.darkPrimary : AppColors.primary;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100 + (16 * _pulseAnimation.value),
              height: 100 + (16 * _pulseAnimation.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(1.0 - _pulseAnimation.value),
                  width: 2.0,
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
