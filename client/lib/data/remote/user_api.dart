import 'dart:convert';
import 'package:http/http.dart' as http;

class UserApi {
  final String baseUrl;
  UserApi(this.baseUrl);

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final url = Uri.parse("$baseUrl/users");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }

    throw Exception("Unable to fetch users");
  }
}
