import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/pharmaceutical_usecases.dart';
import 'pharmaceutical_event.dart';
import 'pharmaceutical_state.dart';

class PharmaceuticalBloc extends Bloc<PharmaceuticalEvent, PharmaceuticalState> {
  final GetMedicinesUseCase getMedicinesUseCase;
  final AddMedicineUseCase addMedicineUseCase;

  PharmaceuticalBloc({
    required this.getMedicinesUseCase,
    required this.addMedicineUseCase,
  }) : super(PharmaceuticalInitial()) {
    on<LoadMedicines>(_onLoadMedicines);
    on<AddMedicineEvent>(_onAddMedicine);
  }

  Future<void> _onLoadMedicines(
    LoadMedicines event,
    Emitter<PharmaceuticalState> emit,
  ) async {
    emit(PharmaceuticalLoading());
    final result = await getMedicinesUseCase(NoParams());
    result.fold(
      (failure) => emit(PharmaceuticalError(failure.message)),
      (medicines) => emit(PharmaceuticalLoaded(medicines)),
    );
  }

  Future<void> _onAddMedicine(
    AddMedicineEvent event,
    Emitter<PharmaceuticalState> emit,
  ) async {
    emit(PharmaceuticalLoading());
    final result = await addMedicineUseCase(
      AddMedicineParams(
        name: event.name,
        generic: event.generic,
        category: event.category,
        details: event.details,
      ),
    );
    result.fold(
      (failure) => emit(PharmaceuticalError(failure.message)),
      (_) => add(LoadMedicines()),
    );
  }
}
