import 'package:pos/domain/models/item_topping_model.dart';
import 'package:pos/domain/models/item_variant_model.dart';

import '../../domain/models/category_model.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/delivery_partner_model.dart';
import '../../domain/models/driver_model.dart';
import '../../domain/models/item_model.dart';
import '../../domain/models/kitchen_model.dart';

class SyncRepository {
  Future<List<DeliveryPartnerModel>> fetchDeliveryPartners(String serverUrl) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      DeliveryPartnerModel(id: 1, name: 'Swiggy'),
      DeliveryPartnerModel(id: 2, name: 'Zomato'),
      DeliveryPartnerModel(id: 3, name: 'Dunzo'),
      DeliveryPartnerModel(id: 4, name: 'Uber Eats'),
      DeliveryPartnerModel(id: 5, name: 'Rapido'),
    ];
  }

  /// Delivery drivers (synced from backend; replace with real API when available).
  Future<List<DriverModel>> fetchDrivers(String serverUrl) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      DriverModel(id: 1, name: 'Driver A'),
      DriverModel(id: 2, name: 'Driver B'),
      DriverModel(id: 3, name: 'Driver C'),
      DriverModel(id: 4, name: 'Driver D'),
    ];
  }

  Future<List<KitchenModel>> fetchKitchens() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      KitchenModel(id: 1, name: "Drinks"),
      KitchenModel(id: 2, name: "Arabian"),
      KitchenModel(id: 3, name: "Bread"),
      KitchenModel(id: 4, name: "Rolls"),
      KitchenModel(id: 5, name: "Grill"),
      KitchenModel(id: 6, name: "Desserts"),
    ];
  }

  Future<List<CategoryModel>> fetchCategories() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      CategoryModel(id: 1, name: "Beverages", otherName: "Drinks"),
      CategoryModel(id: 2, name: "Snacks", otherName: "Fast Food"),
      CategoryModel(id: 3, name: "Bakery", otherName: "Bread"),
      CategoryModel(id: 4, name: "Desserts", otherName: "Sweets"),
      CategoryModel(id: 5, name: "Pizza", otherName: "Italian"),
      CategoryModel(id: 6, name: "Burgers", otherName: "Grill"),
      CategoryModel(id: 7, name: "Sandwiches", otherName: "Subs"),
      CategoryModel(id: 8, name: "Rice Meals", otherName: "Meals"),
      CategoryModel(id: 9, name: "Sea Food", otherName: "Fish"),
      CategoryModel(id: 10, name: "Combos", otherName: "Offers"),
    ];
  }

  Future<List<ItemModel>> fetchItems() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      /// ---------- Beverages ----------
      ItemModel(
        id: 1,
        name: "Coke",
        otherName: "Coca Cola",
        sku: "BEV001",
        price: 40,
        stock: 100,
        imagePath:
            "https://images.unsplash.com/photo-1708651343383-2d52c606d981?q=80&w=522&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 1,
        categoryName: "Beverages",
        categoryOtherName: "Drinks",
        barcode: "1001",
        kitchenId: 1,
        kitchenName: "Drinks",
        variants: [
          ItemVariant(id: 1, name: "Small", price: 30),
          ItemVariant(id: 2, name: "Medium", price: 40),
          ItemVariant(id: 3, name: "Large", price: 50),
        ],
      ),
      ItemModel(
        id: 2,
        name: "Pepsi",
        otherName: "Pepsi",
        sku: "BEV002",
        price: 40,
        stock: 80,
        imagePath:
            "https://images.unsplash.com/photo-1531384370597-8590413be50a?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 1,
        categoryName: "Beverages",
        categoryOtherName: "Drinks",
        barcode: "1002",
        kitchenId: 1,
        kitchenName: "Drinks",
        variants: [
          ItemVariant(id: 1, name: "Small", price: 30),
          ItemVariant(id: 2, name: "Medium", price: 40),
          ItemVariant(id: 3, name: "Large", price: 50),
        ],
      ),
      ItemModel(
        id: 3,
        name: "Sprite",
        otherName: "Sprite",
        sku: "BEV003",
        price: 40,
        stock: 60,
        imagePath:
            "https://images.unsplash.com/photo-1680404005217-a441afdefe83?q=80&w=1964&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 1,
        categoryName: "Beverages",
        categoryOtherName: "Drinks",
        barcode: "1003",
        kitchenId: 1,
        kitchenName: "Drinks",
        variants: [
          ItemVariant(id: 1, name: "Small", price: 30),
          ItemVariant(id: 2, name: "Medium", price: 40),
          ItemVariant(id: 3, name: "Large", price: 50),
        ],
      ),
      ItemModel(
        id: 4,
        name: "Fresh Lime Juice",
        otherName: "Lime",
        sku: "BEV002",
        price: 50,
        stock: 80,
        imagePath: "",
        categoryId: 1,
        categoryName: "Beverages",
        categoryOtherName: "Drinks",
        barcode: "1002",
        kitchenId: 1,
        kitchenName: "Drinks",
        variants: [
          ItemVariant(id: 1, name: "Small", price: 40),
          ItemVariant(id: 2, name: "Medium", price: 50),
          ItemVariant(id: 3, name: "Large", price: 60),
        ],
      ),

      /// ---------- Snacks ----------
      ItemModel(
        id: 5,
        name: "French Fries",
        otherName: "Fries",
        sku: "SNK001",
        price: 90,
        stock: 50,
        imagePath:
            "https://images.unsplash.com/photo-1518013431117-eb1465fa5752?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 2,
        categoryName: "Snacks",
        categoryOtherName: "Fast Food",
        barcode: "2001",
        kitchenId: 2,
        kitchenName: "Arabian",
      ),
      ItemModel(
        id: 6,
        name: "Chicken Nuggets",
        otherName: "Nuggets",
        sku: "SNK002",
        price: 120,
        stock: 40,
        imagePath:
            "https://images.unsplash.com/photo-1562967914-608f82629710?q=80&w=1173&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 2,
        categoryName: "Snacks",
        categoryOtherName: "Fast Food",
        barcode: "2002",
        kitchenId: 2,
        kitchenName: "Arabian",
      ),

      /// ---------- Bakery ----------
      ItemModel(
        id: 7,
        name: "Garlic Bread",
        otherName: "Bread",
        sku: "BAK001",
        price: 110,
        stock: 30,
        imagePath:
            "https://images.unsplash.com/photo-1619531040576-f9416740661b?q=80&w=736&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 3,
        categoryName: "Bakery",
        categoryOtherName: "Bread",
        barcode: "3001",
        kitchenId: 3,
        kitchenName: "Bread",
      ),
      ItemModel(
        id: 8,
        name: "Croissant",
        otherName: "Butter Roll",
        sku: "BAK002",
        price: 80,
        stock: 25,
        imagePath:
            "https://images.unsplash.com/photo-1691480162735-9b91238080f6?q=80&w=880&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 3,
        categoryName: "Bakery",
        categoryOtherName: "Bread",
        barcode: "3002",
        kitchenId: 3,
        kitchenName: "Bread",
      ),

      /// ---------- Desserts ----------
      ItemModel(
        id: 9,
        name: "Chocolate Cake",
        otherName: "Cake",
        sku: "DES001",
        price: 180,
        stock: 20,
        imagePath:
            "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 4,
        categoryName: "Desserts",
        categoryOtherName: "Sweets",
        barcode: "4001",
        kitchenId: 6,
        kitchenName: "Desserts",
      ),
      ItemModel(
        id: 10,
        name: "Ice Cream",
        otherName: "Vanilla",
        sku: "DES002",
        price: 100,
        stock: 35,
        imagePath: "https://media.istockphoto.com/id/1396897706/photo/vanilla-soft-serve-ice-cream-cone.jpg?s=2048x2048&w=is&k=20&c=q_imtzh6iMr8Q7JFFgBpd-hpKlHYiEBn_8t8arlwD1Y=",
        categoryId: 4,
        categoryName: "Desserts",
        categoryOtherName: "Sweets",
        barcode: "4002",
        kitchenId: 6,
        kitchenName: "Desserts",
        toppings: [
          ItemTopping(id: 4, name: "Chocolate Chips", price: 15, maxQty: 3),
          ItemTopping(id: 5, name: "Sprinkles", price: 10, maxQty: 3),
          ItemTopping(id: 6, name: "Caramel Sauce", price: 20),
        ],
      ),

      /// ---------- Pizza ----------
      ItemModel(
        id: 11,
        name: "Margherita Pizza",
        otherName: "Cheese Pizza",
        sku: "PIZ001",
        price: 250,
        stock: 15,
        imagePath:
            "https://images.unsplash.com/photo-1598023696416-0193a0bcd302?q=80&w=1236&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 5,
        categoryName: "Pizza",
        categoryOtherName: "Italian",
        barcode: "5001",
        kitchenId: 2,
        kitchenName: "Arabian",
      ),
      ItemModel(
        id: 12,
        name: "Pepperoni Pizza",
        otherName: "Spicy Pizza",
        sku: "PIZ002",
        price: 320,
        stock: 12,
        imagePath:
            "https://images.unsplash.com/photo-1602658014714-26b99d5a45cf?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 5,
        categoryName: "Pizza",
        categoryOtherName: "Italian",
        barcode: "5002",
        kitchenId: 2,
        kitchenName: "Arabian",
      ),

      /// ---------- Burgers ----------
      ItemModel(
        id: 13,
        name: "Veg Burger",
        otherName: "Veg",
        sku: "BUR001",
        price: 120,
        stock: 25,
        imagePath:
            "https://images.unsplash.com/photo-1520073201527-6b044ba2ca9f?q=80&w=712&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 6,
        categoryName: "Burgers",
        categoryOtherName: "Grill",
        barcode: "6001",
        kitchenId: 5,
        kitchenName: "Grill",
      ),
      ItemModel(
        id: 14,
        name: "Chicken Burger",
        otherName: "Chicken",
        sku: "BUR002",
        price: 150,
        stock: 20,
        imagePath:
            "https://plus.unsplash.com/premium_photo-1683655058728-415f4f2674bf?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 6,
        categoryName: "Burgers",
        categoryOtherName: "Grill",
        barcode: "6002",
        kitchenId: 5,
        kitchenName: "Grill",
      ),

      /// ---------- Sandwiches ----------
      ItemModel(
        id: 15,
        name: "Club Sandwich",
        otherName: "Club",
        sku: "SAN001",
        price: 140,
        stock: 18,
        imagePath:
            "https://plus.unsplash.com/premium_photo-1673809798692-494b974088a4?q=80&w=764&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 7,
        categoryName: "Sandwiches",
        categoryOtherName: "Subs",
        barcode: "7001",
        kitchenId: 4,
        kitchenName: "Rolls",
      ),

      /// ---------- Rice Meals ----------
      ItemModel(
        id: 16,
        name: "Chicken Fried Rice",
        otherName: "Fried Rice",
        sku: "RIC001",
        price: 180,
        stock: 22,
        imagePath:
            "https://images.unsplash.com/photo-1581184953987-5668072c8420?q=80&w=925&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 8,
        categoryName: "Rice Meals",
        categoryOtherName: "Meals",
        barcode: "8001",
        kitchenId: 2,
        kitchenName: "Arabian",
      ),

      /// ---------- Sea Food ----------
      ItemModel(
        id: 17,
        name: "Grilled Fish",
        otherName: "Fish",
        sku: "SEA001",
        price: 260,
        stock: 10,
        imagePath:
            "https://images.unsplash.com/photo-1556814901-18c866c057da?q=80&w=764&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 9,
        categoryName: "Sea Food",
        categoryOtherName: "Fish",
        barcode: "9001",
        kitchenId: 5,
        kitchenName: "Grill",
      ),

      /// ---------- Combos ----------
      ItemModel(
        id: 18,
        name: "Burger + Coke Combo",
        otherName: "Combo",
        sku: "COM001",
        price: 180,
        stock: 15,
        imagePath:
            "https://images.unsplash.com/photo-1700835880296-720183740e32?q=80&w=1171&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        categoryId: 10,
        categoryName: "Combos",
        categoryOtherName: "Offers",
        barcode: "10001",
        kitchenId: 5,
        kitchenName: "Grill",
        variants: [
          ItemVariant(id: 9, name: "Veg", price: 160),
          ItemVariant(id: 10, name: "Chicken", price: 180),
        ],
        toppings: [
          ItemTopping(id: 7, name: "Extra Cheese", price: 25),
          ItemTopping(id: 8, name: "Extra Patty", price: 40),
        ],
      ),
    ];
  }

  Future<List<CustomerModel>> fetchCustomers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      CustomerModel(
        serverId: "1",
        name: "John Doe",
        email: "john@example.com",
        phone: "1234567890",
        gender: "Male",
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isSynced: true,
      ),
      CustomerModel(
        serverId: "2",
        name: "Jane Smith",
        email: "jane@example.com",
        phone: "9876543210",
        gender: "Female",
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isSynced: true,
      ),
      CustomerModel(
        serverId: "3",
        name: "Robert Johnson",
        email: "robert@example.com",
        phone: "5551234567",
        gender: "Male",
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        isSynced: true,
      ),
    ];
  }
}
