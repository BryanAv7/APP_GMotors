import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';

class BuscarUsuarioPage extends StatefulWidget {
  const BuscarUsuarioPage({super.key});

  @override
  State<BuscarUsuarioPage> createState() => _BuscarUsuarioPageState();
}

class _BuscarUsuarioPageState extends State<BuscarUsuarioPage> {
  late Future<List<Usuario>> futureUsuarios;

  final TextEditingController buscarCtrl = TextEditingController();
  List<Usuario> usuarios = [];
  List<Usuario> usuariosFiltrados = [];

  @override
  void initState() {
    super.initState();
    futureUsuarios = UsuarioService.obtenerUsuarios();
  }

  void _filtrarUsuarios(String texto) {
    setState(() {
      usuariosFiltrados = usuarios
          .where((u) =>
          (u.nombreCompleto ?? '')
              .toLowerCase()
              .contains(texto.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC02D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buscar Cliente',
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: FutureBuilder<List<Usuario>>(
        future: futureUsuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          usuarios = snapshot.data!;
          usuariosFiltrados = usuariosFiltrados.isEmpty
              ? usuarios
              : usuariosFiltrados;

          return Column(
            children: [
              _buscador(),
              Expanded(child: _listaUsuarios()),
            ],
          );
        },
      ),
    );
  }

  // ---------------- BUSCADOR ----------------

  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: buscarCtrl,
        onChanged: _filtrarUsuarios,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFBC02D)),
          filled: true,
          fillColor: const Color(0xFF2B2B2B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ---------------- LISTA ----------------

  Widget _listaUsuarios() {
    if (usuariosFiltrados.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron usuarios',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.separated(
      itemCount: usuariosFiltrados.length,
      separatorBuilder: (_, __) =>
      const Divider(color: Colors.white12, height: 1),
      itemBuilder: (context, index) {
        final usuario = usuariosFiltrados[index];

        return ListTile(
          leading: const Icon(Icons.person, color: Color(0xFFFBC02D)),
          title: Text(
            usuario.nombreCompleto ?? 'Sin nombre',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: usuario.ciudad != null
              ? Text(
            usuario.ciudad!,
            style: const TextStyle(color: Colors.white54),
          )
              : null,
          onTap: () {
            Navigator.pop(context, usuario);
          },
        );
      },
    );
  }
}
