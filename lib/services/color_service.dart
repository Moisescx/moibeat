import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorService {
  /// Extrae el color dominante de una canción y genera un gradiente
  static Future<List<Color>> actualizarColorFondo(int idCancion) async {
    try {
      final OnAudioQuery audioQuery = OnAudioQuery();
      final Uint8List? arteBytes = await audioQuery.queryArtwork(
        idCancion,
        ArtworkType.AUDIO,
        size: 200,
      );

      if (arteBytes != null) {
        final PaletteGenerator paleta =
            await PaletteGenerator.fromImageProvider(MemoryImage(arteBytes));
        Color colorDominante =
            paleta.dominantColor?.color ?? const Color(0xFF1E1E1E);
        return [colorDominante, Colors.black];
      } else {
        return [const Color(0xFF1E1E1E), Colors.black];
      }
    } catch (e) {
      debugPrint("Error extrayendo color: $e");
      return [const Color(0xFF1E1E1E), Colors.black];
    }
  }
}
