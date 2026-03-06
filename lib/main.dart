import 'package:flutter/material.dart';
import 'pantalla_principal.dart';
import 'theme_notifier.dart';
import 'package:audio_service/audio_service.dart';
import 'motor_audio.dart';

late AudioHandler motorAudioGlobal; // Variable global para acceder al motor de audio desde cualquier parte de la app


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

motorAudioGlobal = await AudioService.init(
    builder: () => MotorAudio(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mibeat.channel.audio',
      androidNotificationChannelName: 'MiBeat Reproductor',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );
  runApp(
    const MoiBeatApp(),
  ); 
}

class MoiBeatApp extends StatelessWidget {
  const MoiBeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: notificadorTema,
      builder: (context, modoActual, child) {
        return MaterialApp(
          title: 'MiBeat',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: modoActual,
          home: const PantallaPrincipal(),
        );
      },
    );
  }
}
