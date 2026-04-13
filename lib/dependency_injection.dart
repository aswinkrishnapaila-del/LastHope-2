import 'package:get_it/get_it.dart';
import 'core/services/database_service.dart';
import 'features/connectivity/presentation/connectivity_service.dart';
import 'features/connectivity/mesh_service.dart';
import 'features/contacts/data/contact_service.dart';
import 'features/medical/data/medical_service.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/emergency/data/sensor_repository.dart';
import 'features/emergency/presentation/bloc/emergency_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core Services
  sl.registerLazySingleton(() => DatabaseService());

  // Features - Connectivity
  sl.registerLazySingleton(() => ConnectivityService());
  sl.registerLazySingleton(() => MeshService());

  // Features - Contacts
  sl.registerLazySingleton(() => ContactService());

  // Features - Medical
  sl.registerLazySingleton(() => MedicalService());

  // Features - Dashboard
  sl.registerFactory(() => DashboardBloc());

  // Features - Emergency
  sl.registerLazySingleton(() => SensorRepository());
  sl.registerFactory(() => EmergencyBloc(sl(), sl(), sl(), sl()));

  // Core
  // Register generic use cases or core services if any

  // External
  // Register generic external dependencies like SharedPreferences, etc.
}
