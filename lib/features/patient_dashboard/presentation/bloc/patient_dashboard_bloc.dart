import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamro_doctor_mobile/features/patient_dashboard/domain/entities/dashboard_data.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/dashboard_usecases.dart';
import '../../domain/usecases/request_consultation_usecase.dart';
import 'patient_dashboard_event.dart';
import 'patient_dashboard_state.dart';

class PatientDashboardBloc
    extends Bloc<PatientDashboardEvent, PatientDashboardState> {
  final GetDoctorsUseCase getDoctorsUseCase;
  final GetArticlesUseCase getArticlesUseCase;
  final GetLatestHealthRecordUseCase getLatestHealthRecordUseCase;
  final GetConsultationsUseCase getConsultationsUseCase;
  final RequestConsultationUseCase requestConsultationUseCase;

  PatientDashboardBloc({
    required this.getDoctorsUseCase,
    required this.getArticlesUseCase,
    required this.getLatestHealthRecordUseCase,
    required this.getConsultationsUseCase,
    required this.requestConsultationUseCase,
  }) : super(PatientDashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RequestConsultation>(_onRequestConsultation);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<PatientDashboardState> emit,
  ) async {
    emit(PatientDashboardLoading());

    final doctorsResult = await getDoctorsUseCase(NoParams());
    final articlesResult = await getArticlesUseCase(NoParams());
    final recordResult = await getLatestHealthRecordUseCase(NoParams());
    final consultationsResult = await getConsultationsUseCase(NoParams());

    String? errorMessage;

    final doctors = doctorsResult.fold((f) {
      errorMessage = f.message;
      return null;
    }, (d) => d);
    final articles = articlesResult.fold((f) {
      errorMessage = f.message;
      return null;
    }, (a) => a);
    final record = recordResult.fold((f) => null, (r) => r);
    final consultations = consultationsResult.fold(
      (f) => <Consultation>[],
      (c) => c,
    );

    if (doctors != null && articles != null) {
      emit(
        PatientDashboardLoaded(
          doctors: doctors,
          articles: articles,
          latestRecord: record,
          consultations: consultations,
        ),
      );
    } else {
      emit(
        PatientDashboardError(errorMessage ?? 'Failed to load dashboard data'),
      );
    }
  }

  Future<void> _onRequestConsultation(
    RequestConsultation event,
    Emitter<PatientDashboardState> emit,
  ) async {
    final result = await requestConsultationUseCase(event.doctorId);
    result.fold(
      (f) => emit(PatientDashboardError(f.message)),
      (_) => add(LoadDashboardData()), // Refresh dashboard to show pending req
    );
  }
}
