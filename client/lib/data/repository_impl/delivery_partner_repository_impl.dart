import 'package:drift/drift.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';

class DeliveryPartnerRepositoryImpl implements DeliveryPartnerRepository {
  final AppDatabase db;

  DeliveryPartnerRepositoryImpl(this.db);

  static const _defaultPartners = <MapEntry<int, String>>[
    MapEntry(1, 'Swiggy'),
    MapEntry(2, 'Zomato'),
    MapEntry(3, 'Dunzo'),
    MapEntry(4, 'Uber Eats'),
    MapEntry(5, 'Rapido'),
  ];

  @override
  Future<List<DeliveryPartner>> getAll() async {
    final list = await db.deliveryPartnersDao.getAll();
    if (list.isEmpty) {
      for (final e in _defaultPartners) {
        await db.deliveryPartnersDao.upsertDeliveryPartner(
          DeliveryPartnersCompanion.insert(id: Value(e.key), name: e.value),
        );
      }
      return db.deliveryPartnersDao.getAll();
    }
    return list;
  }
}
