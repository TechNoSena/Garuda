import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/widgets/garuda_app_bar.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/models/user_model.dart';
import 'create_shipment_screen.dart';
import 'shipment_detail_screen.dart';

class SupplierHome extends ConsumerStatefulWidget {
  const SupplierHome({super.key});

  @override
  ConsumerState<SupplierHome> createState() => _SupplierHomeState();
}

class _SupplierHomeState extends ConsumerState<SupplierHome> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(shipmentProvider.notifier).loadShipments(user.uid, 'SUPPLIER');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final shipState = ref.watch(shipmentProvider);

    return Scaffold(
      appBar: GarudaAppBar(
        title: 'Garuda',
        role: UserRole.supplier,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateShipmentScreen()),
          );
          if (result == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Shipment'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        color: GarudaColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Hello, ${auth.user?.name ?? 'Supplier'} 👋',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: GarudaColors.textPrimary,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 4),
              Text(
                'Manage your supply chain',
                style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textMuted),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 20),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Pending',
                      value: '${shipState.pendingCount}',
                      icon: Icons.hourglass_empty,
                      color: GarudaColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'In Transit',
                      value: '${shipState.inTransitCount}',
                      icon: Icons.local_shipping,
                      color: GarudaColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Delivered',
                      value: '${shipState.deliveredCount}',
                      icon: Icons.check_circle_outline,
                      color: GarudaColors.success,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

              const SizedBox(height: 24),

              // Shipments list
              Row(
                children: [
                  Text(
                    'Your Shipments',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: GarudaColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${shipState.shipments.length} total',
                    style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (shipState.isLoading)
                const LoadingShimmer(count: 4)
              else if (shipState.shipments.isEmpty)
                const EmptyState(
                  title: 'No shipments yet',
                  subtitle: 'Tap the + button to create your first shipment',
                  icon: Icons.inventory_2_outlined,
                )
              else
                ...shipState.shipments.asMap().entries.map((entry) {
                  return ShipmentTile(
                    shipment: entry.value,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShipmentDetailScreen(shipmentId: entry.value.shipmentId),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: (300 + entry.key * 50).ms).slideX(begin: 0.05);
                }),

              if (shipState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    shipState.error!,
                    style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.danger),
                  ),
                ),

              const SizedBox(height: 80), // FAB clearance
            ],
          ),
        ),
      ),
    );
  }
}
