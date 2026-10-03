/// Why a command failed on the PC. The PC sends [code] in a COMMAND_FAILED
/// status and the phone shows it in its own language; the PC never sends
/// text meant for the screen.
enum RemoteError {
  slideshowNotRunning('NOT_RUNNING'),
  slideshowStartFailed('START_FAILED'),
  slideStateFailed('SLIDE_STATE_FAILED'),
  presenterNotResponding('TIMEOUT'),
  presenterUnreachable('PRESENTER_UNREACHABLE'),
  penColorFailed('PEN_COLOR_FAILED'),
  inkEraseFailed('ERASE_FAILED'),
  pointerBusy('POINTER_BUSY'),
  noMedia('NO_MEDIA'),
  mediaReloaded('MEDIA_RELOADED'),
  mediaNoTrigger('NO_MEDIA_TRIGGER'),
  mediaNeedsFullscreen('MEDIA_NEEDS_FULLSCREEN'),
  screenBlanked('SCREEN_BLANKED'),
  impressUnreachable('NO_CONNECTION'),
  impressNoUno('NO_UNO'),
  impressUntrustedPipe('UNTRUSTED_PIPE'),
  wpsNotInstalled('NO_RPC'),
  wpsNoPresentation('NO_PRESENTATION'),
  wpsStartFailed('WPS_START_FAILED'),
  wpsOpenFromApp('WPS_OPEN_FROM_APP'),
  wpsHighlighterNeedsFocus('WPS_HIGHLIGHTER_NEEDS_FOCUS'),
  wpsNoMediaRewind('WPS_NO_REWIND'),
  lockFailed('LOCK_FAILED'),

  /// Anything else; `info` carries the program's own error.
  commandFailed('COMMAND_FAILED');

  const RemoteError(this.code);

  /// The value on the wire.
  final String code;

  /// Null for a code this build does not know (a newer PC).
  static RemoteError? fromCode(Object? code) {
    for (final error in values) {
      if (error.code == code) return error;
    }
    return null;
  }

  /// The STATUS message reporting this error. [info] is untranslated
  /// detail (an exception, a program's error code), shown after the text.
  Map<String, Object> status([String? info]) => {
        'type': 'STATUS',
        'state': 'COMMAND_FAILED',
        'code': code,
        if (info != null) 'info': info,
        // Phones before error codes show only this.
        'detail': legacyDetail(info),
      };

  /// The Turkish text phones without error codes show. Frozen: new texts
  /// belong in the phone's ARB files.
  String legacyDetail([String? info]) => switch (this) {
        slideshowNotRunning => 'Slayt gösterisi aktif değil.',
        slideshowStartFailed => 'Slayt gösterisi başlatılamadı.',
        slideStateFailed => 'Slayt durumu alınamadı: ${info ?? ''}',
        presenterNotResponding => 'Sunum programı yanıt vermiyor.',
        presenterUnreachable => 'Sunum programına ulaşılamadı.',
        penColorFailed => 'Kalem rengi değiştirilemedi.',
        inkEraseFailed => 'Mürekkep silinemedi.',
        pointerBusy => 'Başka bir cihaz şu an lazeri veya kalemi kullanıyor.',
        noMedia => 'Bu slaytta medya yok.',
        mediaReloaded => 'Slayt yeniden yüklendi, video baştan başladı. Kontrol için tekrar deneyin.',
        mediaNoTrigger => 'Bu slayttaki medya kumandadan kontrol edilemiyor.',
        mediaNeedsFullscreen => 'Slayt medyası yalnızca tam ekran slayt gösterisinde kontrol edilebilir.',
        screenBlanked => 'Ekran karartılmışken slayt medyası kontrol edilemez.',
        impressUnreachable => 'LibreOffice Impress\'e bağlanılamadı.',
        impressNoUno => 'LibreOffice Python (UNO) desteği bulunamadı.',
        impressUntrustedPipe => 'LibreOffice bağlantı soketi başka bir kullanıcıya ait; bağlanılmadı.',
        wpsNotInstalled => 'WPS desteği kurulu değil.',
        wpsNoPresentation => 'WPS\'te açık sunum yok.',
        wpsStartFailed => 'WPS başlatılamadı.',
        wpsOpenFromApp => 'WPS\'te bu özellik yalnızca QuickRemote\'tan açılan sunumda çalışır ("Sunumu WPS ile aç").',
        wpsHighlighterNeedsFocus => 'WPS\'te fosforlu kalem yalnızca slayt gösterisi odaktayken seçilebilir.',
        wpsNoMediaRewind => 'WPS\'te video başa sarılamıyor.',
        lockFailed => 'Bilgisayar kilitlenemedi.',
        commandFailed => 'Sunum komutu başarısız: ${info ?? ''}',
      };
}
