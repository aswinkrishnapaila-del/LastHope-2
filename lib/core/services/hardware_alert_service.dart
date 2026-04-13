import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:volume_controller/volume_controller.dart';

class HardwareAlertService {
  static final HardwareAlertService _instance = HardwareAlertService._internal();
  factory HardwareAlertService() => _instance;
  HardwareAlertService._internal();

  Timer? _strobeTimer;
  bool _isTorchOn = false;
  double? _previousVolume;

  Future<void> startAlert() async {
    debugPrint("🚨 HardwareAlertService: Starting Alarm & Strobe");

    // Maximize volume
    try {
      _previousVolume = await VolumeController.instance.getVolume();
      VolumeController.instance.setVolume(1.0);
    } catch (e) {
      debugPrint("Warning: VolumeController failed: $e");
    }

    // Play Ringtone/Alarm on loop
    try {
      FlutterRingtonePlayer().playAlarm(
        looping: true,
        volume: 1.0,
      );
    } catch (e) {
      debugPrint("Warning: Ringtone player failed: $e");
    }

    // Start strobe light
    _startStrobe();
  }

  void _startStrobe() async {
    _strobeTimer?.cancel();
    bool hasTorch = false;
    try {
      hasTorch = await TorchLight.isTorchAvailable();
    } catch (e) {
      debugPrint("Torch availability check failed: $e");
    }

    if (hasTorch) {
      _strobeTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        try {
          if (_isTorchOn) {
            await TorchLight.disableTorch();
            _isTorchOn = false;
          } else {
            await TorchLight.enableTorch();
            _isTorchOn = true;
          }
        } catch (e) {
          debugPrint("Strobe toggle failed: $e");
        }
      });
    }
  }

  Future<void> stopAlert() async {
    debugPrint("🛑 HardwareAlertService: Stopping Alarm & Strobe");
    
    // Stop Ringtone
    FlutterRingtonePlayer().stop();

    // Revert volume
    if (_previousVolume != null) {
      try {
        VolumeController.instance.setVolume(_previousVolume!);
      } catch (e) {
        debugPrint("Warning: Failed to revert volume: $e");
      }
    }

    // Stop and Reset flashlight
    _strobeTimer?.cancel();
    _strobeTimer = null;
    
    if (_isTorchOn) {
      try {
        await TorchLight.disableTorch();
        _isTorchOn = false;
      } catch (e) {
        debugPrint("Warning: Failed to disable torch on stop: $e");
      }
    }
  }
}
