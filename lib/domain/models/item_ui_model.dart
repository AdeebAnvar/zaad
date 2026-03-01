import 'package:pos/data/local/drift_database.dart';

class ItemUiModel {
  final Item item;
  final List<ItemVariant> variants;
  final List<ItemTopping> toppings;

  ItemUiModel({
    required this.item,
    this.variants = const [],
    this.toppings = const [],
  });

  bool get hasVariants => variants.isNotEmpty;
  bool get hasToppings => toppings.isNotEmpty;
}
