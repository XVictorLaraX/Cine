import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

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

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('Película:', widget.reservaData['titulo']),
                    _buildDetailRow('Sala:', widget.reservaData['sala']),
                    _buildDetailRow('Horario:', widget.reservaData['horario']),
                    _buildDetailRow('Asientos:', widget.reservaData['asientos'].join(', ')),
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
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isProcessing = true);

                          try {
                            // Simular procesamiento de pago
                            await Future.delayed(const Duration(seconds: 2));

                            // Retornar éxito
                            if (mounted) Navigator.pop(context, true);
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isProcessing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error en pago: ${e.toString()}')),
                              );
                            }
                          }
                        }
                      },
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

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      await FirebaseFirestore.instance
          .collection('reservas')
          .doc(widget.reservaData['reservaId'])
          .update({
        'estado': 'completada',
        'fechaPago': FieldValue.serverTimestamp(),
        'metodoPago': 'Tarjeta terminada en ${_cardNumberController.text.substring(15)}',
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            reservationId: widget.reservaData['reservaId'],
          ),
        ),
            (route) => false,
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

class PaymentSuccessScreen extends StatelessWidget {
  final String reservationId;

  const PaymentSuccessScreen({Key? key, required this.reservationId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text(
              'Pago Completado',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Reserva #$reservationId',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}