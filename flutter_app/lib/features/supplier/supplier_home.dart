import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/models/shipment_model.dart';
import '../../core/widgets/garuda_app_bar.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/models/user_model.dart';
import '../shared/settings_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateShipmentScreen()));
          if (result == true) _load();
        },
        icon: const Icon(Icons.add),
        label: Text('New Shipment', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        color: GarudaColors.supplierColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientBanner(
                title: 'Hello, ${auth.user?.name ?? 'Supplier'} 👋',
                subtitle: 'Manage your supply chain',
                gradient: GarudaGradients.supplier,
                icon: Icons.inventory_2_outlined,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: StatChip(label: 'Pending', value: '${shipState.pendingCount}', icon: Icons.hourglass_empty, color: GarudaColors.warning)),
                  const SizedBox(width: 12),
                  Expanded(child: StatChip(label: 'In Transit', value: '${shipState.inTransitCount}', icon: Icons.local_shipping_outlined, color: GarudaColors.info)),
                  const SizedBox(width: 12),
                  Expanded(child: StatChip(label: 'Delivered', value: '${shipState.deliveredCount}', icon: Icons.check_circle_outline, color: GarudaColors.success)),
                ],
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              SectionHeader(title: 'Your Shipments', trailing: '${shipState.shipments.length} total').animate().fadeIn(delay: 200.ms),

              if (shipState.isLoading)
                const LoadingShimmer(count: 4)
              else if (shipState.shipments.isEmpty)
                const EmptyState(title: 'No shipments found', subtitle: 'Tap the + button to create your first shipment', icon: Icons.inventory_2_outlined).animate().fadeIn(delay: 300.ms)
              else
                ...shipState.shipments.asMap().entries.map((entry) {
                  final s = entry.value;
                  final isActive = s.status == ShipmentStatus.inTransit || 
                                   s.status == ShipmentStatus.dispatched || 
                                   s.status == ShipmentStatus.outForDelivery;
                  return Stack(
                    children: [
                      ShipmentTile(
                        shipment: s,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ShipmentDetailScreen(shipmentId: s.shipmentId)));
                        },
                      ),
                      if (isActive)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: GarudaColors.success,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: GarudaColors.success.withValues(alpha: 0.5), blurRadius: 4)],
                                ),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                begin: const Offset(1, 1), end: const Offset(1.4, 1.4), duration: 1.seconds,
                              ),
                              const SizedBox(width: 4),
                              Text('Live', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: GarudaColors.success)),
                            ],
                          ),
                        ),
                    ],
                  ).animate().fadeIn(delay: (300 + entry.key * 50).ms).slideX(begin: 0.05);
                }),

              if (shipState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(shipState.error!, style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.danger)),
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
