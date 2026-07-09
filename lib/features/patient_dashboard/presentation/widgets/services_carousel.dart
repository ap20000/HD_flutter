import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class ServicesCarousel extends StatelessWidget {
  final List<String> services;
  final void Function(String) onTap;

  const ServicesCarousel({
    super.key,
    required this.services,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final List<Map<String, dynamic>> serviceDetails = [
      {
        'name': 'General',
        'icon': Icons.medical_services_outlined,
        'color': const Color(0xFFE3F2FD),
        'iconColor': const Color(0xFF1976D2),
        'gradient': const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      },
      {
        'name': 'Cardiology',
        'icon': Icons.favorite_outline,
        'color': const Color(0xFFFFEBEE),
        'iconColor': const Color(0xFFD32F2F),
        'gradient': const LinearGradient(
          colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      },
      {
        'name': 'Genetics',
        'icon': Icons.biotech_outlined,
        'color': const Color(0xFFF3E5F5),
        'iconColor': const Color(0xFF7B1FA2),
        'gradient': const LinearGradient(
          colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      },
      {
        'name': 'Diagnostic',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF388E3C),
        'gradient': const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: serviceDetails.map((service) {
        return _ServiceItem(
          service: service,
          isDark: isDark,
          onTap: () => onTap(service['name']),
        );
      }).toList(),
    );
  }
}

class _ServiceItem extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isDark;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.service,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ServiceItem> createState() => _ServiceItemState();
}

class _ServiceItemState extends State<_ServiceItem> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.isDark
        ? LinearGradient(
            colors: [AppColors.darkSurface, AppColors.darkSurface.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : widget.service['gradient'] as Gradient;

    final iconColor = widget.isDark ? Colors.white : widget.service['iconColor'] as Color;

    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _scale = 0.92),
          onTapUp: (_) => setState(() => _scale = 1.0),
          onTapCancel: () => setState(() => _scale = 1.0),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.service['icon'] as IconData,
                  color: iconColor,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.service['name'] as String,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
