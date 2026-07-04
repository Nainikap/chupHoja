import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000';
  //this is for emulator right now change it to render's link

  static Future<Map<String, dynamic>> predict(File, imageFile) async {
    final uri = Uri.parse('$_baseUrl/predict');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () =>
          throw Exception('Request timed out- check if server running'),
    );

    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Server error: ${response.statusCode}: ${response.body}');
    }
  }
}
