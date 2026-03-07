package com.example.reproductorw

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.audiofx.Equalizer
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.reproductorw/equalizer"
    private var equalizer: Equalizer? = null
    private var currentAudioSessionId: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initializeEqualizer" -> {
                        val audioSessionId = call.argument<Int>("audioSessionId") ?: 0
                        initializeEqualizer(audioSessionId)
                        result.success(equalizer != null)
                    }
                    "setBandLevel" -> {
                        val bandIndex = call.argument<Int>("bandIndex") ?: 0
                        val levelDb = call.argument<Int>("levelDb") ?: 0
                        setBandLevel(bandIndex, levelDb)
                        result.success(null)
                    }
                    "releaseEqualizer" -> {
                        releaseEqualizer()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun initializeEqualizer(audioSessionId: Int) {
        try {
            // Liberar ecualizador anterior si existe
            releaseEqualizer()
            
            currentAudioSessionId = audioSessionId
            
            // Crear ecualizador con el audioSessionId correcto
            // audioSessionId = 0 intenta usar el session default del sistema
            equalizer = Equalizer(0, audioSessionId)
            equalizer?.enabled = true
            
            // Verificar bandas disponibles
            val numBands = equalizer?.numberOfBands ?: 0
            Log.d("Equalizer", "✅ Ecualizador inicializado con $numBands bandas (sessionId: $audioSessionId)")
        } catch (e: Exception) {
            Log.e("Equalizer", "❌ Error inicializando ecualizador: ${e.message}")
            equalizer = null
        }
    }

    private fun setBandLevel(bandIndex: Int, levelDb: Int) {
        try {
            if (equalizer == null) {
                Log.w("Equalizer", "⚠️ Ecualizador no inicializado")
                return
            }

            // El ecualizador trabaja con valores en milidecibelios (mB)
            // Por lo que multiplicamos por 100: 1dB = 100mB
            val bandRange = equalizer?.bandLevelRange
            val minLevel = bandRange?.get(0)?.toInt() ?: -1500 // -15dB
            val maxLevel = bandRange?.get(1)?.toInt() ?: 1500   // +15dB

            // Limitar el valor entre el rango permitido y convertir a Short
            val levelMbInt = (levelDb * 100).coerceIn(minLevel, maxLevel)
            val levelMb = levelMbInt.toShort()

            // Obtener la banda y establecer el nivel
            val numBands = equalizer?.numberOfBands ?: 0
            if (bandIndex < numBands) {
                equalizer?.setBandLevel(bandIndex.toShort(), levelMb)
                Log.d("Equalizer", "🎚️ Banda $bandIndex -> ${levelDb}dB (${levelMb}mB)")
            } else {
                Log.w("Equalizer", "⚠️ Banda $bandIndex no existe (máximo: ${numBands-1})")
            }
        } catch (e: Exception) {
            Log.e("Equalizer", "❌ Error estableciendo banda $bandIndex: ${e.message}")
        }
    }

    private fun releaseEqualizer() {
        try {
            equalizer?.release()
            equalizer = null
            currentAudioSessionId = 0
            Log.d("Equalizer", "🔌 Ecualizador liberado")
        } catch (e: Exception) {
            Log.e("Equalizer", "❌ Error liberando ecualizador: ${e.message}")
        }
    }

    override fun onDestroy() {
        releaseEqualizer()
        super.onDestroy()
    }
}
