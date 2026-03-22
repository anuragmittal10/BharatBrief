import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

enum PlaybackState { idle, loading, playing, paused, error }

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentArticleId;
  PlaybackState _state = PlaybackState.idle;

  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  bool _disposed = false;

  Stream<PlaybackState> get stateStream => _stateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

  PlaybackState get state => _state;
  String? get currentArticleId => _currentArticleId;
  bool get isPlaying => _state == PlaybackState.playing;

  VoidCallback? onComplete;

  AudioService() {
    _player.onPlayerStateChanged.listen((playerState) {
      switch (playerState) {
        case PlayerState.playing:
          _setState(PlaybackState.playing);
          break;
        case PlayerState.paused:
          _setState(PlaybackState.paused);
          break;
        case PlayerState.stopped:
          _setState(PlaybackState.idle);
          break;
        case PlayerState.completed:
          _setState(PlaybackState.idle);
          _currentArticleId = null;
          onComplete?.call();
          break;
        case PlayerState.disposed:
          break;
      }
    });

    _player.onPositionChanged.listen((position) {
      if (!_disposed) _positionController.add(position);
    });

    _player.onDurationChanged.listen((duration) {
      if (!_disposed) _durationController.add(duration);
    });
  }

  void _setState(PlaybackState newState) {
    _state = newState;
    if (!_disposed) _stateController.add(newState);
  }

  Future<void> play(String url, {String? articleId}) async {
    try {
      if (_currentArticleId == articleId && _state == PlaybackState.paused) {
        await _player.resume();
        return;
      }

      _setState(PlaybackState.loading);
      _currentArticleId = articleId;

      await _player.stop();
      await _player.setSourceUrl(url);
      await _player.resume();
    } catch (e) {
      _setState(PlaybackState.error);
      _currentArticleId = null;
    }
  }

  Future<void> pause() async {
    if (_state == PlaybackState.playing) {
      await _player.pause();
    }
  }

  Future<void> resume() async {
    if (_state == PlaybackState.paused) {
      await _player.resume();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentArticleId = null;
    _setState(PlaybackState.idle);
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setPlaybackRate(double rate) async {
    await _player.setPlaybackRate(rate);
  }

  void togglePlayPause(String url, {String? articleId}) {
    if (_currentArticleId == articleId && _state == PlaybackState.playing) {
      pause();
    } else if (_currentArticleId == articleId &&
        _state == PlaybackState.paused) {
      resume();
    } else {
      play(url, articleId: articleId);
    }
  }

  void dispose() {
    _disposed = true;
    _player.dispose();
    _stateController.close();
    _positionController.close();
    _durationController.close();
  }
}

typedef VoidCallback = void Function();
