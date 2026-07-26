import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'chat_ia_screen.dart';

/// Écran d'inscription de l'élève + paiement Mobile Money (simulé pour le test).
class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _classeController = TextEditingController();
  final _collegeController = TextEditingController();
  final _numeroController = TextEditingController();

  String _operateurChoisi = 'Orange';
  bool _enCoursDeTraitement = false;
  bool _paiementConfirme = false;

  final FirebaseService _firebaseService = FirebaseService();

  final List<String> _operateurs = ['Orange', 'MTN', 'Celtiis'];

  Future<void> _enregistrerEleve() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enCoursDeTraitement = true);

    final numero = _numeroController.text.trim();

    try {
      await _firebaseService.creerEleve(
        id: numero,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        classe: _classeController.text.trim(),
        college: _collegeController.text.trim(),
        numeroMobileMoney: numero,
        operateur: _operateurChoisi,
      );

      setState(() {
        _enCoursDeTraitement = false;
        _paiementConfirme = false;
      });
    } catch (e) {
      setState(() => _enCoursDeTraitement = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'inscription : $e')),
        );
      }
    }
  }

  Future<void> _confirmerPaiementTest() async {
    setState(() => _enCoursDeTraitement = true);
    final numero = _numeroController.text.trim();

    try {
      await _firebaseService.activerAbonnement(numero);
      setState(() {
        _enCoursDeTraitement = false;
        _paiementConfirme = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement confirmé ! Abonnement actif pour 30 jours.'),
            backgroundColor: BeninColors.vert,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatIAScreen(eleveId: numero),
          ),
        );
      }
    } catch (e) {
      setState(() => _enCoursDeTraitement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription - Devoir Bénin IA')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    BeninColors.vert,
                    BeninColors.jaune,
                    BeninColors.rouge,
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Crée ton compte élève',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              _champTexte(_nomController, 'Nom'),
              const SizedBox(height: 14),
              _champTexte(_prenomController, 'Prénom'),
              const SizedBox(height: 14),
              _champTexte(_classeController, 'Classe (ex: 3ème, Terminale D)'),
              const SizedBox(height: 14),
              _champTexte(_collegeController, 'Collège / Lycée'),
              const SizedBox(height: 14),
              _champTexte(
                _numeroController,
                'Numéro Mobile Money',
                clavierNumerique: true,
              ),
              const SizedBox(height: 14),

              const Text('Opérateur Mobile Money',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: _operateurs.map((op) {
                  final selectionne = _operateurChoisi == op;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _operateurChoisi = op),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectionne ? BeninColors.vert : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectionne
                                ? BeninColors.vert
                                : Colors.black12,
                          ),
                        ),
                        child: Text(
                          op,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selectionne ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BeninColors.jaune.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BeninColors.jaune),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: BeninColors.texteFonce),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Abonnement : 100 FCFA / mois, payable par Mobile Money.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (!_paiementConfirme) ...[
                ElevatedButton(
                  onPressed: _enCoursDeTraitement ? null : _enregistrerEleve,
                  child: _enCoursDeTraitement
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("S'inscrire"),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: BeninColors.rouge),
                  onPressed:
                      _enCoursDeTraitement ? null : _confirmerPaiementTest,
                  child: const Text(
                      'Confirmer le paiement (100 FCFA) - TEST'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _champTexte(TextEditingController controller, String label,
      {bool clavierNumerique = false}) {
    return TextFormField(
      controller: controller,
      keyboardType:
          clavierNumerique ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ce champ est obligatoire';
        }
        return null;
      },
    );
  }
}
