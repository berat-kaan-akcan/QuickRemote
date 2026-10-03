import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../services/websocket_service.dart';
import 'app_localizations.dart';

/// The text for a [Failure] in the current language.
extension FailureText on AppLocalizations {
  String failure(Failure failure) => switch (failure) {
        RemoteFailure(:final error?, :final info) => remoteError(error, info),
        RemoteFailure(:final detail) => detail ?? errorUnknown,
        ConnectionFailure(:final error, :final detail) => connectionError(error, detail),
      };

  String remoteError(RemoteError error, [String? info]) => switch (error) {
        RemoteError.slideshowNotRunning => errorSlideshowNotRunning,
        RemoteError.slideshowStartFailed => errorSlideshowStartFailed,
        RemoteError.slideStateFailed => errorSlideStateFailed(info ?? ''),
        RemoteError.presenterNotResponding => errorPresenterNotResponding,
        RemoteError.presenterUnreachable => errorPresenterUnreachable,
        RemoteError.penColorFailed => errorPenColorFailed,
        RemoteError.inkEraseFailed => errorInkEraseFailed,
        RemoteError.pointerBusy => errorPointerBusy,
        RemoteError.noMedia => errorNoMedia,
        RemoteError.mediaReloaded => errorMediaReloaded,
        RemoteError.mediaNoTrigger => errorMediaNoTrigger,
        RemoteError.mediaNeedsFullscreen => errorMediaNeedsFullscreen,
        RemoteError.screenBlanked => errorScreenBlanked,
        RemoteError.impressUnreachable => errorImpressUnreachable,
        RemoteError.impressNoUno => errorImpressNoUno,
        RemoteError.impressUntrustedPipe => errorImpressUntrustedPipe,
        RemoteError.wpsNotInstalled => errorWpsNotInstalled,
        RemoteError.wpsNoPresentation => errorWpsNoPresentation,
        RemoteError.wpsStartFailed => errorWpsStartFailed,
        RemoteError.wpsOpenFromApp => errorWpsOpenFromApp,
        RemoteError.wpsHighlighterNeedsFocus => errorWpsHighlighterNeedsFocus,
        RemoteError.wpsNoMediaRewind => errorWpsNoMediaRewind,
        RemoteError.lockFailed => errorLockFailed,
        RemoteError.commandFailed => errorCommandFailed(info ?? ''),
      };

  String connectionError(ConnectionError error, [String? detail]) => switch (error) {
        ConnectionError.pinEmpty => connectionPinEmpty,
        ConnectionError.wrongPin => connectionWrongPin,
        ConnectionError.rateLimited => connectionRateLimited,
        ConnectionError.timeout => connectionTimeout,
        ConnectionError.authTimeout => connectionAuthTimeout,
        ConnectionError.serverNotFound => connectionServerNotFound(detail ?? ''),
        ConnectionError.certMismatch => connectionCertMismatch,
        ConnectionError.certRejected => connectionCertRejected,
        ConnectionError.unverified => connectionUnverified,
        ConnectionError.closedByPc => connectionClosedByPc,
        ConnectionError.closed => connectionClosed,
        ConnectionError.none || ConnectionError.unknown => connectionUnknown(detail ?? ''),
      };
}
