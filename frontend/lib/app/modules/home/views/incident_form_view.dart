import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class IncidentFormView extends StatefulWidget {
  final Map<String, dynamic>? incident;
  final void Function(Map<String, dynamic> incident) onSave;
  const IncidentFormView({Key? key, this.incident, required this.onSave}) : super(key: key);

  @override
  State<IncidentFormView> createState() => _IncidentFormViewState();
}

class _IncidentFormViewState extends State<IncidentFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  String status = 'Nouveau';
  List<File> _imageFiles = [];
  String? _audioPath;
  FlutterSoundPlayer? _player;
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isPlaying = false;
  bool _isRecording = false;
  Duration? _audioDuration;
  Duration? _audioPosition;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.incident?['title'] ?? '');
    descriptionController = TextEditingController(text: widget.incident?['description'] ?? '');
    locationController = TextEditingController(text: widget.incident?['location'] ?? '');
    status = widget.incident?['status'] ?? 'Nouveau';
    _initRecorder();
    _player = FlutterSoundPlayer();
    _imageFiles = [];
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    _recorder.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }

  Future<void> _playOrPauseAudio() async {
    if (_audioPath == null) return;
    if (!_isPlaying) {
      await _player!.openPlayer();
      await _player!.startPlayer(
        fromURI: _audioPath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _audioPosition = _audioDuration;
          });
        },
      );
      _player!.onProgress!.listen((event) {
        setState(() {
          _audioPosition = event.position;
          _audioDuration = event.duration;
        });
      });
      setState(() => _isPlaying = true);
    } else {
      await _player!.pausePlayer();
      setState(() => _isPlaying = false);
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  void _removeImage(int idx) {
    setState(() {
      _imageFiles.removeAt(idx);
    });
  }

  Future<void> _startOrStopRecording() async {
    if (!_isRecording) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;
      final tempPath = '/tmp/incident_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(toFile: tempPath);
      setState(() {
        _isRecording = true;
      });
    } else {
      final path = await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
    }
  }

  void _deleteAudio() {
    setState(() {
      _audioPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.incident == null ? 'Nouvel incident' : 'Modifier incident'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (v) => v == null || v.isEmpty ? 'Titre requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Description requise' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Localisation'),
                validator: (v) => v == null || v.isEmpty ? 'Localisation requise' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: const [
                  DropdownMenuItem(value: 'Nouveau', child: Text('Nouveau')),
                  DropdownMenuItem(value: 'En cours', child: Text('En cours')),
                  DropdownMenuItem(value: 'Résolu', child: Text('Résolu')),
                ],
                onChanged: (v) => setState(() => status = v ?? 'Nouveau'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.collections),
                    label: const Text('Ajouter des images'),
                  ),
                  const SizedBox(width: 8),
                  if (_imageFiles.isNotEmpty)
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageFiles.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) => Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_imageFiles[idx], width: 54, height: 54, fit: BoxFit.cover),
                              ),
                              GestureDetector(
                                onTap: () => _removeImage(idx),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _startOrStopRecording,
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    label: Text(_isRecording ? 'Arrêter' : 'Ajouter un vocal'),
                  ),
                  if (_audioPath != null && !_isRecording)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.blue, size: 28),
                          tooltip: _isPlaying ? 'Pause' : 'Écouter le vocal',
                          onPressed: _playOrPauseAudio,
                        ),
                        if (_audioDuration != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              _audioPosition != null
                                  ? _formatDuration(_audioPosition!) + ' / ' + _formatDuration(_audioDuration!)
                                  : _formatDuration(_audioDuration!),
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                          tooltip: 'Supprimer le vocal',
                          onPressed: _deleteAudio,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave({
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
                'location': locationController.text.trim(),
                'status': status,
                'image_files': _imageFiles,
                'audio_file': _audioPath,
              });
              Navigator.of(context).pop();
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
