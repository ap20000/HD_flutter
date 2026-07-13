import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/repositories/pharmaceutical_repository.dart';
import '../datasources/pharmaceutical_remote_data_source.dart';

class PharmaceuticalRepositoryImpl implements PharmaceuticalRepository {
  final PharmaceuticalRemoteDataSource remoteDataSource;

  final List<Medicine> _mockMedicines = [
    const Medicine(
      id: 'med_1',
      name: 'Amlodipine Besylate 5mg',
      generic: 'Amlodipine',
      category: 'Antihypertensive',
      manufacturer: 'Deurali-Janta Pharmaceuticals Ltd.',
      formulation: 'Tablet',
      details: 'Calcium channel blocker used to treat high blood pressure and chest pain (angina).',
    ),
    const Medicine(
      id: 'med_2',
      name: 'Metformin Hydrochloride 500mg',
      generic: 'Metformin',
      category: 'Antidiabetic',
      manufacturer: 'Quest Pharmaceuticals Pvt. Ltd.',
      formulation: 'Tablet (Extended Release)',
      details: 'First-line medication for the treatment of type 2 diabetes, particularly in people who are overweight.',
    ),
    const Medicine(
      id: 'med_3',
      name: 'Napa 500mg (Paracetamol)',
      generic: 'Paracetamol / Acetaminophen',
      category: 'Analgesic & Antipyretic',
      manufacturer: 'Beximco Pharmaceuticals Ltd.',
      formulation: 'Tablet',
      details: 'Commonly used medicine to relieve mild to moderate pain and reduce high fever.',
    ),
    const Medicine(
      id: 'med_4',
      name: 'Amoxicillin Trihydrate 250mg',
      generic: 'Amoxicillin',
      category: 'Antibiotic',
      manufacturer: 'Asian Pharmaceuticals Pvt. Ltd.',
      formulation: 'Capsule',
      details: 'Penicillin antibiotic used to treat bacterial infections like chest, ear, and sinus infections.',
    ),
  ];

  PharmaceuticalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Medicine>>> getMedicines() async {
    try {
      final list = await remoteDataSource.getMedicines();
      return Right(list);
    } catch (_) {
      return Right(_mockMedicines);
    }
  }

  @override
  Future<Either<Failure, Medicine>> addMedicine({
    required String name,
    required String generic,
    required String category,
    required String details,
  }) async {
    try {
      final med = await remoteDataSource.addMedicine(
        name: name,
        generic: generic,
        category: category,
        details: details,
      );
      return Right(med);
    } catch (_) {
      final newMed = Medicine(
        id: 'med_${_mockMedicines.length + 1}',
        name: name,
        generic: generic,
        category: category,
        manufacturer: 'My Pharmaceutical Co.',
        formulation: 'Tablet',
        details: details,
      );
      _mockMedicines.insert(0, newMed);
      return Right(newMed);
    }
  }
}
