import 'package:flutter/material.dart';
import '../models/venta_listado_model.dart';

class EditFacturasRapidasScreen extends StatefulWidget {
  final VentaListadoModel venta;

  const EditFacturasRapidasScreen({
    super.key,
    required this.venta,
  });

  @override
  State<EditFacturasRapidasScreen> createState() =>
      _EditarFacturasRapidasScreenState();
}

class _EditarFacturasRapidasScreenState
    extends State<EditFacturasRapidasScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Editar Factura",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: Text(
          "Editar factura #${widget.venta.idVenta}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}