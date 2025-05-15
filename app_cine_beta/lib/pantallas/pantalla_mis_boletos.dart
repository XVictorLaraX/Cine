import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MisBoletosPantalla extends StatefulWidget {
  const MisBoletosPantalla({super.key});

  @override
  State<MisBoletosPantalla> createState() => _MisBoletosScreenState();
}

class _MisBoletosScreenState extends State<MisBoletosPantalla>
    with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, bool> _expandedCards = {};

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Boletos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('boletos')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.docs.isEmpty ?? true) {
            return const Center(child: Text('No tienes boletos aún'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context, index) {
              final boleto = snapshot.data?.docs[index];
              final data = boleto?.data() as Map<String, dynamic>;
              final boletoId = boleto?.id ?? '';

              // Inicializar estado de expansión si no existe
              _expandedCards.putIfAbsent(boletoId, () => false);

              return _buildExpandableBoletoCard(data, boletoId, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildExpandableBoletoCard(Map<String, dynamic> boleto, String boletoId, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        key: Key(boletoId),
        initiallyExpanded: _expandedCards[boletoId] ?? false,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedCards[boletoId] = expanded;
          });
        },
        leading: const Icon(Icons.movie, color: Colors.red),
        title: Text(
          boleto['titulo'] ?? 'Película',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${boleto['cineteca'] ?? 'Cineteca'} - Sala ${boleto['sala'] ?? ''}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Icon(
          _expandedCards[boletoId]! ? Icons.expand_less : Icons.expand_more,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Fecha:',
                    boleto['fechaFuncion'] is Timestamp
                        ? DateFormat('dd/MM/yyyy').format(boleto['fechaFuncion'].toDate())
                        : boleto['fechaFuncion'].toString(),
                  ),
                  _buildInfoRow("Horario:", boleto['horario'] ?? 'No especificado'),
                  _buildInfoRow('Asientos:', (boleto['asientos'] as List).join(', ')),
                  _buildInfoRow('Cantidad:', boleto['cantidadAsientos']?.toString() ?? '1'),
                  const Divider(height: 24),
              _buildInfoRow('Precio unitario:',
                  '\$${boleto['precioUnitario']?.toStringAsFixed(2) ?? '0.00'}'),
              _buildInfoRow('Total pagado:',
                  '\$${boleto['precioTotal']?.toStringAsFixed(2) ?? '0.00'}',
                  isBold: true),
              const Divider(height: 24),
              _buildInfoRow('Método de pago:', boleto['metodoPago'] ?? 'No especificado'),
              _buildInfoRow('Fecha de compra:',
                  DateFormat('dd/MM/yyyy HH:mm').format(
                      (boleto['fechaCompra'] as Timestamp).toDate())),
              const SizedBox(height: 8),
              _buildStatusChip(boleto['estado'] ?? 'activo'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'activo':
        chipColor = Colors.green;
        break;
      case 'usado':
        chipColor = Colors.blue;
        break;
      case 'cancelado':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Chip(
        label: Text(
          status.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        backgroundColor: chipColor,
      ),
    );
  }
}