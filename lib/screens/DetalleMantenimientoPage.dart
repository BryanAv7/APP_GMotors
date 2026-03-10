import 'package:flutter/material.dart';
import '../models/RegistroDetalleDTO.dart';
import '../models/detalle_ui.dart';
import '../models/Tipo.dart';
import '../services/registros_service.dart';
import '../services/tipo_service.dart';
import '../screens/seleccionar_productos_page.dart';

class DetalleMantenimientoPage extends StatefulWidget {
  final int idRegistro;

  const DetalleMantenimientoPage({
    super.key,
    required this.idRegistro,
  });

  @override
  State<DetalleMantenimientoPage> createState() =>
      _DetalleMantenimientoPageState();
}

class _DetalleMantenimientoPageState extends State<DetalleMantenimientoPage> {
  late Future<RegistroDetalleDTO> futureDetalle;
  List<DetalleUI> detallesSeleccionados = [];
  List<Tipo> tiposMantenimiento = [];
  bool guardando = false;
  bool intentoGuardar = false;
  final _formKey = GlobalKey<FormState>();
  int? idTipoSeleccionado;
  int? estadoSeleccionado; // 🆕 NUEVO: Variable para el estado
  final TextEditingController observacionesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarTipos();
    _cargarRegistro();
    _cargarTodoEnOrden();
  }

  Future<void> _cargarTipos() async {
    try {
      final tipos = await TipoService.obtenerTodos();
      setState(() {
        tiposMantenimiento = tipos;
      });
    } catch (e) {
      print('Error al cargar tipos: $e');
    }
  }

  Future<void> _cargarTodoEnOrden() async {
    await _cargarTipos();    // espera a que tipos estén listos
    await _cargarRegistro(); // luego carga el registro
  }

  Future<void> _cargarRegistro() async {
    futureDetalle = RegistrosService.obtenerDetalle(widget.idRegistro);

    try {
      final detalle = await futureDetalle;

      // Cargar observaciones
      if (detalle.descripcion != null) {
        setState(() {
          observacionesCtrl.text = detalle.descripcion!;
        });
      }

      // Buscar el ID del tipo por su nombre
      int? idTipo;
      if (detalle.tipoMantenimiento != null && tiposMantenimiento.isNotEmpty) {
        try {
          final tipoEncontrado = tiposMantenimiento.firstWhere(
                (tipo) => tipo.nombre == detalle.tipoMantenimiento,
          );
          idTipo = tipoEncontrado.idTipo;
        } catch (e) {
          print('Tipo no encontrado: $e');
        }
      }

      setState(() {
        idTipoSeleccionado = idTipo;
        estadoSeleccionado = detalle.estado;
      });

      if (detalle.idFactura != null) {
        final detalles = await RegistrosService.obtenerDetallesFactura(
          detalle.idFactura!,
        );

        setState(() {
          detallesSeleccionados = detalles
              .map((d) => DetalleUI(
            idProducto: d.idProducto,
            nombre: d.descripcion ?? '',
            cantidad: d.cantidad ?? 0,
            precioUnitario: d.precioUnitario ?? 0,
            esProducto: true,
          ))
              .toSet()
              .toList();
        });
      }
    } catch (e) {
      print('Error al cargar detalles: $e');
    }
  }

  @override
  void dispose() {
    observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Actualizar Mantenimiento",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<RegistroDetalleDTO>(
        future: futureDetalle,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final d = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              autovalidateMode: intentoGuardar
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(d),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Información del Cliente', Icons.person),
                  const SizedBox(height: 12),
                  _buildClienteInfo(d),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Vehículo', Icons.motorcycle),
                  const SizedBox(height: 12),
                  _buildVehiculoInfo(d),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Tipo de Servicio', Icons.build),
                  const SizedBox(height: 12),
                  _buildTipoInfo(),
                  const SizedBox(height: 20),

                  // 🆕 NUEVO BLOQUE: Estado del Mantenimiento
                  _buildSectionTitle('Estado del Mantenimiento', Icons.flag),
                  const SizedBox(height: 12),
                  _buildEstadoSelector(),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Productos y Repuestos', Icons.shopping_cart),
                  const SizedBox(height: 12),
                  _productsBox(),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Observaciones', Icons.note_alt),
                  const SizedBox(height: 12),
                  _buildObservacionesField(),
                  const SizedBox(height: 32),

                  _buildGuardarButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(RegistroDetalleDTO d) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFFD700).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem(
            icon: Icons.calendar_today,
            label: 'Fecha',
            value: d.fecha,
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white24,
          ),
          _buildInfoItem(
            icon: Icons.tag,
            label: 'ID Registro',
            value: '#${d.idRegistro.toString().padLeft(8, '0')}',
          )
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFFD700),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
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

  Widget _buildClienteInfo(RegistroDetalleDTO d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: const Color(0xFFFFD700),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.nombreCliente ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculoInfo(RegistroDetalleDTO d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.motorcycle,
            color: const Color(0xFFFFD700),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.marcaMoto ?? 'N/A'} ${d.modeloMoto ?? ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vehículo',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoInfo() {
    if (tiposMantenimiento.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
    }

    final tipoActual = tiposMantenimiento
        .where((t) => t.idTipo == idTipoSeleccionado)
        .map((t) => t.nombre)
        .firstOrNull ?? '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: idTipoSeleccionado != null
              ? const Color(0xFFFFD700).withOpacity(0.5)
              : Colors.white24,
          width: 1.5,
        ),
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Tipo de mantenimiento",
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.build_circle,
            color: idTipoSeleccionado != null
                ? const Color(0xFFFFD700)
                : Colors.white54,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        child: Text(
          tipoActual,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  // 🆕 NUEVO WIDGET: Selector de Estado con Chips
  Widget _buildEstadoSelector() {
    final bool error = intentoGuardar && estadoSeleccionado == null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error
              ? Colors.red.withOpacity(0.8)
              : estadoSeleccionado != null
              ? _getColorEstado(estadoSeleccionado!).withOpacity(0.5)
              : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Seleccione el estado del mantenimiento',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildChipEstado(1, 'En Proceso', Colors.blue),
              _buildChipEstado(2, 'Finalizado', Colors.green),
              ///Descomentar si empieza Logica de "Reserva"
              ///_buildChipEstado(3, 'Reservado', Colors.orange),
            ],
          ),
          if (error) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Debe seleccionar un estado',
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 NUEVO WIDGET: Chip individual de estado
  Widget _buildChipEstado(int valor, String texto, Color color) {
    final bool seleccionado = estadoSeleccionado == valor;

    return GestureDetector(
      onTap: () => setState(() => estadoSeleccionado = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? color : const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? color : Colors.white24,
            width: 2,
          ),
          boxShadow: seleccionado
              ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (seleccionado) ...[
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              texto,
              style: TextStyle(
                color: seleccionado ? Colors.white : Colors.white70,
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 NUEVO HELPER: Obtener color según estado
  Color _getColorEstado(int estado) {
    switch (estado) {
      case 1:
        return Colors.blue; // En Proceso
      case 2:
        return Colors.green; // Finalizado
      case 3:
        return Colors.orange; // Reservado
      default:
        return Colors.white24;
    }
  }

  Widget _productsBox() {
    final bool hayDetalles = detallesSeleccionados.isNotEmpty;
    final bool error = intentoGuardar && !hayDetalles;

    return GestureDetector(
      onTap: () async {
        final resultado = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeleccionarProductosPage(
              detallesIniciales: detallesSeleccionados,
            ),
          ),
        );

        if (resultado != null && resultado is List<DetalleUI>) {
          setState(() {
            detallesSeleccionados = resultado;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: error
                ? Colors.red.withOpacity(0.8)
                : hayDetalles
                ? const Color(0xFFFFD700).withOpacity(0.5)
                : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      child: Icon(
                        hayDetalles ? Icons.check_circle : Icons.edit,
                        color: const Color(0xFFFFD700),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      hayDetalles
                          ? "Productos (${detallesSeleccionados.length})"
                          : "Editar productos",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFFFFD700),
                  size: 16,
                ),
              ],
            ),
            if (hayDetalles) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total:",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "\$${_calcularTotal().toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (error) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Debe seleccionar al menos un producto',
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildObservacionesField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: TextField(
        controller: observacionesCtrl,
        maxLines: 5,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: "Observaciones adicionales",
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
          hintText: "Describe los detalles del servicio...",
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 14,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(bottom: 60),
            child: Icon(Icons.description, color: Colors.white54),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildGuardarButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: guardando ? null : _validarAntesDeGuardar,
        child: guardando
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        )
            : const Text(
          "Actualizar",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🔄 MODIFICADO: Validación incluye estado
  void _validarAntesDeGuardar() {
    setState(() => intentoGuardar = true);

    if (estadoSeleccionado == null) {
      _mostrarError("Debe seleccionar un estado");
      return;
    }

    if (detallesSeleccionados.isEmpty) {
      _mostrarError("Debe seleccionar al menos un producto");
      return;
    }

    if (idTipoSeleccionado == null) {
      _mostrarError("Debe seleccionar un tipo de mantenimiento");
      return;
    }

    _actualizarMantenimiento();
  }

  // 🔄 MODIFICADO: Ahora actualiza estado Y factura
  Future<void> _actualizarMantenimiento() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(
                color: Color(0xFFFFD700),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                'Actualizando...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      setState(() => guardando = true);

      // 1️⃣ PRIMERO: Actualizar el estado
      print('[DetalleMantenimiento] Actualizando estado a: $estadoSeleccionado');

      final resultadoEstado = await RegistrosService.actualizarEstado(
        widget.idRegistro,
        estadoSeleccionado!,
        observaciones: observacionesCtrl.text.trim(),
      );

      if (resultadoEstado == null || resultadoEstado['success'] != true) {
        throw Exception(
            resultadoEstado?['error'] ?? 'Error al actualizar estado'
        );
      }

      print('[DetalleMantenimiento] Estado actualizado exitosamente');

      // 2️⃣ SEGUNDO: Actualizar la factura con los detalles
      final detallesJSON = detallesSeleccionados
          .map((detalle) => {
        "idProducto": detalle.idProducto,
        "descripcion": detalle.nombre,
        "cantidad": detalle.cantidad,
        "precioUnitario": detalle.precioUnitario,
      })
          .toList();

      print('[DetalleMantenimiento] Actualizando factura con ${detallesJSON.length} productos');

      final resultadoFactura = await RegistrosService.actualizarFactura(
        widget.idRegistro,
        detallesJSON,
      );

      Navigator.pop(context); // Cerrar loading dialog

      if (resultadoFactura != null && resultadoFactura['success'] == true) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mantenimiento actualizado exitosamente',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Volver a la pantalla anterior
        Navigator.pop(context, true);
      } else {
        _mostrarError(resultadoFactura?['error'] ?? "Error al actualizar factura");
      }
    } catch (e) {
      Navigator.pop(context); // Cerrar loading dialog
      print('[DetalleMantenimiento] Error: $e');
      _mostrarError("Error: ${e.toString()}");
    } finally {
      setState(() => guardando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  double _calcularTotal() {
    return detallesSeleccionados.fold(
      0.0,
          (sum, detalle) => sum + detalle.subtotal,
    );
  }
}