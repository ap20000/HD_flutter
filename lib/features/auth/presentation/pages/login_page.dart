import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _loginIdFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  double _buttonScale = 1.0;
  bool _loginIdFocused = false;
  bool _passwordFocused = false;
  String? _loginIdError;
  String? _passwordError;
  // Tracks whether the user has interacted (for deferred validation)
  bool _loginIdDirty = false;
  bool _passwordDirty = false;

  late AnimationController _entranceController;
  late AnimationController _pulseController;

  // Staggered entrance animations
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _headingOpacity;
  late Animation<Offset> _headingSlide;
  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;
  late Animation<double> _footerOpacity;

  // Ambient pulse for the logo glow
  late Animation<double> _logoPulse;

  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );
    _logoPulse = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);

    _headingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );
    _headingSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0.0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.45, 0.82, curve: Curves.easeOutCubic),
          ),
        );

    _footerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _loginIdFocusNode.addListener(() {
      setState(() => _loginIdFocused = _loginIdFocusNode.hasFocus);
      if (!_loginIdFocusNode.hasFocus && _loginIdDirty) {
        _validateField(FieldType.loginId);
      }
    });
    _passwordFocusNode.addListener(() {
      setState(() => _passwordFocused = _passwordFocusNode.hasFocus);
      if (!_passwordFocusNode.hasFocus && _passwordDirty) {
        _validateField(FieldType.password);
      }
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _loginIdController.dispose();
    _passwordController.dispose();
    _loginIdFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _validateField(FieldType field) {
    if (field == FieldType.loginId) {
      final v = _loginIdController.text.trim();
      setState(() {
        if (v.isEmpty) {
          _loginIdError = 'Enter your email or phone number';
        } else if (!_isValidEmailOrPhone(v)) {
          _loginIdError = 'Not a valid email or phone number';
        } else {
          _loginIdError = null;
        }
      });
    } else {
      final v = _passwordController.text;
      setState(() {
        if (v.isEmpty) {
          _passwordError = 'Enter your password';
        } else if (v.length < 6) {
          _passwordError = 'Password must be at least 6 characters';
        } else {
          _passwordError = null;
        }
      });
    }
  }

  bool _validateAll() {
    _validateField(FieldType.loginId);
    _validateField(FieldType.password);
    return _loginIdError == null && _passwordError == null;
  }

  void _submitLogin(BuildContext context) {
    setState(() {
      _loginIdDirty = true;
      _passwordDirty = true;
    });
    if (_validateAll()) {
      HapticFeedback.lightImpact();
      context.read<AuthBloc>().add(
        LoginSubmitted(
          loginId: _loginIdController.text.trim(),
          password: _passwordController.text,
        ),
      );
    } else {
      HapticFeedback.mediumImpact();
      _shakeKey.currentState?.shake();
    }
  }

  bool _isValidEmailOrPhone(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    final phoneRegex = RegExp(r'^[0-9]{10,}$');
    return emailRegex.hasMatch(value) || phoneRegex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.surfacePearl,
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              if (state.user.role == 'patient') {
                context.go('/patient-dashboard', extra: state.user);
              } else if (state.user.role == 'doctor') {
                context.go('/doctor-dashboard', extra: state.user);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Welcome, ${state.user.name}'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
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
            } else if (state is AuthOtpSent) {
              context.go('/otp', extra: state.phone);
            }
          },
          child: Stack(
            children: [
              // Ambient background blobs – calmer, more medical
              _AmbientBlob(
                color: isDark
                    ? AppColors.darkPrimary.withOpacity(0.10)
                    : const Color(0xFFDCEEFB),
                size: 380,
                beginOffset: const Offset(-90, -60),
                endOffset: const Offset(-50, 100),
                duration: const Duration(seconds: 16),
              ),
              _AmbientBlob(
                color: isDark
                    ? const Color(0xFF0A3A5C).withOpacity(0.12)
                    : const Color(0xFFE3F2FD),
                size: 300,
                beginOffset: Offset(
                  MediaQuery.of(context).size.width - 160,
                  screenHeight * 0.3,
                ),
                endOffset: Offset(
                  MediaQuery.of(context).size.width - 200,
                  screenHeight * 0.5,
                ),
                duration: const Duration(seconds: 20),
              ),
              _AmbientBlob(
                color: isDark
                    ? AppColors.darkAccent.withOpacity(0.07)
                    : const Color(0xFFE8F5E9),
                size: 240,
                beginOffset: Offset(60, screenHeight * 0.65),
                endOffset: Offset(20, screenHeight * 0.75),
                duration: const Duration(seconds: 13),
              ),

              // Unified backdrop blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: const SizedBox.expand(),
                ),
              ),

              // Scrollable body
              SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Logo ──────────────────────────────────────
                        Center(
                          child: FadeTransition(
                            opacity: _logoOpacity,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: _LogoBadge(
                                isDark: isDark,
                                pulseAnimation: _logoPulse,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Heading ───────────────────────────────────
                        FadeTransition(
                          opacity: _headingOpacity,
                          child: SlideTransition(
                            position: _headingSlide,
                            child: _Heading(isDark: isDark),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Form card ─────────────────────────────────
                        FadeTransition(
                          opacity: _cardOpacity,
                          child: SlideTransition(
                            position: _cardSlide,
                            child: ShakeWidget(
                              key: _shakeKey,
                              child: _FormCard(
                                isDark: isDark,
                                loginIdController: _loginIdController,
                                passwordController: _passwordController,
                                loginIdFocusNode: _loginIdFocusNode,
                                passwordFocusNode: _passwordFocusNode,
                                loginIdFocused: _loginIdFocused,
                                passwordFocused: _passwordFocused,
                                loginIdError: _loginIdError,
                                passwordError: _passwordError,
                                isPasswordVisible: _isPasswordVisible,
                                rememberMe: _rememberMe,
                                buttonScale: _buttonScale,
                                onLoginIdChanged: (v) {
                                  _loginIdDirty = true;
                                  if (_loginIdError != null) {
                                    _validateField(FieldType.loginId);
                                  }
                                },
                                onPasswordChanged: (v) {
                                  _passwordDirty = true;
                                  if (_passwordError != null) {
                                    _validateField(FieldType.password);
                                  }
                                },
                                onPasswordNext: () =>
                                    _passwordFocusNode.requestFocus(),
                                onSubmit: () => _submitLogin(context),
                                onTogglePassword: () => setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                ),
                                onToggleRemember: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                onForgotPassword: () =>
                                    context.push('/forgot-password'),
                                onScaleDown: () =>
                                    setState(() => _buttonScale = 0.97),
                                onScaleUp: () =>
                                    setState(() => _buttonScale = 1.0),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Footer (social + register) ────────────────
                        FadeTransition(
                          opacity: _footerOpacity,
                          child: _Footer(
                            isDark: isDark,
                            onRegister: () => context.push('/register'),
                          ),
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

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  final bool isDark;
  final Animation<double> pulseAnimation;

  const _LogoBadge({required this.isDark, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final glowOpacity = 0.04 + (pulseAnimation.value * 0.06);
        return Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkSurface : Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(glowOpacity),
                blurRadius: 32 + (pulseAnimation.value * 16),
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Image.asset('assets/images/newlogo.png', fit: BoxFit.contain),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final bool isDark;

  const _Heading({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good to see you',
          style: AppTypography.display.copyWith(
            fontSize: 30,
            height: 1.15,
            letterSpacing: -0.5,
            color: isDark ? AppColors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to access your health records and appointments',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final bool isDark;
  final TextEditingController loginIdController;
  final TextEditingController passwordController;
  final FocusNode loginIdFocusNode;
  final FocusNode passwordFocusNode;
  final bool loginIdFocused;
  final bool passwordFocused;
  final String? loginIdError;
  final String? passwordError;
  final bool isPasswordVisible;
  final bool rememberMe;
  final double buttonScale;

  final ValueChanged<String> onLoginIdChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onPasswordNext;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleRemember;
  final VoidCallback onForgotPassword;
  final VoidCallback onScaleDown;
  final VoidCallback onScaleUp;

  const _FormCard({
    required this.isDark,
    required this.loginIdController,
    required this.passwordController,
    required this.loginIdFocusNode,
    required this.passwordFocusNode,
    required this.loginIdFocused,
    required this.passwordFocused,
    required this.loginIdError,
    required this.passwordError,
    required this.isPasswordVisible,
    required this.rememberMe,
    required this.buttonScale,
    required this.onLoginIdChanged,
    required this.onPasswordChanged,
    required this.onPasswordNext,
    required this.onSubmit,
    required this.onTogglePassword,
    required this.onToggleRemember,
    required this.onForgotPassword,
    required this.onScaleDown,
    required this.onScaleUp,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withOpacity(0.55)
                : Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.primary).withOpacity(
                  isDark ? 0.25 : 0.06,
                ),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Email / phone field
              _HealthField(
                isDark: isDark,
                controller: loginIdController,
                focusNode: loginIdFocusNode,
                label: 'Email or phone number',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: loginIdError,
                isFocused: loginIdFocused,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                onChanged: onLoginIdChanged,
                onSubmitted: (_) => onPasswordNext(),
              ),
              const SizedBox(height: 16),

              // Password field
              _HealthField(
                isDark: isDark,
                controller: passwordController,
                focusNode: passwordFocusNode,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                obscureText: !isPasswordVisible,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                errorText: passwordError,
                isFocused: passwordFocused,
                autofillHints: const [AutofillHints.password],
                onChanged: onPasswordChanged,
                onSubmitted: (_) => onSubmit(),
                onVisibilityToggle: onTogglePassword,
              ),
              const SizedBox(height: 16),

              // Remember me + Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RememberMeToggle(
                    isDark: isDark,
                    value: rememberMe,
                    onTap: onToggleRemember,
                  ),
                  TextButton(
                    onPressed: onForgotPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Sign in button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return _SignInButton(
                    isDark: isDark,
                    isLoading: isLoading,
                    scale: buttonScale,
                    onTapDown: isLoading ? null : onScaleDown,
                    onTapUp: isLoading ? null : onScaleUp,
                    onTapCancel: isLoading ? null : onScaleUp,
                    onTap: isLoading ? null : onSubmit,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthField extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? errorText;
  final bool isFocused;
  final bool isPassword;
  final bool obscureText;
  final List<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onVisibilityToggle;

  const _HealthField({
    required this.isDark,
    required this.controller,
    required this.label,
    required this.icon,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.isFocused = false,
    this.isPassword = false,
    this.obscureText = false,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onVisibilityToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    final borderColor = hasError
        ? AppColors.error.withOpacity(0.7)
        : isFocused
        ? primaryColor
        : (isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.black.withOpacity(0.09));

    final bgColor = isFocused
        ? (isDark ? AppColors.darkBackground : Colors.white)
        : (isDark
              ? AppColors.darkBackground.withOpacity(0.35)
              : Colors.grey.withOpacity(0.04));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label above
        if (controller.text.isNotEmpty || isFocused)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: (controller.text.isNotEmpty || isFocused) ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 2),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: hasError
                      ? AppColors.error
                      : isFocused
                      ? primaryColor
                      : (isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary),
                ),
              ),
            ),
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
                      color: primaryColor.withOpacity(0.10),
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
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? AppColors.textOnDarkPrimary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: (controller.text.isEmpty && !isFocused) ? label : null,
              hintStyle: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.textOnDarkSecondary.withOpacity(0.4)
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  icon,
                  size: 20,
                  color: hasError
                      ? AppColors.error.withOpacity(0.7)
                      : isFocused
                      ? primaryColor
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
                            ? primaryColor
                            : (isDark
                                  ? AppColors.textOnDarkSecondary.withOpacity(
                                      0.4,
                                    )
                                  : Colors.black.withOpacity(0.28)),
                      ),
                      onPressed: onVisibilityToggle,
                      splashRadius: 20,
                    )
                  : (hasError
                        ? const Padding(
                            padding: EdgeInsets.only(right: 14),
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
              isDense: false,
            ),
          ),
        ),

        // Error message
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

class _RememberMeToggle extends StatelessWidget {
  final bool isDark;
  final bool value;
  final VoidCallback onTap;

  const _RememberMeToggle({
    required this.isDark,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: value
                      ? primary
                      : (isDark
                            ? Colors.white.withOpacity(0.22)
                            : Colors.black.withOpacity(0.18)),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 13),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              'Stay signed in',
              style: TextStyle(
                fontSize: 13.5,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final bool isDark;
  final bool isLoading;
  final double scale;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final VoidCallback? onTapCancel;

  const _SignInButton({
    required this.isDark,
    required this.isLoading,
    required this.scale,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onTapDown != null ? (_) => onTapDown!() : null,
      onTapUp: onTapUp != null ? (_) => onTapUp!() : null,
      onTapCancel: onTapCancel,
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
                    'Sign in',
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

class _Footer extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRegister;

  const _Footer({required this.isDark, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.10),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'or continue with',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? AppColors.textOnDarkSecondary.withOpacity(0.55)
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.10),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Social buttons
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                isDark: isDark,
                label: 'Google',
                iconWidget: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                isDark: isDark,
                label: 'Apple',
                iconWidget: Icon(
                  Icons.apple,
                  size: 20,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Register prompt
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "New to the app?",
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRegister,
              child: Text(
                'Create an account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final bool isDark;
  final Widget iconWidget;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.isDark,
    required this.iconWidget,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withOpacity(0.45)
              : Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shake animation ──────────────────────────────────────────────────────────

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double shakeCount;
  final double shakeOffset;

  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 460),
    this.shakeCount = 3.5,
    this.shakeOffset = 7,
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() => _controller.forward(from: 0.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final t = _controller.value;
        final offset = t == 0.0
            ? 0.0
            : math.sin(t * widget.shakeCount * 2 * math.pi) *
                  widget.shakeOffset *
                  (1.0 - t); // Decaying shake
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}

// ── Ambient blobs ────────────────────────────────────────────────────────────

class _AmbientBlob extends StatefulWidget {
  final Color color;
  final double size;
  final Offset beginOffset;
  final Offset endOffset;
  final Duration duration;

  const _AmbientBlob({
    required this.color,
    required this.size,
    required this.beginOffset,
    required this.endOffset,
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
      begin: widget.beginOffset,
      end: widget.endOffset,
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

// ── Helpers ──────────────────────────────────────────────────────────────────

enum FieldType { loginId, password }
