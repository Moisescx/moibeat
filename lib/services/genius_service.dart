/*
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeniusService {
  static const String _geniusApiBase = 'https://api.genius.com';
  static final Dio _dio = Dio();
  
  // Token configurado en tiempo de ejecución
  static String? _configuredToken;

  /// Carga el token desde SharedPreferences
  static Future<String?> _obtenerToken() async {
    if (_configuredToken != null) {
      return _configuredToken;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('genius_api_key');
  }

  /// Busca la URL de la canción en Genius usando el título y artista
  static Future<String?> buscarCancionEnGenius(
    String titulo,
    String? artista,
  ) async {
    try {
      final token = await _obtenerToken();
      
      // Si no tenemos token válido, retornar null
      if (token == null || token.isEmpty) {
        debugPrint(
          'Genius API: Token no configurado. '
          'Configúralo en Ajustes > Búsqueda de letras',
        );
        return null;
      }

      final query = '$titulo ${artista ?? ''}'.trim();

      final response = await _dio.get(
        '$_geniusApiBase/search',
        queryParameters: {
          'q': query,
          'access_token': token,
        },
      );

      if (response.statusCode == 200) {
        final hits = response.data['response']['hits'] as List?;

        if (hits != null && hits.isNotEmpty) {
          // Obtener el primer resultado
          final firstResult = hits[0]['result'];
          final url = firstResult['url'] as String?;
          debugPrint('✅ Canción encontrada en Genius: $url');
          return url;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error buscando canción en Genius: $e');
      return null;
    }
  }

  /// Extrae las letras de una URL de Genius (requiere parseo HTML)
  /// NOTA: Esto funciona pero depende de la estructura HTML de Genius
  /// que puede cambiar en cualquier momento
  static Future<String?> obtenerLetraDeUrl(String url) async {
    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.data);

        // Buscar los contenedores de letras en Genius
        final lyricsContainers = document.querySelectorAll(
          '[data-lyrics-container="true"]',
        );

        if (lyricsContainers.isEmpty) {
          debugPrint('⚠️ No se encontraron letras en la URL de Genius');
          return null;
        }

        final StringBuffer letras = StringBuffer();

        for (var container in lyricsContainers) {
          final text = container.text;
          if (text.isNotEmpty) {
            letras.writeln(text);
          }
        }

        final resultado = letras.toString().trim();
        if (resultado.isNotEmpty) {
          debugPrint('✅ Letra obtenida correctamente (${resultado.length} caracteres)');
        }
        return resultado;
      }

      return null;
    } catch (e) {
      debugPrint('Error obteniendo letras de Genius: $e');
      return null;
    }
  }

  /// Busca y obtiene las letras en una sola llamada
  static Future<String?> obtenerLetra(
    String titulo,
    String? artista,
  ) async {
    try {
      debugPrint('🔍 Buscando letra de: $titulo - $artista');

      // Paso 1: Buscar la canción en Genius
      final url = await buscarCancionEnGenius(titulo, artista);
      if (url == null) {
        debugPrint('⚠️ Canción no encontrada en Genius');
        return null;
      }

      // Paso 2: Extraer las letras de la URL
      final letras = await obtenerLetraDeUrl(url);
      return letras;
    } catch (e) {
      debugPrint('Error en obtenerLetra: $e');
      return null;
    }
  }

  /// Configura el token de Genius API en tiempo de ejecución
  static void configurarToken(String token) {
    _configuredToken = token;
    debugPrint('✅ Token de Genius configurado');
  }
}
*/
