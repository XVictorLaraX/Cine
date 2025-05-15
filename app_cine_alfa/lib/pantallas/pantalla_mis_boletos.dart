import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Pantalla que muestra los boletos comprados por el usuario
class PantallaMisBoletos extends StatefulWidget {
  const PantallaMisBoletos({super.key});

  @override
  State<PantallaMisBoletos> createState() => _EstadoMisBoletos();
}

class _EstadoMisBoletos extends State<PantallaMisBoletos>
    with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, bool> _tarjetasExpandidas = {}; // Controla qué tarjetas están abiertas

  @override
  bool get wantKeepAlive => true; // Mantiene el estado al cambiar de pestaña

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Boletos'),
      ),
      body: _construirListaBoletos(),
    );
  }

  // Widget principal que construye la lista de boletos
  Widget _construirListaBoletos() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('boletos')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Manejo de errores
        if (snapshot.hasError) {
          return Center(child: Text('Algo salió mal: ${snapshot.error}'));
        }

        // Mostrar spinner mientras carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Mensaje si no hay boletos
        if (snapshot.data?.docs.isEmpty ?? true) {
          return const Center(
            child: Text('Aún no tienes boletos comprados'),
          );
        }

        // Lista de boletos
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data?.docs.length,
          itemBuilder: (context, index) {
            final boleto = snapshot.data?.docs[index];
            final datos = boleto?.data() as Map<String, dynamic>;
            final idBoleto = boleto?.id ?? '';

            // Inicializar estado de expansión si no existe
            _tarjetasExpandidas.putIfAbsent(idBoleto, () => false);

            return _construirTarjetaBoleto(datos, idBoleto, context);
          },
        );
      },
    );
  }

  // Widget que construye una tarjeta expandible para cada boleto
  Widget _construirTarjetaBoleto(Map<String, dynamic> boleto, String idBoleto, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        key: Key(idBoleto),
        initiallyExpanded: _tarjetasExpandidas[idBoleto] ?? false,
        onExpansionChanged: (expandido) {
          setState(() {
            _tarjetasExpandidas[idBoleto] = expandido;
          });
        },
        leading: const Icon(Icons.movie, color: Colors.red),
        title: Text(
          boleto['titulo'] ?? 'Película no especificada',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${boleto['cineteca'] ?? 'Cine'} - Sala ${boleto['sala'] ?? '?'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Icon(
          _tarjetasExpandidas[idBoleto]! ? Icons.expand_less : Icons.expand_more,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información básica del boleto
                _construirFilaInfo('Fecha:', _formatearFecha(boleto['fechaFuncion'])),
                _construirFilaInfo("Horario:", boleto['horario'] ?? 'No especificado'),
                _construirFilaInfo('Asientos:', _formatearAsientos(boleto['asientos'])),
                _construirFilaInfo('Cantidad:', boleto['cantidadAsientos']?.toString() ?? '1'),

                const Divider(height: 24),

                // Información de precios
                _construirFilaInfo('Precio unitario:',
                    '\$${boleto['precioUnitario']?.toStringAsFixed(2) ?? '0.00'}'),
                _construirFilaInfo('Total pagado:',
                    '\$${boleto['precioTotal']?.toStringAsFixed(2) ?? '0.00'}',
                    negrita: true),

                const Divider(height: 24),

                // Información de compra
                _construirFilaInfo('Método de pago:', boleto['metodoPago'] ?? 'No especificado'),
                _construirFilaInfo('Fecha de compra:',
                    _formatearFechaHora(boleto['fechaCompra'])),

                const SizedBox(height: 8),

                // Estado del boleto
                _construirChipEstado(boleto['estado'] ?? 'activo'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para formatear la fecha de la función
  String _formatearFecha(dynamic fecha) {
    if (fecha is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(fecha.toDate());
    } else if (fecha is String) {
      return fecha;
    }
    return 'Fecha no disponible';
  }

  // Helper para formatear fecha y hora
  String _formatearFechaHora(dynamic fecha) {
    if (fecha is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toDate());
    }
    return 'Fecha no disponible';
  }

  // Helper para formatear la lista de asientos
  String _formatearAsientos(dynamic asientos) {
    if (asientos is List) {
      return asientos.join(', ');
    }
    return 'Asiento no especificado';
  }

  // Widget para mostrar filas de información
  Widget _construirFilaInfo(String etiqueta, String valor, {bool negrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            valor,
            style: TextStyle(
              fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar el estado del boleto como un chip de color
  Widget _construirChipEstado(String estado) {
    Color color;
    String texto;

    switch (estado.toLowerCase()) {
      case 'activo':
        color = Colors.green;
        texto = 'ACTIVO';
        break;
      case 'usado':
        color = Colors.blue;
        texto = 'USADO';
        break;
      case 'cancelado':
        color = Colors.red;
        texto = 'CANCELADO';
        break;
      case 'pendiente':
        color = Colors.orange;
        texto = 'PENDIENTE';
        break;
      default:
        color = Colors.grey;
        texto = estado.toUpperCase();
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Chip(
        label: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        backgroundColor: color,
      ),
    );
  }
}