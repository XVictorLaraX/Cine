import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:app_cine/pantallas//pantalla_pago_.dart';

// Pantalla para seleccionar los asientos en el cine
class PantallaSeleccionarAsiento extends StatefulWidget {
  final String idPelicula;
  final String titulo;
  final String cineteca;
  final String horario;
  final String sala;
  final int cantidadAsientos;
  final double precioTotal;
  final DateTime fechaFuncion;

  const PantallaSeleccionarAsiento({
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
  State<PantallaSeleccionarAsiento> createState() => _EstadoPantallaSalas();
}

class _EstadoPantallaSalas extends State<PantallaSeleccionarAsiento> {
  late Future<List<String>> _futureAsientosOcupados; // Futuro para los asientos ya ocupados
  final List<String> _misAsientos = []; // Lista para los asientos que se van seleccionando
  bool _cargando = false; // Elemento visual de carga, cambia a true cuando se realice un proceso
  List<List<String>> _disposicionSala = []; // Cómo está organizada la sala
  bool _cargandoSala = true; // Comienza a cargar mientras carga la sala
  String? _errorCarga; // Por si algo falla

  @override
  void initState() {
    super.initState();
    _cargarDisposicionSala(); // Al iniciar, se carga cómo está organizada la sala
    _futureAsientosOcupados = _obtenerAsientosOcupados(
      widget.idPelicula,
      widget.horario,
      widget.sala,
      widget.fechaFuncion,
    );

    // Mensaje para recordar cuántos asientos deben ser seleccionados
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
  Future<void> _cargarDisposicionSala() async {
    try {
      debugPrint('Buscando datos de la sala: "${widget.sala}"');

      final doc = await FirebaseFirestore.instance
          .collection('salas')
          .doc(widget.sala.trim())
          .get();

      if (doc.exists) {
        debugPrint('Datos de sala encontrados: ${doc.data()}');

        final datos = doc.data()!;
        List<List<String>> nuevaDisposicion = [];

        // Posibles filas que puede tener la sala. Máximo encontrado (R)
        final letrasFilas = [
          'A', 'B', 'C', 'D', 'E', 'F',
          'G', 'H', 'I', 'I1', 'J', 'K', 'L', 'M', 'N', // I1 representa filas en blanco
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
              nuevaDisposicion.add([]); // Añadimos fila vacía
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
            nuevaDisposicion.add(asientos);
          }
        }

        setState(() { // Se cargan los datos obtenidos
          _disposicionSala = nuevaDisposicion;
          _cargandoSala = false; // El elemento de carga vuelve a hacerse false
        });
      }
    } catch (e) {
      debugPrint('Error cargando disposición de sala: $e');
      setState(() {
        _cargandoSala = false;
      });
    }
  }

  // Método para guardar la reserva (va a pantalla de pago primero)
  Future<void> _hacerReserva() async {
    // Validaciones básicas
    if (_misAsientos.isEmpty) {
      _mostrarMensaje('Selecciona al menos un asiento');
      return;
    }

    if (_misAsientos.length != widget.cantidadAsientos) {
      _mostrarMensaje('Debes seleccionar exactamente ${widget.cantidadAsientos} asiento(s)');
      return;
    }

    setState(() => _cargando = true);

    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) throw Exception('No hay usuario logeado');

      // Verifica que los asientos seleccionados sigan disponibles
      final asientosOcupados = await _obtenerAsientosOcupados(
        widget.idPelicula,
        widget.horario,
        widget.sala,
        widget.fechaFuncion,
      );
      // Si ya fueron seleccionados mientras se estaba procesando
      final asientosEnConflicto = _misAsientos
          .where((asiento) => asientosOcupados.contains(asiento))
          .toList();
      // Menaje de error
      if (asientosEnConflicto.isNotEmpty) {
        throw Exception('Los asientos ${asientosEnConflicto.join(', ')} ya están ocupados');
      }

      // Preparar datos para la reserva si no hubo problemas
      final datosReserva = {
        'peliculaId': widget.idPelicula,
        'titulo': widget.titulo,
        'cineteca': widget.cineteca,
        'horario': widget.horario,
        'sala': widget.sala,
        'asientos': _misAsientos,
        'cantidadAsientos': widget.cantidadAsientos,
        'precioTotal': widget.precioTotal,
        'fechaFuncion': DateFormat('yyyy-MM-dd').format(widget.fechaFuncion),
        'usuarioId': usuario.uid,
        'estado': 'pendiente_pago', // Se confirmará después del pago
      };

      // Ir a pantalla de pago
      if (!mounted) return;
      final pagoExitoso = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaPago (datosReserva: datosReserva),
        ),
      );

      // Si el pago fue exitoso, guardar la reserva en Firebase
      if (pagoExitoso == true) {
        await FirebaseFirestore.instance.collection('reservas').add({
          ...datosReserva,
          'fechaReserva': FieldValue.serverTimestamp(),
          'estado': 'completada',
        });

        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
        _mostrarMensaje('¡Reserva completada!', esError: false);
      }

    } catch (e) {
      debugPrint('Error al hacer reserva: $e');
      if (!mounted) return;
      _mostrarMensaje('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Metodo para mostrar mensajes tipo Snackbar
  void _mostrarMensaje(String texto, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Obtener asientos ya ocupados con esta función
  Future<List<String>> _obtenerAsientosOcupados(
      String idPelicula,
      String horario,
      String sala,
      DateTime fechaFuncion,
      ) async {
    try {// Formatea la fecha para evitar conflictos
      final fechaFormateada = DateFormat('yyyy-MM-dd').format(fechaFuncion);
      // Recupera los datos de firestore
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

  // Seleccionar/deseleccionar asiento
  void _seleccionarAsiento(String asiento) {
    setState(() {
      if (_misAsientos.contains(asiento)) {
        _misAsientos.remove(asiento); // Si ya está, lo quitamos
      } else {
        if (_misAsientos.length < widget.cantidadAsientos) {
          _misAsientos.add(asiento); // Añadimos si no hemos llegado al límite
        } else {
          // Mensaje si intenta seleccionar más de lo permitido
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Máximo ${widget.cantidadAsientos} asientos')),
          );
        }
      }
    });
  }
  // Widget principal
  @override
  Widget build(BuildContext context) {
    final tamanoPantalla = MediaQuery.of(context).size;
    final paddingHorizontal = 20.0;
    final espacioAsientos = 8.0;

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

                if (_disposicionSala.isEmpty) {
                  return const Center(
                    child: Text('No hay datos de asientos para esta sala'),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculamos el tamaño de los asientos según el ancho de pantalla
                    final maxAsientosFila = _disposicionSala.fold(
                        0, (max, fila) => fila.length > max ? fila.length : max);
                    final tamanoAsiento = ((tamanoPantalla.width - paddingHorizontal * 2) -
                        ((maxAsientosFila - 1) * espacioAsientos)) /
                        maxAsientosFila;
                    final tamanoFinal = tamanoAsiento.clamp(30.0, 60.0); // Tamaño mínimo/máximo

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: List.generate(_disposicionSala.length, (indiceFila) {
                          final fila = _disposicionSala[indiceFila];
                          final letraFila = String.fromCharCode(65 + indiceFila);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                Row(
                                  children: List.generate(fila.length, (indice) {
                                    final asiento = fila[indice];
                                    final estaOcupado = asientosOcupados.contains(asiento);
                                    final estaSeleccionado = _misAsientos.contains(asiento);
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
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Asientos: ${_misAsientos.join(', ')}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        '${_misAsientos.length}/${widget.cantidadAsientos}',
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
                      onPressed: _cargando ? null : _hacerReserva,
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