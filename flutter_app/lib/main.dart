import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'app.dart';
import 'core/theme/app_theme.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GarudaOverlay(),
    ),
  );
}

class GarudaOverlay extends StatefulWidget {
  const GarudaOverlay({super.key});

  @override
  State<GarudaOverlay> createState() => _GarudaOverlayState();
}

class _GarudaOverlayState extends State<GarudaOverlay> {
  String alertMessage = "Garuda AI Monitoring Route...";
  double severity = 0.0;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event != null && event is Map) {
        setState(() {
          alertMessage = event['message'] ?? alertMessage;
          severity = event['severity'] ?? severity;
          if (severity > 0.5) isExpanded = true; // Auto expand on high risk
        });
      }
    });
  }

  void _bringAppToForeground() {
    FlutterOverlayWindow.shareData({"action": "EXIT_NAVIGATION"});
    FlutterOverlayWindow.closeOverlay();
    // Use an Android Intent to bring the Garuda app to the foreground
    try {
      // url_launcher is not imported in this file directly for background context, but we can just use shareData
      // The user will see the overlay close and Google Maps will still be open. 
      // They can manually switch back, OR we can try opening it via method channel if implemented.
      // Since we just want it to exit navigation, we close the overlay.
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GestureDetector(
            onTap: () => setState(() => isExpanded = true),
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: GarudaColors.surface.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                border: Border.all(color: GarudaColors.warning, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
              ),
              child: const Center(
                child: Icon(Icons.psychology, color: GarudaColors.warning, size: 32),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GarudaColors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GarudaColors.warning, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_rounded, color: GarudaColors.danger, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Route Alert',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: GarudaColors.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => isExpanded = false),
                    child: const Icon(Icons.close, color: GarudaColors.textMuted, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                alertMessage.length > 70 ? '${alertMessage.substring(0, 70)}...' : alertMessage,
                style: GoogleFonts.inter(fontSize: 13, color: GarudaColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _bringAppToForeground,
                    style: TextButton.styleFrom(foregroundColor: GarudaColors.danger, padding: EdgeInsets.zero, minimumSize: const Size(60, 32)),
                    child: const Text('Exit Nav', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      FlutterOverlayWindow.shareData({"action": "REROUTE_ACCEPTED"});
                      setState(() => isExpanded = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GarudaColors.primary, 
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Reroute Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: GarudaApp(),
    ),
  );
}
