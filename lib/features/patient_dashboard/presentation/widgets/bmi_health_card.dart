import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_widgets.dart';

class BmiHealthCard extends StatelessWidget {
  final double bmi;
  final double weight;
  final double height;

  const BmiHealthCard({
    super.key,
    required this.bmi,
    required this.weight,
    required this.height,
  });

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
    final String category = _getBmiCategory(bmi);
    final Color categoryColor = _getBmiColor(bmi);

    return AppCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: AppColors.divider, width: 1.5),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        bmi.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
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
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double clampedBmi = bmi.clamp(15.0, 40.0);
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
                          width: 5,
                          height: 17,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
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
                      Text('24.9', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                      Text('29.9', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
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
                _showHealthPlanDialog(context, bmi);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'View health plan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthPlanDialog(BuildContext context, double bmiVal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final category = _getBmiCategory(bmiVal);
        final color = _getBmiColor(bmiVal);
        
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your BMI: ${bmiVal.toStringAsFixed(2)} kg/m²',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textTertiary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSuggestionItem('Balanced Diet Plan', 'Prioritize whole grain carbs, lean proteins, and double portion of fiber.', color),
              _buildSuggestionItem('Cardio Activity', 'Engage in moderate-intensity activities for at least 150 minutes per week.', color),
              _buildSuggestionItem('Hydration Goal', 'Consume at least 2.5–3 liters of water spread evenly throughout the day.', color),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it, thanks!', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionItem(String title, String desc, Color bulletColor) {
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
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
