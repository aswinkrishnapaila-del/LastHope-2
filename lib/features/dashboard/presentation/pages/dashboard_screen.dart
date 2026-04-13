import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/services/static_rescue_service.dart';
import '../../../../dependency_injection.dart' as di;
import '../../../emergency/presentation/bloc/emergency_bloc.dart';
import '../../../emergency/presentation/bloc/emergency_event.dart';
import '../../../emergency/presentation/bloc/emergency_state.dart';
import '../../../emergency/presentation/pages/emergency_screen.dart';
import '../../../emergency/presentation/pages/active_emergency_screen.dart';
import '../../../debug/presentation/pages/debug_screen.dart';
import '../../../contacts/presentation/pages/contacts_screen.dart';
import '../../../medical/presentation/pages/medical_screen.dart';
import '../../../map/presentation/pages/map_screen.dart';
import '../../../settings/presentation/pages/settings_screen.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/sos_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardBloc()..add(DashboardStarted()),
        ),
        BlocProvider(
          create: (context) => di.sl<EmergencyBloc>()..add(StartMonitoring()),
        ),
      ],
      child: BlocListener<EmergencyBloc, EmergencyState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == EmergencyStatus.countdown) {
            // Push sensor-countdown screen; it handles triggered → ActiveEmergency
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<EmergencyBloc>(),
                  child: const EmergencyScreen(),
                ),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppConstants.backgroundBlack,
          appBar: _selectedIndex == 0
              ? AppBar(
                  backgroundColor: AppConstants.backgroundBlack,
                  title: _DebugTitle(),
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.medical_services,
                        color: AppConstants.primaryRed,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MedicalScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.contacts,
                        color: AppConstants.primaryRed,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                )
              : null,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              const _DashboardBody(),
              const MapScreen(),
              const SettingsScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.grey[900],
            selectedItemColor: AppConstants.primaryRed,
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() => _selectedIndex = index);
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  bool _isDispatching = false;

  Future<void> _onSosTap() async {
    if (_isDispatching) return;
    setState(() => _isDispatching = true);

    try {
      final appState = context.read<AppStateProvider>();
      final rescueService = StaticRescueService(appState);
      final result = await rescueService.trigger();

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveEmergencyScreen(result: result),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ SOS sequence error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS triggered! Check dialer and SMS.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) setState(() => _isDispatching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            _buildStatusCard(),
            const Spacer(),
            // ── SOS Button ──────────────────────────────────────────────
            SosButton(
              isDispatching: _isDispatching,
              onTap: _onSosTap,
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _isDispatching ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Alerting emergency contacts...',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const Spacer(),
            // ── Simulate Buttons (Testing only) ─────────────────────────
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isDispatching
                      ? null
                      : () {
                          context.read<EmergencyBloc>().add(
                                const CrashDetected('Simulate Crash Detected'),
                              );
                        },
                  child: const Text('Simulate Crash (5s)'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isDispatching
                      ? null
                      : () {
                          context.read<EmergencyBloc>().add(
                                const CrashDetected('Simulate Fall Detected'),
                              );
                        },
                  child: const Text('Simulate Fall (10s)'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  'GPS Accuracy',
                  state.isGpsAccurate ? 'High' : 'Low',
                  state.isGpsAccurate
                      ? AppConstants.statusGreen
                      : AppConstants.warningOrange,
                ),
                _buildStatusItem(
                  'Mesh Network',
                  'Scanning...',
                  AppConstants.warningOrange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _DebugTitle extends StatefulWidget {
  @override
  State<_DebugTitle> createState() => _DebugTitleState();
}

class _DebugTitleState extends State<_DebugTitle> {
  int _tapCount = 0;
  DateTime? _lastTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        if (_lastTap == null ||
            now.difference(_lastTap!) > const Duration(seconds: 1)) {
          _tapCount = 0;
        }
        _tapCount++;
        _lastTap = now;

        if (_tapCount >= 5) {
          _tapCount = 0;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<EmergencyBloc>(),
                child: const DebugScreen(),
              ),
            ),
          );
        }
      },
      child: const Text(
        'Last Hope',
        style: TextStyle(color: AppConstants.primaryRed),
      ),
    );
  }
}
