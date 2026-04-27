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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routingProvider.notifier).compareModes(
        origin: widget.origin,
        destination: widget.destination,
      );
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GarudaDarkColors.textPrimary : GarudaColors.textPrimary;
    final mutedColor = isDark ? GarudaDarkColors.textMuted : GarudaColors.textMuted;
    final surfaceColor = isDark ? GarudaDarkColors.surfaceLight : GarudaColors.surface;
    final state = ref.watch(routingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Compare Modes', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
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
                  child: EmptyState(
                    title: 'Comparison Failed',
                    subtitle: state.error ?? 'Failed to load comparison data.',
                    icon: Icons.error_outline,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance header
                      GlassmorphicCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: GarudaColors.info.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.straighten, color: GarudaColors.info, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Straight-line Distance', style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
                                Text(
                                  '${state.comparison!.straightLineKm.toStringAsFixed(1)} km',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      // Sort tabs
                      const SectionHeader(title: 'Sort By'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _sortChip('Fastest', 'fastest', Icons.speed, isDark, textColor, mutedColor, surfaceColor),
                            const SizedBox(width: 12),
                            _sortChip('Cheapest', 'cheapest', Icons.currency_rupee, isDark, textColor, mutedColor, surfaceColor),
                            const SizedBox(width: 12),
                            _sortChip('Greenest', 'greenest', Icons.eco, isDark, textColor, mutedColor, surfaceColor),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 24),

                      // Mode cards
                      ..._sorted(state.comparison!.comparisons).asMap().entries.map((entry) {
                        final mode = entry.value;
                        final isFirst = entry.key == 0;
                        final tm = mode.transportMode;

                        return GlassmorphicCard(
                          borderColor: isFirst ? tm.color.withValues(alpha: 0.5) : null,
                          gradient: isFirst ? LinearGradient(colors: [isDark ? GarudaDarkColors.card : GarudaColors.card, tm.color.withValues(alpha: 0.05)]) : null,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: tm.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: tm.color.withValues(alpha: 0.3)),
                                    ),
                                    child: Icon(tm.icon, size: 22, color: tm.color),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mode.mode,
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          '${mode.distanceKm.toStringAsFixed(1)} km routed',
                                          style: GoogleFonts.inter(
                                            fontSize: 12, color: mutedColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isFirst)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: tm.color.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _sortBy == 'fastest' ? '⚡ Fastest' :
                                        _sortBy == 'cheapest' ? '💰 Cheapest' : '🌱 Greenest',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: tm.color,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _metricBox('⏱ Duration', mode.durationDisplay, GarudaColors.info, isDark, surfaceColor)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _metricBox('💰 Cost', mode.costDisplay, GarudaColors.warning, isDark, surfaceColor)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _metricBox('🌿 CO₂', mode.co2Display, GarudaColors.success, isDark, surfaceColor)),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (200 + entry.key * 100).ms).slideY(begin: 0.05);
                      }),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _sortChip(String label, String value, IconData icon, bool isDark, Color textColor, Color mutedColor, Color surfaceColor) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? GarudaColors.primary.withValues(alpha: 0.15) : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? GarudaColors.primary : (isDark ? GarudaDarkColors.glassBorder : GarudaColors.glassBorder),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? GarudaColors.primaryLight : mutedColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? textColor : mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color, bool isDark, Color surfaceColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? GarudaDarkColors.glassBorder : GarudaColors.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? GarudaDarkColors.textMuted : GarudaColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
