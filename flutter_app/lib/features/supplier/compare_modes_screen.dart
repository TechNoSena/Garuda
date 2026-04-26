import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/shipment_model.dart';
import '../../core/models/compare_model.dart';
import '../../core/providers/routing_provider.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_shimmer.dart';

class CompareModesScreen extends ConsumerStatefulWidget {
  final LatLng origin;
  final LatLng destination;

  const CompareModesScreen({super.key, required this.origin, required this.destination});

  @override
  ConsumerState<CompareModesScreen> createState() => _CompareModesScreenState();
}

class _CompareModesScreenState extends ConsumerState<CompareModesScreen> {
  String _sortBy = 'fastest'; // fastest, cheapest, greenest

  @override
  void initState() {
    super.initState();
    ref.read(routingProvider.notifier).compareModes(
      origin: widget.origin,
      destination: widget.destination,
    );
  }

  List<ModeComparison> _sorted(List<ModeComparison> items) {
    final list = List<ModeComparison>.from(items);
    switch (_sortBy) {
      case 'cheapest':
        list.sort((a, b) => a.estimatedCostInr.compareTo(b.estimatedCostInr));
      case 'greenest':
        list.sort((a, b) => a.estimatedCo2G.compareTo(b.estimatedCo2G));
      default:
        list.sort((a, b) => a.estimatedDurationMins.compareTo(b.estimatedDurationMins));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Compare Modes', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: state.isLoading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: LoadingShimmer(count: 5, height: 100),
            )
          : state.comparison == null
              ? Center(
                  child: Text(
                    state.error ?? 'Failed to load comparison',
                    style: GoogleFonts.inter(color: GarudaColors.textMuted),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance header
                      GlassmorphicCard(
                        child: Row(
                          children: [
                            const Icon(Icons.straighten, color: GarudaColors.textMuted, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Straight-line: ${state.comparison!.straightLineKm.toStringAsFixed(1)} km',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: GarudaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Sort tabs
                      Row(
                        children: [
                          _sortChip('Fastest', 'fastest', Icons.speed),
                          const SizedBox(width: 8),
                          _sortChip('Cheapest', 'cheapest', Icons.currency_rupee),
                          const SizedBox(width: 8),
                          _sortChip('Greenest', 'greenest', Icons.eco),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Mode cards
                      ..._sorted(state.comparison!.comparisons).asMap().entries.map((entry) {
                        final mode = entry.value;
                        final isFirst = entry.key == 0;
                        final tm = mode.transportMode;

                        return GlassmorphicCard(
                          borderColor: isFirst ? tm.color.withValues(alpha: 0.5) : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: tm.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(tm.icon, size: 20, color: tm.color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mode.mode,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: GarudaColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${mode.distanceKm.toStringAsFixed(1)} km',
                                          style: GoogleFonts.inter(
                                            fontSize: 11, color: GarudaColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isFirst)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: tm.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _sortBy == 'fastest' ? '⚡ Fastest' :
                                        _sortBy == 'cheapest' ? '💰 Cheapest' : '🌱 Greenest',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: tm.color,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _metricBox('⏱ Duration', mode.durationDisplay, GarudaColors.info),
                                  const SizedBox(width: 10),
                                  _metricBox('💰 Cost', mode.costDisplay, GarudaColors.warning),
                                  const SizedBox(width: 10),
                                  _metricBox('🌿 CO₂', mode.co2Display, GarudaColors.success),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (100 + entry.key * 80).ms).slideY(begin: 0.05);
                      }),
                    ],
                  ),
                ),
    );
  }

  Widget _sortChip(String label, String value, IconData icon) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? GarudaColors.primary.withValues(alpha: 0.2) : GarudaColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? GarudaColors.primary : GarudaColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? GarudaColors.primaryLight : GarudaColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? GarudaColors.primaryLight : GarudaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: GarudaColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
