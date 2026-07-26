import 'package:cloud_firestore/cloud_firestore.dart';

/// Représente un élève inscrit dans l'application.
/// Correspond exactement à un document dans la collection Firestore "eleves".
class Eleve {
  final String id; // ID du document Firestore (souvent = numéro Mobile Money)
  final String nom;
  final String prenom;
  final String classe; // ex: "3ème", "Terminale D"
  final String college;
  final String numeroMobileMoney;
  final String operateur; // "Orange", "MTN" ou "Celtiis"
  final DateTime dateFinAbonnement;
  final bool statutActif;
  final DateTime dateInscription;

  Eleve({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.classe,
    required this.college,
    required this.numeroMobileMoney,
    required this.operateur,
    required this.dateFinAbonnement,
    required this.statutActif,
    required this.dateInscription,
  });

  /// Convertit l'objet Dart en Map pour l'enregistrer dans Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'classe': classe,
      'college': college,
      'numeroMobileMoney': numeroMobileMoney,
      'operateur': operateur,
      'dateFinAbonnement': Timestamp.fromDate(dateFinAbonnement),
      'statutActif': statutActif,
      'dateInscription': Timestamp.fromDate(dateInscription),
    };
  }

  /// Construit un objet Eleve à partir d'un document Firestore.
  factory Eleve.fromMap(String id, Map<String, dynamic> map) {
    return Eleve(
      id: id,
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      classe: map['classe'] ?? '',
      college: map['college'] ?? '',
      numeroMobileMoney: map['numeroMobileMoney'] ?? '',
      operateur: map['operateur'] ?? '',
      dateFinAbonnement: (map['dateFinAbonnement'] as Timestamp).toDate(),
      statutActif: map['statutActif'] ?? false,
      dateInscription: (map['dateInscription'] as Timestamp).toDate(),
    );
  }

  /// Calcule dynamiquement si l'abonnement est encore valide aujourd'hui.
  bool get estEncoreValide => DateTime.now().isBefore(dateFinAbonnement);
}
