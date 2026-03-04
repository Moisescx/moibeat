import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';


class VentanaActualizacion extends StatefulWidget {
  final String urlApk;
  final String versionNueva;

  const VentanaActualizacion({
    super.key, 
    required this.urlApk, 
    required this.versionNueva
  });

  @override
  State<VentanaActualizacion> createState() => _VentanaActualizacionState();
}

class _VentanaActualizacionState extends State<VentanaActualizacion> {
  double _progreso = 0.0;
  bool _descargando = false;
  String _estado = "Hay una nueva versión de MiBeat con mejoras. ¿Quieres instalarla ahora?";

  Future<void> _iniciarDescarga() async {
    setState(() {
      _descargando = true;
      _estado = "Descargando la actualización...";
    });

    try {
      final directorio = await getTemporaryDirectory();
      final rutaGuardado = "${directorio.path}/MiBeat_v${widget.versionNueva}.apk";
      Dio dio = Dio();

      await dio.download(
        widget.urlApk,
        rutaGuardado,
        onReceiveProgress: (recibido, total) {
          if (total != -1) {
            setState(() {
              _progreso = recibido / total;
            });
          }
        },
      );

      setState(() {
        _estado = "¡Descarga completa! Abriendo instalador...";
      });

      await OpenFilex.open(rutaGuardado);
      
      if (mounted) Navigator.pop(context);

    } catch (e) {
      setState(() {
        _estado = "Ocurrió un error al descargar 😅. Revisa tu internet.";
        _descargando = false;
      });
      debugPrint("Error OTA: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.greenAccent, size: 30),
          const SizedBox(width: 10),
          Text("Versión ${widget.versionNueva}", style: const TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Text(_estado, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          
          if (_descargando) ...[
            LinearProgressIndicator(
              value: _progreso,
              backgroundColor: Colors.grey[800],
              color: Colors.greenAccent,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 10),
            Text(
              "${(_progreso * 100).toStringAsFixed(0)}%", 
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18)
            ),
          ]
        ],
      ),
      actions: [
        if (!_descargando)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Quizás más tarde", style: TextStyle(color: Colors.grey)),
          ),
        if (!_descargando)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _iniciarDescarga,
            child: const Text("Descargar e Instalar", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}