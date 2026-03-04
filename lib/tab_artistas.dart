import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class TabArtistas extends StatelessWidget {
  final OnAudioQuery audioQuery;
  final Function(ArtistModel) onArtistTap;

  const TabArtistas({
    super.key,
    required this.audioQuery,
    required this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ArtistModel>>(
      future: audioQuery.queryArtists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.greenAccent),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No encontré artistas 🎤',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        Map<String, List<ArtistModel>> agrupados = {};
        List<ArtistModel> especiales = [];

        for (var artista in snapshot.data!) {
          String nombre = artista.artist ?? "Desconocido";
          if (nombre == "<unknown>") nombre = "Desconocido";

          String primeraLetra = nombre[0].toUpperCase();

          if (RegExp(r'[A-Z]').hasMatch(primeraLetra)) {
            if (!agrupados.containsKey(primeraLetra)) {
              agrupados[primeraLetra] = [];
            }
            agrupados[primeraLetra]!.add(artista);
          } else {
            especiales.add(artista);
          }
        }

        List<String> letras = agrupados.keys.toList()..sort();

        if (especiales.isNotEmpty) {
          agrupados['#'] = especiales;
          letras.add('#');
        }

        return ListView.builder(
          itemCount: letras.length,
          itemBuilder: (context, index) {
            String letra = letras[index];
            List<ArtistModel> artistasDeEstaLetra = agrupados[letra]!;

            artistasDeEstaLetra.sort(
              (a, b) => (a.artist ?? "").compareTo(b.artist ?? ""),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- LA LETRA GIGANTE ---
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    top: 20.0,
                    bottom: 10.0,
                  ),
                  child: Text(
                    letra,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),

                // --- LOS ARTISTAS DE ESA LETRA ---
                ...artistasDeEstaLetra.map((artista) {
                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: SizedBox(
                          width: 55,
                          height: 55,
                          child: QueryArtworkWidget(
                            id: artista.id,
                            type: ArtworkType.ARTIST,
                            artworkBorder: BorderRadius.zero,
                            nullArtworkWidget: Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        artista.artist ?? "Desconocido",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "${artista.numberOfTracks} canciones",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      onTap: () {
                        onArtistTap(artista);
                      },
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}
