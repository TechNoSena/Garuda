import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/shipment_model.dart';
import '../../core/models/routing_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/providers/routing_provider.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/garuda_app_bar.dart';
import '../../core/widgets/risk_badge.dart';
import '../../core/services/api_service.dart';
import '../../core/models/analytics_model.dart';
import 'compare_modes_screen.dart';
import 'location_picker_screen.dart';

class CreateShipmentScreen extends ConsumerStatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  ConsumerState<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends ConsumerState<CreateShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _consumerEmailCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _logisticsIdCtrl = TextEditingController(text: 'logistics-uid');

  LatLng _origin = const LatLng(lat: 22.5436, lng: 85.7969);
  String _originName = "Origin Coordinates";
  LatLng _destination = const LatLng(lat: 22.7681, lng: 86.2007);
  String _destinationName = "Destination Coordinates";
  TransportMode _selectedMode = TransportMode.roadCar;
  String _cargoType = 'general';
  
  BillingEstimate? _billingEstimate;
  bool _isLoadingBilling = false;
  Map<String, dynamic>? _precheckResult;
  bool _isLoadingPrecheck = false;

  final List<String> _cargoTypes = ['general', 'fragile', 'perishable', 'hazardous', 'electronics'];

  Future<void> _pickLocation(bool isOrigin) async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(
        initialLocation: isOrigin ? _origin : _destination,
      )),
    );
    if (result != null && mounted) {
      setState(() {
        if (isOrigin) {
          _origin = result.latLng;
          _originName = result.name;
        } else {
          _destination = result.latLng;
          _destinationName = result.name;
        }
        // reset checks
        _billingEstimate = null;
        _precheckResult = null;
      });
    }
  }

  @override
  void dispose() {
    _consumerEmailCtrl.dispose();
    _descriptionCtrl.dispose();
    _weightCtrl.dispose();
    _logisticsIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _createShipment() async {  
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final shipment = await ref.read(shipmentProvider.notifier).createShipment(
      supplierId: user.uid,
      logisticsId: _logisticsIdCtrl.text.trim(),
      consumerEmail: _consumerEmailCtrl.text.trim(),
      origin: _origin,
      destination: _destination,
      routeMode: _selectedMode.value,
      packageDescription: _descriptionCtrl.text.isNotEmpty ? _descriptionCtrl.text.trim() : null,
      weightKg: double.tryParse(_weightCtrl.text),
    );

    if (shipment != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Shipment created successfully!', style: GoogleFonts.inter(color: Colors.white)),
            ],
          ),
          backgroundColor: GarudaColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _compareModes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareModesScreen(origin: _origin, destination: _destination),
      ),
    );
  }

  Future<void> _fetchBillingEstimate() async {
    setState(() => _isLoadingBilling = true);
    try {
      final est = await ApiService().getBillingEstimate(
        origin: _origin,
        destination: _destination,
        mode: _selectedMode.value,
        weightKg: double.tryParse(_weightCtrl.text) ?? 5.0,
        isFragile: _cargoType == 'fragile',
      );
      if (mounted) setState(() => _billingEstimate = est);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingBilling = false);
    }
  }

  Future<void> _runPrecheck() async {
    setState(() => _isLoadingPrecheck = true);
    try {
      final sid = await ref.read(routingProvider.notifier).ensureSession();
      final res = await ApiService().precheckRoute(
        sessionId: sid,
        origin: _origin,
        destination: _destination,
        mode: _selectedMode.value,
        cargoType: _cargoType,
      );
      if (mounted) setState(() => _precheckResult = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Precheck Failed: $e', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: GarudaColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoadingPrecheck = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipState = ref.watch(shipmentProvider);

    return Scaffold(
      appBar: const GarudaAppBar(title: 'New Shipment', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Locations ──────────────────────────────────────
              const SectionHeader(title: '1. Locations'),
              GlassmorphicCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildLocationPicker(true, 'Origin', _originName),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: GarudaColors.glassBorderStrong),
                    ),
                    _buildLocationPicker(false, 'Destination', _destinationName),
                  ],
                ),
              ).animate().fadeIn(delay: 50.ms),

              // ── Package Details ────────────────────────────────
              const SizedBox(height: 16),
              const SectionHeader(title: '2. Package Details'),
              GlassmorphicCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _descriptionCtrl,
                      style: GoogleFonts.inter(color: GarudaColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Package Description',
                        hintText: 'E.g. Electronics, Medical Supplies',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(color: GarudaColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              prefixIcon: Icon(Icons.scale_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Cargo Type', style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _cargoTypes.map((type) {
                        final isSel = _cargoType == type;
                        return ChoiceChip(
                          label: Text(type.toUpperCase()),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _cargoType = type);
                          },
                          backgroundColor: GarudaColors.surfaceLight,
                          selectedColor: GarudaColors.primary.withValues(alpha: 0.2),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                            color: isSel ? GarudaColors.primaryLight : GarudaColors.textMuted,
                          ),
                          side: BorderSide(color: isSel ? GarudaColors.primary : GarudaColors.glassBorderStrong),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _consumerEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(color: GarudaColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Consumer Email',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _logisticsIdCtrl,
                      style: GoogleFonts.inter(color: GarudaColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Logistics Partner ID',
                        hintText: 'Enter Logistics Email or UID',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),

              // ── Transport Mode ─────────────────────────────────
              const SizedBox(height: 16),
              SectionHeader(
                title: '3. Transport Mode',
                trailing: 'Compare Options',
                onTrailingTap: _compareModes,
              ),
              GlassmorphicCard(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TransportMode.values.map((mode) {
                    final isSel = _selectedMode == mode;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMode = mode;
                          _billingEstimate = null;
                          _precheckResult = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSel ? GarudaColors.primary.withValues(alpha: 0.15) : GarudaColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? GarudaColors.primary : GarudaColors.glassBorderStrong),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_modeIcon(mode), size: 18, color: isSel ? GarudaColors.primaryLight : GarudaColors.textMuted),
                            const SizedBox(width: 8),
                            Text(
                              mode.value.replaceAll('ROAD_', ''),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                                color: isSel ? GarudaColors.textPrimary : GarudaColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 250.ms),

              // ── Intelligence Pre-Flight ───────────────────────
              const SizedBox(height: 16),
              const SectionHeader(title: '4. Garuda Intelligence'),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingBilling ? null : _fetchBillingEstimate,
                      icon: _isLoadingBilling 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.receipt_long, size: 16),
                      label: const Text('Get Estimate'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingPrecheck ? null : _runPrecheck,
                      icon: _isLoadingPrecheck
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.shield_outlined, size: 16),
                      label: const Text('Pre-flight Check'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 350.ms),

              // Billing Results
              if (_billingEstimate != null) ...[
                const SizedBox(height: 16),
                GlassmorphicCard(
                  gradient: LinearGradient(colors: [GarudaColors.card, GarudaColors.cardHover]),
                  borderColor: GarudaColors.success.withValues(alpha: 0.5),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Estimate', style: GoogleFonts.spaceGrotesk(fontSize: 16, color: GarudaColors.textPrimary)),
                          Text('₹${_billingEstimate!.totalEstimatedCostInr.toStringAsFixed(0)}', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: GarudaColors.success)),
                        ],
                      ),
                      const Divider(),
                      InfoRow(label: 'Transport Cost', value: '₹${_billingEstimate!.breakdown['transport_cost_inr']}'),
                      if (_billingEstimate!.breakdown['weight_surcharge_inr'] != null && _billingEstimate!.breakdown['weight_surcharge_inr']! > 0)
                        InfoRow(label: 'Weight Surcharge', value: '₹${_billingEstimate!.breakdown['weight_surcharge_inr']}'),
                      if (_billingEstimate!.breakdown['carbon_tax_inr'] != null && _billingEstimate!.breakdown['carbon_tax_inr']! > 0)
                        InfoRow(label: 'Carbon Tax', value: '₹${_billingEstimate!.breakdown['carbon_tax_inr']}', valueColor: GarudaColors.danger),
                    ],
                  ),
                ).animate().fadeIn().slideY(),
              ],

              // Precheck Results
              if (_precheckResult != null) ...[
                const SizedBox(height: 12),
                GlassmorphicCard(
                  borderColor: _precheckResult!['safe_to_dispatch'] == true ? GarudaColors.success.withValues(alpha: 0.5) : GarudaColors.danger.withValues(alpha: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _precheckResult!['safe_to_dispatch'] == true ? Icons.check_circle : Icons.warning_rounded,
                            color: _precheckResult!['safe_to_dispatch'] == true ? GarudaColors.success : GarudaColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _precheckResult!['safe_to_dispatch'] == true ? 'Clear for Dispatch' : 'High Risk Route',
                            style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: GarudaColors.textPrimary),
                          ),
                        ],
                      ),
                      if (_precheckResult!['alerts'] != null && (_precheckResult!['alerts'] as List).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...(_precheckResult!['alerts'] as List).map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: GarudaColors.warning),
                              const SizedBox(width: 6),
                              Expanded(child: Text(a['detail'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textSecondary))),
                            ],
                          ),
                        )),
                      ]
                    ],
                  ),
                ).animate().fadeIn().slideY(),
              ],

              const SizedBox(height: 32),

              // Create Button
              GradientButton(
                label: 'Create Shipment',
                onPressed: _createShipment,
                isLoading: shipState.isLoading,
                icon: Icons.rocket_launch,
                gradient: GarudaGradients.primary,
              ).animate().fadeIn(delay: 450.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPicker(bool isOrigin, String label, String valueDisplay) {
    return InkWell(
      onTap: () => _pickLocation(isOrigin),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isOrigin ? GarudaColors.primary : GarudaColors.accent).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isOrigin ? Icons.trip_origin : Icons.location_on, 
              size: 18, 
              color: isOrigin ? GarudaColors.primaryLight : GarudaColors.accentLight
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  valueDisplay,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: GarudaColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: GarudaColors.textMuted),
        ],
      ),
    );
  }

  IconData _modeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.roadBike: return Icons.two_wheeler;
      case TransportMode.roadCar: return Icons.local_shipping;
      case TransportMode.rail: return Icons.train;
      case TransportMode.flight: return Icons.flight;
      case TransportMode.ship: return Icons.directions_boat;
    }
  }
}
