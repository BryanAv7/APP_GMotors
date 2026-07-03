import 'package:flutter/material.dart';
import '../models/RegistroDetalleDTO.dart';
import '../models/DetalleFacturaDTO.dart';
import '../services/registros_service.dart';
import '../utils/token_manager.dart';

class HistorialMisMantenimientosPage extends StatefulWidget {
  const HistorialMisMantenimientosPage({super.key});

  @override
  State<HistorialMisMantenimientosPage> createState() =>
      _HistorialMisMantenimientosPageState();
}

class _HistorialMisMantenimientosPageState
    extends State<HistorialMisMantenimientosPage> {
  late Future<List<RegistroDetalleDTO>> futureHistorial;
  List<RegistroDetalleDTO> historialMantenimientos = [];
  String nombreCliente = '';

  @override
  void initState() {
    super.initState();
    _cargarHistorialUsuario();
  }

  Future<void> _cargarHistorialUsuario() async {
    try {
      // Obtener nombre del usuario logueado
      final userJson = await TokenManager.getUserJson();
      if (userJson != null) {
        nombreCliente = userJson['nombre_completo'] ?? 'Mi Historial';
      }

      // Cargar historial del usuario actual
      futureHistorial = RegistrosService.buscarHistorialPorNombre(nombreCliente);
      setState(() {});
    } catch (e) {
      print('Error al cargar historial: $e');
    }
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
          "Historial de Mantenimientos",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<RegistroDetalleDTO>>(
        future: futureHistorial,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildCargando();
          } else if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildSinDatos();
          }

          historialMantenimientos = snapshot.data!;
          return _buildListaHistorial();
        },
      ),
    );
  }

  Widget _buildCargando() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFFFD700),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          const Text(
            'Cargando historial...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade300,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'Error al cargar historial',
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
              ),
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              label: const Text(
                'Volver',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinDatos() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              color: Colors.white54,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin historial de mantenimientos',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aún no tienes registros de mantenimiento',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
              ),
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              label: const Text(
                'Volver',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaHistorial() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información del usuario
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.2),
                  const Color(0xFFFFD700).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mantenimientos Realizados',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cliente: ${nombreCliente}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${historialMantenimientos.length} registros',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Lista de mantenimientos
          Text(
            'Historial (Más reciente)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historialMantenimientos.length,
            itemBuilder: (context, index) {
              final registro = historialMantenimientos[index];
              return _buildTarjetaMantenimiento(registro);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaMantenimiento(RegistroDetalleDTO registro) {
    final fecha = registro.fecha.isNotEmpty
        ? _formatearFecha(registro.fecha)
        : 'Fecha no disponible';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: const Color(0xFFFFD700),
          collapsedIconColor: const Color(0xFFFFD700),
          backgroundColor: const Color(0xFF1E1E1E),
          collapsedBackgroundColor: const Color(0xFF1E1E1E),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFFFFD700),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Date: $fecha',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (registro.tipoMantenimiento != null &&
                        registro.tipoMantenimiento!.isNotEmpty)
                      Text(
                        'Tipo: ${registro.tipoMantenimiento}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildIndicadorEstado(registro.estado),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),

                  // Vehículo
                  _buildInfoField(
                    icon: Icons.two_wheeler,
                    label: 'Vehículo',
                    value: '${registro.marcaMoto ?? 'N/A'} ${registro.modeloMoto ?? ''}',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),

                  // Placa
                  if (registro.placaMoto != null && registro.placaMoto!.isNotEmpty) ...[
                    _buildInfoField(
                      icon: Icons.badge,
                      label: 'Placa',
                      value: registro.placaMoto!,
                      color: Colors.cyan,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Encargado
                  if (registro.nombreEncargado != null &&
                      registro.nombreEncargado!.isNotEmpty) ...[
                    _buildInfoField(
                      icon: Icons.supervisor_account,
                      label: 'Encargado',
                      value: registro.nombreEncargado!,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Costo Total
                  if (registro.costoTotal != null) ...[
                    _buildInfoField(
                      icon: Icons.attach_money,
                      label: 'Costo Total',
                      value: '\$${registro.costoTotal!.toStringAsFixed(2)}',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 🆕 ✅ DESPLEGABLE DE DETALLES DE FACTURA
                  if (registro.idFactura != null) ...[
                    _buildDetallesFacturaExpansion(registro.idFactura!),
                    const SizedBox(height: 12),
                  ],

                  // Observaciones
                  if (registro.descripcion != null &&
                      registro.descripcion!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.note, color: Colors.amber, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Observaciones',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            registro.descripcion!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MOSTRAR DETALLES DE FACTURA
  Widget _buildDetallesFacturaExpansion(int idFactura) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.blue,
          collapsedIconColor: Colors.blue,
          backgroundColor: Colors.blue.withOpacity(0.05),
          collapsedBackgroundColor: Colors.blue.withOpacity(0.05),
          title: Row(
            children: [
              Icon(Icons.receipt, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Detalles de Factura',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: FutureBuilder<List<DetalleFacturaDTO>>(
                future: RegistrosService.obtenerDetallesFactura(idFactura),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                        strokeWidth: 2,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Error al cargar detalles',
                        style: TextStyle(color: Colors.red.shade300),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No hay detalles disponibles',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  final detalles = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detalles.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white12,
                      height: 12,
                    ),
                    itemBuilder: (context, index) {
                      final detalle = detalles[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Descripción del producto/servicio
                            Text(
                              'Productos:\n${detalle.descripcion}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Cantidad, precio y subtotal en fila
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cantidad: ${detalle.cantidad}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Precio: \$${detalle.precioUnitario.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Subtotal: \$${detalle.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndicadorEstado(int estado) {
    String textoEstado = 'Pendiente';
    Color colorEstado = Colors.orange;
    IconData iconoEstado = Icons.schedule;

    if (estado == 0) {
      textoEstado = 'Recibido';
      colorEstado = Colors.orange;
      iconoEstado = Icons.wallet_travel_sharp;
    } else if (estado == 1) {
      textoEstado = 'En Proceso';
      colorEstado = Colors.blue;
      iconoEstado = Icons.autorenew;
    } else if (estado == 2) {
      textoEstado = 'Finalizado';
      colorEstado = Colors.green;
      iconoEstado = Icons.check_circle;
    } else if (estado == 3) {
      textoEstado = 'Entregado';
      colorEstado = Colors.red;
      iconoEstado = Icons.motorcycle_outlined;
    } else if (estado == 4) {
      textoEstado = 'Facturado';
      colorEstado = Colors.deepPurple;
      iconoEstado = Icons.receipt_long;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: colorEstado.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorEstado.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconoEstado,
            color: colorEstado,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            textoEstado,
            style: TextStyle(
              color: colorEstado,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return fecha;
    }
  }
}