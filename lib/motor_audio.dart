import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MotorAudio extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer reproductor = AudioPlayer();

  MotorAudio() {
    reproductor.playbackEventStream.listen(_notificarEstadoAlSistema);

    reproductor.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]); 
      }
    });
  }

  void _notificarEstadoAlSistema(PlaybackEvent event) {
    final playing = reproductor.playing;
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2], 
      
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[reproductor.processingState]!,
      playing: playing,
      updatePosition: reproductor.position,
      bufferedPosition: reproductor.bufferedPosition,
      speed: reproductor.speed,
      queueIndex: event.currentIndex,
    ));
  }

  
  @override
  Future<void> play() => reproductor.play();

  @override
  Future<void> pause() => reproductor.pause();

  @override
  Future<void> skipToNext() => reproductor.seekToNext();

  @override
  Future<void> skipToPrevious() => reproductor.seekToPrevious();

  @override
  Future<void> stop() async {
    await reproductor.stop();
    return super.stop();
  }
}