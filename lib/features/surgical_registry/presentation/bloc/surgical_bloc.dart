import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/surgical_usecases.dart';
import 'surgical_event.dart';
import 'surgical_state.dart';

class SurgicalBloc extends Bloc<SurgicalEvent, SurgicalState> {
  final GetSurgicalLogsUseCase getSurgicalLogsUseCase;
  final AddSurgicalLogUseCase addSurgicalLogUseCase;

  SurgicalBloc({
    required this.getSurgicalLogsUseCase,
    required this.addSurgicalLogUseCase,
  }) : super(SurgicalInitial()) {
    on<LoadSurgicalLogs>(_onLoadSurgicalLogs);
    on<AddSurgicalLogEvent>(_onAddSurgicalLog);
  }

  Future<void> _onLoadSurgicalLogs(
    LoadSurgicalLogs event,
    Emitter<SurgicalState> emit,
  ) async {
    emit(SurgicalLoading());
    final result = await getSurgicalLogsUseCase(NoParams());
    result.fold(
      (failure) => emit(SurgicalError(failure.message)),
      (logs) => emit(SurgicalLoaded(logs)),
    );
  }

  Future<void> _onAddSurgicalLog(
    AddSurgicalLogEvent event,
    Emitter<SurgicalState> emit,
  ) async {
    emit(SurgicalLoading());
    final result = await addSurgicalLogUseCase(
      AddSurgicalLogParams(
        procedure: event.procedure,
        hospital: event.hospital,
        surgeon: event.surgeon,
        notes: event.notes,
      ),
    );
    result.fold(
      (failure) => emit(SurgicalError(failure.message)),
      (_) => add(LoadSurgicalLogs()),
    );
  }
}
