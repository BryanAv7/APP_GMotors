import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/usuario.dart';
import '../models/moto.dart';
import '../models/Tipo.dart';
import '../models/detalle_ui.dart';
import '../screens/BuscarUsuarioPage.dart';
import '../services/moto_service.dart';
import '../services/tipo_service.dart';
import '../services/registros_service.dart';
import '../screens/seleccionar_productos_page.dart';
import '../utils/token_manager.dart';

class AgregarMantenimientoPage extends StatefulWidget {
  const AgregarMantenimientoPage({super.key});

  @override
  State<AgregarMantenimientoPage> createState() =>
      _AgregarMantenimientoPageState();
}

class _AgregarMantenimientoPageState extends State<AgregarMantenimientoPage> {
  // ---------------- FORM ----------------
  final _formKey = GlobalKey<FormState>();
  bool intentoGuardar = false;

  // ---------------- CONTROLLERS ----------------
  final TextEditingController clienteCtrl = TextEditingController();
  final TextEditingController vehiculoCtrl = TextEditingController();
  final TextEditingController descripcionCtrl = TextEditingController();

  // ---------------- DATA ----------------
  int? idClienteSeleccionado;
  int? idTipoSeleccionado;
  List<DetalleUI> detallesSeleccionados = [];

  // VEHÍCULO ----------------
  int? idMotoSeleccionada;
  List<Moto> motosCliente = [];
  bool cargandoMotos = false;

  // TIPOS ----------------
  List<Tipo> tiposMantenimiento = [];
  bool cargandoTipos = false;

  // NÚMERO DE REGISTRO
  int numeroRegistroSiguiente = 0;
  bool cargandoNumeroRegistro = true;

  // OCR
  final ImagePicker _picker = ImagePicker();
  bool procesandoOCR = false;

  // BÚSQUEDA
  bool clienteSeleccionadoPorOCR = false;

  @override
  void initState() {
    super.initState();
    _cargarTipos();
    _cargarNumeroRegistro();
  }

  Future<void> _cargarNumeroRegistro() async {
    try {
      final registros = await RegistrosService.listarRegistros();
      setState(() {
        numeroRegistroSiguiente = registros.length + 1;
        cargandoNumeroRegistro = false;
      });
    } catch (e) {
      print('Error al obtener número de registro: $e');
      setState(() {
        numeroRegistroSiguiente = 1;
        cargandoNumeroRegistro = false;
      });
    }
  }

  void _limpiarCampos() {
    setState(() {
      idClienteSeleccionado = null;
      idTipoSeleccionado = null;
      idMotoSeleccionada = null;
      detallesSeleccionados = [];
      clienteCtrl.clear();
      vehiculoCtrl.clear();
      descripcionCtrl.clear();
      motosCliente = [];
      clienteSeleccionadoPorOCR = false;
      intentoGuardar = false;
    });
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
          "Nuevo Mantenimiento",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _limpiarCampos,
            tooltip: 'Limpiar campos',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: intentoGuardar
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),

              _buildSectionTitle('Información del Cliente', Icons.person),
              const SizedBox(height: 12),
              _searchClienteField(),
              const SizedBox(height: 20),

              _buildSectionTitle('Vehículo', Icons.motorcycle),
              const SizedBox(height: 12),
              _dropdownVehiculo(),
              const SizedBox(height: 20),

              _buildSectionTitle('Tipo de Servicio', Icons.build),
              const SizedBox(height: 12),
              _dropdownTipo(),
              const SizedBox(height: 20),

              _buildSectionTitle('Productos y Repuestos', Icons.shopping_cart),
              const SizedBox(height: 12),
              _productsBox(),
              const SizedBox(height: 20),

              _buildSectionTitle('Observaciones', Icons.note_alt),
              const SizedBox(height: 12),
              _descriptionField(),
              const SizedBox(height: 32),

              _buildGuardarButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: DateTime.now().toString().split(' ')[0],
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white24,
              ),
              _buildInfoItem(
                icon: Icons.tag,
                label: 'Registro',
                value: cargandoNumeroRegistro
                    ? '...'
                    : '#${numeroRegistroSiguiente.toString().padLeft(8, '0')}',
              ),
            ],
          ),
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

  Widget _searchClienteField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: idClienteSeleccionado != null && intentoGuardar == false
              ? const Color(0xFFFFD700).withOpacity(0.5)
              : Colors.white24,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: clienteCtrl,
              readOnly: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                labelText: "Cliente",
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: idClienteSeleccionado != null
                      ? const Color(0xFFFFD700)
                      : Colors.white54,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: (_) {
                if (idClienteSeleccionado == null) {
                  return 'Seleccione un cliente';
                }
                return null;
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: clienteSeleccionadoPorOCR ? Colors.grey : const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: clienteSeleccionadoPorOCR ? null : _buscarCliente,
              tooltip: clienteSeleccionadoPorOCR ? 'Deshabilitado - Cliente seleccionado por OCR' : 'Buscar cliente',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirCamaraCliente() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2B2B2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Buscar Vehículo por Placa',
                  style: TextStyle(
                    color: Colors.yellow[700],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.yellow),
                title: const Text(
                  'Tomar foto',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Detecta Placa',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _procesarPlacaOCR(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.yellow),
                title: const Text(
                  'Elegir de galería',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Selecciona una foto de la placa',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _procesarPlacaOCR(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _procesarPlacaOCR(ImageSource source) async {
    final XFile? imagen = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (imagen == null) return;

    setState(() => procesandoOCR = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2B2B),
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
                    'Detectando placa y\nbuscando dueño...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
    );

    try {
      final File imageFile = File(imagen.path);
      final resultado = await MotoService.buscarDuenoPorPlaca(imageFile);

      Navigator.pop(context);

      if (resultado != null && resultado['success'] == true) {
        setState(() {
          idClienteSeleccionado = resultado['idUsuario'];
          clienteCtrl.text = resultado['nombreCompleto'];
          clienteSeleccionadoPorOCR = true;
        });

        await _cargarMotos(resultado['idUsuario']);

        setState(() {
          idMotoSeleccionada = resultado['idMoto'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cliente encontrado: ${resultado['nombreCompleto']} | Vehículo: ${resultado['marca']} ${resultado['modelo']} (${resultado['placa']})',
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        final mensaje = resultado?['mensaje'] ??
            'No se pudo procesar la imagen';
        final placa = resultado?['placa'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              placa != null
                  ? '❌ $mensaje | Placa detectada: $placa'
                  : '❌ $mensaje',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.yellow,
              onPressed: () => _abrirCamaraCliente(),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error al procesar la imagen: $e');
    } finally {
      setState(() => procesandoOCR = false);
    }
  }

  Widget _dropdownVehiculo() {
    if (idClienteSeleccionado == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white24,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white38, size: 25),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Seleccione primero un cliente",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.black),
                onPressed: _abrirCamaraCliente,
                tooltip: 'Detectar placa con cámara',
              ),
            ),
          ],
        ),
      );
    }

    if (cargandoMotos) {
      return Container(
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
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Cargando vehículos...",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: clienteSeleccionadoPorOCR ? const Color(0xFFFFD700) : Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.black),
                onPressed: clienteSeleccionadoPorOCR ? _abrirCamaraCliente : null,
                tooltip: clienteSeleccionadoPorOCR ? 'Detectar placa con cámara' : 'Deshabilitado - Cliente seleccionado por búsqueda',
              ),
            ),
          ],
        ),
      );
    }

    if (motosCliente.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white24,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.white38, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Este cliente no tiene vehículos registrados",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: clienteSeleccionadoPorOCR ? const Color(0xFFFFD700) : Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.black),
                onPressed: clienteSeleccionadoPorOCR ? _abrirCamaraCliente : null,
                tooltip: clienteSeleccionadoPorOCR ? 'Detectar placa con cámara' : 'Deshabilitado - Cliente seleccionado por búsqueda',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: idMotoSeleccionada != null
              ? const Color(0xFFFFD700).withOpacity(0.5)
              : Colors.white24,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              dropdownColor: const Color(0xFF2B2B2B),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                labelText: "Vehículo (Placa)",
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.motorcycle,
                  color: idMotoSeleccionada != null
                      ? const Color(0xFFFFD700)
                      : Colors.white54,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              value: idMotoSeleccionada,
              items: motosCliente.map((moto) {
                return DropdownMenuItem(
                  value: moto.id_moto,
                  child: Text("${moto.placa} - ${moto.modelo}"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => idMotoSeleccionada = value);
              },
              validator: (value) => value == null ? 'Seleccione un vehículo' : null,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: clienteSeleccionadoPorOCR ? const Color(0xFFFFD700) : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.black),
              onPressed: clienteSeleccionadoPorOCR ? _abrirCamaraCliente : null,
              tooltip: clienteSeleccionadoPorOCR ? 'Detectar placa con cámara' : 'Deshabilitado - Cliente seleccionado por búsqueda',
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownTipo() {
    if (cargandoTipos) {
      return _buildLoadingField("Cargando tipos de servicio...");
    }

    if (tiposMantenimiento.isEmpty) {
      return _campoBloqueado(
        "No hay tipos de servicio disponibles",
        Icons.warning_amber,
      );
    }

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<int>(
        dropdownColor: const Color(0xFF2B2B2B),
        style: const TextStyle(color: Colors.white, fontSize: 15),
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
        value: idTipoSeleccionado,
        items: tiposMantenimiento.map((tipo) {
          return DropdownMenuItem<int>(
            value: tipo.idTipo,
            child: Text(tipo.nombre),
          );
        }).toList(),

        onChanged: (value) async {
          if (value != null) {
            final tipoSeleccionado = await TipoService.obtenerPorId(value);

            setState(() {
              idTipoSeleccionado = value;
              detallesSeleccionados.clear();

              if (tipoSeleccionado != null &&
                  tipoSeleccionado.producto != null &&
                  tipoSeleccionado.productoPvp != null) {


                final detalleAutomatico = DetalleUI(
                  idProducto: tipoSeleccionado.producto!.id_producto,
                  nombre: tipoSeleccionado.producto!.nombre,
                  cantidad: 1,
                  precioUnitario: tipoSeleccionado.productoPvp!,
                  esProducto: true,
                  imagenUrl: tipoSeleccionado.producto!.rutaImagenProductos,
                );

                // Agregar a detalles si no está ya
                if (!detallesSeleccionados.any((d) => d.idProducto == tipoSeleccionado.producto!.id_producto)) {
                  detallesSeleccionados.add(detalleAutomatico);

                  // Agregar concepto manual si existe
                  if (tipoSeleccionado.conceptoManual != null && tipoSeleccionado.conceptoManual!.isNotEmpty) {
                    final conceptoManual = DetalleUI(
                      idProducto: -1,
                      nombre: tipoSeleccionado.conceptoManual!,
                      cantidad: tipoSeleccionado.conceptoCantidad ?? 1,
                      precioUnitario: tipoSeleccionado.conceptoPrecioUnitario ?? 0,
                      esProducto: false,
                    );

                    if (!detallesSeleccionados.any((d) => d.nombre == tipoSeleccionado.conceptoManual!)) {
                      detallesSeleccionados.add(conceptoManual);
                    }
                  }

                  if (descripcionCtrl.text.isEmpty) {
                    descripcionCtrl.text = tipoSeleccionado.descripcion ?? '';
                  }
                }
              }
            });
          }
        },
        validator: (value) =>
        value == null ? 'Seleccione un tipo de mantenimiento' : null,
      ),
    );
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                        hayDetalles ? Icons.check_circle : Icons.add_shopping_cart,
                        color: const Color(0xFFFFD700),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      hayDetalles
                          ? "Productos (${detallesSeleccionados.length})"
                          : "Seleccionar productos",
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

  Widget _descriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: descripcionCtrl,
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _validarAntesDeGuardar,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Guardar Mantenimiento",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoBloqueado(String texto, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white12,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingField(String texto) {
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
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _validarAntesDeGuardar() {
    setState(() => intentoGuardar = true);

    final formValido = _formKey.currentState!.validate();

    if (idClienteSeleccionado == null ||
        idTipoSeleccionado == null ||
        detallesSeleccionados.isEmpty ||
        !formValido) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Complete todos los campos obligatorios",
                  style: TextStyle(fontSize: 15),
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
      return;
    }
    if (idMotoSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Text(
                "Debe seleccionar un vehículo",
                style: TextStyle(fontSize: 15),
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
      return;
    }

    _confirmGuardar();
  }

  void _confirmGuardar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFFFFD700),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Confirmar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "¿Está seguro de guardar este mantenimiento?",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "Cancelar",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _guardarMantenimiento();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Confirmar",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarMantenimiento() async {
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
                'Guardando mantenimiento...',
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
      final userJson = await TokenManager.getUserJson();
      final idUsuarioActual = userJson?['id_usuario'];

      if (idUsuarioActual == null) {
        Navigator.pop(context);
        _mostrarError("No se pudo obtener el usuario actual");
        return;
      }

      final body = {
        "idCliente": idClienteSeleccionado,
        "idEncargado": idUsuarioActual,
        "idMoto": idMotoSeleccionada,
        "idTipo": idTipoSeleccionado,
        "estado": 1,
        "observaciones": descripcionCtrl.text.trim(),
        "detalles":
        detallesSeleccionados.map((detalle) => detalle.toJson()).toList(),
      };

      //print('JSON a enviar: ${jsonEncode(body)}');

      final resultado = await RegistrosService.crear(body);

      Navigator.pop(context);

      if (resultado != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Mantenimiento guardado exitosamente",
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
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
      } else {
        _mostrarError("No se recibió respuesta del servidor");
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError("Error al guardar: ${e.toString()}");
      print('❌ Error completo: $e');
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _buscarCliente() async {
    //print('Iniciando búsqueda de cliente...');
    final Usuario? usuario = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuscarUsuarioPage()),
    );

    if (usuario != null) {
      setState(() {
        idClienteSeleccionado = usuario.idUsuario;
        clienteCtrl.text = usuario.nombreCompleto ?? '';
        clienteSeleccionadoPorOCR = false;

        idMotoSeleccionada = null;
        vehiculoCtrl.clear();
        motosCliente.clear();
        cargandoMotos = true;
      });

      _cargarMotos(usuario.idUsuario!);
    }
  }

  Future<void> _cargarMotos(int idUsuario) async {
    try {
      final motos = await MotoService.listarMotosPorUsuario(idUsuario);
      setState(() {
        motosCliente = motos;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text("Error al cargar vehículos"),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => cargandoMotos = false);
    }
  }

  Future<void> _cargarTipos() async {
    setState(() => cargandoTipos = true);
    try {
      final tipos = await TipoService.obtenerTodos();
      setState(() {
        tiposMantenimiento = tipos;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text("Error al cargar tipos: $e")),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => cargandoTipos = false);
    }
  }

  double _calcularTotal() {
    return detallesSeleccionados.fold(
      0.0,
          (sum, detalle) => sum + detalle.subtotal,
    );
  }
}