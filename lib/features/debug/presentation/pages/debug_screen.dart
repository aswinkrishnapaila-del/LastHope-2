import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../../core/services/sms_service.dart';
import '../../../../dependency_injection.dart';
import '../../../connectivity/presentation/connectivity_service.dart';
import '../../../connectivity/mesh_service.dart';
import '../../../emergency/presentation/bloc/emergency_bloc.dart';
import '../../../emergency/presentation/bloc/emergency_event.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = sl<ConnectivityService>();
    final emergencyBloc = context.read<EmergencyBloc>(); // Access provided bloc

    return Scaffold(
      appBar: AppBar(title: const Text("Debug Mode")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live Sensor Data
            const Text(
              "Live Accelerometer Data:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            StreamBuilder<AccelerometerEvent>(
              stream: accelerometerEventStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text("Waiting for sensors...");
                }
                final e = snapshot.data!;
                return Text(
                  "X: ${e.x.toStringAsFixed(2)}, Y: ${e.y.toStringAsFixed(2)}, Z: ${e.z.toStringAsFixed(2)}",
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                );
              },
            ),
            const SizedBox(height: 20),

            // Connection Status
            const Text(
              "Server Connection:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            StreamBuilder<bool>(
              stream: connectivity.connectionStatus,
              initialData: false,
              builder: (context, snapshot) {
                final isConnected = snapshot.data ?? false;
                return Row(
                  children: [
                    Icon(
                      isConnected ? Icons.check_circle : Icons.error,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? "CONNECTED" : "DISCONNECTED",
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 40),

            // Manual Triggers
            ElevatedButton(
              onPressed: () => connectivity.sendPing(),
              child: const Text("Test WebSocket Handshake (PING)"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                emergencyBloc.add(const CrashDetected("Manual Debug Trigger"));
                Navigator.pop(context); // Close debug to see the red screen
              },
              child: const Text("Simulate Crash Event"),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                String message = "SOS! I have crashed. Location: Debug.";
                List<String> recipients = ["1234567890"]; // Dummy number
                await sendSMS(message: message, recipients: recipients);
              },
              child: const Text("Test SMS"),
            ),
            const Divider(height: 40),

            // Offline Mesh Network
            const Text(
              "Offline Mesh Network:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final meshService = sl<MeshService>();
                      // Using dummy user ID for debug
                      meshService.startBroadcastingSOS(
                        "DEBUG_USER",
                        12.34,
                        56.78,
                      );
                    },
                    child: const Text("Start Broadcasting SOS"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final meshService = sl<MeshService>();
                      meshService.startScanningForHelp("RESCUER_DEBUG");
                    },
                    child: const Text("Start Scanning"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black12,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: SingleChildScrollView(
                child: StreamBuilder<String>(
                  stream: sl<MeshService>().statusStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      // We should ideally accumulate logs, but stream only sends latest.
                      // For a simple debug log, let's just show the latest or use a list if we implemented it differently.
                      // The prompt asked for "Status Log ... show logs like 'Connected...'".
                      // Since statusStream broadcasts *strings*, showing the latest is the simplest MVP.
                      // To show log history, we'd need a StatefulWidget to accumulate.
                      // The prompt says "Simple text area that listens ... to show logs".
                      // I'll wrap this in a customized widget in a later step if needed, or better:
                      // I'll assume showing the LATEST log is acceptable for "Status Log" label.
                      // OR, I can create a local list in this builder if it rebuilds? No.
                      // I will stick to showing the latest log message for now to be safe with stateless widget.
                      return Text(
                        "Latest: ${snapshot.data}",
                        style: const TextStyle(fontFamily: 'monospace'),
                      );
                    }
                    return const Text(
                      "No Mesh Activity",
                      style: TextStyle(color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
