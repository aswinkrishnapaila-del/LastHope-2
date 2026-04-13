import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/static_rescue_service.dart';
import '../../../../core/services/hardware_alert_service.dart';
import '../../../contacts/data/contact_model.dart';
import '../../../medical/data/medical_info_model.dart';

/// Shown immediately when SOS is triggered (manual or sensor-based).
/// Displays: flashing banner, live map, alerted contacts, medical summary.
class ActiveEmergencyScreen extends StatefulWidget {
  final RescueResult result;

  const ActiveEmergencyScreen({super.key, required this.result});

  @override
  State<ActiveEmergencyScreen> createState() => _ActiveEmergencyScreenState();
}

class _ActiveEmergencyScreenState extends State<ActiveEmergencyScreen>
    with TickerProviderStateMixin {
  // ── Flash animation ───────────────────────────────────────────────────
  late final AnimationController _flashController;
  late final Animation<Color?> _flashColor;

  // ── Live location update ──────────────────────────────────────────────
  final MapController _mapController = MapController();
  late LatLng _liveLocation;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _liveLocation = widget.result.location;

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _flashColor = ColorTween(
      begin: const Color(0xFFB71C1C),
      end: const Color(0xFFEF9A9A),
    ).animate(_flashController);

    _startLiveLocationTracking();
  }

  void _startLiveLocationTracking() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() => _liveLocation = LatLng(pos.latitude, pos.longitude));
      try {
        _mapController.move(_liveLocation, _mapController.camera.zoom);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _flashController.dispose();
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // ── Flashing Banner ─────────────────────────────────────
            AnimatedBuilder(
              animation: _flashColor,
              builder: (_, child) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: _flashColor.value,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'EMERGENCY CONTACTS ALERTED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Map Section ───────────────────────────────
                    _buildMapSection(),

                    const SizedBox(height: 4),

                    // ── Alerted Contacts ───────────────────────────
                    _buildSection(
                      icon: Icons.people_alt_rounded,
                      title: 'Contacts Alerted',
                      color: Colors.orange,
                      child: _buildContactsList(widget.result.contacts),
                    ),

                    // ── Medical Details ────────────────────────────
                    _buildSection(
                      icon: Icons.medical_services_rounded,
                      title: 'Medical Information',
                      color: Colors.red.shade400,
                      child: _buildMedicalPanel(widget.result.medicalInfo),
                    ),

                    // ── Safe Button ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'I AM SAFE — CANCEL EMERGENCY',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                              HardwareAlertService().stopAlert();
                              Navigator.popUntil(context, (r) => r.isFirst);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Map ──────────────────────────────────────────────────────────────
  Widget _buildMapSection() {
    return Container(
      height: 220,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade900, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _liveLocation,
              initialZoom: 16.0,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lasthope.app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _liveLocation,
                    width: 50,
                    height: 50,
                    child: const _PulsingMarker(),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.my_location, color: Colors.red, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'LIVE LOCATION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  // ── Contacts list ─────────────────────────────────────────────────────
  Widget _buildContactsList(List<Contact> contacts) {
    if (contacts.isEmpty) {
      return _infoTile('No emergency contacts saved.', Colors.grey);
    }
    return Column(
      children: contacts.map((c) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade900,
              child: Text(
                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(c.name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(c.phoneNumber,
                style: const TextStyle(color: Colors.white60)),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'ALERTED',
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Medical panel ─────────────────────────────────────────────────────
  Widget _buildMedicalPanel(MedicalInfo info) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _medRow(Icons.water_drop, 'Blood Type',
              info.bloodType.isNotEmpty ? info.bloodType : 'Unknown',
              Colors.red.shade300),
          _divider(),
          _medRow(Icons.warning_amber, 'Allergies',
              info.allergies.isNotEmpty ? info.allergies : 'None',
              Colors.amber),
          _divider(),
          _medRow(Icons.medication, 'Medications',
              info.medications.isNotEmpty ? info.medications : 'None',
              Colors.blue.shade300),
          _divider(),
          _medRow(Icons.monitor_heart, 'Conditions',
              info.medicalConditions.isNotEmpty ? info.medicalConditions : 'None',
              Colors.purple.shade300),
          _divider(),
          _medRow(Icons.volunteer_activism, 'Organ Donor',
              info.organDonor ? 'YES' : 'NO',
              info.organDonor ? Colors.green : Colors.grey),
        ],
      ),
    );
  }

  Widget _medRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: Color(0xFF2C2C2C), indent: 16);

  Widget _infoTile(String text, Color color) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: TextStyle(color: color)),
      );
}

/// Animated red dot marker.
class _PulsingMarker extends StatefulWidget {
  const _PulsingMarker();

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween(begin: 0.7, end: 1.0).animate(_c);
    _opacity = Tween(begin: 0.4, end: 1.0).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: const Icon(Icons.location_on,
              color: Colors.red, size: 48),
        ),
      ),
    );
  }
}
