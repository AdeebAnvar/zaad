import 'package:pos/data/local/drift_database.dart';

abstract class DeliveryPartnerRepository {
  Future<List<DeliveryPartner>> getAll();
}
