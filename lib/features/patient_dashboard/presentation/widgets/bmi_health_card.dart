import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class BmiHealthCard extends StatefulWidget {
  final double bmi;
  final double weight;
  final double height;

  const BmiHealthCard({
    super.key,
    required this.bmi,
    required this.weight,
    required this.height,
  });

  @override
  State<BmiHealthCard> createState() => _BmiHealthCardState();
}

class _BmiHealthCardState extends State<BmiHealthCard> {
  double _scale = 1.0;

  String _getBmiCategory(double val) {
    if (val < 18.5) return 'Underweight';
    if (val < 25) return 'Healthy';
    if (val < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiColor(double val) {
    if (val < 18.5) return AppColors.bmiUnderweight;
    if (val < 25) return AppColors.bmiHealthy;
    if (val < 30) return AppColors.bmiOverweight;
    return AppColors.bmiObese;
  }

  @override
  Widget build(BuildContext context) {
    final String category = _getBmiCategory(widget.bmi);
    final Color categoryColor = _getBmiColor(widget.bmi);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Body Mass Index Card. Current BMI: ${widget.bmi.toStringAsFixed(2)}, category: $category.',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.98),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: () {
          HapticFeedback.lightImpact();
          _showHealthPlanDialog(context, widget.bmi);
        },
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : AppColors.divider,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Body Mass Index',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white60 : AppColors.textPrimary.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              widget.bmi.toStringAsFixed(2),
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? AppColors.darkPrimary.withOpacity(0.15) 
                            : AppColors.primarySoft.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.monitor_weight_outlined,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double totalWidth = constraints.maxWidth;
                    final double clampedBmi = widget.bmi.clamp(15.0, 40.0);
                    final double pointerPercentage = (clampedBmi - 15.0) / 25.0;
                    final double pointerPosition = pointerPercentage * totalWidth;

                    return Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 7,
                                width: totalWidth,
                                child: Row(
                                  children: [
                                    Expanded(flex: 35, child: Container(color: AppColors.bmiUnderweight)),
                                    Expanded(flex: 64, child: Container(color: AppColors.bmiHealthy)),
                                    Expanded(flex: 50, child: Container(color: AppColors.bmiOverweight)),
                                    Expanded(flex: 101, child: Container(color: AppColors.bmiObese)),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: pointerPosition - 2.5,
                              top: -5,
                              child: Container(
                                width: 6,
                                height: 17,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkSurface : Colors.white, 
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('15', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                            Text('18.5', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                            Text('25', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                            Text('30', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                            Text('40', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showHealthPlanDialog(context, widget.bmi);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'View Health Plan',
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHealthPlanDialog(BuildContext context, double bmiVal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final category = _getBmiCategory(bmiVal);
        final color = _getBmiColor(bmiVal);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppColors.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$category Weight Plan',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your BMI: ${bmiVal.toStringAsFixed(2)} kg/m²',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12, 
                          fontWeight: FontWeight.w600, 
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : AppColors.textTertiary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSuggestionItem('Balanced Diet Plan', 'Prioritize whole grain carbs, lean proteins, and double portion of fiber.', color, isDark),
              _buildSuggestionItem('Cardio Activity', 'Engage in moderate-intensity activities for at least 150 minutes per week.', color, isDark),
              _buildSuggestionItem('Hydration Goal', 'Consume at least 2.5–3 liters of water spread evenly throughout the day.', color, isDark),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Got it, thanks!', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionItem(String title, String desc, Color bulletColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: bulletColor, shape: BoxShape.circle),
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
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc, 
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12, 
                    color: isDark ? Colors.white60 : AppColors.textSecondary, 
                    height: 1.4,
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
