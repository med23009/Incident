import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  String _location = 'Sélectionner un emplacement';
  List<File> _imageFiles = [];
  String? _audioPath;
  FlutterSoundPlayer? _player;
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isPlaying = false;
  bool _isRecording = false;
  Duration? _audioDuration;
  Duration? _audioPosition;
  bool _isRecorderInitialized = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.incident?['title'] ?? '');
    descriptionController = TextEditingController(text: widget.incident?['description'] ?? '');
    _location = widget.incident?['location'] ?? 'Sélectionner un emplacement';
    _initRecorder();
    _player = FlutterSoundPlayer();
    _imageFiles = [];
    if (widget.incident?['image_files'] != null) {
      _imageFiles = List<File>.from(widget.incident!['image_files']);
    }
    if (widget.incident?['audio_file'] != null) {
      _audioPath = widget.incident!['audio_file'];
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    if (_isRecorderInitialized) {
      _recorder.closeRecorder();
    }
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
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return;
    }
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
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
    if (!_isRecorderInitialized) {
      await _initRecorder();
    }
    
    if (!_isRecording) {
      if (!_isRecorderInitialized) return;
      
      // Créer un chemin de fichier temporaire approprié
      final dir = await getTemporaryDirectory();
      final tempPath = '${dir.path}/incident_${DateTime.now().millisecondsSinceEpoch}.aac';
      
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

  void _selectLocation() {
    // Cette fonction sera implémentée pour sélectionner un emplacement
    // Pour l'instant, nous simulons une sélection
    setState(() {
      _location = 'Emplacement sélectionné'; // Ceci serait normalement défini par une carte ou une liste
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.incident == null ? 'Nouvel incident' : 'Modifier incident'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
              ElevatedButton.icon(
                onPressed: _selectLocation,
                icon: const Icon(Icons.location_on),
                label: Text(_location),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  alignment: Alignment.centerLeft,
                ),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave({
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
                'location': _location,
                'image_files': _imageFiles,
                'audio_file': _audioPath,
              });
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Enregistrer'),
        ),
      ),
    );
  }
}
