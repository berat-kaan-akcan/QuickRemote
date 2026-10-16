import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/websocket/presentation_state.dart';

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

  test('the slide state names the program running the show', () {
    final state = PresentationState()
      ..updatePresenters({'presenter': 'powerpoint', 'presenters': ['powerpoint', 'wps']})
      ..updateFromSlideState({'current': 0, 'total': 0, 'presenter': 'wps'});
    expect(state.presenterNames, ['WPS Office']);
  });
}
