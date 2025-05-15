import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:app_cine/pantallas//pago_pantalla.dart';

// Pantalla para seleccionar asientos en el cine
class PantallaSeleccionAsientos extends StatefulWidget {
  final String idPelicula;
  final String titulo;
  final String cineteca;
  final String horario;
  final String sala;
  final int cantidadAsientos;
  final double precioTotal;
  final DateTime fechaFuncion;

  const PantallaSeleccionAsientos({
    super.key,
    required this.idPelicula,
    required this.titulo,
    required this.cineteca,
    required this.horario,
    required this.sala,
    required this.cantidadAsientos,
    required this.precioTotal,
    required this.fechaFuncion,
  });

  @override
  State<PantallaSeleccionAsientos> createState() => _EstadoSeleccionAsientos();
}

class _EstadoSeleccionAsientos extends State<PantallaSeleccionAsientos> {
  late Future<List<String>> _futureAsientosOcupados; // Futuro para cargar asientos ocupados
  final List<String> _asientosElegidos = []; // Lista de asientos que el usuario selecciona
  bool _cargando = false; // Para mostrar spinner durante operaciones
  List<List<String>> _configuracionSala = []; // Matriz con la disposición de asientos
  bool _cargandoSala = true; // Flag para carga inicial

  @override
  void initState() {
    super.initState();
    _obtenerConfiguracionSala(); // Cargamos cómo está distribuida la sala
    _futureAsientosOcupados = _obtenerAsientosOcupados(
      widget.idPelicula,
      widget.horario,
      widget.sala,
      widget.fechaFuncion,
    );

    // Mostramos un mensajito para que el usuario sepa cuántos asientos debe elegir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona ${widget.cantidadAsientos} asiento(s)'),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  // Método para cargar cómo están distribuidos los asientos en la sala
  Future<void> _obtenerConfiguracionSala() async {
    try {
      debugPrint('Buscando configuración de la sala: "${widget.sala}"');

      final doc = await FirebaseFirestore.instance
          .collection('salas')
          .doc(widget.sala.trim())
          .get();

      if (doc.exists) {
        debugPrint('Configuración encontrada: ${doc.data()}');

        final datos = doc.data()!;
        List<List<String>> configuracion = [];

        // Letras de filas que podrían existir (de la A a la R)
        final letrasFilas = [
          'A', 'B', 'C', 'D', 'E', 'F',
          'G', 'H', 'I', 'I1', 'J', 'K', 'L', 'M', 'N',
          'O', 'P', 'Q', 'R'
        ];

        for (var fila in letrasFilas) {
          if (datos.containsKey(fila)) {
            String asientosStr = datos[fila] as String;
            debugPrint('Procesando fila $fila: $asientosStr');

            // Algunas filas están marcadas como vacías (ej: "I1")
            final esFilaVacia = RegExp(r'^[A-Z]1$').hasMatch(asientosStr.trim());

            if (esFilaVacia) {
              debugPrint('Fila $fila está vacía ($asientosStr)');
              configuracion.add([]); // Añadimos fila vacía
              continue;
            }

            // Procesamos los asientos de la fila
            List<String> asientos = asientosStr
                .split(',')
                .map((item) {
              final limpio = item.trim().replaceAll('"', '');
              return (limpio.isEmpty || RegExp(r'^[A-Z]1$').hasMatch(limpio))
                  ? ''
                  : '$fila$limpio';
            })
                .toList();

            debugPrint('Fila $fila procesada: $asientos');
            configuracion.add(asientos);
          }
        }

        setState(() {
          _configuracionSala = configuracion;
          _cargandoSala = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar la sala: $e');
      setState(() {
        _cargandoSala = false;
      });
    }
  }

  // Método para guardar la reserva (va a pantalla de pago primero)
  Future<void> _confirmarReserva() async {
    // Validaciones básicas
    if (_asientosElegidos.isEmpty) {
      _mostrarMensaje('Selecciona al menos un asiento');
      return;
    }

    if (_asientosElegidos.length != widget.cantidadAsientos) {
      _mostrarMensaje('Debes seleccionar exactamente ${widget.cantidadAsientos} asiento(s)');
      return;
    }

    setState(() => _cargando = true);

    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) throw Exception('No hay usuario logueado');

      // 1. Verificamos que los asientos sigan disponibles
      final asientosOcupados = await _obtenerAsientosOcupados(
        widget.idPelicula,
        widget.horario,
        widget.sala,
        widget.fechaFuncion,
      );

      final asientosEnConflicto = _asientosElegidos
          .where((asiento) => asientosOcupados.contains(asiento))
          .toList();

      if (asientosEnConflicto.isNotEmpty) {
        throw Exception('Los asientos ${asientosEnConflicto.join(', ')} ya están ocupados');
      }

      // 2. Preparamos los datos para la reserva
      final datosReserva = {
        'peliculaId': widget.idPelicula,
        'titulo': widget.titulo,
        'cineteca': widget.cineteca,
        'horario': widget.horario,
        'sala': widget.sala,
        'asientos': _asientosElegidos,
        'cantidadAsientos': widget.cantidadAsientos,
        'precioTotal': widget.precioTotal,
        'fechaFuncion': DateFormat('yyyy-MM-dd').format(widget.fechaFuncion),
        'usuarioId': usuario.uid,
        'estado': 'pendiente_pago', // Cambiará a "completada" si el pago funciona
      };

      // 3. Vamos a la pantalla de pago
      if (!mounted) return;
      final pagoExitoso = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaPago(datosReserva: datosReserva),
        ),
      );

      // 4. Si el pago fue exitoso, guardamos la reserva
      if (pagoExitoso == true) {
        await FirebaseFirestore.instance.collection('reservas').add({
          ...datosReserva,
          'fechaReserva': FieldValue.serverTimestamp(),
          'estado': 'completada',
        });

        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
        _mostrarMensaje('¡Reserva confirmada!', esError: false);
      }

    } catch (e) {
      debugPrint('Error al reservar: $e');
      if (!mounted) return;
      _mostrarMensaje('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Helper para mostrar mensajes al usuario
  void _mostrarMensaje(String mensaje, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Obtiene los asientos ya ocupados para esta función
  Future<List<String>> _obtenerAsientosOcupados(
      String idPelicula,
      String horario,
      String sala,
      DateTime fechaFuncion,
      ) async {
    try {
      final fechaFormateada = DateFormat('yyyy-MM-dd').format(fechaFuncion);

      final query = await FirebaseFirestore.instance
          .collection('reservas')
          .where('peliculaId', isEqualTo: idPelicula)
          .where('horario', isEqualTo: horario)
          .where('sala', isEqualTo: sala)
          .where('fechaFuncion', isEqualTo: fechaFormateada)
          .get();

      return query.docs
          .expand((doc) => List<String>.from(doc.data()['asientos'] ?? []))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener asientos ocupados: $e');
      return [];
    }
  }

  // Selecciona/deselecciona un asiento
  void _seleccionarAsiento(String asiento) {
    setState(() {
      if (_asientosElegidos.contains(asiento)) {
        _asientosElegidos.remove(asiento); // Si ya está, lo quitamos
      } else {
        if (_asientosElegidos.length < widget.cantidadAsientos) {
          _asientosElegidos.add(asiento); // Añadimos si aún no ha llegado al límite
        } else {
          // Mostramos error si intenta seleccionar más de lo permitido
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Máximo ${widget.cantidadAsientos} asientos')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tamanoPantalla = MediaQuery.of(context).size;
    final paddingHorizontal = 20.0;
    final espacioEntreAsientos = 8.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Asientos - ${widget.sala}'),
      ),
      body: SingleChildScrollView(
        child: Column(
            children: [
        // Representación de la pantalla del cine
        Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        height: 30,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'PANTALLA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      // Mapa de asientos
      _cargandoSala
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<String>>(
        future: _obtenerAsientosOcupados(
            widget.idPelicula, widget.horario, widget.sala, widget.fechaFuncion),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final asientosOcupados = snapshot.data ?? [];

          if (_configuracionSala.isEmpty) {
            return const Center(
              child: Text('No hay asientos configurados para esta sala'),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Calculamos el tamaño de cada asiento para que quepan todos
              final maxAsientosPorFila = _configuracionSala.fold(
                  0, (max, fila) => fila.length > max ? fila.length : max);
              final tamanoAsiento = ((tamanoPantalla.width - paddingHorizontal * 2) -
                  ((maxAsientosPorFila - 1) * espacioEntreAsientos)) /
                  maxAsientosPorFila;
              final tamanoFinal = tamanoAsiento.clamp(30.0, 60.0); // Tamaño mínimo/máximo

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: List.generate(_configuracionSala.length, (indiceFila) {
                    final fila = _configuracionSala[indiceFila];
                    final letraFila = String.fromCharCode(65 + indiceFila);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Letra de la fila
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                              'Fila $letraFila',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Asientos de la fila
                          Row(
                            children: List.generate(fila.length, (indice) {
                              final asiento = fila[indice];
                              final estaOcupado = asientosOcupados.contains(asiento);
                              final estaSeleccionado = _asientosElegidos.contains(asiento);
                              final estaVacio = asiento.isEmpty;
                              final numeroAsiento = asiento.replaceAll(RegExp(r'^[A-Z]+'), '');

                              return Container(
                                width: tamanoFinal,
                                height: tamanoFinal,
                                margin: EdgeInsets.only(
                                  left: indice == 0 ? 16.0 : 0,
                                  right: indice < fila.length - 1 ? 8.0 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: estaVacio || estaOcupado
                                      ? null
                                      : () => _seleccionarAsiento(asiento),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: estaVacio
                                          ? Colors.transparent
                                          : estaOcupado
                                          ? Colors.red.withOpacity(0.7)
                                          : estaSeleccionado
                                          ? Colors.green
                                          : Colors.blue.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(6),
                                      border: estaVacio
                                          ? null
                                          : Border.all(
                                        color: estaOcupado
                                            ? Colors.red
                                            : estaSeleccionado
                                            ? Colors.green[800]!
                                            : Colors.blue[700]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: estaVacio
                                          ? null
                                          : Text(
                                        numeroAsiento,
                                        style: TextStyle(
                                          fontSize: tamanoFinal * 0.35,
                                          color: estaOcupado || estaSeleccionado
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            },
          );
        },
      ),

      // Resumen y botón de confirmación
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Asientos: ${_asientosElegidos.join(', ')}',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    '${_asientosElegidos.length}/${widget.cantidadAsientos}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${widget.precioTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _confirmarReserva,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Confirmar Reserva',
                    style: TextStyle(fontSize: 18, color: Colors.white),
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
}