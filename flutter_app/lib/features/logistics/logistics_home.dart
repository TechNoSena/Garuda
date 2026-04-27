import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/models/shipment_model.dart';
import '../../core/widgets/garuda_app_bar.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../shared/settings_screen.dart';
import 'assign_driver_screen.dart';

class LogisticsHome extends ConsumerStatefulWidget {
  const LogisticsHome({super.key});

  @override
  ConsumerState<LogisticsHome> createState() => _LogisticsHomeState();
}

class _LogisticsHomeState extends ConsumerState<LogisticsHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(shipmentProvider.notifier).loadShipments(user.uid, 'LOGISTICS');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(shipmentProvider);

    return Scaffold(
      appBar: GarudaAppBar(
        title: 'Garuda',
        role: UserRole.logistics,
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
        color: GarudaColors.logisticsColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientBanner(
                title: 'Hello, ${auth.user?.name ?? 'Partner'} 🚛',
                subtitle: 'Manage fleet operations',
                gradient: GarudaGradients.logistics,
                icon: Icons.local_shipping_outlined,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: StatChip(label: 'Pending', value: '${state.pendingCount}', icon: Icons.pending_actions, color: GarudaColors.warning)),
                  const SizedBox(width: 12),
                  Expanded(child: StatChip(label: 'Active', value: '${state.inTransitCount}', icon: Icons.local_shipping, color: GarudaColors.info)),
                  const SizedBox(width: 12),
                  Expanded(child: StatChip(label: 'Completed', value: '${state.deliveredCount}', icon: Icons.done_all, color: GarudaColors.success)),
                ],
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              SectionHeader(title: 'Fleet Shipments', trailing: '${state.shipments.length} total').animate().fadeIn(delay: 200.ms),

              if (state.isLoading)
                const LoadingShimmer(count: 4)
              else if (state.shipments.isEmpty)
                const EmptyState(title: 'No shipments', subtitle: 'Shipments assigned to your logistics firm will appear here', icon: Icons.inventory_2_outlined).animate().fadeIn(delay: 300.ms)
              else
                ...state.shipments.asMap().entries.map((entry) {
                  final s = entry.value;
                  final isActive = s.status == ShipmentStatus.inTransit ||
                                   s.status == ShipmentStatus.dispatched ||
                                   s.status == ShipmentStatus.outForDelivery;
                  return Stack(
                    children: [
                      ShipmentTile(
                        shipment: s,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AssignDriverScreen(shipmentId: s.shipmentId)),
                          ).then((_) => _load());
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

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
