import 'package:equatable/equatable.dart';

enum EmergencyStatus { initial, monitoring, countdown, safe, triggered }

class EmergencyState extends Equatable {
  final EmergencyStatus status;
  final String? message;
  final int countdownValue;

  const EmergencyState({
    this.status = EmergencyStatus.initial,
    this.message,
    this.countdownValue = 10,
  });

  EmergencyState copyWith({
    EmergencyStatus? status,
    String? message,
    int? countdownValue,
  }) {
    return EmergencyState(
      status: status ?? this.status,
      message: message ?? this.message,
      countdownValue: countdownValue ?? this.countdownValue,
    );
  }

  @override
  List<Object?> get props => [status, message, countdownValue];
}
