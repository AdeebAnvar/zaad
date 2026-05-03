import 'package:pos/data/local/drift_database.dart';

abstract class DriverRepository {
  Future<List<Driver>> getAll();
}
