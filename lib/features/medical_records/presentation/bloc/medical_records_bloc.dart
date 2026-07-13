import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/medical_records_usecases.dart';
import 'medical_records_event.dart';
import 'medical_records_state.dart';

class MedicalRecordsBloc extends Bloc<MedicalRecordsEvent, MedicalRecordsState> {
  final GetMedicalRecordsUseCase getMedicalRecordsUseCase;
  final UploadMedicalRecordUseCase uploadMedicalRecordUseCase;
  final ShareMedicalRecordUseCase shareMedicalRecordUseCase;

  MedicalRecordsBloc({
    required this.getMedicalRecordsUseCase,
    required this.uploadMedicalRecordUseCase,
    required this.shareMedicalRecordUseCase,
  }) : super(MedicalRecordsInitial()) {
    on<LoadMedicalRecords>(_onLoadMedicalRecords);
    on<UploadMedicalRecordEvent>(_onUploadMedicalRecord);
    on<ShareMedicalRecordEvent>(_onShareMedicalRecord);
  }

  Future<void> _onLoadMedicalRecords(
    LoadMedicalRecords event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(MedicalRecordsLoading());
    final result = await getMedicalRecordsUseCase(NoParams());
    result.fold(
      (failure) => emit(MedicalRecordsError(failure.message)),
      (records) => emit(MedicalRecordsLoaded(records)),
    );
  }

  Future<void> _onUploadMedicalRecord(
    UploadMedicalRecordEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(MedicalRecordsLoading());
    final result = await uploadMedicalRecordUseCase(
      UploadParams(
        title: event.title,
        recordType: event.recordType,
        fileUrl: event.fileUrl,
      ),
    );
    result.fold(
      (failure) => emit(MedicalRecordsError(failure.message)),
      (_) => add(LoadMedicalRecords()),
    );
  }

  Future<void> _onShareMedicalRecord(
    ShareMedicalRecordEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(MedicalRecordsLoading());
    final result = await shareMedicalRecordUseCase(
      ShareParams(
        recordId: event.recordId,
        doctorId: event.doctorId,
        durationInHours: event.durationInHours,
      ),
    );
    result.fold(
      (failure) => emit(MedicalRecordsError(failure.message)),
      (_) => add(LoadMedicalRecords()),
    );
  }
}
