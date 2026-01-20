import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  final String moduleName;

  const ComingSoonScreen({super.key, required this.moduleName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Próximamente'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A), // Tu color oscuro del login
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono animado o estático
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.construction_rounded, size: 60, color: Colors.orange),
            ),
            const SizedBox(height: 30),
            
            const Text(
              '¡Estamos trabajando en ello!',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A)
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            
            Text(
              'El módulo de "$moduleName" se está cocinando.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            
            const Text(
              'El equipo de Urbian está preparando algo increíble para ti.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 50),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0F172A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Volver al Inicio', style: TextStyle(color: Color(0xFF0F172A))),
              ),
            )
          ],
        ),
      ),
    );
  }
}