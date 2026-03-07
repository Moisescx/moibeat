import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class BarraDeProgreso extends StatefulWidget {
  final AudioPlayer reproductor;
  final ValueNotifier<List<Color>> coloresFondo;

  const BarraDeProgreso({
    super.key,
    required this.reproductor,
    required this.coloresFondo,
  });

  @override
  State<BarraDeProgreso> createState() => _BarraDeProgresoState();
}

class _BarraDeProgresoState extends State<BarraDeProgreso> {
  double? _valorArrastre;
  bool _estabaReproduciendo = false;

  String _formatearTiempo(Duration duracion) {
    String dosDigitos(int n) => n.toString().padLeft(2, "0");
    String minutos = dosDigitos(duracion.inMinutes.remainder(60));
    String segundos = dosDigitos(duracion.inSeconds.remainder(60));
    return "$minutos:$segundos";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.reproductor.positionStream,
      builder: (context, snapshotPosicion) {
        final posicionActual = snapshotPosicion.data ?? Duration.zero;
        final duracionTotal = widget.reproductor.duration ?? Duration.zero;

        double valorSlider =
            _valorArrastre ?? posicionActual.inSeconds.toDouble();
        double maxSlider = duracionTotal.inSeconds.toDouble();

        if (valorSlider > maxSlider) valorSlider = maxSlider;
        if (maxSlider <= 0) maxSlider = 1;

        return ValueListenableBuilder<List<Color>>(
          valueListenable: widget.coloresFondo,
          builder: (context, colores, child) {
            Color colorActivo =
                colores.isNotEmpty ? colores[0] : Colors.greenAccent;

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14.0,
                    ),
                    activeTrackColor: colorActivo,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor: colorActivo.withValues(alpha: 0.3),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: maxSlider,
                    value: valorSlider,
                    onChangeStart: (value) {
                      _estabaReproduciendo = widget.reproductor.playing;
                      widget.reproductor.pause();
                      setState(() {
                        _valorArrastre = value;
                      });
                    },
                    onChanged: (value) {
                      setState(() {
                        _valorArrastre = value;
                      });
                    },
                    onChangeEnd: (value) async {
                      await widget.reproductor.seek(
                        Duration(seconds: value.toInt()),
                      );
                      if (_estabaReproduciendo) {
                        widget.reproductor.play();
                      }
                      setState(() {
                        _valorArrastre = null;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatearTiempo(
                          Duration(seconds: valorSlider.toInt()),
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatearTiempo(duracionTotal),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
