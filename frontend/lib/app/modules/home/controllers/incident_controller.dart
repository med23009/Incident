import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IncidentController extends GetxController {
  final incidents = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<void> fetchIncidents() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final response = await http.get(
        Uri.parse('http://192.168.188.205:8000/api/incidents/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        incidents.value = data.cast<Map<String, dynamic>>();
      } else {
        errorMessage.value = 'Erreur lors du chargement des incidents';
      }
    } catch (e) {
      errorMessage.value = 'Erreur réseau ou serveur';
    }
    isLoading.value = false;
  }
  Future<void> createIncident(Map<String, dynamic> data) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      var uri = Uri.parse('http://192.168.188.205:8000/api/incidents/');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Conversion du titre en type d'incident (utiliser 'other' par défaut)
      request.fields['type'] = 'other';
      
      // Description de l'incident
      request.fields['description'] = data['description'] ?? '';
      
      // Extraction des coordonnées de localisation
      // Si la localisation est une chaîne, utiliser des coordonnées par défaut
      // Dans une implémentation réelle, ces valeurs seraient extraites d'un service de géolocalisation
      double latitude = 0.0;
      double longitude = 0.0;
      
      if (data['latitude'] != null && data['longitude'] != null) {
        latitude = data['latitude'];
        longitude = data['longitude'];
      }
      
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      
      // Gestion des fichiers image
      if (data['image_files'] != null && data['image_files'] is List) {
        for (var file in data['image_files']) {
          request.files.add(await http.MultipartFile.fromPath('images', file.path));
        }
      }
      
      // Gestion du fichier audio
      if (data['audio_file'] != null) {
        request.files.add(await http.MultipartFile.fromPath('audio_description', data['audio_file']));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        await fetchIncidents();
        errorMessage.value = '';
      } else {
        print('Erreur API: ${response.statusCode} - ${response.body}');
        errorMessage.value = 'Erreur lors de la création de l\'incident: ${response.statusCode}';
      }
    } catch (e) {
      print('Exception: $e');
      errorMessage.value = 'Erreur réseau ou serveur: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateIncident(int index, Map<String, dynamic> data) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final id = incidents[index]['id'];
      var uri = Uri.parse('http://192.168.188.205:8000/api/incidents/$id/');
      var request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = data['title'] ?? '';
      request.fields['description'] = data['description'] ?? '';
      request.fields['location'] = data['location'] ?? '';
      request.fields['status'] = data['status'] ?? '';
      if (data['image_files'] != null && data['image_files'] is List) {
        for (var file in data['image_files']) {
          request.files.add(await http.MultipartFile.fromPath('images', file.path));
        }
      }
      if (data['audio_file'] != null) {
        request.files.add(await http.MultipartFile.fromPath('audio', data['audio_file']));
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        fetchIncidents();
      } else {
        errorMessage.value = 'Erreur lors de la modification de l\'incident';
      }
    } catch (e) {
      errorMessage.value = 'Erreur réseau ou serveur';
    }
    isLoading.value = false;
  }

  Future<void> deleteIncident(int index) async {
      isLoading.value = true;
      errorMessage.value = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        final id = incidents[index]['id'];
        final response = await http.delete(
          Uri.parse('http://192.168.188.205:8000/api/incidents/$id/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 204) {
          incidents.removeAt(index);
          incidents.refresh();
        } else {
          errorMessage.value = 'Erreur lors de la suppression de l\'incident';
        }
      } catch (e) {
        errorMessage.value = 'Erreur réseau ou serveur';
      }
      isLoading.value = false;
    }
  }