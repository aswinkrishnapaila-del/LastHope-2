import 'package:equatable/equatable.dart';

abstract class EmergencyEvent extends Equatable {
  const EmergencyEvent();

  @override
  List<Object> get props => [];
}

class StartMonitoring extends EmergencyEvent {}

class StopMonitoring extends EmergencyEvent {}

class CrashDetected extends EmergencyEvent {
  final String reason;

  const CrashDetected(this.reason);

  @override
  List<Object> get props => [reason];
}

class CancelEmergency extends EmergencyEvent {}

class TriggerEmergencyCall extends EmergencyEvent {}

class ManualSOSPressed extends EmergencyEvent {}

class CountdownTicked extends EmergencyEvent {
  final int secondsRemaining;
  const CountdownTicked(this.secondsRemaining);
  @override
  List<Object> get props => [secondsRemaining];
}
