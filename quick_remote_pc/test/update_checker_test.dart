import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/desktop/update_checker.dart';

String _release(String tag, {bool prerelease = false, bool draft = false, String? url}) => jsonEncode({
      'tag_name': tag,
      'prerelease': prerelease,
      'draft': draft,
      'html_url': url ?? 'https://github.com/berat-kaan-akcan/QuickRemote/releases/tag/$tag',
    });

void main() {
  group('SemVer', () {
    test('reads tags with and without v, short versions and pre-releases', () {
      expect(SemVer.tryParse('v1.2.3').toString(), '1.2.3');
      expect(SemVer.tryParse('0.3').toString(), '0.3.0');
      expect(SemVer.tryParse('1.0.0-rc.1+build.5').toString(), '1.0.0-rc.1');
      expect(SemVer.tryParse('latest'), isNull);
      expect(SemVer.tryParse(''), isNull);
    });

    test('orders by number, a pre-release before its release', () {
      SemVer v(String s) => SemVer.tryParse(s)!;
      expect(v('0.10.0') > v('0.9.9'), isTrue);
      expect(v('1.0.0') > v('1.0.0-rc.2'), isTrue);
      expect(v('1.0.0-rc.10') > v('1.0.0-rc.2'), isTrue);
      expect(v('1.0.0-beta') > v('1.0.0-1'), isTrue);
      expect(v('v1.2.0'), v('1.2'));
      expect(v('0.1.0') > v('0.1.0'), isFalse);
    });
  });

  group('ReleaseInfo.fromJson', () {
    test('takes a release and its page in this repo', () {
      final info = ReleaseInfo.fromJson(jsonDecode(_release('v0.3.0')))!;
      expect(info.version.toString(), '0.3.0');
      expect(info.page.toString(), 'https://github.com/berat-kaan-akcan/QuickRemote/releases/tag/v0.3.0');
    });

    test('skips drafts, pre-releases and tags that are no version', () {
      expect(ReleaseInfo.fromJson(jsonDecode(_release('v0.3.0', draft: true))), isNull);
      expect(ReleaseInfo.fromJson(jsonDecode(_release('v0.3.0', prerelease: true))), isNull);
      expect(ReleaseInfo.fromJson(jsonDecode(_release('nightly'))), isNull);
      expect(ReleaseInfo.fromJson(['v0.3.0']), isNull);
    });

    test('a page outside the repo is replaced by the releases page', () {
      final info = ReleaseInfo.fromJson(jsonDecode(_release('v0.3.0', url: 'https://evil.example/download')))!;
      expect(info.page.toString(), 'https://github.com/berat-kaan-akcan/QuickRemote/releases/latest');
      final http = ReleaseInfo.fromJson(
          jsonDecode(_release('v0.3.0', url: 'http://github.com/berat-kaan-akcan/QuickRemote/releases/x')))!;
      expect(http.page.isScheme('https'), isTrue);
    });
  });

  group('UpdateChecker', () {
    test('tells only a newer release', () async {
      Uri? asked;
      final checker = UpdateChecker(
        currentVersion: '0.2.0',
        fetch: (url) async {
          asked = url;
          return _release('v0.3.0');
        },
      );
      expect((await checker.check())?.version.toString(), '0.3.0');
      expect(asked, UpdateChecker.latestRelease);

      expect(await UpdateChecker(currentVersion: '0.3.0', fetch: (_) async => _release('v0.3.0')).check(), isNull);
      expect(await UpdateChecker(currentVersion: '0.4.0', fetch: (_) async => _release('v0.3.0')).check(), isNull);
    });

    test('a failed or broken answer is no update', () async {
      expect(await UpdateChecker(currentVersion: '0.2.0', fetch: (_) async => null).check(), isNull);
      expect(await UpdateChecker(currentVersion: '0.2.0', fetch: (_) async => '{not json').check(), isNull);
      expect(await UpdateChecker(currentVersion: '0.2.0', fetch: (_) async => throw Exception('offline')).check(), isNull);
    });

    test('a build without a version never finds one', () async {
      var asked = false;
      final checker = UpdateChecker(
        currentVersion: 'dev',
        fetch: (_) async {
          asked = true;
          return _release('v9.0.0');
        },
      );
      expect(await checker.check(), isNull);
      expect(asked, isFalse);
    });
  });
}
