import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';

class PrescriptionPage extends StatefulWidget {
  final String patientName;
  final String dateStr;
  final bool isDoctor;

  const PrescriptionPage({
    super.key,
    required this.patientName,
    this.dateStr = 'Oct 24, 2023',
    this.isDoctor = false,
  });

  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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

  Widget _buildPremiumCard({
    required Widget child,
    required Color cardColor,
    required Color borderColor,
    required bool isDark,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
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
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAmbientGlows(bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.secondary;
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(isDark ? 0.06 : 0.03),
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          left: -120,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(isDark ? 0.05 : 0.02),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEF2F6);
    final textPrimaryColor = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded, 
            color: textPrimaryColor, 
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Digital Prescription',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        actions: [
          _AnimatedInteractiveButton(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prescription shared successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.share_outlined, 
                color: isDark ? AppColors.darkPrimary : AppColors.primary, 
                size: 22,
              ),
            ),
          ),
          _AnimatedInteractiveButton(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Downloading prescription PDF...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.download_outlined, 
                color: isDark ? AppColors.darkPrimary : AppColors.primary, 
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _buildAmbientGlows(isDark),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient details card
            _AnimatedEntrance(
              animation: _entranceController,
              delay: 0,
              child: _buildPatientHeader(context, cardColor, borderColor),
            ),
            const SizedBox(height: 16),
            
            // Diagnosis
            _AnimatedEntrance(
              animation: _entranceController,
              delay: 1,
              child: _buildSectionCard(
                context,
                cardColor: cardColor,
                borderColor: borderColor,
                title: 'DIAGNOSIS & OBSERVATION',
                child: Text(
                  'Patient presenting with mild hypertension and elevated BMI. Suggestive of lifestyle-induced metabolic strain. No immediate acute respiratory distress observed.',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF434655),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Medications
            _AnimatedEntrance(
              animation: _entranceController,
              delay: 2,
              child: _buildSectionCard(
                context,
                cardColor: cardColor,
                borderColor: borderColor,
                title: 'MEDICATIONS',
                child: Column(
                  children: [
                    _buildMedicationItem(
                      context,
                      name: 'Amlodipine 5mg',
                      type: 'Calcium channel blocker',
                      instructions: 'Take with a full glass of water. Avoid grapefruit juice during the course.',
                    ),
                    Divider(
                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEAEDFF), 
                      height: 28,
                    ),
                    _buildMedicationItem(
                      context,
                      name: 'Metformin 500mg',
                      type: 'Antidiabetic agent',
                      instructions: 'Take twice daily after meals. Maintain consistent daily timing.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // General Advice
            _AnimatedEntrance(
              animation: _entranceController,
              delay: 3,
              child: _buildSectionCard(
                context,
                cardColor: cardColor,
                borderColor: borderColor,
                title: 'GENERAL ADVICE',
                child: Column(
                  children: [
                    _buildAdviceBullet(context, 'Low sodium diet recommended.'),
                    _buildAdviceBullet(context, 'Daily brisk walk for 30 minutes.'),
                    _buildAdviceBullet(context, 'Increase water intake to 3L/day.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Doctor Signature
            _AnimatedEntrance(
              animation: _entranceController,
              delay: 4,
              child: _buildDoctorSignature(context, cardColor, borderColor),
            ),
            
            // Send action (for Doctor role)
            if (widget.isDoctor) ...[
              const SizedBox(height: 32),
              _AnimatedEntrance(
                animation: _entranceController,
                delay: 5,
                child: _AnimatedInteractiveButton(
                  scaleFactor: 0.95,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prescription finalised and sent to patient.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.darkPrimary : const Color(0xFF004AC6)).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Finalise & Send',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    ],
  ),
);
}

  Widget _buildPatientHeader(BuildContext context, Color cardColor, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildPremiumCard(
      cardColor: cardColor,
      borderColor: borderColor,
      isDark: isDark,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPrimary.withOpacity(0.15) : const Color(0xFFE8F0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded, 
              color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6), 
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '24Y, Male • ${widget.dateStr}',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
    required Color cardColor,
    required Color borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildPremiumCard(
      cardColor: cardColor,
      borderColor: borderColor,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildMedicationItem(BuildContext context, {required String name, required String type, required String instructions}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPrimary.withOpacity(0.12) : const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.medication_outlined,
            color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rx',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.darkPrimary : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                type,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEEF2F6),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  instructions,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF434655),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceBullet(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF434655),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorSignature(BuildContext context, Color cardColor, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildPremiumCard(
      cardColor: cardColor,
      borderColor: borderColor,
      isDark: isDark,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Aradhana',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NMC License: #29384-H',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Senior Consultant Physician',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFD1FAE5),
              border: Border.all(
                color: const Color(0xFF10B981), 
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
                SizedBox(width: 6),
                Text(
                  'VERIFIED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Interactive Spring Button Interaction ────────────────────────────────────

class _AnimatedInteractiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;

  const _AnimatedInteractiveButton({
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.92,
  });

  @override
  State<_AnimatedInteractiveButton> createState() => _AnimatedInteractiveButtonState();
}

class _AnimatedInteractiveButtonState extends State<_AnimatedInteractiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
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
