import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'pantalla_ajustes.dart';
import 'theme_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tabs/tab_artistas.dart';
import 'tabs/tab_canciones.dart';
import 'tabs/tab_playlists.dart';
import 'package:audio_service/audio_service.dart';
import 'main.dart';
import 'motor_audio.dart';
import 'widgets/player_sheet.dart';
import 'widgets/artist_songs_sheet.dart';
import 'widgets/song_options_sheet.dart';
import 'widgets/playlist_detail_sheet.dart';
import 'tabs/tab_favoritos.dart';
import 'services/color_service.dart';
// import 'services/lyrics_service.dart'; // SUSPENDIDO
import 'services/storage_service.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _reproductor = (motorAudioGlobal as MotorAudio).reproductor;
  SongModel? _cancionActual;
  int _indiceActual = -1;
  final ValueNotifier<int> _notificadorIndice = ValueNotifier(-1);
  final ValueNotifier<List<String>> _notificadorFavoritos = ValueNotifier([]);
  // final ValueNotifier<bool> _viendoLetra = ValueNotifier(false); // SUSPENDIDO
  // final ValueNotifier<String> _letraActual = ValueNotifier("Buscando letra..."); // SUSPENDIDO
  List<SongModel> _listaCanciones = [];
  List<SongModel> _colaReproduccion = [];
  StreamSubscription<int?>? _indexSub;

  List<String> _misPlaylists = [];

  final ValueNotifier<List<Color>> _coloresFondo = ValueNotifier([
    const Color(0xFF1E1E1E),
    Colors.black,
  ]);

  bool _tienePermiso = false;
  late Future<List<SongModel>> _cancionesFuture;

  @override
  void initState() {
    super.initState();
    _cargarPlaylists();
    _cargarFavoritos();
    // _cargarConfiguracionGenius(); // SUSPENDIDO

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pedirPermisos();
    });

    _indexSub = _reproductor.currentIndexStream.listen((index) {
      if (index != null && index < _colaReproduccion.length) {
        setState(() {
          _indiceActual = index;
          _cancionActual = _colaReproduccion[index];
          _actualizarColorFondo(_colaReproduccion[index].id);
          // _buscarLetra(_colaReproduccion[index]); // SUSPENDIDO
        });
        _notificadorIndice.value = index;
      }
    });
  }

  @override
  void dispose() {
    _indexSub?.cancel();
    _reproductor.dispose();
    _notificadorIndice.dispose();
    _coloresFondo.dispose();
    _notificadorFavoritos.dispose();
    // _viendoLetra.dispose(); // SUSPENDIDO
    // _letraActual.dispose(); // SUSPENDIDO
    super.dispose();
  }

  Future<void> _cargarPlaylists() async {
    final playlists = await StorageService.cargarPlaylists();
    setState(() {
      _misPlaylists = playlists;
    });
  }

  Future<void> _cargarFavoritos() async {
    _notificadorFavoritos.value = await StorageService.cargarFavoritos();
  }

  Future<void> _actualizarColorFondo(int idCancion) async {
    final colores = await ColorService.actualizarColorFondo(idCancion);
    _coloresFondo.value = colores;
  }

  // --- MÉTODOS DE LETRAS (SUSPENDIDOS) ---
  /*
  Future<void> _cargarConfiguracionGenius() async {
    final prefs = await SharedPreferences.getInstance();
    final geniusHabilitado = prefs.getBool('genius_habilitado') ?? false;
    LyricsService.habilitarGeniusAPI = geniusHabilitado;
    
    if (geniusHabilitado) {
      debugPrint('✅ Genius API habilitado');
    }
  }

  Future<void> _buscarLetra(SongModel cancion) async {
    _letraActual.value = "Buscando letra...\n🔍";
    final letra = await LyricsService.obtenerLetra(cancion);
    _letraActual.value = letra;
  }
  */

  Future<void> _pedirPermisos() async {
    PermissionStatus statusStorage = await Permission.storage.request();
    PermissionStatus statusAudio = await Permission.audio.request();

    if (statusStorage.isGranted || statusAudio.isGranted) {
      setState(() {
        _tienePermiso = true;
        _cancionesFuture = _audioQuery.querySongs(
          ignoreCase: true,
          orderType: OrderType.ASC_OR_SMALLER,
          sortType: null,
          uriType: UriType.EXTERNAL,
        );
        _cancionesFuture
            .then((songs) {
              final filtradas = songs.where((cancion) {
                final duracion = cancion.duration ?? 0;
                final esMusica = cancion.isMusic ?? true;
                final esAlarma = cancion.isAlarm ?? false;
                final esNotificacion = cancion.isNotification ?? false;
                return duracion >= 60000 &&
                    esMusica &&
                    !esAlarma &&
                    !esNotificacion;
              }).toList();
              setState(() {
                _listaCanciones = filtradas;
                _colaReproduccion = filtradas;
              });
            })
            .catchError((_) {});
      });
    }
  }

  void _reproducirCancion(int index) async {
    if (index < 0 || index >= _colaReproduccion.length) return;

    final tarjetasNotificacion = _colaReproduccion.map((cancion) {
      return MediaItem(
        id: cancion.id.toString(),
        album: cancion.album ?? "MiBeat",
        title: cancion.title,
        artist: cancion.artist ?? "Artista desconocido",
        artUri: Uri.parse(
          "content://media/external/audio/media/${cancion.id}/albumart",
        ),
      );
    }).toList();

    await motorAudioGlobal.updateQueue(tarjetasNotificacion);

    final listaParaElReproductor = ConcatenatingAudioSource(
      children: _colaReproduccion.map((cancion) {
        return AudioSource.uri(Uri.parse(cancion.uri!));
      }).toList(),
    );

    try {
      await _reproductor.setAudioSource(
        listaParaElReproductor,
        initialIndex: index,
      );
      _reproductor.play();
    } catch (e) {
      debugPrint("Error al reproducir: $e");
    }
  }

  void _mostrarPantallaReproduccion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ValueListenableBuilder<int>(
          valueListenable: _notificadorIndice,
          builder: (context, indiceActualizado, child) {
            if (indiceActualizado == -1) return const SizedBox.shrink();

            var cancionMostrar = _colaReproduccion[indiceActualizado];

            return PlayerSheet(
              cancionMostrar: cancionMostrar,
              reproductor: _reproductor,
              coloresFondo: _coloresFondo,
              // viendoLetra: _viendoLetra, // SUSPENDIDO
              // letraActual: _letraActual, // SUSPENDIDO
              notificadorFavoritos: _notificadorFavoritos,
              indiceActual: indiceActualizado,
              onAgregarAPlaylist: (cancion) {
                _mostrarOpcionesCancion(context, cancion);
              },
            );
          },
        );
      },
    );
  }

  void _mostrarCancionesArtista(BuildContext context, ArtistModel artista) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return ArtistSongsSheet(
          artista: artista,
          audioQuery: _audioQuery,
          onSongTap: (index, cancionesDelArtista) {
            setState(() {
              _colaReproduccion = cancionesDelArtista;
            });
            _reproducirCancion(index);
            _mostrarPantallaReproduccion(context);
          },
        );
      },
    );
  }

  void _mostrarOpcionesCancion(BuildContext context, SongModel cancion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SongOptionsSheet(cancion: cancion, playlists: _misPlaylists);
      },
    );
  }

  void _abrirPlaylist(BuildContext context, String nombrePlaylist) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> idsGuardados =
        prefs.getStringList('canciones_de_$nombrePlaylist') ?? [];

    List<SongModel> cancionesDeEstaPlaylist = _listaCanciones.where((cancion) {
      return idsGuardados.contains(cancion.id.toString());
    }).toList();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return PlaylistDetailSheet(
          nombrePlaylist: nombrePlaylist,
          cancionesDeEstaPlaylist: cancionesDeEstaPlaylist,
          onSongTap: (index, canciones) {
            setState(() {
              _colaReproduccion = canciones;
            });
            _reproducirCancion(index);
            _mostrarPantallaReproduccion(context);
          },
        );
      },
    );
  }

  void _mostrarDialogoCrearAlbum(BuildContext context) {
    TextEditingController controladorNombre = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Nueva Playlist",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controladorNombre,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Nombre de tu playlist (ej. Rock 90s)",
              hintStyle: TextStyle(color: Colors.grey[600]),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                String nombrePlaylist = controladorNombre.text.trim();
                if (nombrePlaylist.isNotEmpty &&
                    !_misPlaylists.contains(nombrePlaylist)) {
                  setState(() {
                    _misPlaylists.add(nombrePlaylist);
                  });

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setStringList(
                    'mis_playlists_guardadas',
                    _misPlaylists,
                  );

                  Navigator.pop(context);
                }
              },
              child: const Text(
                "Crear",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: notificadorTema,
      builder: (context, tema, child) {
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'MiBeat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PantallaAjustes(),
                      ),
                    );
                  },
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.only(left: 8),
                indicatorColor: Colors.greenAccent,
                labelColor: Colors.greenAccent,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Canciones'),
                  Tab(text: 'Playlists'),
                  Tab(text: 'Artistas'),
                  Tab(text: 'Favoritos'),
                ],
              ),
            ),

            // --- AQUÍ ESTÁN LAS 4 PANTALLAS ---
            body: TabBarView(
              children: [
                TabCanciones(
                  tienePermiso: _tienePermiso,
                  cancionesFuture: _tienePermiso ? _cancionesFuture : null,
                  listaCanciones: _listaCanciones,
                  onPlay: (indice, listaBase) {
                    setState(() {
                      _colaReproduccion = listaBase;
                    });
                    _reproducirCancion(indice);
                    _mostrarPantallaReproduccion(context);
                  },
                  onLongPress: (cancion) {
                    _mostrarOpcionesCancion(context, cancion);
                  },
                ),

                TabPlaylists(
                  playlists: _misPlaylists,
                  onCrearPlaylist: () {
                    _mostrarDialogoCrearAlbum(context);
                  },
                  onPlaylistTap: (nombre) {
                    _abrirPlaylist(context, nombre);
                  },
                ),

                TabArtistas(
                  audioQuery: _audioQuery,
                  onArtistTap: (artista) {
                    _mostrarCancionesArtista(context, artista);
                  },
                ),

                // --- NUEVA PESTAÑA DE FAVORITOS ---
                TabFavoritos(
                  listaCanciones: _listaCanciones,
                  notificadorFavoritos: _notificadorFavoritos,
                  onPlay: (index, cancionesFavoritas) {
                    setState(() {
                      _colaReproduccion = cancionesFavoritas;
                    });
                    _reproducirCancion(index);
                    _mostrarPantallaReproduccion(context);
                  },
                ),
              ],
            ),

            bottomNavigationBar: _cancionActual == null
                ? const SizedBox.shrink()
                : SafeArea(
                    child: GestureDetector(
                      onTap: () {
                        _mostrarPantallaReproduccion(context);
                      },
                      child: Container(
                        height: 72,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: [
                              // --- LA LÍNEA FINA DE PROGRESO ---
                              StreamBuilder<Duration>(
                                stream: _reproductor.positionStream,
                                builder: (context, snapshot) {
                                  final posicion =
                                      snapshot.data ?? Duration.zero;
                                  final duracion =
                                      _reproductor.duration ??
                                      const Duration(seconds: 1);

                                  double progreso =
                                      posicion.inMilliseconds /
                                      duracion.inMilliseconds;
                                  if (progreso.isNaN || progreso.isInfinite) {
                                    progreso = 0.0;
                                  }
                                  if (progreso > 1.0) progreso = 1.0;

                                  return LinearProgressIndicator(
                                    value: progreso,
                                    minHeight: 3,
                                    backgroundColor: Colors.grey[800],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.greenAccent,
                                        ),
                                  );
                                },
                              ),

                              // --- EL CONTENIDO DEL REPRODUCTOR ---
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 45,
                                          height: 45,
                                          child: QueryArtworkWidget(
                                            id: _cancionActual!.id,
                                            type: ArtworkType.AUDIO,
                                            artworkBorder: BorderRadius.zero,
                                            nullArtworkWidget: Container(
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.music_note,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _cancionActual!.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _cancionActual!.artist ??
                                                  "Artista desconocido",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      StreamBuilder<bool>(
                                        stream: _reproductor.playingStream,
                                        builder: (context, snapshot) {
                                          bool isPlaying =
                                              snapshot.data ?? false;
                                          return IconButton(
                                            icon: Icon(
                                              isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                            ),
                                            iconSize: 36,
                                            color: Colors.white,
                                            onPressed: () {
                                              if (isPlaying) {
                                                _reproductor.pause();
                                              } else {
                                                _reproductor.play();
                                              }
                                            },
                                          );
                                        },
                                      ),

                                      IconButton(
                                        icon: const Icon(
                                          Icons.skip_next_rounded,
                                        ),
                                        iconSize: 32,
                                        color: Colors.white,
                                        onPressed: () {
                                          _reproducirCancion(_indiceActual + 1);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
