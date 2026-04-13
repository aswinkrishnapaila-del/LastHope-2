import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/sms_service.dart';
import '../../../../core/services/cloud_rescue_service.dart';
import '../../../connectivity/presentation/connectivity_service.dart';
import '../../../contacts/data/contact_service.dart';
import '../../../medical/data/medical_service.dart';
import '../../data/sensor_repository.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/hardware_alert_service.dart';
import 'emergency_event.dart';
import 'emergency_state.dart';

class EmergencyBloc extends Bloc<EmergencyEvent, EmergencyState> {
  final SensorRepository _sensorRepository;
  final ConnectivityService _connectivityService;
  final ContactService _contactService;
  final MedicalService _medicalService;

  StreamSubscription<String>? _crashSubscription;
  Timer? _countdownTimer;

  /// Lock that prevents a second sensor event from overriding an active countdown.
  bool _isEmergencyActive = false;

  EmergencyBloc(
    this._sensorRepository,
    this._connectivityService,
    this._contactService,
    this._medicalService,
  ) : super(const EmergencyState()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<StopMonitoring>(_onStopMonitoring);
    on<CrashDetected>(_onCrashDetected);
    on<CancelEmergency>(_onCancelEmergency);
    on<TriggerEmergencyCall>(_onTriggerEmergencyCall);
    on<ManualSOSPressed>(_onManualSOSPressed);
    on<CountdownTicked>(_onCountdownTicked);
  }

  void _onManualSOSPressed(
    ManualSOSPressed event,
    Emitter<EmergencyState> emit,
  ) {
    emit(
      state.copyWith(
        status: EmergencyStatus.countdown,
        message: "MANUAL SOS!",
        countdownValue: 5,
      ),
    );
    _startCountdown();
  }

  void _onCountdownTicked(CountdownTicked event, Emitter<EmergencyState> emit) {
    if (event.secondsRemaining <= 0) {
      add(TriggerEmergencyCall());
    } else {
      emit(state.copyWith(countdownValue: event.secondsRemaining));
    }
  }

  void _onStartMonitoring(StartMonitoring event, Emitter<EmergencyState> emit) {
    _sensorRepository.startMonitoring();
    _crashSubscription?.cancel();
    _crashSubscription = _sensorRepository.crashStream.listen((reason) {
      add(CrashDetected(reason));
    });
    emit(
      state.copyWith(
        status: EmergencyStatus.monitoring,
        message: "Monitoring Active",
      ),
    );
  }

  void _onStopMonitoring(StopMonitoring event, Emitter<EmergencyState> emit) {
    _sensorRepository.stopMonitoring();
    _crashSubscription?.cancel();
    emit(
      state.copyWith(
        status: EmergencyStatus.initial,
        message: "Monitoring Stopped",
      ),
    );
  }

  void _onCrashDetected(CrashDetected event, Emitter<EmergencyState> emit) {
    // ── SENSOR LOCK: ignore all events once countdown is already running ──
    if (_isEmergencyActive) {
      debugPrint('🔒 Sensor event ignored — emergency already active: ${event.reason}');
      return;
    }
    _isEmergencyActive = true;
    
    final int timerLength = event.reason.toLowerCase().contains('fall') ? 10 : 5;
    
    emit(
      state.copyWith(
        status: EmergencyStatus.countdown,
        message: event.reason,
        countdownValue: timerLength,
      ),
    );
    _startCountdown();
  }

  void _onCancelEmergency(CancelEmergency event, Emitter<EmergencyState> emit) {
    _countdownTimer?.cancel();
    _isEmergencyActive = false; // release lock so sensors fire again
    
    // Stop ringing and flashing
    HardwareAlertService().stopAlert();

    emit(
      state.copyWith(
        status: EmergencyStatus.safe,
        message: 'Emergency Cancelled - User Safe',
        countdownValue: 0,
      ),
    );
    // Resume monitoring after cancel
    add(StartMonitoring());
  }

  Future<void> _onTriggerEmergencyCall(
    TriggerEmergencyCall event,
    Emitter<EmergencyState> emit,
  ) async {
    _countdownTimer?.cancel();

    // 1. Get Location
    Position? position;
    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
      position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } catch (e) {
      debugPrint("Location Error: $e");
    }

    final lat = position?.latitude ?? 0.0;
    final lng = position?.longitude ?? 0.0;
    final mapLink = "https://maps.google.com/?q=$lat,$lng";

    // 2. Fetch Data
    final contacts = await _contactService.getContacts().first;
    final medicalInfo = await _medicalService.getMedicalInfo();

    final isSimulation = state.message?.startsWith('Simulate') ?? false;

    // 3. Construct Message
    String message = isSimulation
        ? "TEST MESSAGE: This is a simulated emergency from LastHope. No real emergency is happening. Location: $mapLink"
        : "Emergency is detected come to this location asap: $mapLink";

    // 4. Send SMS to Contacts (Local Fallback & Cloud Trigger concurrently)
    if (contacts.isNotEmpty) {
      List<String> recipients = contacts.map((c) => c.phoneNumber).toList();

      // 4a. Fire off Cloud SOS via FastAPI Backend
      // This service fetches location/medical/contacts again to be fully decoupled and robust.
      // We don't await this so it doesn't block the local SMS fallback
      CloudRescueService().triggerCloudSOS();

      // 4b. Local Fallback (Direct SMS)
      await sendSMS(message: message, recipients: recipients);

      // 4c. Auto-dial the first emergency contact or starred contact and start Hardware Alarm
      if (!isSimulation) {
        HardwareAlertService().startAlert();

        final prefs = await SharedPreferences.getInstance();
        final starredId = prefs.getString('starred_contact_id');
        
        String phoneToCall = recipients.first;
        if (starredId != null) {
          final starredContact = contacts.firstWhere(
            (c) => c.id == starredId, 
            orElse: () => contacts.first,
          );
          if (starredContact.phoneNumber.isNotEmpty) {
             phoneToCall = starredContact.phoneNumber;
          }
        }
        
        await autoDial(phoneToCall);
      }
    }

    // 5. Send WebSocket Payload
    List<String> contactNumbers = contacts.map((c) => c.phoneNumber).toList();

    _connectivityService.sendSos({
      "lat": lat,
      "lng": lng,
      "user_id": "user_123", // Placeholder
      "user_name": medicalInfo.bloodType.isNotEmpty
          ? "User (${medicalInfo.bloodType})"
          : "User",
      "timestamp": DateTime.now().toIso8601String(),
      "type": "CRASH",
      "contacts": contactNumbers,
    });

    emit(state.copyWith(status: EmergencyStatus.triggered));
    _isEmergencyActive = false; // release lock after trigger completes
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    int currentCount = state.countdownValue;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      currentCount--;
      add(CountdownTicked(currentCount));
      if (currentCount <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  Future<void> close() {
    _crashSubscription?.cancel();
    _countdownTimer?.cancel();
    // Do not dispose _sensorRepository here as it is a singleton managed by GetIt
    return super.close();
  }
}
