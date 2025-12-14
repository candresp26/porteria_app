import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    // Inicializamos el controlador aquí
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el ancho de la pantalla para ajustar el pad si es necesario
    final double width = MediaQuery.of(context).size.width * 0.8; // 80% del ancho

    return AlertDialog(
      title: const Text("Firma de Recibido"),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Hace que el diálogo no ocupe toda la pantalla
        children: [
          const Text("Por favor firme en el recuadro:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          
          // 🔥 CORRECCIÓN AQUÍ:
          // Usamos SizedBox para OBLIGAR al widget a tener tamaño.
          // Sin esto, dentro de un Column, la firma colapsa a tamaño 0.
          SizedBox(
            width: width,
            height: 200, 
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                color: Colors.white,
              ),
              child: Signature(
                controller: _controller,
                height: 200, // Altura explícita
                width: width, // Ancho explícito
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _controller.clear();
          },
          child: const Text("Borrar", style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_controller.isNotEmpty) {
              final Uint8List? data = await _controller.toPngBytes();
              if (mounted) Navigator.pop(context, data);
            } else {
              // Si intenta confirmar sin firmar, le avisamos
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Debe firmar para continuar"))
              );
            }
          },
          child: const Text("Confirmar"),
        ),
      ],
    );
  }
}