import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

class EqualizerService {
  static const platform = MethodChannel('com.example.reproductorw/equalizer');

  /// Bandas de frecuencia: 60Hz, 250Hz, 1kHz, 4kHz, 16kHz
  static const List<String> bandLabels = ['60Hz', '250Hz', '1K', '4K', '16K'];
  static const List<int> bandCenterFrequencies = [60, 250, 1000, 4000, 16000];

  /// Presets predefinidos
  static const Map<String, List<int>> presets = {
    'Normal': [0, 0, 0, 0, 0],
    'Bass': [10, 8, 0, -5, -8],
    'Treble': [-8, -5, 0, 8, 10],
    'Rock': [8, 5, -5, 5, 8],
    'Pop': [5, 3, -2, 4, 7],
    'Voces': [-5, 5, 8, 5, -3],
    'Clásica': [-2, 0, 0, 3, 5],
  };

  /// Valores actuales del ecualizador (-15 a +15 dB)
  static final List<double> bandValues = [0, 0, 0, 0, 0];

  /// Inicializar ecualizador en Android con el audioPlayer
  static Future<bool> initialize(AudioPlayer audioPlayer) async {
    try {
      // Obtener el audioSessionId del reproductor
      int audioSessionId = audioPlayer.androidAudioSessionId ?? 0;
      
      debugPrint('📱 AudioSessionId obtenido: $audioSessionId');
      
      final result = await platform.invokeMethod<bool>('initializeEqualizer', {
        'audioSessionId': audioSessionId,
      });
      
      if (result == true) {
        debugPrint('✅ Ecualizador inicializado correctamente');
      }
      return result ?? false;
    } catch (e) {
      debugPrint('Error inicializando ecualizador: $e');
      return false;
    }
  }

  /// Establecer valor para una banda específica
  static Future<void> setBandLevel(int bandIndex, int levelDb) async {
    try {
      bandValues[bandIndex] = levelDb.toDouble();
      await platform.invokeMethod('setBandLevel', {
        'bandIndex': bandIndex,
        'levelDb': levelDb,
      });
      // Guardar preferencia
      await _saveBandPreference(bandIndex, levelDb);
    } catch (e) {
      debugPrint('Error al establecer banda $bandIndex: $e');
    }
  }

  /// Aplicar preset
  static Future<void> applyPreset(String presetName) async {
    try {
      final preset = presets[presetName];
      if (preset == null) return;

      for (int i = 0; i < preset.length; i++) {
        await setBandLevel(i, preset[i]);
      }
      
      // Guardar preset actual
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('equalizer_preset', presetName);
    } catch (e) {
      debugPrint('Error aplicando preset $presetName: $e');
    }
  }

  /// Guardar preferencia de banda
  static Future<void> _saveBandPreference(int bandIndex, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('eq_band_$bandIndex', value);
    } catch (e) {
      debugPrint('Error guardando preferencia de banda: $e');
    }
  }

  /// Cargar preferencias guardadas
  static Future<void> loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Intentar cargar preset guardado
      final savedPreset = prefs.getString('equalizer_preset');
      if (savedPreset != null && presets.containsKey(savedPreset)) {
        await applyPreset(savedPreset);
        return;
      }

      // Si no hay preset, cargar bandas individuales
      for (int i = 0; i < 5; i++) {
        final value = prefs.getInt('eq_band_$i') ?? 0;
        await setBandLevel(i, value);
      }
    } catch (e) {
      debugPrint('Error cargando preferencias del ecualizador: $e');
    }
  }

  /// Resetear ecualizador a valores por defecto
  static Future<void> reset() async {
    try {
      for (int i = 0; i < 5; i++) {
        await setBandLevel(i, 0);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('equalizer_preset');
      
      debugPrint('✅ Ecualizador reseteado');
    } catch (e) {
      debugPrint('Error reseteando ecualizador: $e');
    }
  }

  /// Obtener el preset actual
  static Future<String?> getCurrentPreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('equalizer_preset');
    } catch (e) {
      debugPrint('Error obteniendo preset actual: $e');
      return null;
    }
  }

  /// Releaser/Liberar recursos cuando la app se cierre
  static Future<void> release() async {
    try {
      await platform.invokeMethod('releaseEqualizer');
    } catch (e) {
      debugPrint('Error liberando ecualizador: $e');
    }
  }
}
