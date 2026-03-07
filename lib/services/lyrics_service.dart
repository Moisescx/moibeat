import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
// import 'genius_service.dart'; // SUSPENDIDO

class LyricsService {
  /// Variable de control para habilitar/deshabilitar búsqueda en Genius
  static bool habilitarGeniusAPI = false;

  /// Busca letras en archivos locales que coincidan con la canción
  static Future<String?> buscarLetraLocal(SongModel cancion) async {
    try {
      String rutaAudio = cancion.data;
      String rutaBase = rutaAudio.substring(0, rutaAudio.lastIndexOf('.'));
      File archivoLrc = File("$rutaBase.lrc");
      File archivoTxt = File("$rutaBase.txt");

      if (await archivoLrc.exists()) {
        return await archivoLrc.readAsString();
      } else if (await archivoTxt.exists()) {
        return await archivoTxt.readAsString();
      }
      return null;
    } catch (e) {
      debugPrint("Error leyendo letra: $e");
      return null;
    }
  }

  /// Busca letras primero localmente, luego en Genius API
  static Future<String> obtenerLetra(SongModel cancion) async {
    // Paso 1: Buscar archivo local
    final letraLocal = await buscarLetraLocal(cancion);
    if (letraLocal != null) {
      return letraLocal;
    }

    // Paso 2: Si está habilitada Genius, buscar en internet (SUSPENDIDO)
    /*
    if (habilitarGeniusAPI) {
      final letraGenius = await GeniusService.obtenerLetra(
        cancion.title,
        cancion.artist,
      );

      if (letraGenius != null && letraGenius.isNotEmpty) {
        return letraGenius;
      }
    }
    */

    // Paso 3: Si todo falla, mostrar instrucciones
    return _obtenerMensajeAyuda(cancion, false); // Cambiado a false para no mencionar Genius
  }

  /// Mensaje de ayuda con instrucciones
  static String _obtenerMensajeAyuda(SongModel cancion, bool geniusHabilitado) {
    // Siempre mostrar solo la opción local, ya que Genius está suspendido
    return "No se encontró la letra.\n\n"
        "Para verla aquí, crea un archivo con el mismo nombre que la canción:\n\n"
        "${cancion.title}.lrc\n"
        "o\n"
        "${cancion.title}.txt\n\n"
        "Colócalo en la misma carpeta que el archivo de audio.";
  }
}
