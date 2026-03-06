import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'pantalla_ajustes.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tab_artistas.dart';
import 'tab_canciones.dart';
import 'tab_playlists.dart';
import 'package:audio_service/audio_service.dart';
import 'main.dart'; 
import 'motor_audio.dart'; 

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
  List<SongModel> _listaCanciones = [];
  List<SongModel> _colaReproduccion = [];
  StreamSubscription<int?>? _indexSub;

  List<String> _misPlaylists = [];

  bool _tienePermiso = false;
  late Future<List<SongModel>> _cancionesFuture;

  @override
  void initState() {
    super.initState();
    _cargarPlaylists();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pedirPermisos();
    });

    _indexSub = _reproductor.currentIndexStream.listen((index) {
      if (index != null && index < _colaReproduccion.length) {
        setState(() {
          _indiceActual = index;
          _cancionActual = _colaReproduccion[index];
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
    super.dispose();
  }

  Future<void> _cargarPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _misPlaylists = prefs.getStringList('mis_playlists_guardadas') ?? [];
    });
  }

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

            return Container(
              height: MediaQuery.of(context).size.height * 0.95,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[850]!, Colors.black],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),

                    // --- CARÁTULA FLOTANTE ---
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: QueryArtworkWidget(
                          id: cancionMostrar.id,
                          type: ArtworkType.AUDIO,
                          artworkWidth: MediaQuery.of(context).size.width * 0.8,
                          artworkHeight:
                              MediaQuery.of(context).size.width * 0.8,
                          artworkBorder: BorderRadius.zero,
                          size: 1000,
                          quality: 100,
                          nullArtworkWidget: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.width * 0.8,
                            color: Colors.grey[900],
                            child: const Icon(
                              Icons.music_note,
                              size: 100,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // --- TÍTULO Y ARTISTA ---
                    TextScroll(
                      cancionMostrar.title,
                      mode: TextScrollMode.bouncing,
                      velocity: const Velocity(pixelsPerSecond: Offset(20, 0)),
                      delayBefore: const Duration(seconds: 3),
                      pauseBetween: const Duration(seconds: 10),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextScroll(
                      cancionMostrar.artist ?? "Artista desconocido",
                      mode: TextScrollMode.bouncing,
                      velocity: const Velocity(pixelsPerSecond: Offset(15, 0)),
                      delayBefore: const Duration(seconds: 3),
                      pauseBetween: const Duration(seconds: 10),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),
                    BarraDeProgreso(reproductor: _reproductor),
                    const SizedBox(height: 20),

                    // --- BOTONES ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // BOTÓN 1: SHUFFLE (Aleatorio)
                        StreamBuilder<bool>(
                          stream: _reproductor.shuffleModeEnabledStream,
                          builder: (context, snapshot) {
                            final isShuffle = snapshot.data ?? false;
                            return IconButton(
                              icon: Icon(
                                Icons.shuffle_rounded,
                                color: isShuffle
                                    ? Colors.greenAccent
                                    : Colors.white,
                              ),
                              iconSize: 28,
                              onPressed: () async {
                                final enable = !isShuffle;
                                if (enable)
                                  await _reproductor
                                      .shuffle(); 
                                await _reproductor.setShuffleModeEnabled(
                                  enable,
                                );
                              },
                            );
                          },
                        ),

                        // BOTÓN 2: ANTERIOR (Inteligente)
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          iconSize: 45,
                          color: Colors.white,
                          onPressed: () {
                            if (_reproductor.processingState ==
                                ProcessingState.idle) {
                              _reproducirCancion(
                                _indiceActual > 0 ? _indiceActual - 1 : 0,
                              );
                            } else if (_reproductor.hasPrevious) {
                              _reproductor.seekToPrevious();
                            }
                          },
                        ),

                        // BOTÓN 3: PLAY / PAUSA (Inteligente)
                        StreamBuilder<bool>(
                          stream: _reproductor.playingStream,
                          builder: (context, snapshot) {
                            bool isPlaying = snapshot.data ?? false;
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.greenAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                padding: const EdgeInsets.all(16),
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                iconSize: 45,
                                color: Colors.black,
                                onPressed: () {
                                  if (isPlaying) {
                                    _reproductor.pause();
                                  } else {
                                    if (_reproductor.processingState ==
                                        ProcessingState.idle) {
                                      _reproducirCancion(_indiceActual);
                                    } else {
                                      _reproductor.play();
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),

                        // BOTÓN 4: SIGUIENTE (Inteligente)
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          iconSize: 45,
                          color: Colors.white,
                          onPressed: () {
                            if (_reproductor.processingState ==
                                ProcessingState.idle) {
                              _reproducirCancion(_indiceActual + 1);
                            } else if (_reproductor.hasNext) {
                              _reproductor.seekToNext();
                            }
                          },
                        ),

                        // BOTÓN 5: REPETIR (Loop)
                        StreamBuilder<LoopMode>(
                          stream: _reproductor.loopModeStream,
                          builder: (context, snapshot) {
                            final loopMode = snapshot.data ?? LoopMode.off;
                            IconData icon = Icons.repeat_rounded;
                            Color color = Colors.white;

                            if (loopMode == LoopMode.all)
                              color = Colors.greenAccent;
                            else if (loopMode == LoopMode.one) {
                              icon = Icons.repeat_one_rounded;
                              color = Colors.greenAccent;
                            }

                            return IconButton(
                              icon: Icon(icon, color: color),
                              iconSize: 28,
                              onPressed: () async {
                                if (loopMode == LoopMode.off)
                                  await _reproductor.setLoopMode(LoopMode.all);
                                else if (loopMode == LoopMode.all)
                                  await _reproductor.setLoopMode(LoopMode.one);
                                else
                                  await _reproductor.setLoopMode(LoopMode.off);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
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
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.7, 
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Canciones de ${artista.artist}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: FutureBuilder<List<SongModel>>(
                  future: _audioQuery.queryAudiosFrom(
                    AudiosFromType.ARTIST_ID,
                    artista.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.greenAccent,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay canciones 😅',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    var cancionesDelArtista = snapshot.data!;

                    return ListView.builder(
                      itemCount: cancionesDelArtista.length,
                      itemBuilder: (context, index) {
                        var cancion = cancionesDelArtista[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                          ),
                          title: Text(
                            cancion.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            setState(() {
                              _colaReproduccion = cancionesDelArtista;
                            });
                            _reproducirCancion(index);

                            Navigator.pop(context);
                            _mostrarPantallaReproduccion(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Agregar '${cancion.title}' a...",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              if (_misPlaylists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Primero debes crear una playlist en la pestaña 'Playlists'",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ..._misPlaylists.map((nombrePlaylist) {
                  return ListTile(
                    leading: const Icon(
                      Icons.queue_music,
                      color: Colors.greenAccent,
                    ),
                    title: Text(
                      nombrePlaylist,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();

                      List<String> cancionesDeEstaPlaylist =
                          prefs.getStringList('canciones_de_$nombrePlaylist') ??
                          [];

                      String idCancion = cancion.id.toString();

                      if (!cancionesDeEstaPlaylist.contains(idCancion)) {
                        cancionesDeEstaPlaylist.add(idCancion);
                        await prefs.setStringList(
                          'canciones_de_$nombrePlaylist',
                          cancionesDeEstaPlaylist,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Agregada a $nombrePlaylist',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.greenAccent,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Esta canción ya está en la playlist',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }

                      Navigator.pop(context);
                    },
                  );
                }),
            ],
          ),
        );
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
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.85, 
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),

              // --- LA PORTADA INTELIGENTE DE LA PLAYLIST ---
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: cancionesDeEstaPlaylist.isNotEmpty
                      ? QueryArtworkWidget(
                          id: cancionesDeEstaPlaylist.first.id,
                          type: ArtworkType.AUDIO,
                          artworkBorder: BorderRadius.zero,
                          size: 500,
                          nullArtworkWidget: const Icon(
                            Icons.music_note,
                            size: 80,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(
                          Icons.queue_music,
                          size: 80,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                nombrePlaylist,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "${cancionesDeEstaPlaylist.length} canciones",
                style: const TextStyle(fontSize: 16, color: Colors.greenAccent),
              ),
              const SizedBox(height: 24),

              // --- LA LISTA DE CANCIONES ---
              Expanded(
                child: cancionesDeEstaPlaylist.isEmpty
                    ? Center(
                        child: Text(
                          "Aún no has agregado canciones aquí",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: cancionesDeEstaPlaylist.length,
                        itemBuilder: (context, index) {
                          var cancion = cancionesDeEstaPlaylist[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 45,
                                height: 45,
                                child: QueryArtworkWidget(
                                  id: cancion.id,
                                  type: ArtworkType.AUDIO,
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
                            title: Text(
                              cancion.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              cancion.artist ?? "Desconocido",
                              maxLines: 1,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            onTap: () {
                              setState(() {
                                _colaReproduccion = cancionesDeEstaPlaylist;
                              });
                              _reproducirCancion(index);
                              Navigator.pop(context);
                              _mostrarPantallaReproduccion(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
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
              Tab(text: 'Carpetas'),
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

            const Center(
              child: Text(
                '📁 Pantalla de Carpetas\n(Próximamente)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
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
                              final posicion = snapshot.data ?? Duration.zero;
                              final duracion =
                                  _reproductor.duration ??
                                  const Duration(seconds: 1);

                              double progreso =
                                  posicion.inMilliseconds /
                                  duracion.inMilliseconds;
                              if (progreso.isNaN || progreso.isInfinite)
                                progreso = 0.0;
                              if (progreso > 1.0) progreso = 1.0;

                              return LinearProgressIndicator(
                                value: progreso,
                                minHeight: 3,
                                backgroundColor: Colors.grey[800],
                                valueColor: const AlwaysStoppedAnimation<Color>(
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
                                      bool isPlaying = snapshot.data ?? false;
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
                                    icon: const Icon(Icons.skip_next_rounded),
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
  }
}

class BarraDeProgreso extends StatefulWidget {
  final AudioPlayer reproductor;
  const BarraDeProgreso({super.key, required this.reproductor});

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
      builder: (context, snapshot) {
        final posicionActual = snapshot.data ?? Duration.zero;
        final duracionTotal = widget.reproductor.duration ?? Duration.zero;

        double valorSlider =
            _valorArrastre ?? posicionActual.inSeconds.toDouble();
        double maxSlider = duracionTotal.inSeconds.toDouble();

        if (valorSlider > maxSlider) valorSlider = maxSlider;
        if (maxSlider <= 0) maxSlider = 1;

        return Column(
          children: [
            Slider(
              min: 0.0,
              max: maxSlider,
              value: valorSlider,
              activeColor: Colors.greenAccent,
              inactiveColor: Colors.grey[800],
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
                await widget.reproductor.seek(Duration(seconds: value.toInt()));
                if (_estabaReproduciendo) {
                  widget.reproductor.play();
                }
                setState(() {
                  _valorArrastre = null;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatearTiempo(Duration(seconds: valorSlider.toInt())),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    _formatearTiempo(duracionTotal),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
