import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:app_cine/screens/pago_screen.dart';

class SalasScreen extends StatefulWidget {
  final String peliculaId;
  final String titulo;
  final String cineteca;
  final String horario;
  final String sala;
  final int cantidadAsientos;
  final double precioTotal;
  final DateTime fechaFuncion;

  const SalasScreen({
    super.key,
    required this.peliculaId,
    required this.titulo,
    required this.cineteca,
    required this.horario,
    required this.sala,
    required this.cantidadAsientos,
    required this.precioTotal,
    required this.fechaFuncion,
  });

  @override
  State<SalasScreen> createState() => _SalasScreenState();
}

class _SalasScreenState extends State<SalasScreen> {
  late Future<List<String>> _asientosOcupadosFuture;

  final List<String> _asientosSeleccionados = [];
  bool _isLoading = false;
  List<List<String>> _salaConfiguracion = [];
  bool _loadingSala = true;
  @override
  void initState() {
    super.initState();

    _cargarConfiguracionSala();
    _asientosOcupadosFuture = getAsientosOcupados(
      widget.peliculaId,
      widget.horario,
      widget.sala,
      widget.fechaFuncion,
    );

    // Mostrar mensaje informativo sobre la cantidad de asientos a seleccionar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona ${widget.cantidadAsientos} asiento(s)'),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }


  String? _errorCarga;

  Future<void> _cargarConfiguracionSala() async {
    try {
      debugPrint('Buscando sala: "${widget.sala}"');

      final doc = await FirebaseFirestore.instance
          .collection('salas')
          .doc(widget.sala.trim())
          .get();

      if (doc.exists) {
        debugPrint('Documento encontrado: ${doc.data()}');

        final data = doc.data()!;
        List<List<String>> nuevaConfiguracion = [];

        // Letras de filas que podrían existir
        final letrasFilas = [
          'A', 'B', 'C', 'D', 'E', 'F',
          'G', 'H', 'I', 'I1', 'J', 'K', 'L', 'M', 'N',
          'O', 'P', 'Q', 'R'
        ];

        for (var fila in letrasFilas) {
          if (data.containsKey(fila)) {
            String asientosStr = data[fila] as String;
            debugPrint('Procesando fila $fila: $asientosStr');

            final asientoEsEspecial = RegExp(r'^[A-Z]1$').hasMatch(asientosStr.trim());

            if (asientoEsEspecial) {
              debugPrint('Fila $fila marcada como vacía ($asientosStr)');
              nuevaConfiguracion.add([]); // Fila vacía
              continue;
            }

            // Procesamiento normal
            List<String> asientos = asientosStr
                .split(',')
                .map((item) {
              final trimmed = item.trim().replaceAll('"', '');
              return (trimmed.isEmpty || RegExp(r'^[A-Z]1$').hasMatch(trimmed))
                  ? ''
                  : '$fila$trimmed';
            })
                .toList();

            debugPrint('Fila $fila procesada: $asientos');
            nuevaConfiguracion.add(asientos);
          }
        }

        setState(() {
          _salaConfiguracion = nuevaConfiguracion;
          _loadingSala = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar configuración de sala: $e');
      setState(() {
        _loadingSala = false;
      });
    }
  }

  Future<void> _guardarReserva() async {
    if (_asientosSeleccionados.isEmpty) {
      _mostrarSnackbar('Selecciona al menos un asiento');
      return;
    }

    if (_asientosSeleccionados.length != widget.cantidadAsientos) {
      _mostrarSnackbar('Debes seleccionar exactamente ${widget.cantidadAsientos} asiento(s)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // 1. Verificar disponibilidad de asientos (sin guardar aún)
      final asientosOcupados = await getAsientosOcupados(
        widget.peliculaId,
        widget.horario,
        widget.sala,
        widget.fechaFuncion,
      );

      final asientosConflictivos = _asientosSeleccionados
          .where((asiento) => asientosOcupados.contains(asiento))
          .toList();

      if (asientosConflictivos.isNotEmpty) {
        throw Exception('Asientos ${asientosConflictivos.join(', ')} ya están ocupados');
      }

      // 2. Preparar datos de reserva (sin guardar)
      final reservaData = {
        'peliculaId': widget.peliculaId,
        'titulo': widget.titulo,
        'cineteca': widget.cineteca,
        'horario': widget.horario,
        'sala': widget.sala,
        'asientos': _asientosSeleccionados,
        'cantidadAsientos': widget.cantidadAsientos,
        'precioTotal': widget.precioTotal,
        'fechaFuncion': DateFormat('yyyy-MM-dd').format(widget.fechaFuncion),
        'usuarioId': user.uid,
        'estado': 'pendiente_pago',
      };

      // 3. Navegar a pantalla de pago
      if (!mounted) return;
      final pagoExitoso = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => pago_screen(reservaData: reservaData),
        ),
      );

      // 4. Solo guardar si el pago fue exitoso
      if (pagoExitoso == true) {
        await FirebaseFirestore.instance.collection('reservas').add({
          ...reservaData,
          'fechaReserva': FieldValue.serverTimestamp(),
          'estado': 'completada',
        });

        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
        _mostrarSnackbar('Reserva y pago completados', isError: false);
      }

    } catch (e) {
      debugPrint('Error en reserva: $e');
      if (!mounted) return;
      _mostrarSnackbar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarSnackbar(String mensaje, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<List<String>> getAsientosOcupados(
      String peliculaId,
      String horario,
      String sala,
      DateTime fechaFuncion,
      ) async {
    try {
      final fechaFormateada = DateFormat('yyyy-MM-dd').format(fechaFuncion);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservas')
          .where('peliculaId', isEqualTo: peliculaId)
          .where('horario', isEqualTo: horario)
          .where('sala', isEqualTo: sala)
          .where('fechaFuncion', isEqualTo: fechaFormateada)
          .get();

      return querySnapshot.docs
          .expand((doc) => List<String>.from(doc.data()['asientos'] ?? []))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo asientos ocupados: $e');
      return [];
    }
  }

  void _toggleAsiento(String asiento) {
    setState(() {
      if (_asientosSeleccionados.contains(asiento)) {
        _asientosSeleccionados.remove(asiento);
      } else {
        if (_asientosSeleccionados.length < widget.cantidadAsientos) {
          _asientosSeleccionados.add(asiento);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Solo puedes seleccionar ${widget.cantidadAsientos} asientos')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final paddingHorizontal = 20.0;
    final espacioEntreAsientos = 8.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Selección de asientos - ${widget.sala}'),
      ),
      body: SingleChildScrollView(  // ScrollView vertical para toda la pantalla
        child: Column(
          children: [
            // Pantalla
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

            // Contenedor principal de asientos
            _loadingSala
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<String>>(
              future: getAsientosOcupados(
                  widget.peliculaId, widget.horario, widget.sala, widget.fechaFuncion),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final asientosOcupados = snapshot.data ?? [];

                if (_salaConfiguracion.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron asientos para esta sala'),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxAsientosPorFila = _salaConfiguracion.fold(
                        0, (max, fila) => fila.length > max ? fila.length : max);
                    final tamanoAsiento = ((screenSize.width - paddingHorizontal * 2) -
                        ((maxAsientosPorFila - 1) * espacioEntreAsientos)) /
                        maxAsientosPorFila;
                    final tamanoFinal = tamanoAsiento.clamp(30.0, 60.0);

                    return SingleChildScrollView(  // Scroll horizontal para las filas
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: List.generate(_salaConfiguracion.length, (filaIndex) {
                          final fila = _salaConfiguracion[filaIndex];
                          final letraFila = String.fromCharCode(65 + filaIndex);

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
                                  children: List.generate(fila.length, (index) {
                                    final asiento = fila[index];
                                    final isOcupado = asientosOcupados.contains(asiento);
                                    final isSelected = _asientosSeleccionados.contains(asiento);
                                    final isEmpty = asiento.isEmpty;
                                    final numeroAsiento = asiento.replaceAll(RegExp(r'^[A-Z]+'), '');

                                    return Container(
                                      width: tamanoFinal,
                                      height: tamanoFinal,
                                      margin: EdgeInsets.only(
                                        left: index == 0 ? 16.0 : 0,
                                        right: index < fila.length - 1 ? 8.0 : 0,
                                      ),
                                      child: GestureDetector(
                                        onTap: isEmpty || isOcupado
                                            ? null
                                            : () => _toggleAsiento(asiento),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isEmpty
                                                ? Colors.transparent
                                                : isOcupado
                                                ? Colors.red.withOpacity(0.7)
                                                : isSelected
                                                ? Colors.green
                                                : Colors.blue.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(6),
                                            border: isEmpty
                                                ? null
                                                : Border.all(
                                              color: isOcupado
                                                  ? Colors.red
                                                  : isSelected
                                                  ? Colors.green[800]!
                                                  : Colors.blue[700]!,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: isEmpty
                                                ? null
                                                : Text(
                                              numeroAsiento,
                                              style: TextStyle(
                                                fontSize: tamanoFinal * 0.35,
                                                color: isOcupado || isSelected
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

            // Resumen y botón de compra
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
                        'Asientos: ${_asientosSeleccionados.join(', ')}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        '${_asientosSeleccionados.length}/${widget.cantidadAsientos}',
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
                      onPressed: _isLoading ? null : _guardarReserva,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
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