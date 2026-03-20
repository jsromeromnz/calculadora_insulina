import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// === NUEVA IMPORTACIÓN ===
import 'package:auto_size_text/auto_size_text.dart';

void main() {
  runApp(const InsulinAppGob());
}

class InsulinAppGob extends StatelessWidget {
  const InsulinAppGob({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculadora de Insulina',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        fontFamily: 'GobCL',
        useMaterial3: true,
      ),
      home: const PediatricoCalculatorGob(),
    );
  }
}

class PediatricoCalculatorGob extends StatefulWidget {
  const PediatricoCalculatorGob({super.key});

  @override
  State<PediatricoCalculatorGob> createState() =>
      _PediatricoCalculatorGobState();
}

class _PediatricoCalculatorGobState extends State<PediatricoCalculatorGob> {
  // Controladores de texto (se mantienen iguales)
  final _bgActualController = TextEditingController();
  final _bgObjetivoController = TextEditingController();
  final _carbsController = TextEditingController();
  final _ratioController = TextEditingController();
  final _isfController = TextEditingController();

  bool _useHalfUnits = true;
  double? _totalDose;
  bool _isHypo = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Cargar datos persistentes (se mantiene igual)
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ratioController.text = prefs.getString('ratio') ?? "";
      _isfController.text = prefs.getString('isf') ?? "";
      _bgObjetivoController.text = prefs.getString('bgObjetivo') ?? "";
      _useHalfUnits = prefs.getBool('halfUnits') ?? true;
    });
  }

  // Guardar datos persistentes (se mantiene igual)
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ratio', _ratioController.text);
    await prefs.setString('isf', _isfController.text);
    await prefs.setString('bgObjetivo', _bgObjetivoController.text);
    await prefs.setBool('halfUnits', _useHalfUnits);
  }

  void _calculate() {
    _saveData();

    double bgActual = double.tryParse(_bgActualController.text) ?? 0;
    double bgObjetivo = double.tryParse(_bgObjetivoController.text) ?? 0;
    double carbs = double.tryParse(_carbsController.text) ?? 0;
    double ratio = double.tryParse(_ratioController.text) ?? 0;
    double isf = double.tryParse(_isfController.text) ?? 0;

    // SAFEGUARD: Alerta de hipoglucemia (< 70 mg/dL)
    if (bgActual > 0 && bgActual < 70) {
      setState(() {
        _isHypo = true;
        _totalDose = null;
      });
      return;
    }

    if (ratio <= 0 || isf <= 0) {
      setState(() {
        _isHypo = false;
        _totalDose = null;
      });
      return;
    }

    setState(() {
      _isHypo = false;
      double foodBolus = carbs / ratio;
      double correction =
          (bgActual > bgObjetivo) ? (bgActual - bgObjetivo) / isf : 0;
      double rawDose = foodBolus + correction;

      if (_useHalfUnits) {
        _totalDose = (rawDose * 2).round() / 2;
      } else {
        _totalDose = rawDose.roundToDouble();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Definimos el color institucional para usarlo en la barra superior
    final Color institutionalBlue = Colors.blue.shade800;

    return Scaffold(
      // === CAMBIO 1: ELIMINAMOS LA APPBAR ESTÁNDAR ===
      body: Column(
        children: [
          // === CAMBIO 2: IMPLEMENTACIÓN DE LA BARRA SUPERIOR PERSONALIZADA ===
          // Usamos SafeArea para que el contenido no se corte por el notch/cámara
          SafeArea(
            bottom: false, // Solo queremos el SafeArea superior
            child: Container(
              height: 100, // Altura fija de la barra
              width: double.infinity, // Ocupa todo el ancho
              decoration: BoxDecoration(
                color: Colors.white, // Fondo base blanco
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  // --- 50% Izquierdo: LOGO (con fondo blanco) ---
                  Expanded(
                    flex: 1, // Esto garantiza el split perfecto del 50%
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(15.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain, // Escala la imagen para que quepa
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  // --- 50% Derecho: TEXTO (con fondo azul institucional) ---
                  Expanded(
                    flex: 1, // Split perfecto del 50%
                    child: Container(
                      color: institutionalBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // === CAMBIO 3: USO DE AUTOSIZETEXT ===
                          const AutoSizeText(
                            "UCM Pediatría",
                            maxLines: 1,
                            minFontSize:
                                12, // Tamaño mínimo antes de fallar (seguridad)
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 22, // Tamaño ideal
                            ),
                          ),
                          const SizedBox(height: 2),
                          const AutoSizeText(
                            "Calculadora de Insulina",
                            maxLines:
                                2, // Permite hasta 2 líneas si es necesario
                            minFontSize: 10,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                              fontSize: 16, // Tamaño ideal
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === CAMBIO 4: EL CONTENIDO SCROLLABLE VA DEBAJO DE LA BARRA ===
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_isHypo) _buildHypoWarning(),
                  _buildInputSection("Parámetros Guardados", [
                    _buildField(_ratioController, "Ratio (Gramos de HC por 1U)",
                        Icons.scale),
                    _buildField(
                        _isfController,
                        "Sensibilidad (mg/dL de glicemia por 1U)",
                        Icons.trending_down),
                    _buildField(_bgObjetivoController, "Glicemia Ideal",
                        Icons.track_changes),
                  ]),
                  const SizedBox(height: 16),
                  _buildInputSection("Datos del Momento", [
                    _buildField(
                        _bgActualController, "Glicemia Actual", Icons.bloodtype,
                        isCritical: true),
                    _buildField(_carbsController, "Carbohidratos (g)",
                        Icons.restaurant),
                  ]),
                  const SizedBox(height: 16),
                  _buildRoundingToggle(),
                  const SizedBox(height: 30),
                  _buildResultDisplay(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets auxiliares (se mantienen iguales) ---

  Widget _buildField(
      TextEditingController controller, String label, IconData icon,
      {bool isCritical = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isCritical ? Colors.red.shade700 : Colors.grey.shade700,
          ),
          prefixIcon:
              Icon(icon, color: isCritical ? Colors.red : Colors.blueGrey),
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: (_) => _calculate(),
      ),
    );
  }

  Widget _buildInputSection(String title, List<Widget> fields) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.blueAccent)),
            const Divider(),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _buildRoundingToggle() {
    return Column(
      children: [
        const Text(
          "Tipo de Lápiz",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12, // Espacio horizontal entre los chips
          runSpacing: 8, // Espacio vertical en caso de que necesiten envolver
          alignment: WrapAlignment.center,
          children: [
            ChoiceChip(
              label: const Text("Medias Unidades"),
              selected: _useHalfUnits,
              onSelected: (val) {
                setState(() {
                  _useHalfUnits = true;
                  _calculate();
                });
              },
            ),
            ChoiceChip(
              label: const Text("Unidades Enteras"),
              selected: !_useHalfUnits,
              onSelected: (val) {
                setState(() {
                  _useHalfUnits = false;
                  _calculate();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHypoWarning() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 2),
      ),
      child: const Column(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 48),
          SizedBox(height: 8),
          Text("¡ALERTA DE HIPOGLICEMIA!",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                  fontSize: 16)),
          Text(
            "Glicemia inferior a 70 mg/dL.\nNo administrar insulina. Corregir con 15g de HC rápidos.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _isHypo ? Colors.grey.shade200 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text("DOSIS RECOMENDADA",
              style: TextStyle(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.blueGrey)),
          const SizedBox(height: 8),
          Text(
            _totalDose != null ? "${_totalDose!.toStringAsFixed(1)} U" : "--",
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: _isHypo ? Colors.grey : Colors.blue.shade900,
            ),
          ),
          const Text("Insulina Ultrarrápida",
              style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
