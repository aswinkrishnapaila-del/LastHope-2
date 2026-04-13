import 'package:equatable/equatable.dart';

enum DashboardStatus { initial, loading, loaded, failure }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final bool isGpsAccurate;
  final bool isSosActive;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.isGpsAccurate = false,
    this.isSosActive = false,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    bool? isGpsAccurate,
    bool? isSosActive,
  }) {
    return DashboardState(
      status: status ?? this.status,
      isGpsAccurate: isGpsAccurate ?? this.isGpsAccurate,
      isSosActive: isSosActive ?? this.isSosActive,
    );
  }

  @override
  List<Object> get props => [status, isGpsAccurate, isSosActive];
}
