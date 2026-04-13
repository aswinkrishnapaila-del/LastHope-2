import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(const DashboardState()) {
    on<DashboardStarted>(_onDashboardStarted);
    on<UpdateGpsStatus>(_onUpdateGpsStatus);
    on<ToggleSos>(_onToggleSos);
  }

  void _onDashboardStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) {
    // Simulate initial checks
    emit(state.copyWith(status: DashboardStatus.loaded, isGpsAccurate: true));
  }

  void _onUpdateGpsStatus(UpdateGpsStatus event, Emitter<DashboardState> emit) {
    emit(state.copyWith(isGpsAccurate: event.isAccurate));
  }

  void _onToggleSos(ToggleSos event, Emitter<DashboardState> emit) {
    emit(state.copyWith(isSosActive: !state.isSosActive));
  }
}
