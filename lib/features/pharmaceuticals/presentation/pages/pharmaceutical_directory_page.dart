import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../bloc/pharmaceutical_bloc.dart';
import '../bloc/pharmaceutical_event.dart';
import '../bloc/pharmaceutical_state.dart';
import '../../domain/entities/medicine.dart';

class PharmaceuticalDirectoryPage extends StatefulWidget {
  final bool isDark;
  final String userRole; // "patient" or "pharmaceutical"

  const PharmaceuticalDirectoryPage({
    super.key,
    required this.isDark,
    required this.userRole,
  });

  @override
  State<PharmaceuticalDirectoryPage> createState() =>
      _PharmaceuticalDirectoryPageState();
}

class _PharmaceuticalDirectoryPageState
    extends State<PharmaceuticalDirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<PharmaceuticalBloc>().add(LoadMedicines());
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onRegisterMedicine() {
    final nameController = TextEditingController();
    final genericController = TextEditingController();
    final categoryController = TextEditingController();
    final detailsController = TextEditingController();
    final isDark = widget.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
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
                  'Register Medicine Brand',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  decoration: _getInputDecoration(
                    'Brand Name (e.g. Napa 500mg)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: genericController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  decoration: _getInputDecoration(
                    'Generic Name (e.g. Paracetamol)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  decoration: _getInputDecoration('Category (e.g. Analgesic)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  decoration: _getInputDecoration(
                    'Therapeutic Class & Usage Details',
                  ),
                ),
                const SizedBox(height: 24),
                _AnimatedBounceButton(
                  onTap: () {
                    if (nameController.text.isNotEmpty) {
                      this.context.read<PharmaceuticalBloc>().add(
                        AddMedicineEvent(
                          name: nameController.text,
                          generic: genericController.text.isNotEmpty
                              ? genericController.text
                              : nameController.text,
                          category: categoryController.text.isNotEmpty
                              ? categoryController.text
                              : 'General',
                          details: detailsController.text,
                        ),
                      );
                      Navigator.pop(modalContext);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Publish Medicine Listing',
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
  }

  InputDecoration _getInputDecoration(String label) {
    final isDark = widget.isDark;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isPharmaAdmin = widget.userRole == 'pharmaceutical';

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
          isPharmaAdmin ? 'Pharma Brand Manager' : 'Pharmaceutical Directory',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xFFEEF2F6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                              fontFamily: AppTypography.fontFamily,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search brand or generic formula...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isPharmaAdmin) ...[
                  const SizedBox(width: 10),
                  _AnimatedBounceButton(
                    onTap: _onRegisterMedicine,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<PharmaceuticalBloc, PharmaceuticalState>(
              builder: (context, state) {
                if (state is PharmaceuticalLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                } else if (state is PharmaceuticalError) {
                  return Center(child: Text('Error: ${state.message}'));
                } else if (state is PharmaceuticalLoaded) {
                  final list = state.medicines;
                  final filtered = list
                      .where(
                        (m) =>
                            m.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            m.generic.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            m.category.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                      )
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No matching medicines found.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final med = filtered[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.vaccines_outlined,
                                    color: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.name,
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Generic: ${med.generic}',
                                        style: const TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, thickness: 1),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : const Color(0xFFEEF2F6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    med.category.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? AppColors.darkPrimary
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  med.formulation,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              med.manufacturer,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            if (med.details.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                med.details,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
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
