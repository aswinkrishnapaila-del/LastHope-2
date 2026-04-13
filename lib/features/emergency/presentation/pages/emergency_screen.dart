import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/services/static_rescue_service.dart';
import '../bloc/emergency_bloc.dart';
import '../bloc/emergency_event.dart';
import '../bloc/emergency_state.dart';
import 'active_emergency_screen.dart';

/// Shown after a sensor (crash/fall) triggers a countdown.
/// Displays the countdown timer and an "I AM SAFE" cancel button.
/// When the countdown reaches 0 the Bloc emits triggered → navigate out.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmergencyBloc, EmergencyState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == EmergencyStatus.safe) {
          // User cancelled — pop back to dashboard
          Navigator.of(context).popUntil((r) => r.isFirst);
        } else if (state.status == EmergencyStatus.triggered) {
          // Countdown finished — fire rescue and show active screen
          final appState = context.read<AppStateProvider>();
          final rescueService = StaticRescueService(appState);
          Navigator.of(context).popUntil((r) => r.isFirst);
          rescueService.trigger(reason: state.message).then((result) {
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ActiveEmergencyScreen(result: result),
                ),
              );
            }
          });
        }
      },
      builder: (context, state) {
        final count = state.countdownValue;
        // Colour shifts red → white as countdown decreases
        final urgency = count <= 3 ? Colors.white : Colors.white70;

        return Scaffold(
          backgroundColor: AppConstants.primaryRed,
          body: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),

                  // Reason (e.g. "Fall Detected" / "Hard Crash Detected")
                  Text(
                    state.message ?? 'EMERGENCY!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SOS activating...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 40),

                  // Countdown number
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      color: urgency,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    count == 1 ? '1 second remaining' : '$count seconds remaining',
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),

                  const SizedBox(height: 60),

                  // Cancel button
                  SizedBox(
                    width: 220,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 22),
                      label: const Text(
                        'I AM SAFE',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context.read<EmergencyBloc>().add(CancelEmergency());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
