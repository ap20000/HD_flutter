import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../medical_records/presentation/bloc/medical_records_bloc.dart';
import '../../../medical_records/presentation/bloc/medical_records_event.dart';
import '../../../medical_records/presentation/bloc/medical_records_state.dart';
import '../../../medical_records/domain/entities/medical_record.dart';

class MedicalRecordsPage extends StatefulWidget {
  final bool isDark;

  const MedicalRecordsPage({super.key, required this.isDark});

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  final List<String> _doctors = [
    'Dr. Pramod',
    'Dr. Sachin',
    'Dr. Aradhana',
    'Dr. Anjali',
  ];
  final List<int> _durations = [1, 2, 4, 12, 24];

  @override
  void initState() {
    super.initState();
    // Dispatch loading event on start
    context.read<MedicalRecordsBloc>().add(LoadMedicalRecords());
  }

  void _onUploadRecord() {
    final titleController = TextEditingController();
    String selectedType = 'Report';
    String? selectedFileName;
    final isDark = widget.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Medical Record',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: AppTypography.fontFamily,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Record Title',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFEEF2F6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: isDark
                          ? AppColors.darkSurface
                          : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: AppTypography.fontFamily,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Record Type',
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFEEF2F6),
                          ),
                        ),
                      ),
                      items: ['Report', 'Prescription', 'Lab Result', 'Other']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setModalState(() {
                          selectedFileName =
                              'Lab_Report_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.pdf';
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.02)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFEEF2F6),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedFileName ??
                                    'Select Document (PDF/Image)',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: selectedFileName != null
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : const Color(0xFF94A3B8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AnimatedBounceButton(
                      onTap: () {
                        if (titleController.text.isNotEmpty &&
                            selectedFileName != null) {
                          // Dispatch BLoC event
                          this.context.read<MedicalRecordsBloc>().add(
                            UploadMedicalRecordEvent(
                              title: titleController.text,
                              recordType: selectedType,
                              fileUrl: selectedFileName!,
                            ),
                          );
                          Navigator.pop(modalContext);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill all fields and select a file.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Save Record',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onShareRecord(MedicalRecord record) {
    String? selectedDoctor = _doctors.first;
    int selectedDuration = 4;
    final isDark = widget.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share "${record.title}"',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDoctor,
                    dropdownColor: isDark
                        ? AppColors.darkSurface
                        : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: AppTypography.fontFamily,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Select Doctor',
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFEEF2F6),
                        ),
                      ),
                    ),
                    items: _doctors
                        .map(
                          (doc) =>
                              DropdownMenuItem(value: doc, child: Text(doc)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedDoctor = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedDuration,
                    dropdownColor: isDark
                        ? AppColors.darkSurface
                        : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: AppTypography.fontFamily,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Access Duration',
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFEEF2F6),
                        ),
                      ),
                    ),
                    items: _durations
                        .map(
                          (dur) => DropdownMenuItem(
                            value: dur,
                            child: Text('$dur Hours'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedDuration = val);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  _AnimatedBounceButton(
                    onTap: () {
                      // Dispatch BLoC share event
                      this.context.read<MedicalRecordsBloc>().add(
                        ShareMedicalRecordEvent(
                          recordId: record.id,
                          doctorId: selectedDoctor!,
                          durationInHours: selectedDuration,
                        ),
                      );
                      Navigator.pop(modalContext);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Grant Temporary Access',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAmbientGlows(bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(isDark ? 0.05 : 0.02),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String type) {
    switch (type) {
      case 'Lab Result':
        return Icons.analytics_outlined;
      case 'Prescription':
        return Icons.receipt_long_outlined;
      case 'Report':
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Medical Records',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildAmbientGlows(isDark),
          BlocBuilder<MedicalRecordsBloc, MedicalRecordsState>(
            builder: (context, state) {
              if (state is MedicalRecordsLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              } else if (state is MedicalRecordsError) {
                return Center(child: Text('Error: ${state.message}'));
              } else if (state is MedicalRecordsLoaded) {
                final records = state.records;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Documents (${records.length})',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          _AnimatedBounceButton(
                            onTap: _onUploadRecord,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.primary.withOpacity(0.12)
                                    : const Color(0xFFE8F0FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add Record',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.darkPrimary
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final bool isShared = record.sharedWith != null;

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : const Color(0xFFEEF2F6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.2 : 0.02,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.04)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      _getIconData(record.recordType),
                                      color: isDark
                                          ? AppColors.darkPrimary
                                          : AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record.title,
                                          style: TextStyle(
                                            fontFamily:
                                                AppTypography.fontFamily,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${record.date} • ${record.fileSize}',
                                          style: TextStyle(
                                            fontFamily:
                                                AppTypography.fontFamily,
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white54
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isShared
                                                ? const Color(0xFFD1FAE5)
                                                : (isDark
                                                      ? Colors.white
                                                            .withOpacity(0.05)
                                                      : const Color(
                                                          0xFFF1F5F9,
                                                        )),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            isShared
                                                ? 'SHARED: ${record.sharedWith} (${record.shareDuration})'
                                                : 'PRIVATE DOCUMENT',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: isShared
                                                  ? const Color(0xFF047857)
                                                  : (isDark
                                                        ? Colors.white60
                                                        : const Color(
                                                            0xFF64748B,
                                                          )),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _AnimatedBounceButton(
                                    onTap: () => _onShareRecord(record),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isShared
                                            ? const Color(0xFF10B981)
                                            : (isDark
                                                  ? Colors.white.withOpacity(
                                                      0.06,
                                                    )
                                                  : const Color(0xFFEEF2F6)),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isShared
                                            ? Icons.share
                                            : Icons.share_outlined,
                                        size: 16,
                                        color: isShared
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF64748B)),
                                      ),
                                    ),
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
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}

class _AnimatedBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedBounceButton({required this.child, required this.onTap});

  @override
  State<_AnimatedBounceButton> createState() => _AnimatedBounceButtonState();
}

class _AnimatedBounceButtonState extends State<_AnimatedBounceButton>
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
