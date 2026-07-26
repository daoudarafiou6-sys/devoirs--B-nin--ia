import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/eleve_model.dart';
import '../theme/app_theme.dart';

/// Écran Admin : accessible uniquement avec un mot de passe.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // TODO: Remplace "MonMotDePasseAdmin" par le mot de passe de ton choix.
  static const String _motDePasseAdmin = 'MonMotDePasseAdmin';

  final TextEditingController _motDePasseController = TextEditingController();
  bool _accesAutorise = false;
  String? _erreurMotDePasse;

  void _verifierMotDePasse() {
    if (_motDePasseController.text == _motDePasseAdmin) {
      setState(() {
        _accesAutorise = true;
        _erreurMotDePasse = null;
      });
    } else {
      setState(() => _erreurMotDePasse = 'Mot de passe incorrect');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_accesAutorise) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accès Admin')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 60, color: BeninColors.vert),
              const SizedBox(height: 20),
              TextField(
                controller: _motDePasseController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe administrateur',
                  errorText: _erreurMotDePasse,
                ),
                onSubmitted: (_) => _verifierMotDePasse(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _verifierMotDePasse,
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    return const _TableauDeBordAdmin();
  }
}

class _TableauDeBordAdmin extends StatelessWidget {
  const _TableauDeBordAdmin();

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord Admin')),
      body: FutureBuilder<Map<String, int>>(
        future: firebaseService.getStatistiquesAdmin(),
        builder: (context, statsSnapshot) {
          if (!statsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = statsSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _carteStatistique(
                      titre: 'Total élèves',
                      valeur: '${stats['nombreTotalEleves']}',
                      couleur: BeninColors.vert,
                      icone: Icons.people,
                    ),
                    const SizedBox(width: 12),
                    _carteStatistique(
                      titre: 'Élèves actifs',
                      valeur: '${stats['nombreElevesActifs']}',
                      couleur: BeninColors.jaune,
                      icone: Icons.check_circle,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _carteStatistique(
                  titre: 'Revenu Mobile Money estimé',
                  valeur: '${stats['revenuTotalFcfa']} FCFA',
                  couleur: BeninColors.rouge,
                  icone: Icons.account_balance_wallet,
                  pleineLargeur: true,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Liste des élèves',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Eleve>>(
                  stream: firebaseService.streamTousLesEleves(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final eleves = snapshot.data!;
                    if (eleves.isEmpty) {
                      return const Text('Aucun élève inscrit pour le moment.');
                    }
                    return Column(
                      children: eleves.map((e) => _ligneEleve(e)).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _carteStatistique({
    required String titre,
    required String valeur,
    required Color couleur,
    required IconData icone,
    bool pleineLargeur = false,
  }) {
    final carte = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: couleur),
          const SizedBox(height: 8),
          Text(titre, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(valeur,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: couleur)),
        ],
      ),
    );

    return pleineLargeur ? carte : Expanded(child: carte);
  }

  Widget _ligneEleve(Eleve eleve) {
    final formatDate = DateFormat('dd/MM/yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                eleve.estEncoreValide ? BeninColors.vert : BeninColors.rouge,
            child: Text(
              eleve.prenom.isNotEmpty ? eleve.prenom[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${eleve.prenom} ${eleve.nom}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${eleve.classe} • ${eleve.college}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Fin abonnement : ${formatDate.format(eleve.dateFinAbonnement)}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: eleve.estEncoreValide
                  ? BeninColors.vert.withOpacity(0.15)
                  : BeninColors.rouge.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              eleve.estEncoreValide ? 'Actif' : 'Expiré',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: eleve.estEncoreValide
                    ? BeninColors.vert
                    : BeninColors.rouge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
