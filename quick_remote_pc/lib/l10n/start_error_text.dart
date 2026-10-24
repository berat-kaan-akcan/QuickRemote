import '../services/server/network/platform_network.dart';
import 'app_localizations.dart';

/// The reason a server start failed, in the UI language where it is known.
String startErrorText(AppLocalizations l10n, Object error) => switch (error) {
      TlsSetupException(error: TlsSetupError.opensslMissing) => l10n.opensslMissing,
      TlsSetupException(error: TlsSetupError.keyReadable, :final detail) => l10n.tlsKeyReadable(detail ?? ''),
      _ => '$error',
    };
