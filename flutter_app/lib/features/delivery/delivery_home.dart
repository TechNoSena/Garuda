import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/models/shipment_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/widgets/garuda_app_bar.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../shared/settings_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        color: GarudaColors.deliveryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientBanner(
                title: 'Hello, ${auth.user?.name ?? 'Driver'} 🛵',
                subtitle: 'Your delivery queue',
                gradient: GarudaGradients.delivery,
                icon: Icons.two_wheeler,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: StatChip(label: 'Active', value: '${activeShipments.length}', icon: Icons.delivery_dining, color: GarudaColors.warning)),
                  const SizedBox(width: 12),
                  Expanded(child: StatChip(label: 'Delivered', value: '${completedShipments.length}', icon: Icons.check_circle_outline, color: GarudaColors.success)),
                ],
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              SectionHeader(title: 'Active Deliveries', trailing: '${activeShipments.length} pending').animate().fadeIn(delay: 200.ms),

              if (state.isLoading)
                const LoadingShimmer(count: 3)
              else if (activeShipments.isEmpty)
                const EmptyState(title: 'No active deliveries', subtitle: 'Assigned shipments will appear here', icon: Icons.delivery_dining).animate().fadeIn(delay: 300.ms)
              else
                ...activeShipments.asMap().entries.map((entry) {
                  final shipment = entry.value;
                  return ShipmentTile(
                    shipment: shipment,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ActiveRideScreen(shipmentId: shipment.shipmentId)),
                      ).then((_) => _load());
                    },
                  ).animate().fadeIn(delay: (300 + entry.key * 50).ms).slideX(begin: 0.05);
                }),

              if (completedShipments.isNotEmpty) ...[
                const SizedBox(height: 32),
                SectionHeader(title: 'Completed Today').animate().fadeIn(),
                ...completedShipments.take(5).map((s) => Opacity(
                  opacity: 0.7,
                  child: ShipmentTile(shipment: s, onTap: () {}),
                )).toList().animate().fadeIn(),
              ],

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
