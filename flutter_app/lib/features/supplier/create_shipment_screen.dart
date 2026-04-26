import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/shipment_model.dart';
import '../../core/models/routing_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/shipment_provider.dart';
import '../../core/providers/routing_provider.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/risk_badge.dart';
import '../../core/services/api_service.dart';
import '../../core/models/analytics_model.dart';
import 'compare_modes_screen.dart';

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

  // Origin / Destination
  final _originLatCtrl = TextEditingController(text: '22.5436');
  final _originLngCtrl = TextEditingController(text: '85.7969');
  final _destLatCtrl = TextEditingController(text: '22.7681');
  final _destLngCtrl = TextEditingController(text: '86.2007');

  TransportMode _selectedMode = TransportMode.roadCar;
  BillingEstimate? _billingEstimate;
  bool _isLoadingBilling = false;
  Map<String, dynamic>? _precheckResult;
  bool _isLoadingPrecheck = false;

  LatLng get _origin => LatLng(
    lat: double.tryParse(_originLatCtrl.text) ?? 22.5436,
    lng: double.tryParse(_originLngCtrl.text) ?? 85.7969,
  );

  LatLng get _destination => LatLng(
    lat: double.tryParse(_destLatCtrl.text) ?? 22.7681,
    lng: double.tryParse(_destLngCtrl.text) ?? 86.2007,
  );

  @override
  void dispose() {
    _consumerEmailCtrl.dispose();
    _descriptionCtrl.dispose();
    _weightCtrl.dispose();
    _logisticsIdCtrl.dispose();
    _originLatCtrl.dispose();
    _originLngCtrl.dispose();
    _destLatCtrl.dispose();
    _destLngCtrl.dispose();
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
        const SnackBar(content: Text('Shipment created successfully!')),
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

  void _checkRisk() {
    ref.read(routingProvider.notifier).analyzeRisk(
      origin: _origin,
      destination: _destination,
      mode: _selectedMode.value,
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
      final res = await ApiService().precheckRoute(
        sessionId: 'mock-session', // In a real app we'd grab this from routingProvider
        origin: _origin,
        destination: _destination,
        mode: _selectedMode.value,
        cargoType: 'general',
      );
      if (mounted) setState(() => _precheckResult = res);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingPrecheck = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipState = ref.watch(shipmentProvider);
    final routeState = ref.watch(routingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('New Shipment', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Origin
              _sectionTitle('Origin'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _originLatCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: GarudaColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Lat'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _originLngCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: GarudaColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Lng'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Destination
              _sectionTitle('Destination'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _destLatCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: GarudaColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Lat'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _destLngCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: GarudaColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Lng'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Transport mode
              _sectionTitle('Transport Mode'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TransportMode.values.map((mode) {
                  final selected = _selectedMode == mode;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMode = mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? mode.color.withValues(alpha: 0.15) : GarudaColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? mode.color : GarudaColors.glassBorder,
                          width: selected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(mode.icon, size: 18, color: selected ? mode.color : GarudaColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            mode.label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected ? mode.color : GarudaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Pre-dispatch actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _compareModes,
                      icon: const Icon(Icons.compare_arrows, size: 18),
                      label: const Text('Compare'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: routeState.isLoading ? null : _checkRisk,
                      icon: routeState.isLoading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.shield_outlined, size: 18),
                      label: const Text('Risk Check'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingPrecheck ? null : _runPrecheck,
                      icon: _isLoadingPrecheck
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.security, size: 18),
                      label: const Text('Pre-Dispatch Check'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingBilling ? null : _fetchBillingEstimate,
                      icon: _isLoadingBilling
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.receipt_long, size: 18),
                      label: const Text('Billing Estimate'),
                    ),
                  ),
                ],
              ),

              // Precheck result
              if (_precheckResult != null) ...[
                const SizedBox(height: 12),
                GlassmorphicCard(
                  borderColor: _precheckResult!['safe_to_dispatch'] == true ? GarudaColors.success : GarudaColors.danger,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_precheckResult!['safe_to_dispatch'] == true ? Icons.check_circle : Icons.warning, 
                               color: _precheckResult!['safe_to_dispatch'] == true ? GarudaColors.success : GarudaColors.danger),
                          const SizedBox(width: 8),
                          Text(
                            _precheckResult!['safe_to_dispatch'] == true ? 'Safe to Dispatch' : 'Dispatch Warning',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: GarudaColors.textPrimary),
                          ),
                        ],
                      ),
                      if ((_precheckResult!['alerts'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...(_precheckResult!['alerts'] as List).map((a) => Text(
                          "• ${a['detail']}", 
                          style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.textSecondary)
                        ))
                      ],
                    ],
                  ),
                ),
              ],

              // Billing result
              if (_billingEstimate != null) ...[
                const SizedBox(height: 12),
                GlassmorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estimated Cost', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: GarudaColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(
                        '₹${_billingEstimate!.totalEstimatedCostInr.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: GarudaColors.accent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Base: ₹${_billingEstimate!.breakdown['transport_cost_inr']} | Surcharges: ₹${_billingEstimate!.breakdown['weight_surcharge_inr']} | Carbon Tax: ₹${_billingEstimate!.breakdown['carbon_tax_inr']}',
                        style: GoogleFonts.inter(fontSize: 11, color: GarudaColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],

              // Risk result
              if (routeState.riskAnalysis != null) ...[
                const SizedBox(height: 12),
                GlassmorphicCard(
                  borderColor: routeState.riskAnalysis!.verdict.color.withValues(alpha: 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RiskBadge(
                            verdict: routeState.riskAnalysis!.verdict,
                            score: routeState.riskAnalysis!.riskScore,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => ref.read(routingProvider.notifier).clearRisk(),
                          ),
                        ],
                      ),
                      if (routeState.riskAnalysis!.headsUp != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          routeState.riskAnalysis!.headsUp!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: GarudaColors.textPrimary,
                          ),
                        ),
                      ],
                      if (routeState.riskAnalysis!.contextReason != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          routeState.riskAnalysis!.contextReason!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: GarudaColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Package info
              _sectionTitle('Package Details'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionCtrl,
                style: GoogleFonts.inter(color: GarudaColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                  hintText: 'e.g. Electronics - Laptop',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: GarudaColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.scale_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _consumerEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(color: GarudaColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Consumer Email',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Consumer email required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _logisticsIdCtrl,
                style: GoogleFonts.inter(color: GarudaColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Logistics Partner ID',
                  prefixIcon: Icon(Icons.business_outlined, size: 20),
                ),
              ),

              const SizedBox(height: 24),

              // Submit
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: shipState.isLoading ? null : _createShipment,
                  icon: shipState.isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: const Text('Create Shipment'),
                ),
              ),

              if (shipState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(shipState.error!, style: GoogleFonts.inter(fontSize: 12, color: GarudaColors.danger)),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: GarudaColors.textSecondary,
      ),
    );
  }
}
