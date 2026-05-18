import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../patient_dashboard/domain/entities/dashboard_data.dart';
import '../../domain/entities/doctor_dashboard_data.dart';
import '../../domain/usecases/doctor_dashboard_usecases.dart';

// Events
abstract class DoctorDashboardEvent extends Equatable {
  const DoctorDashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDoctorDashboardData extends DoctorDashboardEvent {}
class ToggleOnlineStatus extends DoctorDashboardEvent {
  final bool isOnline;
  const ToggleOnlineStatus(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}

class RespondToRequest extends DoctorDashboardEvent {
  final String id;
  final String status;
  const RespondToRequest(this.id, this.status);
  @override
  List<Object?> get props => [id, status];
}

// States
abstract class DoctorDashboardState extends Equatable {
  const DoctorDashboardState();
  @override
  List<Object?> get props => [];
}

class DoctorDashboardInitial extends DoctorDashboardState {}
class DoctorDashboardLoading extends DoctorDashboardState {}
class DoctorDashboardLoaded extends DoctorDashboardState {
  final DoctorStats stats;
  final List<Workplace> workplaces;
  final List<Consultation> consultations;
  final bool isOnline;

  const DoctorDashboardLoaded({
    required this.stats,
    required this.workplaces,
    required this.consultations,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [stats, workplaces, consultations, isOnline];

  DoctorDashboardLoaded copyWith({
    DoctorStats? stats,
    List<Workplace>? workplaces,
    List<Consultation>? consultations,
    bool? isOnline,
  }) {
    return DoctorDashboardLoaded(
      stats: stats ?? this.stats,
      workplaces: workplaces ?? this.workplaces,
      consultations: consultations ?? this.consultations,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class DoctorDashboardError extends DoctorDashboardState {
  final String message;
  const DoctorDashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class DoctorDashboardBloc extends Bloc<DoctorDashboardEvent, DoctorDashboardState> {
  final GetDoctorStatsUseCase getStatsUseCase;
  final GetDoctorWorkplacesUseCase getWorkplacesUseCase;
  final GetDoctorConsultationsUseCase getConsultationsUseCase;
  final UpdateDoctorStatusUseCase updateStatusUseCase;
  final RespondToConsultationUseCase respondToConsultationUseCase;

  DoctorDashboardBloc({
    required this.getStatsUseCase,
    required this.getWorkplacesUseCase,
    required this.getConsultationsUseCase,
    required this.updateStatusUseCase,
    required this.respondToConsultationUseCase,
  }) : super(DoctorDashboardInitial()) {
    on<LoadDoctorDashboardData>(_onLoadDoctorDashboardData);
    on<ToggleOnlineStatus>(_onToggleOnlineStatus);
    on<RespondToRequest>(_onRespondToRequest);
  }

  Future<void> _onLoadDoctorDashboardData(
    LoadDoctorDashboardData event,
    Emitter<DoctorDashboardState> emit,
  ) async {
    emit(DoctorDashboardLoading());

    final statsRes = await getStatsUseCase(NoParams());
    final workplacesRes = await getWorkplacesUseCase(NoParams());
    final consultationsRes = await getConsultationsUseCase(NoParams());

    String? error;
    final stats = statsRes.fold((f) { error = f.message; return null; }, (s) => s);
    final workplaces = workplacesRes.fold((f) => <Workplace>[], (w) => w);
    final consultations = consultationsRes.fold((f) => <Consultation>[], (c) => c);

    if (stats != null) {
      emit(DoctorDashboardLoaded(
        stats: stats,
        workplaces: workplaces,
        consultations: consultations,
        isOnline: true, // Defaulting for now, will be updated by ToggleOnlineStatus or user profile
      ));
    } else {
      emit(DoctorDashboardError(error ?? 'Failed to load dashboard'));
    }
  }

  Future<void> _onToggleOnlineStatus(
    ToggleOnlineStatus event,
    Emitter<DoctorDashboardState> emit,
  ) async {
    if (state is DoctorDashboardLoaded) {
      final currentState = state as DoctorDashboardLoaded;
      final result = await updateStatusUseCase(event.isOnline);
      
      result.fold(
        (failure) => null, // Handle failure if needed, e.g., show a snackbar
        (isOnline) => emit(currentState.copyWith(isOnline: isOnline)),
      );
    }
  }

  Future<void> _onRespondToRequest(
    RespondToRequest event,
    Emitter<DoctorDashboardState> emit,
  ) async {
    final result = await respondToConsultationUseCase(
      RespondParams(id: event.id, status: event.status),
    );
    result.fold(
      (f) => emit(DoctorDashboardError(f.message)),
      (_) => add(LoadDoctorDashboardData()), // Refresh to update list
    );
  }
}
