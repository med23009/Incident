import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
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
      print('Token utilisé pour POST incident: $token');

      final dioClient = dio.Dio();
      final String url = 'http://192.168.188.205:8000/api/incidents/';

      // Prépare le FormData
      dio.FormData formData = dio.FormData.fromMap({
        'type': data['type'] ?? 'other',
        'description': data['description'] ?? '',
        'latitude': data['latitude']?.toString() ?? '0.0',
        'longitude': data['longitude']?.toString() ?? '0.0',
      });

      // Ajout des images
      if (data['image_files'] != null && data['image_files'] is List) {
        for (var file in data['image_files']) {
          formData.files.add(MapEntry(
            'images',
            await dio.MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
          ));
        }
      }
      // Ajout de l'audio
      if (data['audio_file'] != null) {
        formData.files.add(MapEntry(
          'audio_description',
          await dio.MultipartFile.fromFile(data['audio_file'], filename: data['audio_file'].split('/').last),
        ));
      }

      final response = await dioClient.post(
        url,
        data: formData,
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 201) {
        await fetchIncidents();
        errorMessage.value = '';
      } else {
        print('Erreur API: ${response.statusCode} - ${response.data}');
        String backendError = '';
        try {
          if (response.data is Map && response.data.isNotEmpty) {
            backendError = response.data.values.first.toString();
          }
        } catch (_) {}
        errorMessage.value = backendError.isNotEmpty
            ? 'Erreur lors de la création de l\'incident : $backendError'
            : 'Erreur lors de la création de l\'incident: ${response.statusCode}';
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