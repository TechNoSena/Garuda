import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/widgets/garuda_app_bar.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/loading_shimmer.dart';
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
    _load();
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
                'Hello, ${auth.user?.name ?? 'Partner'} 🚛',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: GarudaColors.textPrimary),
              ).animate().fadeIn(),
              const SizedBox(height: 4),
              Text(
                'Manage fleet operations',
                style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textMuted),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 20),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Pending',
                      value: '${state.pendingCount}',
                      icon: Icons.pending_actions,
                      color: GarudaColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Active',
                      value: '${state.inTransitCount}',
                      icon: Icons.local_shipping,
                      color: GarudaColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Completed',
                      value: '${state.deliveredCount}',
                      icon: Icons.done_all,
                      color: GarudaColors.success,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              Text(
                'Shipments',
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600, color: GarudaColors.textPrimary),
              ),
              const SizedBox(height: 12),

              if (state.isLoading)
                const LoadingShimmer(count: 4)
              else if (state.shipments.isEmpty)
                const EmptyState(
                  title: 'No shipments',
                  subtitle: 'Shipments assigned to your logistics firm will appear here',
                  icon: Icons.inventory_2_outlined,
                )
              else
                ...state.shipments.asMap().entries.map((entry) {
                  return ShipmentTile(
                    shipment: entry.value,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignDriverScreen(shipmentId: entry.value.shipmentId),
                        ),
                      ).then((_) => _load());
                    },
                  ).animate().fadeIn(delay: (300 + entry.key * 50).ms);
                }),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
