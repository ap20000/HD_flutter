import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';

class PrescriptionPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Pearl White background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Digital Prescription',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prescription shared successfully!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColors.primary, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading prescription PDF...')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header Info Card
            _buildPatientHeader(),
            const SizedBox(height: 24),
            
            // Diagnosis & Observation Card
            _buildSectionCard(
              title: 'DIAGNOSIS & OBSERVATION',
              child: const Text(
                'Patient presenting with mild hypertension and elevated BMI. Suggestive of lifestyle-induced metabolic strain. No immediate acute respiratory distress observed.',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF434655),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Medications Card
            _buildSectionCard(
              title: 'MEDICATIONS',
              child: Column(
                children: [
                  _buildMedicationItem(
                    name: 'Amlodipine 5mg',
                    type: 'Calcium channel blocker',
                    instructions: 'Take with a full glass of water. Avoid grapefruit juice during the course.',
                  ),
                  const Divider(color: Color(0xFFEAEDFF), height: 28),
                  _buildMedicationItem(
                    name: 'Metformin 500mg',
                    type: 'Antidiabetic agent',
                    instructions: 'Take twice daily after meals. Maintain consistent daily timing.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // General Advice Card
            _buildSectionCard(
              title: 'GENERAL ADVICE',
              child: Column(
                children: [
                  _buildAdviceBullet('Low sodium diet recommended.'),
                  _buildAdviceBullet('Daily brisk walk for 30 minutes.'),
                  _buildAdviceBullet('Increase water intake to 3L/day.'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Prescribing Doctor Signature Card
            _buildDoctorSignature(),
            
            if (isDoctor) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prescription finalised and sent to patient.')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  label: const Text(
                    'Finalise & Send',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004AC6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded, color: Color(0xFF004AC6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '24Y, Male • $dateStr',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildMedicationItem({required String name, required String type, required String instructions}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Rx',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          type,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          instructions,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: Color(0xFF434655),
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceBullet(String text) {
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
              decoration: const BoxDecoration(
                color: Color(0xFF004AC6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF434655),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorSignature() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Dr. Aradhana',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'NMC License: #29384-H',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Senior Consultant Physician',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          // Doctor stamp / signature visual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF004AC6).withOpacity(0.4), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'VERIFIED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF004AC6),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
