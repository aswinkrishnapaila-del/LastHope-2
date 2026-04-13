import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class DashboardStarted extends DashboardEvent {}

class UpdateGpsStatus extends DashboardEvent {
  final bool isAccurate;
  const UpdateGpsStatus(this.isAccurate);

  @override
  List<Object> get props => [isAccurate];
}

class ToggleSos extends DashboardEvent {}
