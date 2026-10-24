import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/websocket/presentation_state.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

void main() {
  test('names every program the PC controls while no show runs', () {
    final state = PresentationState()
      ..updatePresenters({'presenter': 'impress', 'presenters': ['impress', 'wps']})
      ..isPptRunning = false;
    expect(state.presenterNames, ['LibreOffice Impress', 'WPS Office']);
  });

  test('an older PC sends only its presenter', () {
    final state = PresentationState()
      ..updatePresenters({'presenter': 'impress'})
      ..isPptRunning = false;
    expect(state.presenterNames, ['LibreOffice Impress']);
  });

  test('the PC\'s name is kept as one short line', () {
    final state = PresentationState()..updatePresenters({'presenter': 'impress', 'name': '  berat\u202E  cachyos\n '});
    expect(state.pcName, 'berat cachyos');
    state.updatePresenters({'presenter': 'impress', 'name': 'a' * 100});
    expect(state.pcName, hasLength(PresentationState.maxNameLength));
    // An older PC, or anything that is not a name.
    for (final name in [null, '', '   ', 42]) {
      state.updatePresenters({'presenter': 'impress', 'name': name});
      expect(state.pcName, isNull);
    }
    // The end of a show resets the slides, not the connection's name.
    state
      ..updatePresenters({'presenter': 'impress', 'name': 'Ofis-PC'})
      ..reset();
    expect(state.pcName, 'Ofis-PC');
  });

  test('the PC tells its system; an older PC does not', () {
    final state = PresentationState()..updatePresenters({'presenter': 'powerpoint', 'platform': 'windows'});
    expect(state.platform, 'windows');
    state.updatePresenters({'presenter': 'impress'});
    expect(state.platform, isNull);
  });

  test('a PC with the laser overlay says so; an older PC does not', () {
    final state = PresentationState()..updatePresenters({'presenter': 'impress', 'overlay': true});
    expect(state.toolsAnywhere, isTrue);
    state.updatePresenters({'presenter': 'impress'});
    expect(state.toolsAnywhere, isFalse);
  });

  test('the slide state names the program running the show', () {
    final state = PresentationState()
      ..updatePresenters({'presenter': 'powerpoint', 'presenters': ['powerpoint', 'wps']})
      ..updateFromSlideState({'current': 0, 'total': 0, 'presenter': 'wps'});
    expect(state.presenterNames, ['WPS Office']);
  });

  test('the slide state tells what is in front and which tools work', () {
    final state = PresentationState()
      ..updateFromSlideState({
        'current': 2,
        'total': 9,
        'front': FrontWindow.show,
        'caps': [RemoteCaps.laser, RemoteCaps.pen, 'teleport', 7],
      });
    expect(state.caps?.front, FrontWindow.show);
    // Values this version does not know are left out.
    expect(state.caps?.caps, {RemoteCaps.laser, RemoteCaps.pen});

    // An unknown window is no window.
    state.updateFromSlideState({'current': 2, 'total': 9, 'front': 'tv', 'caps': <String>[]});
    expect(state.caps, const PresenterCaps());
  });

  test('an older PC sends no caps: the remote guesses as before', () {
    final state = PresentationState()
      ..updateFromSlideState({'current': 2, 'total': 9, 'caps': [RemoteCaps.laser]})
      ..updateFromSlideState({'current': 3, 'total': 9, 'front': FrontWindow.pdf});
    expect(state.caps, isNull);
  });

  test('the "no show" status names the program in front; a lost link forgets it', () {
    final state = PresentationState()
      ..updateFromStatus({'state': 'POWERPOINT_NOT_RUNNING', 'presenter': 'wps'});
    expect(state.frontPresenter, 'wps');
    // The empty SLIDE_STATE after it (without one) keeps it.
    state.updateCaps({'data': null}, keep: true);
    expect(state.frontPresenter, 'wps');
    state.updateCaps({'data': null, 'presenter': 'impress'}, keep: true);
    expect(state.frontPresenter, 'impress');
    state.reset();
    expect(state.frontPresenter, isNull);
  });

  test('the "no show" status may carry them; a lost link drops them', () {
    final state = PresentationState()
      ..updateFromStatus({
        'state': 'POWERPOINT_NOT_RUNNING',
        'front': FrontWindow.pdf,
        'caps': <String>[],
      });
    expect(state.isPptRunning, isFalse);
    expect(state.caps?.front, FrontWindow.pdf);
    // An empty SLIDE_STATE after it keeps them; one with caps replaces them.
    state.updateCaps({'data': null}, keep: true);
    expect(state.caps?.front, FrontWindow.pdf);
    state.updateCaps({'data': null, 'front': FrontWindow.browser, 'caps': <String>[]}, keep: true);
    expect(state.caps?.front, FrontWindow.browser);
    state.reset();
    expect(state.caps, isNull);
  });
}
