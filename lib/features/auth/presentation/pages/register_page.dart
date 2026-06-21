import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

// ── Field identifiers ────────────────────────────────────────────────────────

enum _Field { name, email, phone, password }

// ── Page ─────────────────────────────────────────────────────────────────────

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus nodes
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // Focus state
  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _phoneFocused = false;
  bool _passwordFocused = false;

  // Errors
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;

  // Dirty flags – only validate after first blur
  final Set<_Field> _dirty = {};

  // UI state
  bool _isPasswordVisible = false;
  bool _passwordStrengthVisible = false;
  String _selectedRole = 'patient';
  double _buttonScale = 1.0;

  // Password strength (0–4)
  int _passwordStrength = 0;

  // Animations
  late AnimationController _entranceCtrl;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;
  late Animation<double> _footerOpacity;

  final GlobalKey<_ShakeWidgetState> _shakeKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
          ),
        );
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.3, 0.78, curve: Curves.easeOutCubic),
          ),
        );
    _footerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _setupFocusListeners();
    _passwordController.addListener(_updatePasswordStrength);
    _entranceCtrl.forward();
  }

  void _setupFocusListeners() {
    void listen(
      FocusNode node,
      _Field field,
      VoidCallback setFocused,
      VoidCallback clearFocused,
    ) {
      node.addListener(() {
        if (node.hasFocus) {
          setFocused();
        } else {
          clearFocused();
          if (_dirty.contains(field)) _validateField(field);
        }
      });
    }

    listen(
      _nameFocus,
      _Field.name,
      () => setState(() => _nameFocused = true),
      () => setState(() => _nameFocused = false),
    );
    listen(
      _emailFocus,
      _Field.email,
      () => setState(() => _emailFocused = true),
      () => setState(() => _emailFocused = false),
    );
    listen(
      _phoneFocus,
      _Field.phone,
      () => setState(() => _phoneFocused = true),
      () => setState(() => _phoneFocused = false),
    );
    listen(
      _passwordFocus,
      _Field.password,
      () => setState(() {
        _passwordFocused = true;
        _passwordStrengthVisible = true;
      }),
      () => setState(() {
        _passwordFocused = false;
        _passwordStrengthVisible = _passwordController.text.isNotEmpty;
      }),
    );
  }

  void _updatePasswordStrength() {
    final p = _passwordController.text;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) score++;
    setState(() => _passwordStrength = score);
    if (_dirty.contains(_Field.password) && _passwordError != null) {
      _validateField(_Field.password);
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  void _validateField(_Field field) {
    setState(() {
      switch (field) {
        case _Field.name:
          _nameError = null;
        case _Field.email:
          final v = _emailController.text.trim();
          if (v.isEmpty) {
            _emailError = 'Enter your email address';
          } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
            _emailError = 'Not a valid email address';
          } else {
            _emailError = null;
          }
        case _Field.phone:
          final v = _phoneController.text.trim();
          if (v.isEmpty) {
            _phoneError = 'Enter your phone number';
          } else if (!RegExp(r'^[0-9]{10,}$').hasMatch(v)) {
            _phoneError = 'Enter at least 10 digits';
          } else {
            _phoneError = null;
          }
        case _Field.password:
          final v = _passwordController.text;
          if (v.isEmpty) {
            _passwordError = 'Choose a password';
          } else if (v.length < 6) {
            _passwordError = 'At least 6 characters required';
          } else {
            _passwordError = null;
          }
      }
    });
  }

  bool _validateAll() {
    for (final f in _Field.values) {
      _dirty.add(f);
      _validateField(f);
    }
    return _nameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  void _submit(BuildContext context) {
    setState(() => _dirty.addAll(_Field.values));
    if (_validateAll()) {
      HapticFeedback.lightImpact();
      context.read<AuthBloc>().add(
        RegisterSubmitted(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
        ),
      );
    } else {
      HapticFeedback.mediumImpact();
      _shakeKey.currentState?.shake();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.surfacePearl,
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthOtpSent) {
              context.go('/otp', extra: state.phone);
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                ),
              );
              _shakeKey.currentState?.shake();
            }
          },
          child: Stack(
            children: [
              // Ambient blobs
              _AmbientBlob(
                color: isDark
                    ? AppColors.darkPrimary.withOpacity(0.10)
                    : const Color(0xFFDCEEFB),
                size: 360,
                begin: const Offset(-100, -40),
                end: const Offset(-40, 120),
                duration: const Duration(seconds: 16),
              ),
              _AmbientBlob(
                color: isDark
                    ? const Color(0xFF0A3A5C).withOpacity(0.10)
                    : const Color(0xFFE3F2FD),
                size: 300,
                begin: Offset(
                  MediaQuery.of(context).size.width - 140,
                  MediaQuery.of(context).size.height * 0.35,
                ),
                end: Offset(
                  MediaQuery.of(context).size.width - 190,
                  MediaQuery.of(context).size.height * 0.5,
                ),
                duration: const Duration(seconds: 20),
              ),
              _AmbientBlob(
                color: isDark
                    ? AppColors.darkAccent.withOpacity(0.06)
                    : const Color(0xFFE8F5E9),
                size: 220,
                begin: Offset(40, MediaQuery.of(context).size.height * 0.68),
                end: Offset(10, MediaQuery.of(context).size.height * 0.78),
                duration: const Duration(seconds: 14),
              ),

              // Global backdrop blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: const SizedBox.expand(),
                ),
              ),

              // Scrollable content
              SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.07)
                                  : Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.07),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: isDark
                                  ? Colors.white.withOpacity(0.8)
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Header
                        FadeTransition(
                          opacity: _titleOpacity,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create your account',
                                  style: AppTypography.display.copyWith(
                                    fontSize: 28,
                                    height: 1.2,
                                    letterSpacing: -0.4,
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Join thousands managing their health with us',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isDark
                                        ? AppColors.textOnDarkSecondary
                                        : AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form card
                        FadeTransition(
                          opacity: _cardOpacity,
                          child: SlideTransition(
                            position: _cardSlide,
                            child: _ShakeWidget(
                              key: _shakeKey,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 20,
                                    sigmaY: 20,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      24,
                                      20,
                                      24,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurface.withOpacity(
                                              0.55,
                                            )
                                          : Colors.white.withOpacity(0.72),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.07)
                                            : Colors.white.withOpacity(0.5),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (isDark
                                                      ? Colors.black
                                                      : AppColors.primary)
                                                  .withOpacity(
                                                    isDark ? 0.25 : 0.06,
                                                  ),
                                          blurRadius: 32,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: AutofillGroup(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Full name
                                          _RegField(
                                            isDark: isDark,
                                            controller: _nameController,
                                            focusNode: _nameFocus,
                                            label: 'Full name',
                                            icon: Icons.person_outline_rounded,
                                            keyboardType: TextInputType.name,
                                            textInputAction:
                                                TextInputAction.next,
                                            autofillHints: const [
                                              AutofillHints.name,
                                            ],
                                            isFocused: _nameFocused,
                                            errorText: _nameError,
                                            onChanged: (v) {
                                              _dirty.add(_Field.name);
                                              if (_nameError != null)
                                                _validateField(_Field.name);
                                            },
                                            onSubmitted: (_) =>
                                                _emailFocus.requestFocus(),
                                          ),
                                          const SizedBox(height: 14),

                                          // Email
                                          _RegField(
                                            isDark: isDark,
                                            controller: _emailController,
                                            focusNode: _emailFocus,
                                            label: 'Email address',
                                            icon: Icons.mail_outline_rounded,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            textInputAction:
                                                TextInputAction.next,
                                            autofillHints: const [
                                              AutofillHints.email,
                                            ],
                                            isFocused: _emailFocused,
                                            errorText: _emailError,
                                            onChanged: (v) {
                                              _dirty.add(_Field.email);
                                              if (_emailError != null)
                                                _validateField(_Field.email);
                                            },
                                            onSubmitted: (_) =>
                                                _phoneFocus.requestFocus(),
                                          ),
                                          const SizedBox(height: 14),

                                          // Phone
                                          _RegField(
                                            isDark: isDark,
                                            controller: _phoneController,
                                            focusNode: _phoneFocus,
                                            label: 'Phone number',
                                            icon: Icons.phone_iphone_rounded,
                                            keyboardType: TextInputType.phone,
                                            textInputAction:
                                                TextInputAction.next,
                                            autofillHints: const [
                                              AutofillHints.telephoneNumber,
                                            ],
                                            isFocused: _phoneFocused,
                                            errorText: _phoneError,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                15,
                                              ),
                                            ],
                                            onChanged: (v) {
                                              _dirty.add(_Field.phone);
                                              if (_phoneError != null)
                                                _validateField(_Field.phone);
                                            },
                                            onSubmitted: (_) =>
                                                _passwordFocus.requestFocus(),
                                          ),
                                          const SizedBox(height: 14),

                                          // Password
                                          _RegField(
                                            isDark: isDark,
                                            controller: _passwordController,
                                            focusNode: _passwordFocus,
                                            label: 'Password',
                                            icon: Icons.lock_outline_rounded,
                                            isPassword: true,
                                            obscureText: !_isPasswordVisible,
                                            keyboardType:
                                                TextInputType.visiblePassword,
                                            textInputAction:
                                                TextInputAction.done,
                                            autofillHints: const [
                                              AutofillHints.newPassword,
                                            ],
                                            isFocused: _passwordFocused,
                                            errorText: _passwordError,
                                            onChanged: (v) {
                                              _dirty.add(_Field.password);
                                            },
                                            onSubmitted: (_) =>
                                                _submit(context),
                                            onVisibilityToggle: () => setState(
                                              () => _isPasswordVisible =
                                                  !_isPasswordVisible,
                                            ),
                                          ),

                                          // Password strength meter
                                          AnimatedSize(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            curve: Curves.easeOut,
                                            child: _passwordStrengthVisible
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 10,
                                                        ),
                                                    child:
                                                        _PasswordStrengthMeter(
                                                          isDark: isDark,
                                                          strength:
                                                              _passwordStrength,
                                                        ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),

                                          const SizedBox(height: 24),

                                          // Role selection
                                          Text(
                                            'I am registering as',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors
                                                        .textOnDarkSecondary
                                                  : AppColors.textSecondary,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              _RoleChip(
                                                label: 'Patient',
                                                icon: Icons
                                                    .person_outline_rounded,
                                                description:
                                                    'Book appointments & view records',
                                                isSelected:
                                                    _selectedRole == 'patient',
                                                isDark: isDark,
                                                onTap: () => setState(
                                                  () =>
                                                      _selectedRole = 'patient',
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              _RoleChip(
                                                label: 'Doctor',
                                                icon: Icons
                                                    .medical_services_outlined,
                                                description:
                                                    'Manage patients & schedules',
                                                isSelected:
                                                    _selectedRole == 'doctor',
                                                isDark: isDark,
                                                onTap: () => setState(
                                                  () =>
                                                      _selectedRole = 'doctor',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 28),

                                          // Register button
                                          BlocBuilder<AuthBloc, AuthState>(
                                            builder: (context, state) {
                                              final isLoading =
                                                  state is AuthLoading;
                                              return _RegisterButton(
                                                isDark: isDark,
                                                isLoading: isLoading,
                                                scale: _buttonScale,
                                                onTapDown: isLoading
                                                    ? null
                                                    : () => setState(
                                                        () =>
                                                            _buttonScale = 0.97,
                                                      ),
                                                onTapUp: isLoading
                                                    ? null
                                                    : () => setState(
                                                        () =>
                                                            _buttonScale = 1.0,
                                                      ),
                                                onTap: isLoading
                                                    ? null
                                                    : () => _submit(context),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Footer
                        FadeTransition(
                          opacity: _footerOpacity,
                          child: _Footer(isDark: isDark),
                        ),
                        const SizedBox(height: 24),
                      ],
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
}

// ── Field widget ─────────────────────────────────────────────────────────────

class _RegField extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<String> autofillHints;
  final bool isFocused;
  final String? errorText;
  final bool isPassword;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onVisibilityToggle;

  const _RegField({
    required this.isDark,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    required this.keyboardType,
    required this.textInputAction,
    required this.autofillHints,
    required this.isFocused,
    this.errorText,
    this.isPassword = false,
    this.obscureText = false,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onVisibilityToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    final borderColor = hasError
        ? AppColors.error.withOpacity(0.65)
        : isFocused
        ? primary
        : (isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.black.withOpacity(0.09));

    final bgColor = isFocused
        ? (isDark ? AppColors.darkBackground : Colors.white)
        : (isDark
              ? AppColors.darkBackground.withOpacity(0.35)
              : Colors.grey.withOpacity(0.04));

    final hasContent = controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floating label
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: (hasContent || isFocused)
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 5, left: 2),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: hasError
                          ? AppColors.error
                          : isFocused
                          ? primary
                          : (isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textSecondary),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isFocused ? 1.5 : 1.0,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            focusNode: focusNode,
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            maxLines: 1,
            enableSuggestions: !isPassword,
            autocorrect: !isPassword,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textOnDarkPrimary
                  : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: (!hasContent && !isFocused) ? label : null,
              hintStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.textOnDarkSecondary.withOpacity(0.4)
                    : AppColors.textTertiary,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  icon,
                  size: 20,
                  color: hasError
                      ? AppColors.error.withOpacity(0.7)
                      : isFocused
                      ? primary
                      : (isDark
                            ? AppColors.textOnDarkSecondary.withOpacity(0.35)
                            : Colors.black.withOpacity(0.28)),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 0,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: isFocused
                            ? primary
                            : (isDark
                                  ? AppColors.textOnDarkSecondary.withOpacity(
                                      0.4,
                                    )
                                  : Colors.black.withOpacity(0.28)),
                      ),
                      splashRadius: 20,
                      onPressed: onVisibilityToggle,
                    )
                  : (hasError
                        ? Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                          )
                        : null),
              border: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 16,
              ),
            ),
          ),
        ),

        // Error text with animated height
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Password strength meter ───────────────────────────────────────────────────

class _PasswordStrengthMeter extends StatelessWidget {
  final bool isDark;
  final int strength; // 0–4

  const _PasswordStrengthMeter({required this.isDark, required this.strength});

  static const _labels = ['Too weak', 'Weak', 'Fair', 'Good', 'Strong'];
  static const _colors = [
    Color(0xFFE53935),
    Color(0xFFEF6C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF00897B),
  ];

  @override
  Widget build(BuildContext context) {
    final label = _labels[strength.clamp(0, 4)];
    final color = _colors[strength.clamp(0, 4)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = i < strength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: filled
                      ? color
                      : (isDark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '· Use 8+ chars, uppercase, numbers & symbols',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textOnDarkSecondary.withOpacity(0.5)
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Role chip ─────────────────────────────────────────────────────────────────

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppColors.darkPrimary.withOpacity(0.13)
                      : AppColors.primary.withOpacity(0.06))
                : (isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.white.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? primary
                  : (isDark
                        ? Colors.white.withOpacity(0.09)
                        : Colors.black.withOpacity(0.08)),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isSelected
                          ? primary
                          : (isDark
                                ? AppColors.textOnDarkSecondary.withOpacity(
                                    0.45,
                                  )
                                : Colors.black.withOpacity(0.35)),
                    ),
                  ),
                  const Spacer(),
                  // Radio dot
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? primary
                            : (isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.18)),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? primary
                      : (isDark
                            ? AppColors.textOnDarkPrimary
                            : AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.4,
                  color: isDark
                      ? AppColors.textOnDarkSecondary.withOpacity(0.55)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Register button ───────────────────────────────────────────────────────────

class _RegisterButton extends StatelessWidget {
  final bool isDark;
  final bool isLoading;
  final double scale;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  const _RegisterButton({
    required this.isDark,
    required this.isLoading,
    required this.scale,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onTapDown != null ? (_) => onTapDown!() : null,
      onTapUp: onTapUp != null ? (_) => onTapUp!() : null,
      onTapCancel: onTapUp,
      onTap: onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? AppColors.darkPrimary : AppColors.primary,
                isDark ? AppColors.darkAccent : const Color(0xFF2563EB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                    .withOpacity(isLoading ? 0.12 : 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final bool isDark;

  const _Footer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account?',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Text(
                'Sign in',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 12,
              color: isDark
                  ? AppColors.textOnDarkSecondary.withOpacity(0.4)
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: 5),
            Text(
              'Your data is encrypted and never sold',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.textOnDarkSecondary.withOpacity(0.45)
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Shake widget ─────────────────────────────────────────────────────────────

class _ShakeWidget extends StatefulWidget {
  final Widget child;

  const _ShakeWidget({super.key, required this.child});

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _ctrl.reset();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void shake() => _ctrl.forward(from: 0.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final offset = _ctrl.value == 0
            ? 0.0
            : math.sin(_ctrl.value * 3.5 * 2 * math.pi) *
                  7 *
                  (1.0 - _ctrl.value);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}

// ── Ambient blob ──────────────────────────────────────────────────────────────

class _AmbientBlob extends StatefulWidget {
  final Color color;
  final double size;
  final Offset begin;
  final Offset end;
  final Duration duration;

  const _AmbientBlob({
    required this.color,
    required this.size,
    required this.begin,
    required this.end,
    required this.duration,
  });

  @override
  State<_AmbientBlob> createState() => _AmbientBlobState();
}

class _AmbientBlobState extends State<_AmbientBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<Offset>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        left: _anim.value.dx,
        top: _anim.value.dy,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
