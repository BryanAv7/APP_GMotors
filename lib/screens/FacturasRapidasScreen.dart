import 'package:flutter/material.dart';
import '../models/venta_create_model.dart';
import '../models/detalle_venta_createDTO.dart';
import '../models/detalle_ui.dart';
import '../services/venta_service.dart';
import '../utils/token_manager.dart';
import '../screens/HistorialFacturasRapidasScreen.dart';
import '../screens/seleccionar_productos_page.dart';

class FacturasRapidasScreen extends StatefulWidget {
  const FacturasRapidasScreen({super.key});

  @override
  State<FacturasRapidasScreen> createState() => _FacturasRapidasScreenState();
}

class _FacturasRapidasScreenState extends State<FacturasRapidasScreen> {
  final _formKey = GlobalKey<FormState>();
  bool intentoGuardar = false;

  // CLIENTE RÁPIDO
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController cedulaCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();
  final TextEditingController direccionCtrl = TextEditingController();
  final TextEditingController correoCtrl = TextEditingController();
  final TextEditingController observacionesCtrl = TextEditingController();

  // PRODUCTOS
  List<DetalleUI> productos = [];

  @override
  void dispose() {
    nombreCtrl.dispose();
    cedulaCtrl.dispose();
    telefonoCtrl.dispose();
    direccionCtrl.dispose();
    correoCtrl.dispose();
    observacionesCtrl.dispose();
    super.dispose();
  }

  double get total => productos.fold(0, (s, p) => s + p.subtotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        title: const Text(
          "Factura Rápida",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _limpiar,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionTitle("Información del Cliente", Icons.person),
              const SizedBox(height: 12),
              _clienteFields(),

              const SizedBox(height: 20),

              _buildSectionTitle("Productos y Repuestos", Icons.shopping_cart),
              const SizedBox(height: 12),
              _productosBox(),

              const SizedBox(height: 20),

              _buildSectionTitle("Observaciones", Icons.note),
              const SizedBox(height: 12),
              _observaciones(),

              const SizedBox(height: 20),


              const SizedBox(height: 30),

              _guardarButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFFD700)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  _clienteFields() {
    return Column(
      children: [
        _input(nombreCtrl, "Nombre Cliente", Icons.person, "nombre"),
        const SizedBox(height: 10),

        _input(cedulaCtrl, "Cédula/RUC", Icons.badge, "cedula"),
        const SizedBox(height: 10),

        _input(telefonoCtrl, "Teléfono", Icons.phone, "telefono"),
        const SizedBox(height: 10),

        _input(direccionCtrl, "Dirección", Icons.home, "direccion"),
        const SizedBox(height: 10),

        _input(correoCtrl, "Correo", Icons.email, "correo"),
      ],
    );
  }

  Widget _input(
      TextEditingController ctrl,
      String label,
      IconData icon,
      String type,
      ) {
    String? validator(String? v) {
      final value = v?.trim() ?? "";

      if (type == "nombre") {
        return null;
      }

      // Cédula 10-13
      if (type == "cedula" && value.isNotEmpty) {
        if (!RegExp(r'^\d{10,13}$').hasMatch(value)) {
          return "Cédula/RUC debe tener 10 a 13 dígitos";
        }
      }

      // Teléfono 7-10
      if (type == "telefono" && value.isNotEmpty) {
        if (!RegExp(r'^\d{7,10}$').hasMatch(value)) {
          return "Teléfono inválido (7-10 dígitos)";
        }
      }

      // Correo válido
      if (type == "correo" && value.isNotEmpty) {
        final email = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!email.hasMatch(value)) {
          return "Correo inválido";
        }
      }

      return null;
    }

    return Container(
      decoration: _boxDecoration(),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(10),
        ),
      ),
    );
  }

  Widget _productosBox() {
    final bool hayProductos = productos.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeleccionarProductosPage(
              detallesIniciales: productos,
            ),
          ),
        );

        if (result != null && result is List<DetalleUI>) {
          setState(() {
            productos = List.from(result);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hayProductos
                ? const Color(0xFFFFD700).withOpacity(0.5)
                : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Color(0xFFFFD700),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      hayProductos
                          ? "Productos (${productos.length})"
                          : "Seleccionar productos",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFFD700),
                  size: 16,
                ),
              ],
            ),

            // TOTAL
            if (hayProductos) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total:",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "\$${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _observaciones() {
    return Container(
      decoration: _boxDecoration(),
      child: TextField(
        controller: observacionesCtrl,
        maxLines: 3,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "Información adicional",
          hintStyle: TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(10),
        ),
      ),
    );
  }

  Widget _totalBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD700)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "TOTAL",
            style: TextStyle(color: Colors.white),
          ),
          Text(
            "\$${total.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _guardarButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
        ),
        onPressed: _guardar,
        child: const Text(
          "Guardar Factura",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold,),
        ),
      ),
    );
  }


  BoxDecoration _boxDecoration({Color borderColor = Colors.white24}) {
    return BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor),
    );
  }

  // ================= LOGICA =================

  void _limpiar() {
    nombreCtrl.clear();
    cedulaCtrl.clear();
    telefonoCtrl.clear();
    direccionCtrl.clear();
    correoCtrl.clear();
    observacionesCtrl.clear();
    setState(() => productos = []);
  }

  Future<void> _guardar() async {
    setState(() => intentoGuardar = true);

    if (!_formKey.currentState!.validate()) return;
    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Agregue productos")),
      );
      return;
    }

    try {
      final user = await TokenManager.getUserJson();

      final venta = VentaCreateModel(
        nombre: nombreCtrl.text,
        cedula: cedulaCtrl.text,
        telefono: telefonoCtrl.text,
        direccion: direccionCtrl.text,
        correo: correoCtrl.text,
        idUsuarioVendedor: user?['id_usuario'],
        observaciones: observacionesCtrl.text,
        detalles: productos
            .map((p) => DetalleVentaCreateDTO(
          idProducto: p.idProducto,
          descripcion: p.nombre,
          cantidad: p.cantidad,
          precioUnitario: p.precioUnitario,
        ))
            .toList(),
      );

      final res = await VentaService.crearVenta(venta);

      if (res != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HistorialFacturasRapidasScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}