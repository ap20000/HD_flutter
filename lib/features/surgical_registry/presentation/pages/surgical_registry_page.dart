import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../bloc/surgical_bloc.dart';
import '../bloc/surgical_event.dart';
import '../bloc/surgical_state.dart';
import '../../domain/entities/surgical_log.dart';

class SurgicalRegistryPage extends StatefulWidget {
  final bool isDark;
  final String userRole; // "patient" or "surgical"

  const SurgicalRegistryPage({
    super.key,
    required this.isDark,
    required this.userRole,
  });

  @override
  State<SurgicalRegistryPage> createState() => _SurgicalRegistryPageState();
}

class _SurgicalRegistryPageState extends State<SurgicalRegistryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock Distributor products (surgicalRoutes.js)
  final List<Map<String, dynamic>> _distributorProducts = [
    {
      'id': 'prod_1',
      'name': 'Sterile Scalpels #11',
      'category': 'Cutting Instruments',
      'price': 'Rs. 450 / Box',
      'stock': '140 Boxes',
    },
    {
      'id': 'prod_2',
      'name': 'Reinforced Surgical Gown (L)',
      'category': 'Protective Wear',
      'price': 'Rs. 1,200 / Unit',
      'stock': '85 Units',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Default to 2 tabs if surgical distributor, or 1 tab if patient
    _tabController = TabController(
      length: widget.userRole == 'surgical' ? 2 : 1,
      vsync: this,
    );
    context.read<SurgicalBloc>().add(LoadSurgicalLogs());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onAddSurgicalLog() {
    final procedureController = TextEditingController();
    final hospitalController = TextEditingController();
    final surgeonController = TextEditingController();
    final notesController = TextEditingController();
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
                  'Log Surgical Procedure',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: procedureController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  decoration: _getInputDecoration('Procedure/Surgery Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hospitalController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  decoration: _getInputDecoration('Hospital / Clinic'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: surgeonController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  decoration: _getInputDecoration('Operating Surgeon'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  decoration: _getInputDecoration('Recovery Notes / Comments'),
                ),
                const SizedBox(height: 24),
                _AnimatedBounceButton(
                  onTap: () {
                    if (procedureController.text.isNotEmpty) {
                      this.context.read<SurgicalBloc>().add(
                        AddSurgicalLogEvent(
                          procedure: procedureController.text,
                          hospital: hospitalController.text.isNotEmpty
                              ? hospitalController.text
                              : 'Unknown Clinic',
                          surgeon: surgeonController.text.isNotEmpty
                              ? surgeonController.text
                              : 'Unknown',
                          notes: notesController.text,
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
                        'Save Log Entry',
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

  void _onAddProduct() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final priceController = TextEditingController();
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
                  'Add Surgical Product',
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
                  decoration: _getInputDecoration('Product Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  decoration: _getInputDecoration('Category'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  decoration: _getInputDecoration('Price (e.g. Rs. 500 / Box)'),
                ),
                const SizedBox(height: 24),
                _AnimatedBounceButton(
                  onTap: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        _distributorProducts.insert(0, {
                          'id': 'prod_${_distributorProducts.length + 1}',
                          'name': nameController.text,
                          'category': categoryController.text.isNotEmpty
                              ? categoryController.text
                              : 'General',
                          'price': priceController.text.isNotEmpty
                              ? priceController.text
                              : 'Contact Support',
                          'stock': 'In Stock',
                        });
                      });
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Surgical catalog updated!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
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
                        'Save Product',
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

  Widget _buildPatientHistoryTab() {
    final isDark = widget.isDark;
    return BlocBuilder<SurgicalBloc, SurgicalState>(
      builder: (context, state) {
        if (state is SurgicalLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        } else if (state is SurgicalError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is SurgicalLoaded) {
          final logs = state.logs;
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
                      'Surgical History Logs (${logs.length})',
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
                      onTap: _onAddSurgicalLog,
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
                              'Log Surgery',
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
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = logs[index];
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
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.04)
                                      : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.healing_outlined,
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.procedure,
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
                                      log.date,
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white54
                                            : const Color(0xFF94A3B8),
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
                              const Icon(
                                Icons.business_outlined,
                                size: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                log.hospital,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_pin_outlined,
                                size: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Surgeon: ${log.surgeon}',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          if (log.notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.02)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                log.notes,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
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
    );
  }

  Widget _buildDistributorTab() {
    final isDark = widget.isDark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Surgical Distributor Portal',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
              _AnimatedBounceButton(
                onTap: _onAddProduct,
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
                        'Add Product',
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Active Orders',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '12 Pending',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Subscription Status',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Active • Boosted',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
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
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: _distributorProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final prod = _distributorProducts[index];
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
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
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
                        Icons.precision_manufacturing_outlined,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod['name'] as String,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Category: ${prod['category']} • ${prod['stock']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      prod['price'] as String,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isSurgicalDistributor = widget.userRole == 'surgical';

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
          isSurgicalDistributor
              ? 'Surgical Distributor'
              : 'Surgical History Registry',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        bottom: isSurgicalDistributor
            ? TabBar(
                controller: _tabController,
                indicatorColor: isDark
                    ? AppColors.darkPrimary
                    : AppColors.primary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTypography.fontFamily,
                ),
                tabs: const [
                  Tab(text: 'My Patient Logs'),
                  Tab(text: 'Distributor Catalog'),
                ],
              )
            : null,
      ),
      body: isSurgicalDistributor
          ? TabBarView(
              controller: _tabController,
              children: [_buildPatientHistoryTab(), _buildDistributorTab()],
            )
          : _buildPatientHistoryTab(),
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
