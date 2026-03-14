import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/delivery_partner_model.dart';

class SyncApi {
  final String baseUrl;

  SyncApi(this.baseUrl);

  /// Fetches delivery partners from server.
  /// Expected endpoint: GET $baseUrl/api/delivery-partners
  /// Expected response: [{ "id": 1, "name": "Swiggy" }, ...]
  Future<List<DeliveryPartnerModel>> fetchDeliveryPartners() async {
    if (baseUrl.isEmpty) return [];

    final uri = Uri.parse('$baseUrl/api/delivery-partners');
    final res = await http.get(uri);

    if (res.statusCode != 200) return [];

    final list = jsonDecode(res.body);
    if (list is! List) return [];

    return list
        .map((e) => DeliveryPartnerModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
