import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service responsable de l'appel à l'API Gemini (Google AI).
///
/// IMPORTANT SÉCURITÉ :
/// Ne mets jamais ta vraie clé API directement dans le code source
/// si l'app est publiée publiquement. Pour un vrai lancement, passe
/// par un petit serveur relais (Cloud Function) qui garde la clé
/// secrète côté serveur. Pour le développement/test, tu peux la
/// mettre ici temporairement.
class GeminiService {
  // TODO: Remplace par ta vraie clé API Gemini (https://aistudio.google.com/apikey)
  static const String _apiKey = 'METS_TA_CLE_API_GEMINI_ICI';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Envoie une question texte à Gemini et retourne la réponse expliquée.
  Future<String> poserQuestionTexte(String question) async {
    final prompt = '''
Tu es un professeur béninois qui aide un élève avec ses devoirs.
Réponds en français, de façon claire, simple et pédagogique,
avec des explications étape par étape adaptées à un élève du collège ou du lycée.

Question de l'élève : $question
''';

    return _appelerGemini(prompt);
  }

  /// Envoie une question accompagnée d'une photo à Gemini.
  Future<String> poserQuestionAvecPhoto(
      String question, List<int> imageBytes) async {
    final imageBase64 = base64Encode(imageBytes);

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Tu es un professeur béninois. Explique et résous cet exercice "
                  "en français, étape par étape, de façon simple. "
                  "Question de l'élève : $question"
            },
            {
              "inline_data": {"mime_type": "image/jpeg", "data": imageBase64}
            }
          ]
        }
      ]
    });

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return _extraireReponse(response);
  }

  /// Fonction interne pour l'appel texte simple.
  Future<String> _appelerGemini(String prompt) async {
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return _extraireReponse(response);
  }

  /// Extrait le texte de la réponse JSON de Gemini.
  String _extraireReponse(http.Response response) {
    if (response.statusCode != 200) {
      return "Erreur : impossible de contacter l'IA pour le moment. "
          "Vérifie ta connexion internet et réessaie.";
    }
    try {
      final data = jsonDecode(response.body);
      final texte = data['candidates'][0]['content']['parts'][0]['text'];
      return texte as String;
    } catch (e) {
      return "Erreur : la réponse de l'IA n'a pas pu être lue.";
    }
  }
}
