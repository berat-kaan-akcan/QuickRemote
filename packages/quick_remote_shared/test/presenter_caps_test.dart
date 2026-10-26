import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:test/test.dart';

void main() {
  test('toJson and fromJson round-trip', () {
    const caps = PresenterCaps(front: FrontWindow.show, caps: {RemoteCaps.pen, RemoteCaps.laser});
    final json = caps.toJson();
    expect(json, {
      'front': 'show',
      'caps': ['laser', 'pen'],
    });
    expect(PresenterCaps.fromJson(json), caps);
  });

  test('an unknown front is left out of the message', () {
    expect(const PresenterCaps(caps: {RemoteCaps.goto}).toJson(), {
      'caps': ['goto'],
    });
  });

  test('a state without caps (an older PC) gives null', () {
    expect(PresenterCaps.fromJson({'current': 1, 'total': 3}), isNull);
    expect(PresenterCaps.fromJson({'caps': 'laser'}), isNull);
  });

  test('values this version does not know are ignored', () {
    final caps = PresenterCaps.fromJson({
      'front': 'hologram',
      'caps': ['laser', 'teleport', 3, null],
    })!;
    expect(caps.front, isNull);
    expect(caps.caps, {RemoteCaps.laser});
  });

  test('an empty list means no tool works', () {
    final caps = PresenterCaps.fromJson({'front': 'pdf', 'caps': <Object>[]})!;
    expect(caps.front, FrontWindow.pdf);
    expect(caps.caps, isEmpty);
    expect(FrontWindow.isViewer(caps.front), isTrue);
    expect(FrontWindow.isViewer(FrontWindow.show), isFalse);
  });

  test('plus adds caps and keeps front; equality ignores order', () {
    const base = PresenterCaps(front: FrontWindow.other);
    final more = base.plus([RemoteCaps.spotlight, RemoteCaps.laser]);
    expect(more.front, FrontWindow.other);
    expect(more, const PresenterCaps(front: FrontWindow.other, caps: {RemoteCaps.laser, RemoteCaps.spotlight}));
    expect(more.hashCode, const PresenterCaps(front: FrontWindow.other, caps: {RemoteCaps.spotlight, RemoteCaps.laser}).hashCode);
    expect(more == base, isFalse);
  });

  test('a presentation site in front goes along, and plus keeps it', () {
    const caps = PresenterCaps(front: FrontWindow.browser, caps: {RemoteCaps.goto}, site: WebPresenters.googleSlides);
    final json = caps.toJson();
    expect(json, {
      'front': 'browser',
      'caps': ['goto'],
      'site': 'googleSlides',
    });
    expect(PresenterCaps.fromJson(json), caps);
    expect(caps.plus([RemoteCaps.laser]).site, WebPresenters.googleSlides);
    expect(caps == const PresenterCaps(front: FrontWindow.browser, caps: {RemoteCaps.goto}), isFalse);
    // A site this version does not know is left out; so is no site.
    expect(PresenterCaps.fromJson({'front': 'browser', 'caps': <Object>[], 'site': 'prezi'})!.site, isNull);
    expect(const PresenterCaps(front: FrontWindow.browser).toJson().containsKey('site'), isFalse);
  });
}
