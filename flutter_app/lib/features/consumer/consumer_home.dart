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
              Text(
                'Hello, ${auth.user?.name ?? 'there'} 👋',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: GarudaColors.textPrimary,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 4),
              Text(
                'Track your deliveries',
                style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textMuted),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // Track input
              GlassmorphicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📦 Track a Shipment',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: GarudaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _trackingIdCtrl,
                            style: GoogleFonts.inter(color: GarudaColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Enter shipment ID',
                              prefixIcon: Icon(Icons.search, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onSubmitted: (_) => _trackShipment(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _trackShipment,
                            child: const Text('Track'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

              if (_trackedIds.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Recent Tracking',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: GarudaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ..._trackedIds.map((id) => GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TrackShipmentScreen(shipmentId: id)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: GarudaColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GarudaColors.glassBorder, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping, size: 18, color: GarudaColors.textMuted),
                        const SizedBox(width: 10),
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
                        const Icon(Icons.chevron_right, size: 18, color: GarudaColors.textMuted),
                      ],
                    ),
                  ),
                )),
              ],

              // Info card
              const SizedBox(height: 24),
              GlassmorphicCard(
                borderColor: GarudaColors.primary.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🦅 Powered by Garuda AI',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: GarudaColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your deliveries are protected by AI-powered route optimization. '
                      'Garuda detects disruptions before they affect your package and '
                      'automatically reroutes for the fastest delivery.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: GarudaColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
