import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import 'inscription_screen.dart';

class _Message {
  final String texte;
  final bool estEleve;
  _Message(this.texte, this.estEleve);
}

/// Écran principal : l'élève pose ses questions (texte ou photo) à l'IA.
class ChatIAScreen extends StatefulWidget {
  final String eleveId;

  const ChatIAScreen({super.key, required this.eleveId});

  @override
  State<ChatIAScreen> createState() => _ChatIAScreenState();
}

class _ChatIAScreenState extends State<ChatIAScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _questionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final List<_Message> _messages = [];
  File? _imageSelectionnee;
  bool _abonnementActif = false;
  bool _chargementStatut = true;
  bool _enAttenteReponse = false;

  @override
  void initState() {
    super.initState();
    _verifierAbonnement();
  }

  Future<void> _verifierAbonnement() async {
    final actif =
        await _firebaseService.verifierEtMettreAJourStatut(widget.eleveId);
    setState(() {
      _abonnementActif = actif;
      _chargementStatut = false;
    });
  }

  Future<void> _choisirImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() => _imageSelectionnee = File(image.path));
    }
  }

  Future<void> _envoyerQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty && _imageSelectionnee == null) return;

    if (!_abonnementActif) {
      setState(() {
        _messages.add(_Message(
          question.isEmpty ? '[Photo envoyée]' : question,
          true,
        ));
        _messages.add(_Message(
          "Renouvelle ton abonnement de 100F par Mobile Money pour recevoir la réponse.",
          false,
        ));
        _questionController.clear();
        _imageSelectionnee = null;
      });
      return;
    }

    setState(() {
      _messages.add(_Message(
        question.isEmpty ? '[Photo envoyée]' : question,
        true,
      ));
      _enAttenteReponse = true;
    });

    final controllerTexte = _questionController.text.trim();
    final image = _imageSelectionnee;
    _questionController.clear();
    setState(() => _imageSelectionnee = null);

    try {
      String reponse;
      if (image != null) {
        final bytes = await image.readAsBytes();
        reponse = await _geminiService.poserQuestionAvecPhoto(
            controllerTexte, bytes);
      } else {
        reponse = await _geminiService.poserQuestionTexte(controllerTexte);
      }

      setState(() {
        _messages.add(_Message(reponse, false));
        _enAttenteReponse = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_Message(
            "Erreur : impossible d'obtenir une réponse pour le moment.",
            false));
        _enAttenteReponse = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargementStatut) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devoir Bénin IA'),
        actions: [
          if (!_abonnementActif)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Renouveler l'abonnement",
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const InscriptionScreen()),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: _abonnementActif
                ? BeninColors.vert.withOpacity(0.15)
                : BeninColors.rouge.withOpacity(0.15),
            child: Text(
              _abonnementActif
                  ? 'Abonnement actif ✅'
                  : 'Abonnement expiré — renouvelle pour 100 FCFA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _abonnementActif ? BeninColors.vert : BeninColors.rouge,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.estEleve
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: msg.estEleve
                          ? BeninColors.vert
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: msg.estEleve
                          ? null
                          : Border.all(color: Colors.black12),
                    ),
                    child: Text(
                      msg.texte,
                      style: TextStyle(
                        color: msg.estEleve ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_enAttenteReponse)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (_imageSelectionnee != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_imageSelectionnee!,
                        height: 60, width: 60, fit: BoxFit.cover),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: BeninColors.rouge),
                    onPressed: () =>
                        setState(() => _imageSelectionnee = null),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_camera,
                      color: BeninColors.vert),
                  onPressed: () => _choisirImage(ImageSource.camera),
                  tooltip: 'Prendre une photo',
                ),
                IconButton(
                  icon: const Icon(Icons.image, color: BeninColors.vert),
                  onPressed: () => _choisirImage(ImageSource.gallery),
                  tooltip: 'Choisir une photo',
                ),
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      hintText: 'Pose ta question ici...',
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: BeninColors.vert),
                  onPressed: _envoyerQuestion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
