import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_cine/navegador/navegador.dart';

// Pantalla para procesar el pago de los boletos
class PantallaPago extends StatefulWidget {
  final Map<String, dynamic> datosReserva; // Datos de la reserva que viene de la pantalla anterior

  const PantallaPago({Key? key, required this.datosReserva}) : super(key: key);

  @override
  State<PantallaPago> createState() => _EstadoPantallaPago();
}

class _EstadoPantallaPago extends State<PantallaPago> {
  final _formularioKey = GlobalKey<FormState>(); // Key para validar el formulario
  final TextEditingController _controladorNumeroTarjeta = TextEditingController();
  final TextEditingController _controladorFechaVencimiento = TextEditingController();
  final TextEditingController _controladorCVV = TextEditingController();
  bool _procesandoPago = false; // Para mostrar spinner durante el pago
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late DateTime _fechaFuncion; // Fecha de la función

  @override
  void initState() {
    super.initState();
    _fechaFuncion = DateTime.now(); // Inicializamos con la fecha actual
  }

  @override
  void dispose() {
    // Limpiamos los controladores al destruir el widget
    _controladorNumeroTarjeta.dispose();
    _controladorFechaVencimiento.dispose();
    _controladorCVV.dispose();
    super.dispose();
  }

  // Método para crear la reserva y el boleto en Firestore
  Future<void> _guardarReservaYBoleto() async {
    final usuario = _auth.currentUser;
    if (usuario == null) throw Exception('No hay usuario logeado');

    // Creación de la reserva con los datos seleccionados
    final datosReserva = {
      'userId': usuario.uid,
      'peliculaId': widget.datosReserva['peliculaId'],
      'titulo': widget.datosReserva['titulo'],
      'cineteca': widget.datosReserva['cineteca'],
      'sala': widget.datosReserva['sala'],
      'horario': widget.datosReserva['horario'],
      'fechaFuncion': widget.datosReserva['fechaFuncion'],
      'asientos': widget.datosReserva['asientos'],
      'cantidadAsientos': widget.datosReserva['cantidadAsientos'],
      'precioUnitario': widget.datosReserva['precioPorAsiento'],
      'precioTotal': widget.datosReserva['precioTotal'],
      'fechaReserva': FieldValue.serverTimestamp(),
      'estado': 'completada',
      'metodoPago': 'Tarjeta terminada en ${_controladorNumeroTarjeta.text.substring(15)}',
    };

    final referenciaReserva = await _firestore.collection('reservas').add(datosReserva);

    // Luego se crea el boleto asociado con los mismos datos
    final datosBoleto = {
      'userId': usuario.uid,
      'reservaId': referenciaReserva.id,
      'peliculaId': widget.datosReserva['peliculaId'],
      'titulo': widget.datosReserva['titulo'],
      'cineteca': widget.datosReserva['cineteca'],
      'sala': widget.datosReserva['sala'],
      'horario': widget.datosReserva['horario'],
      'fechaFuncion': widget.datosReserva['fechaFuncion'],
      'asientos': widget.datosReserva['asientos'],
      'cantidadAsientos': widget.datosReserva['cantidadAsientos'],
      'precioUnitario': widget.datosReserva['precioPorAsiento'],
      'precioTotal': widget.datosReserva['precioTotal'],
      'fechaCompra': FieldValue.serverTimestamp(),
      'estado': 'activo',
      'metodoPago': 'Tarjeta terminada en ${_controladorNumeroTarjeta.text.substring(15)}',
    };

    await _firestore.collection('boletos').add(datosBoleto);
  }

  // Método para procesar el pago (simulado)
  Future<void> _procesarPago() async {
    if (!_formularioKey.currentState!.validate()) return;

    setState(() => _procesandoPago = true);

    try {
      // Simulamos el procesamiento del pago (2 segundos)
      await Future.delayed(const Duration(seconds: 2));

      // Guardamos la reserva y el boleto en sus respectivas colecciones de FireStore
      await _guardarReservaYBoleto();

      if (!mounted) return;

      // Redirigimos al usuario al navegador principal
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const Navegador(),
        ),
            (route) => false,
      );

      // Mostramos mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pago completado! Tu reserva está lista'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _procesandoPago = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oops! Error al procesar el pago: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar Reserva'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de la compra
            _crearResumenCompra(),

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
              key: _formularioKey,
              child: Column(
                children: [
                  // Campo para el número de tarjeta
                  _crearCampoTarjeta(),

                  const SizedBox(height: 20),

                  // Fila con fecha vencimiento y CVV
                  Row(
                    children: [
                      // Fecha de vencimiento
                      _crearCampoFechaVencimiento(),

                      const SizedBox(width: 20),

                      // CVV
                      _crearCampoCVV(),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Botón para confirmar pago
                  _crearBotonPago(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget que muestra el resumen de la compra
  Widget _crearResumenCompra() {
    return Card(
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
            // Tarjeta de resumen para verificar que los datos sean correctos
            const SizedBox(height: 10),
            _crearFilaDetalle('Película:', widget.datosReserva['titulo']),
            _crearFilaDetalle('Cineteca:', widget.datosReserva['cineteca']),
            _crearFilaDetalle('Sala:', widget.datosReserva['sala']),
            _crearFilaDetalle('Fecha:', DateFormat('yyyy-MM-dd').format(_fechaFuncion)),
            _crearFilaDetalle('Horario:', widget.datosReserva['horario']),
            _crearFilaDetalle('Asientos:', (widget.datosReserva['asientos'] as List).join(', ')),
            _crearFilaDetalle('Cantidad:', widget.datosReserva['cantidadAsientos'].toString()),
            const Divider(),
            _crearFilaDetalle(
              'Total:',
              '\$${widget.datosReserva['precioTotal'].toStringAsFixed(2)}',
              negrita: true,
            ),
          ],
        ),
      ),
    );
  }

  // Widget para el campo de número de tarjeta
  Widget _crearCampoTarjeta() {
    return TextFormField(
      controller: _controladorNumeroTarjeta,
      decoration: const InputDecoration(
        labelText: 'Número de Tarjeta',
        prefixIcon: Icon(Icons.credit_card),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(16),
        FormateadorNumeroTarjeta(),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa tu número de tarjeta';
        }
        if (value.replaceAll(' ', '').length != 16) {
          return 'El número debe tener 16 dígitos';
        }
        return null;
      },
    );
  }

  // Widget para el campo de fecha de vencimiento
  Widget _crearCampoFechaVencimiento() {
    return Expanded(
      child: TextFormField(
        controller: _controladorFechaVencimiento,
        decoration: const InputDecoration(
          labelText: 'MM/AA',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
          FormateadorFechaTarjeta(),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingresa la fecha';
          }
          if (value.length != 5) {
            return 'Usa formato MM/AA';
          }

          final partes = value.split('/');
          if (partes.length != 2 || partes[0].isEmpty || partes[1].isEmpty) {
            return 'Formato incorrecto';
          }

          final mes = int.tryParse(partes[0]);
          final ano = int.tryParse(partes[1]);

          if (mes == null || ano == null) {
          return 'Solo números permitidos';
          }

          // Validar mes (1-12)
          if (mes < 1 || mes > 12) {
          return 'Mes debe ser 01-12';
          }

          // Validar año (mínimo el actual)
          final anoActual = DateTime.now().year % 100;
          final mesActual = DateTime.now().month;

          if (ano < anoActual || (ano == anoActual && mes <= mesActual)) {
          return 'Tarjeta expirada';
          }

          return null;
        },
      ),
    );
  }

  // Widget para el campo CVV
  Widget _crearCampoCVV() {
    return Expanded(
      child: TextFormField(
        controller: _controladorCVV,
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
            return 'Ingresa el CVV';
          }
          if (value.length != 3) {
            return 'CVV debe tener 3 dígitos';
          }
          return null;
        },
      ),
    );
  }

  // Widget para el botón de pago
  Widget _crearBotonPago() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _procesarPago,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _procesandoPago
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
    );
  }

  // widget para crear los elementos que iran en la tarjeta de resumen
  Widget _crearFilaDetalle(String etiqueta, String valor, {bool negrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
                fontSize: negrita ? 16 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Formateador para el número de tarjeta (XXXX XXXX XXXX XXXX)
class FormateadorNumeroTarjeta extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var texto = newValue.text.replaceAll(' ', '');
    if (texto.length > 16) texto = texto.substring(0, 16);

    var formateado = '';
    for (int i = 0; i < texto.length; i++) {
      if (i > 0 && i % 4 == 0) formateado += ' ';
      formateado += texto[i];
    }

    return TextEditingValue(
      text: formateado,
      selection: TextSelection.collapsed(offset: formateado.length),
    );
  }
}

// Formateador para fecha de vencimiento (MM/AA)
class FormateadorFechaTarjeta extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var texto = newValue.text.replaceAll('/', '');
    if (texto.length > 4) texto = texto.substring(0, 4);

    var formateado = '';
    for (int i = 0; i < texto.length; i++) {
      if (i == 2) formateado += '/';
      formateado += texto[i];
    }

    return TextEditingValue(
      text: formateado,
      selection: TextSelection.collapsed(offset: formateado.length),
    );
  }
}