import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserController extends GetxController {
  final userName = ''.obs;
  final userEmail = ''.obs;

  Future<void> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;
    // Décoder le JWT pour obtenir les infos utilisateur
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = json.decode(payload);
      userEmail.value = payloadMap['email'] ?? '';
      userName.value = payloadMap['username'] ?? '';
    } catch (_) {
      // fallback possible : requête API user profile
    }
  }
}
