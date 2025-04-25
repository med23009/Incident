import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/incident_controller.dart';
import '../controllers/user_controller.dart';
import 'incident_form_view.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  const AudioPlayerWidget({Key? key, required this.audioUrl}) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  Duration? _duration;
  Duration? _position;

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
    _player.onProgress?.listen((event) {
      setState(() {
        _position = event.position;
        _duration = event.duration;
      });
    });
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _playOrPause() async {
    if (!_isPlaying) {
      await _player.startPlayer(
        fromURI: widget.audioUrl,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _position = _duration;
          });
        },
      );
      setState(() => _isPlaying = true);
    } else {
      await _player.pausePlayer();
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.green, size: 28),
          onPressed: _playOrPause,
        ),
        if (_duration != null)
          Expanded(
            child: Slider(
              value: (_position ?? Duration.zero).inMilliseconds.toDouble(),
              min: 0,
              max: _duration!.inMilliseconds.toDouble(),
              onChanged: (v) async {
                await _player.seekToPlayer(Duration(milliseconds: v.toInt()));
              },
            ),
          ),
        if (_duration != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              _position != null
                  ? _formatDuration(_position!) + ' / ' + _formatDuration(_duration!)
                  : _formatDuration(_duration!),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
      ],
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final IncidentController incidentController;
  late final UserController userController;

  @override
  void initState() {
    super.initState();
    incidentController = Get.put(IncidentController());
    userController = Get.put(UserController());
    incidentController.fetchIncidents();
    userController.fetchUserInfo();
  }

  void _logout() async {
    final controller = Get.find<AuthController>();
    await controller.logout();
  }

  void _openIncidentForm({Map<String, dynamic>? incident, int? index}) {
    // Utiliser Navigator.push pour ouvrir le formulaire comme une page séparée
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IncidentFormView(
          incident: incident,
          onSave: (data) async {
            if (incident == null) {
              // Création
              await incidentController.createIncident(data);
            } else {
              // Modification
              await incidentController.updateIncident(index!, data);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openIncidentForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel incident'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  //backgroundImage: AssetImage('assets/avatar.png'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userController.userEmail.value.isNotEmpty ? userController.userEmail.value : 'Utilisateur',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(userController.userEmail.value.isNotEmpty ? userController.userEmail.value : 'utilisateur@example.com',
                          style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            )),
            const SizedBox(height: 24),
            const Text('Incidents signalés', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (incidentController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (incidentController.errorMessage.value.isNotEmpty) {
                  return Center(child: Text(incidentController.errorMessage.value, style: const TextStyle(color: Colors.red)));
                }
                final incidents = incidentController.incidents;
                if (incidents.isEmpty) {
                  return const Center(child: Text('Aucun incident signalé pour l\'instant.'));
                }
                return ListView.separated(
                  itemCount: incidents.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final incident = incidents[index];
                    return ListTile(
                      leading: incident['image_url'] != null && incident['image_url'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(incident['image_url'], width: 48, height: 48, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.report, color: Colors.orange, size: 40),
                      title: Text(incident['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (incident['description'] != null && incident['description'].toString().isNotEmpty)
                            Text(incident['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (incident['location'] != null && incident['location'].toString().isNotEmpty)
                            Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.blueGrey), SizedBox(width: 2), Text(incident['location'], style: const TextStyle(fontSize: 12))]),
                          Row(
                            children: [
                              Chip(
                                label: Text(incident['status'] ?? 'N/A', style: const TextStyle(fontSize: 12)),
                                backgroundColor: incident['status'] == 'Résolu'
                                    ? Colors.green[200]
                                    : (incident['status'] == 'En cours' ? Colors.orange[200] : Colors.grey[200]),
                              ),
                              const SizedBox(width: 8),
                              Text(incident['date'] ?? '', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (incident['audio_url'] != null && incident['audio_url'].toString().isNotEmpty)
                            SizedBox(width: 180, child: AudioPlayerWidget(audioUrl: incident['audio_url'])),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Modifier',
                            onPressed: () => _openIncidentForm(incident: incident, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Supprimer',
                            onPressed: () => incidentController.deleteIncident(index),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
