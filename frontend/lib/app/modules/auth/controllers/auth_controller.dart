import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:local_auth/local_auth.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final obscurePassword = true.obs;
  final LocalAuthentication auth = LocalAuthentication();

  void toggleObscurePassword() => obscurePassword.value = !obscurePassword.value;

  Future<void> login(String email, String password) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('http://192.168.188.205:8000/api/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      isLoading.value = false;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access'];
        final refreshToken = data['refresh'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        errorMessage.value = '';
        Get.offAllNamed('/home');
      } else {
        final data = jsonDecode(response.body);
        errorMessage.value = data['detail'] ?? 'Erreur de connexion';
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Erreur réseau ou serveur';
    }
  }

  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');
    if (accessToken != null && accessToken.isNotEmpty) {
      // Vérifier si le token est encore valide
      final isValid = await _isTokenValid(accessToken);
      if (isValid) {
        // Optionnel : demander la biométrie
        bool authenticated = true;
        try {
          bool canCheck = await auth.canCheckBiometrics;
          bool isAvailable = await auth.isDeviceSupported();
          if (canCheck && isAvailable) {
            authenticated = await auth.authenticate(
              localizedReason: 'Authentifiez-vous pour continuer',
              options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
            );
          }
        } catch (_) {}
        if (authenticated) {
          Get.offAllNamed('/home');
          return;
        }
      } else if (refreshToken != null && refreshToken.isNotEmpty) {
        // Rafraîchir le token
        final refreshed = await _refreshToken(refreshToken);
        if (refreshed) {
          Get.offAllNamed('/home');
          return;
        }
      }
    }
    // Sinon, rester sur la page de login
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    Get.offAllNamed('/login');
  }

  Future<void> register(String email, String password) async {
    // Validation côté client
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      errorMessage.value = 'Format d\'email invalide';
      return;
    }
    if (password.length < 8) {
      errorMessage.value = 'Le mot de passe doit contenir au moins 8 caractères';
      return;
    }
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('http://192.168.188.205:8000/api/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      isLoading.value = false;
      if (response.statusCode == 201) {
        // Succès : connexion automatique
        errorMessage.value = '';
        await login(email, password);
        Get.snackbar('Inscription réussie', 'Vous êtes maintenant connecté.', snackPosition: SnackPosition.BOTTOM);
      } else {
        final data = jsonDecode(response.body);
        errorMessage.value = data['email']?.join(' ') ?? data['username']?.join(' ') ?? data['password']?.join(' ') ?? 'Erreur lors de l\'inscription';
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Erreur réseau ou serveur';
    }
  }

  Future<bool> _isTokenValid(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = json.decode(payload);
      final exp = payloadMap['exp'];
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expiry);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.188.205:8000/api/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> biometricLogin() async {
    errorMessage.value = '';
    try {
      bool canCheck = await auth.canCheckBiometrics;
      bool isAvailable = await auth.isDeviceSupported();
      if (!canCheck || !isAvailable) {
        errorMessage.value = 'Biométrie non disponible sur cet appareil';
        return;
      }
      bool authenticated = await auth.authenticate(
        localizedReason: 'Veuillez vous authentifier avec votre biométrie',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (authenticated) {
        // Vérifie si un token existe déjà
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('access_token');
        if (accessToken != null && accessToken.isNotEmpty) {
          Get.offAllNamed('/home');
        } else {
          errorMessage.value = 'Veuillez d’abord vous connecter manuellement';
        }
      } else {
        errorMessage.value = 'Authentification biométrique échouée';
      }
    } catch (e) {
      errorMessage.value = 'Erreur biométrique : ${e.toString()}';
    }
  }
}
