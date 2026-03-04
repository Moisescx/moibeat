import 'package:flutter/material.dart';
import 'theme_notifier.dart';
import 'ventana_actualizacion.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes'), elevation: 0),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // --- EL INTERRUPTOR DE MODO OSCURO ---
          ValueListenableBuilder<ThemeMode>(
            valueListenable: notificadorTema,
            builder: (context, modoActual, child) {
              bool esOscuro = modoActual == ThemeMode.dark;

              return SwitchListTile(
                title: const Text('Modo Oscuro'),
                subtitle: const Text('Cambiar entre tema claro y oscuro'),
                secondary: Icon(esOscuro ? Icons.dark_mode : Icons.light_mode),
                value: esOscuro,
                activeThumbColor: Colors.greenAccent,
                onChanged: (valor) {
                  notificadorTema.value = valor
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.update, color: Colors.white),
            title: const Text(
              "Buscar actualizaciones",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              _buscarActualizacion(context);
            },
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Column(
              children: [
                const Text(
                  'MiBeat v2.0.0',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Desarrollado con ❤️ por MM',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- EL CEREBRO DE LAS ACTUALIZACIONES ---
  Future<void> _buscarActualizacion(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Buscando actualizaciones..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String versionActual = packageInfo.version; // Ej: "2.0.0"

      String urlJson =
          "https://raw.githubusercontent.com/Moisescx/mibeat/main/version.json";

      Dio dio = Dio();
      var respuesta = await dio.get(urlJson);

      var datos = respuesta.data is String
          ? jsonDecode(respuesta.data)
          : respuesta.data;
      String ultimaVersion = datos['ultima_version'];
      String linkApk = datos['link_apk'];

      if (ultimaVersion != versionActual &&
          _esVersionMayor(ultimaVersion, versionActual)) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => VentanaActualizacion(
            urlApk: linkApk,
            versionNueva: ultimaVersion,
          ),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡MiBeat está actualizado a la última versión! 😎"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al conectar con el servidor 😅"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _esVersionMayor(String internet, String actual) {
    List<int> vInternet = internet
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    List<int> vActual = actual
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    for (int i = 0; i < 3; i++) {
      if (vInternet.length > i && vActual.length > i) {
        if (vInternet[i] > vActual[i]) return true;
        if (vInternet[i] < vActual[i]) return false;
      }
    }
    return false;
  }
}
