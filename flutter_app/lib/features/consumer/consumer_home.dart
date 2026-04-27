import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/widgets/garuda_app_bar.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/funky_box.dart';
import '../../core/models/user_model.dart';
import '../../core/models/shipment_model.dart';
import '../shared/settings_screen.dart';
import 'track_shipment_screen.dart';

class ConsumerHome extends ConsumerStatefulWidget {
  const ConsumerHome({super.key});

  @override
  ConsumerState<ConsumerHome> createState() => _ConsumerHomeState();
}

class _ConsumerHomeState extends ConsumerState<ConsumerHome> {
  final _trackingIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMyOrders());
  }

  @override
  void dispose() {
    _trackingIdCtrl.dispose();
    super.dispose();
  }

  /// Auto-load orders linked to the consumer's email — no manual search needed
  void _loadMyOrders() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(shipmentProvider.notifier).loadShipments(user.email, 'CONSUMER');
    }
  }

  void _trackShipment() {
    final id = _trackingIdCtrl.text.trim();
    if (id.isEmpty) return;

    Navigator.push(context, MaterialPageRoute(builder: (_) => TrackShipmentScreen(shipmentId: id)));
    _trackingIdCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final shipState = ref.watch(shipmentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;
    final mutedColor = isDark ? GarudaDarkColors.textMuted : GarudaColors.textMuted;

    final activeOrders = shipState.shipments.where((s) =>
        s.status != ShipmentStatus.delivered &&
        s.status != ShipmentStatus.cancelled).toList();
    final deliveredOrders = shipState.shipments.where((s) =>
        s.status == ShipmentStatus.delivered).toList();

    return Scaffold(
      appBar: GarudaAppBar(
        title: 'Garuda',
        role: UserRole.consumer,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadMyOrders),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadMyOrders(),
          color: GarudaColors.consumerColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientBanner(
                  title: 'Hello, ${auth.user?.name ?? 'there'} 👋',
                  subtitle: 'Your deliveries at a glance',
                  gradient: GarudaGradients.consumer,
                  icon: Icons.inventory_2_outlined,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Stats
                Row(
                  children: [
                    Expanded(child: StatChip(label: 'Active', value: '${activeOrders.length}', icon: Icons.local_shipping, color: GarudaColors.warning)),
                    const SizedBox(width: 12),
                    Expanded(child: StatChip(label: 'Delivered', value: '${deliveredOrders.length}', icon: Icons.check_circle_outline, color: GarudaColors.success)),
                  ],
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // My Active Orders — auto-loaded
                if (activeOrders.isNotEmpty) ...[
                  SectionHeader(title: 'Active Orders', trailing: '${activeOrders.length} in progress').animate().fadeIn(delay: 150.ms),
                  ...activeOrders.asMap().entries.map((entry) {
                    final s = entry.value;
                    return _OrderCard(
                      shipment: s,
                      isDark: isDark,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TrackShipmentScreen(shipmentId: s.shipmentId)),
                      ).then((_) => _loadMyOrders()),
                    ).animate().fadeIn(delay: (200 + entry.key * 60).ms).slideX(begin: 0.05);
                  }),
                  const SizedBox(height: 16),
                ],

                // Delivered
                if (deliveredOrders.isNotEmpty) ...[
                  const SectionHeader(title: 'Delivered').animate().fadeIn(),
                  ...deliveredOrders.take(5).map((s) => Opacity(
                    opacity: 0.65,
                    child: _OrderCard(
                      shipment: s,
                      isDark: isDark,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackShipmentScreen(shipmentId: s.shipmentId))),
                    ),
                  )).toList().animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                ],

                if (shipState.shipments.isEmpty && !shipState.isLoading)
                  const EmptyState(
                    title: 'No orders yet',
                    subtitle: 'Orders linked to your email will appear here automatically',
                    icon: Icons.inbox_outlined,
                  ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                // Manual track input (secondary option)
                GlassmorphicCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 Track by ID',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text('Have a tracking ID? Enter it below.', style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _trackingIdCtrl,
                              style: GoogleFonts.inter(color: textColor, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Enter shipment ID',
                                prefixIcon: Icon(Icons.search, size: 20),
                              ),
                              onSubmitted: (_) => _trackShipment(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _trackShipment,
                              child: const Text('Track'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                // Info card
                const SizedBox(height: 24),
                FunkyBox.cornerAccent(
                  color: isDark ? GarudaDarkColors.surfaceLight : GarudaColors.primaryLight.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: GarudaColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Powered by Garuda AI',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your deliveries are protected by AI-powered route optimization. '
                        'Garuda detects disruptions before they affect your package and '
                        'automatically reroutes for the fastest delivery.',
                        style: GoogleFonts.inter(fontSize: 13, color: mutedColor, height: 1.5),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Order card widget for consumer's "My Orders" section
class _OrderCard extends StatelessWidget {
  final Shipment shipment;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _OrderCard({
    required this.shipment,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? GarudaDarkColors.card : GarudaColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? GarudaDarkColors.glassBorder : GarudaColors.glassBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _statusColor(shipment.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor(shipment.status).withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(shipment.status.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shipment.packageDescription ?? 'Package',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StatusBadge(label: shipment.status.label, color: _statusColor(shipment.status)),
                      const Spacer(),
                      if (shipment.currentLocation != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: GarudaColors.success,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: GarudaColors.success.withValues(alpha: 0.5), blurRadius: 4)],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('Live', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: GarudaColors.success)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: mutedColor),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending:
      case ShipmentStatus.assigned:
        return GarudaColors.warning;
      case ShipmentStatus.dispatched:
      case ShipmentStatus.inTransit:
      case ShipmentStatus.outForDelivery:
        return GarudaColors.info;
      case ShipmentStatus.delivered:
        return GarudaColors.success;
      case ShipmentStatus.cancelled:
      case ShipmentStatus.exception:
        return GarudaColors.danger;
    }
  }
}
