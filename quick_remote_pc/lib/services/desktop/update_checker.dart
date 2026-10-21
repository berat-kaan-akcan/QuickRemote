import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_version.dart';

/// A semantic version (`1.2.3`, `1.2.3-beta.1`); build metadata is ignored.
@immutable
class SemVer implements Comparable<SemVer> {
  const SemVer(
    this.major,
    this.minor,
    this.patch, [
    this.preRelease = const [],
  ]);

  final int major;
  final int minor;
  final int patch;

  /// The dot-separated parts after `-`; empty for a release.
  final List<String> preRelease;

  static final _pattern = RegExp(
    r'^[vV]?(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$',
  );

  /// Reads `v1.2.3`, `1.2.3`, `1.2` or `1.2.3-rc.1`; null for anything else.
  static SemVer? tryParse(String text) {
    final m = _pattern.firstMatch(text.trim());
    if (m == null) return null;
    return SemVer(
      int.parse(m[1]!),
      int.parse(m[2] ?? '0'),
      int.parse(m[3] ?? '0'),
      m[4]?.split('.') ?? const [],
    );
  }

  @override
  int compareTo(SemVer other) {
    for (final (a, b) in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
    ]) {
      if (a != b) return a.compareTo(b);
    }
    // A pre-release comes before its release.
    if (preRelease.isEmpty || other.preRelease.isEmpty) {
      return other.preRelease.length.sign - preRelease.length.sign;
    }
    for (var i = 0; i < preRelease.length && i < other.preRelease.length; i++) {
      final a = preRelease[i], b = other.preRelease[i];
      final an = int.tryParse(a), bn = int.tryParse(b);
      final c = switch ((an, bn)) {
        (int x, int y) => x.compareTo(y),
        (int _, null) => -1, // numeric parts come before words
        (null, int _) => 1,
        _ => a.compareTo(b),
      };
      if (c != 0) return c;
    }
    return preRelease.length.compareTo(other.preRelease.length);
  }

  bool operator >(SemVer other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) => other is SemVer && compareTo(other) == 0;

  @override
  int get hashCode =>
      Object.hash(major, minor, patch, Object.hashAll(preRelease));

  @override
  String toString() =>
      '$major.$minor.$patch${preRelease.isEmpty ? '' : '-${preRelease.join('.')}'}';
}

/// The newest release on GitHub.
@immutable
class ReleaseInfo {
  const ReleaseInfo({required this.version, required this.page});

  final SemVer version;

  /// The release's page; always on github.com under [UpdateChecker.repoPage].
  final Uri page;

  /// Reads the `releases/latest` answer. Null for drafts, pre-releases and
  /// tags that are no version.
  static ReleaseInfo? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    if (json['draft'] == true || json['prerelease'] == true) return null;
    final tag = json['tag_name'];
    if (tag is! String) return null;
    final version = SemVer.tryParse(tag);
    if (version == null) return null;
    // The page opens in the browser: only a link into this repo is taken.
    final url = json['html_url'];
    final parsed = url is String ? Uri.tryParse(url) : null;
    final page =
        parsed != null &&
            parsed.isScheme('https') &&
            parsed.host == 'github.com' &&
            parsed.path.startsWith('${UpdateChecker.repoPage.path}/')
        ? parsed
        : UpdateChecker.repoPage.replace(
            path: '${UpdateChecker.repoPage.path}/releases/latest',
          );
    return ReleaseInfo(version: version, page: page);
  }
}

/// Fetches a URL's body; null when it could not be had.
typedef FetchText = Future<String?> Function(Uri url);

/// Asks GitHub for the newest release. Only tells: nothing is downloaded.
class UpdateChecker {
  UpdateChecker({FetchText? fetch, String currentVersion = appVersion})
    : _fetch = fetch ?? fetchWithHttpClient,
      current = SemVer.tryParse(currentVersion);

  static final latestRelease = Uri.parse(
    'https://api.github.com/repos/berat-kaan-akcan/QuickRemote/releases/latest',
  );
  static final repoPage = Uri.parse(
    'https://github.com/berat-kaan-akcan/QuickRemote',
  );

  final FetchText _fetch;

  /// This build's version; null when it is no version (then nothing is newer).
  final SemVer? current;

  /// The newest release when it is newer than this build; else null, also
  /// when GitHub could not be reached.
  Future<ReleaseInfo?> check() async {
    final current = this.current;
    if (current == null) return null;
    try {
      final body = await _fetch(latestRelease);
      if (body == null) return null;
      final release = ReleaseInfo.fromJson(jsonDecode(body));
      if (release == null || !(release.version > current)) return null;
      return release;
    } catch (e) {
      debugPrint('UpdateChecker: $e');
      return null;
    }
  }

  /// GET with dart:io's [HttpClient]: 10 s, at most 256 KB, 200 only.
  static Future<String?> fetchWithHttpClient(Uri url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client
          .getUrl(url)
          .timeout(const Duration(seconds: 10));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        // GitHub refuses API requests without a User-Agent.
        ..set(HttpHeaders.userAgentHeader, 'QuickRemote-PC/$appVersion');
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return null;
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 10))) {
        bytes.addAll(chunk);
        if (bytes.length > 256 * 1024) return null;
      }
      return utf8.decode(bytes);
    } finally {
      client.close(force: true);
    }
  }
}

/// Opens [url] in the default browser. Only https links are opened.
Future<void> openInBrowser(Uri url) async {
  if (!url.isScheme('https')) return;
  try {
    if (Platform.isWindows) {
      // explorer.exe hands a URL to the default browser.
      await Process.run('explorer', [url.toString()]);
    } else if (Platform.isLinux) {
      // gtk_show_uri_on_window, which hands the browser an activation
      // token: KWin and Mutter keep a browser started by a bare xdg-open
      // behind the window that asked for it.
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('openInBrowser: $e');
  }
}
