class PresentationState {
  int currentSlide = 0;
  int totalSlides = 0;
  String slideNotes = '';
  bool isPptRunning = true;

  bool hasMedia = false;
  String? mediaTitle;
  String? mediaArtist;
  String? mediaThumbnailBase64;
  int positionMs = 0;
  int durationMs = 0;
  bool isPlaying = false;
  int systemVolume = -1; // 0-100; -1 = bilinmiyor
  bool systemMuted = false;

  void reset() {
    currentSlide = 0;
    totalSlides = 0;
    slideNotes = '';
    isPptRunning = false;
  }

  void updateFromSlideState(Map<String, dynamic> message) {
    isPptRunning = true;
    currentSlide = message['current'] as int? ?? 0;
    totalSlides = message['total'] as int? ?? 0;
    slideNotes = message['notes'] as String? ?? '';
  }

  void updateFromSmtcState(Map<String, dynamic> message) {
    hasMedia = message['hasMedia'] as bool? ?? false;
    mediaTitle = message['title'] as String?;
    mediaArtist = message['artist'] as String?;
    mediaThumbnailBase64 = message['thumbnail'] as String?;
    positionMs = (message['positionMs'] as num?)?.toInt() ?? 0;
    durationMs = (message['durationMs'] as num?)?.toInt() ?? 0;
    isPlaying = message['isPlaying'] as bool? ?? false;
  }

  void updateFromStatus(Map<String, dynamic> message) {
    final state = message['state'] as String?;
    if (state == 'POWERPOINT_NOT_RUNNING') {
      isPptRunning = false;
    } else if (state == 'VOLUME_CHANGED') {
      final vol = message['volume'];
      final mut = message['muted'];
      if (vol != null) systemVolume = (vol as num).toInt();
      if (mut != null) systemMuted = mut as bool;
    }
  }
}
