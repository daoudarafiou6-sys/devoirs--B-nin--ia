import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'inscription_screen.dart';
import 'admin_screen.dart';

/// Premier écran affiché au lancement de l'app.
/// Permet de choisir entre l'espace Élève et l'espace Admin.
class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 8,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  gradient: LinearGradient(colors: [
                    BeninColors.vert,
                    BeninColors.jaune,
                    BeninColors.rouge,
                  ]),
                ),
              ),
              const SizedBox(height: 32),
              const Icon(Icons.school, size: 90, color: BeninColors.vert),
              const SizedBox(height: 16),
              const Text(
                'Devoir Bénin IA',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "L'aide aux devoirs par intelligence artificielle,\n"
                "de la 6ème à la Terminale.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text("Je suis élève"),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InscriptionScreen()),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.admin_panel_settings,
                    color: BeninColors.rouge),
                label: const Text("Espace Administrateur",
                    style: TextStyle(color: BeninColors.rouge)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: BeninColors.rouge),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
