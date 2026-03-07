import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  /// Carga la lista de playlists guardadas
  static Future<List<String>> cargarPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('mis_playlists_guardadas') ?? [];
  }

  /// Guarda las playlists
  static Future<void> guardarPlaylists(List<String> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('mis_playlists_guardadas', playlists);
  }

  /// Carga la lista de canciones favoritas
  static Future<List<String>> cargarFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('mis_favoritas') ?? [];
  }

  /// Guarda las canciones favoritas
  static Future<void> guardarFavoritos(List<String> favoritos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('mis_favoritas', favoritos);
  }

  /// Obtiene las canciones de una playlist específica
  static Future<List<String>> obtenerCancionesDePlaylist(
    String nombrePlaylist,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('canciones_de_$nombrePlaylist') ?? [];
  }

  /// Guarda las canciones de una playlist
  static Future<void> guardarCancionesDePlaylist(
    String nombrePlaylist,
    List<String> canciones,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('canciones_de_$nombrePlaylist', canciones);
  }

  /// Agrega una canción a una playlist
  static Future<void> agregarCancionAPlaylist(
    String nombrePlaylist,
    String idCancion,
  ) async {
    List<String> canciones = await obtenerCancionesDePlaylist(nombrePlaylist);
    if (!canciones.contains(idCancion)) {
      canciones.add(idCancion);
      await guardarCancionesDePlaylist(nombrePlaylist, canciones);
    }
  }

  /// Verifica si una canción está en una playlist
  static Future<bool> estaEnPlaylist(
    String nombrePlaylist,
    String idCancion,
  ) async {
    final canciones = await obtenerCancionesDePlaylist(nombrePlaylist);
    return canciones.contains(idCancion);
  }
}
