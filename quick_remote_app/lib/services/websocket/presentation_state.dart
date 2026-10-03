class PresentationState {
  int currentSlide = 0;
  int totalSlides = 0;
  String slideNotes = '';
  bool isPptRunning = true;

  /// Presentation program on the PC ('powerpoint' on Windows, 'impress' on
  /// Linux; 'wps' while WPS runs the show).
  String presenter = 'powerpoint';

  /// Every program the PC controls (older PCs send only [presenter]).
  List<String> presenters = const ['powerpoint'];

  static String nameOf(String presenter) => switch (presenter) {
        'impress' => 'LibreOffice Impress',
        'wps' => 'WPS Office',
        _ => 'PowerPoint',
      };

  /// The program running the show, or while none does, every one the PC
  /// controls ("PowerPoint veya WPS Office").
  String get presenterName =>
      isPptRunning ? nameOf(presenter) : presenters.map(nameOf).join(' veya ');

  void updatePresenters(Map<String, dynamic> authReply) {
    presenter = authReply['presenter'] as String? ?? 'powerpoint';
    final list = authReply['presenters'];
    presenters = list is List && list.isNotEmpty ? list.whereType<String>().toList() : [presenter];
  }

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
    pptHasMedia = false;
    pptIsMediaPlaying = false;
    // Without a connection there is no "now playing" to show.
    hasMedia = false;
    mediaTitle = null;
    mediaArtist = null;
    mediaThumbnailBase64 = null;
    positionMs = 0;
    durationMs = 0;
    isPlaying = false;
    systemVolume = -1;
    systemMuted = false;
  }

  bool pptHasMedia = false;
  bool pptIsMediaPlaying = false;

  void updateFromSlideState(Map<String, dynamic> message) {
    isPptRunning = true;
    final running = message['presenter'];
    if (running is String) presenter = running;
    final newSlide = message['current'] as int? ?? 0;
    if (newSlide != currentSlide) {
      pptIsMediaPlaying = false;
    }
    currentSlide = newSlide;
    totalSlides = message['total'] as int? ?? 0;
    slideNotes = message['notes'] as String? ?? '';
    pptHasMedia = message['hasMedia'] as bool? ?? false;
    
    if (message['isMediaPlaying'] != null) {
      pptIsMediaPlaying = message['isMediaPlaying'] as bool;
    }
  }

  void updateFromSmtcState(Map<String, dynamic> message) {
    hasMedia = message['hasMedia'] as bool? ?? false;
    mediaTitle = message['title'] as String?;
    mediaArtist = message['artist'] as String?;
    // The PC sends the cover only when it changed; no key means "keep it".
    if (message.containsKey('thumbnail')) {
      mediaThumbnailBase64 = message['thumbnail'] as String?;
    }
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
