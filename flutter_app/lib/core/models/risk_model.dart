import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum RiskVerdict {
  safe('SAFE', 'Safe', GarudaColors.riskSafe, Icons.check_circle),
  caution('CAUTION', 'Caution', GarudaColors.riskCaution, Icons.warning_amber),
  highRisk('HIGH_RISK', 'High Risk', GarudaColors.riskHigh, Icons.dangerous);

  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const RiskVerdict(this.value, this.label, this.color, this.icon);

  static RiskVerdict fromString(String val) {
    return RiskVerdict.values.firstWhere(
      (e) => e.value == val,
      orElse: () => RiskVerdict.safe,
    );
  }
}

class RiskAnalysis {
  final RiskVerdict verdict;
  final double riskScore;
  final String? headsUp;
  final String? contextReason;
  final Map<String, dynamic>? severityBreakdown;
  final String? navigationUrl;
  final String? error;

  RiskAnalysis({
    required this.verdict,
    required this.riskScore,
    this.headsUp,
    this.contextReason,
    this.severityBreakdown,
    this.navigationUrl,
    this.error,
  });

  factory RiskAnalysis.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>? ?? json;
    return RiskAnalysis(
      verdict: RiskVerdict.fromString(json['verdict'] ?? 'SAFE'),
      riskScore: (json['risk_score'] ?? analysis['final_risk_score'] ?? 0).toDouble(),
      headsUp: analysis['heads_up'],
      contextReason: analysis['context_reason'],
      severityBreakdown: analysis['severity_breakdown'],
      navigationUrl: json['navigation_url'],
      error: analysis['error'],
    );
  }

  double get s => (severityBreakdown?['s'] ?? 0).toDouble();
  double get h => (severityBreakdown?['h'] ?? 0).toDouble();
  double get w => (severityBreakdown?['w'] ?? 0).toDouble();
  double get t => (severityBreakdown?['t'] ?? 0).toDouble();
}
