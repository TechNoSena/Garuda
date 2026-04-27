import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/garuda_app_bar.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/models/user_model.dart';
import 'track_shipment_screen.dart';

class ConsumerHome extends ConsumerStatefulWidget {
  const ConsumerHome({super.key});

  @override
  ConsumerState<ConsumerHome> createState() => _ConsumerHomeState();
}

class _ConsumerHomeState extends ConsumerState<ConsumerHome> {
  final _trackingIdCtrl = TextEditingController();
  final List<String> _trackedIds = [];

  @override
  void dispose() {
    _trackingIdCtrl.dispose();
    super.dispose();
  }

  void _trackShipment() {
    final id = _trackingIdCtrl.text.trim();
    if (id.isEmpty) return;

    if (!_trackedIds.contains(id)) {
      setState(() => _trackedIds.insert(0, id));
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrackShipmentScreen(shipmentId: id)),
    );
    _trackingIdCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: GarudaAppBar(
        title: 'Garuda',
        role: UserRole.consumer,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientBanner(
                title: 'Hello, ${auth.user?.name ?? 'there'} 👋',
                subtitle: 'Track your deliveries',
                gradient: GarudaGradients.consumer,
                icon: Icons.inventory_2_outlined,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              // Track input
              GlassmorphicCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📦 Track a Shipment',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GarudaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _trackingIdCtrl,
                            style: GoogleFonts.inter(color: GarudaColors.textPrimary, fontSize: 14),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GarudaColors.accent,
                            ),
                            child: const Text('Track'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

              if (_trackedIds.isNotEmpty) ...[
                const SizedBox(height: 32),
                const SectionHeader(title: 'Recent Tracking').animate().fadeIn(),
                ..._trackedIds.map((id) => GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TrackShipmentScreen(shipmentId: id)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: GarudaColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GarudaColors.glassBorder, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping, size: 20, color: GarudaColors.textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            id,
                            style: const TextStyle(
                              fontSize: 13,
                              color: GarudaColors.textPrimary,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: GarudaColors.textMuted),
                      ],
                    ),
                  ),
                )).toList().animate().fadeIn(delay: 200.ms),
              ],

              // Info card
              const SizedBox(height: 32),
              GlassmorphicCard(
                borderColor: GarudaColors.primary.withValues(alpha: 0.4),
                gradient: LinearGradient(
                  colors: [GarudaColors.card, GarudaColors.cardHover],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: GarudaColors.primaryLight, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Powered by Garuda AI',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: GarudaColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your deliveries are protected by AI-powered route optimization. '
                      'Garuda detects disruptions before they affect your package and '
                      'automatically reroutes for the fastest delivery.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: GarudaColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
