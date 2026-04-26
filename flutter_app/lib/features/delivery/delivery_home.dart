import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/models/shipment_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/widgets/garuda_app_bar.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/loading_shimmer.dart';
import 'active_ride_screen.dart';

class DeliveryHome extends ConsumerStatefulWidget {
  const DeliveryHome({super.key});

  @override
  ConsumerState<DeliveryHome> createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends ConsumerState<DeliveryHome> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(shipmentProvider.notifier).loadShipments(user.uid, 'DELIVERY_MAN');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(shipmentProvider);

    final activeShipments = state.shipments.where((s) =>
        s.status != ShipmentStatus.delivered &&
        s.status != ShipmentStatus.cancelled).toList();
    final completedShipments = state.shipments.where((s) =>
        s.status == ShipmentStatus.delivered).toList();

    return Scaffold(
      appBar: GarudaAppBar(
        title: 'Garuda',
        role: UserRole.deliveryMan,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
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
              Text(
                'Hello, ${auth.user?.name ?? 'Driver'} 🛵',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: GarudaColors.textPrimary),
              ).animate().fadeIn(),
              const SizedBox(height: 4),
              Text(
                'Your delivery queue',
                style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textMuted),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 20),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Active',
                      value: '${activeShipments.length}',
                      icon: Icons.delivery_dining,
                      color: GarudaColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Delivered',
                      value: '${completedShipments.length}',
                      icon: Icons.check_circle_outline,
                      color: GarudaColors.success,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // Active deliveries
              Text(
                'Active Deliveries',
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600, color: GarudaColors.textPrimary),
              ),
              const SizedBox(height: 12),

              if (state.isLoading)
                const LoadingShimmer(count: 3)
              else if (activeShipments.isEmpty)
                const EmptyState(
                  title: 'No active deliveries',
                  subtitle: 'Assigned shipments will appear here',
                  icon: Icons.delivery_dining,
                )
              else
                ...activeShipments.asMap().entries.map((entry) {
                  final shipment = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ShipmentTile(
                      shipment: shipment,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActiveRideScreen(shipmentId: shipment.shipmentId),
                          ),
                        ).then((_) => _load());
                      },
                    ),
                  ).animate().fadeIn(delay: (300 + entry.key * 50).ms);
                }),

              // Completed section
              if (completedShipments.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Completed Today',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: GarudaColors.textSecondary),
                ),
                const SizedBox(height: 8),
                ...completedShipments.take(5).map((s) => ShipmentTile(shipment: s)),
              ],

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
