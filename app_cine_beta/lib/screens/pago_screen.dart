import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_cine/screens/cine_navegador.dart';

class pago_screen extends StatefulWidget {
  final Map<String, dynamic> reservaData;

  const pago_screen({Key? key, required this.reservaData}) : super(key: key);

  @override
  State<pago_screen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<pago_screen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  bool _isProcessing = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late DateTime fechaFuncion;

  @override
  void initState() {
    super.initState();
    fechaFuncion = DateTime.now(); // Initialize fechaFuncion
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _crearReservaYBoleto() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // 1. Crear la reserva
    final reservaData = {
      'userId': user.uid,
      'peliculaId': widget.reservaData['peliculaId'],
      'titulo': widget.reservaData['titulo'],
      'cineteca': widget.reservaData['cineteca'],
      'sala': widget.reservaData['sala'],
      'horario': widget.reservaData['horario'],
      'fechaFuncion': widget.reservaData['fechaFuncion'],
      'asientos': widget.reservaData['asientos'],
      'cantidadAsientos': widget.reservaData['cantidadAsientos'],
      'precioUnitario': widget.reservaData['precioPorAsiento'],
      'precioTotal': widget.reservaData['precioTotal'],
      'fechaReserva': FieldValue.serverTimestamp(),
      'estado': 'completada',
      'metodoPago': 'Tarjeta terminada en ${_cardNumberController.text.substring(15)}',
    };

    final reservaRef = await _firestore.collection('reservas').add(reservaData);

    // 2. Crear el boleto
    final boletoData = {
      'userId': user.uid,
      'reservaId': reservaRef.id,
      'peliculaId': widget.reservaData['peliculaId'],
      'titulo': widget.reservaData['titulo'],
      'cineteca': widget.reservaData['cineteca'],
      'sala': widget.reservaData['sala'],
      'horario': widget.reservaData['horario'],
      'fechaFuncion': widget.reservaData['fechaFuncion'],
      'asientos': widget.reservaData['asientos'],
      'cantidadAsientos': widget.reservaData['cantidadAsientos'],
      'precioUnitario': widget.reservaData['precioPorAsiento'],
      'precioTotal': widget.reservaData['precioTotal'],
      'fechaCompra': FieldValue.serverTimestamp(),
      'estado': 'activo',
      'metodoPago': 'Tarjeta terminada en ${_cardNumberController.text.substring(15)}',
    };

    await _firestore.collection('boletos').add(boletoData);
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Simular procesamiento de pago (2 segundos)
      await Future.delayed(const Duration(seconds: 2));

      // Crear reserva y boleto después del pago exitoso
      await _crearReservaYBoleto();

      if (!mounted) return;

      // Redireccionar a Mis Boletos
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const CineNavegador(),
        ),
            (route) => false,
      );

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago completado y reserva creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en el pago: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de la reserva
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de Compra',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('Película:', widget.reservaData['titulo']),
                    _buildDetailRow('Cineteca:', widget.reservaData['cineteca']),
                    _buildDetailRow('Sala:', widget.reservaData['sala']),
                    _buildDetailRow('Fecha:', DateFormat('yyyy-MM-dd').format(fechaFuncion)),
                    _buildDetailRow('Horario:', widget.reservaData['horario']),
                    _buildDetailRow('Asientos:', (widget.reservaData['asientos'] as List).join(', ')),
                    _buildDetailRow('Cantidad:', widget.reservaData['cantidadAsientos'].toString()),
                    const Divider(),
                    _buildDetailRow(
                      'Total:',
                      '\$${widget.reservaData['precioTotal'].toStringAsFixed(2)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Formulario de pago
            Text(
              'Datos de Pago',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Número de tarjeta
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Tarjeta',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      CardNumberFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese el número de tarjeta';
                      }
                      if (value.replaceAll(' ', '').length != 16) {
                        return 'Número de tarjeta inválido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Fecha de vencimiento y CVV
                  Row(
                    children: [
                      // Fecha de vencimiento
                      Expanded(
                        child: TextFormField(
                          controller: _expiryDateController,
                          decoration: const InputDecoration(
                            labelText: 'MM/AA',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            CardExpiryFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese fecha de vencimiento';
                            }
                            if (value.length != 5) {
                              return 'Formato MM/AA requerido';
                            }

                            final parts = value.split('/');
                            if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
                              return 'Formato inválido';
                            }

                            final month = int.tryParse(parts[0]);
                            final year = int.tryParse(parts[1]);

                            if (month == null || year == null) {
                              return 'Solo números permitidos';
                            }

                            // Validar mes (1-12)
                            if (month < 1 || month > 12) {
                              return 'Mes debe ser entre 01 y 12';
                            }

                            // Validar año (mínimo 25)
                            if (year < 25) {
                              return 'Año debe ser 25 o mayor';
                            }

                            // Validar fecha no expirada
                            final currentYear = DateTime.now().year % 100;
                            final currentMonth = DateTime.now().month;

                            if (year < currentYear || (year == currentYear && month <= currentMonth)) {
                              return 'Tarjeta expirada';
                            }

                            return null;
                          },
                        ),
                      ),

                      const SizedBox(width: 20),

                      // CVV
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese CVV';
                            }
                            if (value.length != 3) {
                              return 'CVV inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Botón de pago
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Confirmar Pago',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) text = text.substring(0, 16);

    var formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 4) text = text.substring(0, 4);

    var formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2) formatted += '/';
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
