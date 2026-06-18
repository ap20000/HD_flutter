import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_widgets.dart';

class SpecialistsSection extends StatelessWidget {
  final List doctors;
  const SpecialistsSection({super.key, required this.doctors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Specialists',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See all',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170, // Slightly taller for animation breathing room
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: doctors.isNotEmpty ? doctors.length : 3,
            itemBuilder: (context, index) {
              final String name = doctors.isNotEmpty ? doctors[index].name : (index == 0 ? 'Dr. Aradhana' : (index == 1 ? 'Dr. Rohan' : 'Dr. Sneha'));
              final String specialty = doctors.isNotEmpty ? doctors[index].specialty : (index == 0 ? 'Cardiologist' : (index == 1 ? 'Pediatrician' : 'Dermatologist'));
              final String avatarUrl = index == 0
                  ? 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150'
                  : (index == 1 ? 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150' : 'https://images.unsplash.com/photo-1594824436951-7f12bc57ee52?w=150');

              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: NetworkImage(avatarUrl),
                            backgroundColor: AppColors.primarySoft,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: VerifiedBadge(size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
