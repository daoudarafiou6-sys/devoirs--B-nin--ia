import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/eleve_model.dart';

/// Centralise toutes les opérations Firestore de l'application.
/// Collection utilisée : "eleves"
class FirebaseService {
  final CollectionReference _eleves =
      FirebaseFirestore.instance.collection('eleves');

  /// Prix de l'abonnement mensuel en Francs CFA.
  static const int prixAbonnementFcfa = 100;

  /// Crée un nouvel élève dans Firestore.
  Future<void> creerEleve({
    required String id,
    required String nom,
    required String prenom,
    required String classe,
    required String college,
    required String numeroMobileMoney,
    required String operateur,
  }) async {
    final maintenant = DateTime.now();
    final eleve = Eleve(
      id: id,
      nom: nom,
      prenom: prenom,
      classe: classe,
      college: college,
      numeroMobileMoney: numeroMobileMoney,
      operateur: operateur,
      dateFinAbonnement: maintenant,
      statutActif: false,
      dateInscription: maintenant,
    );
    await _eleves.doc(id).set(eleve.toMap());
  }

  /// Active (ou renouvelle) l'abonnement de l'élève pour 30 jours.
  Future<void> activerAbonnement(String eleveId) async {
    final nouvelleDateFin = DateTime.now().add(const Duration(days: 30));
    await _eleves.doc(eleveId).update({
      'statutActif': true,
      'dateFinAbonnement': Timestamp.fromDate(nouvelleDateFin),
    });
  }

  /// Récupère un élève par son ID (numéro Mobile Money).
  Future<Eleve?> getEleve(String eleveId) async {
    final doc = await _eleves.doc(eleveId).get();
    if (!doc.exists) return null;
    return Eleve.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Vérifie si l'abonnement d'un élève est réellement actif.
  Future<bool> verifierEtMettreAJourStatut(String eleveId) async {
    final eleve = await getEleve(eleveId);
    if (eleve == null) return false;

    final estValide = eleve.estEncoreValide;
    if (estValide != eleve.statutActif) {
      await _eleves.doc(eleveId).update({'statutActif': estValide});
    }
    return estValide;
  }

  /// Flux temps réel de la liste de tous les élèves (pour l'écran Admin).
  Stream<List<Eleve>> streamTousLesEleves() {
    return _eleves.orderBy('dateInscription', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Eleve.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  /// Calcule les statistiques globales pour le tableau de bord admin.
  Future<Map<String, int>> getStatistiquesAdmin() async {
    final snapshot = await _eleves.get();
    final tousLesEleves = snapshot.docs
        .map((doc) => Eleve.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    final nombreTotalEleves = tousLesEleves.length;
    final nombreElevesActifs =
        tousLesEleves.where((e) => e.estEncoreValide).length;
    final revenuTotalFcfa = nombreElevesActifs * prixAbonnementFcfa;

    return {
      'nombreTotalEleves': nombreTotalEleves,
      'nombreElevesActifs': nombreElevesActifs,
      'revenuTotalFcfa': revenuTotalFcfa,
    };
  }
}
