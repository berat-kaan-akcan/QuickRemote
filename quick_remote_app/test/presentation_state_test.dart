import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/websocket/presentation_state.dart';

void main() {
  test('names every program the PC controls while no show runs', () {
    final state = PresentationState()
      ..updatePresenters({'presenter': 'impress', 'presenters': ['impress', 'wps']})
      ..isPptRunning = false;
    expect(state.presenterName, 'LibreOffice Impress veya WPS Office');
  });

  test('an older PC sends only its presenter', () {
    final state = PresentationState()
      ..updatePresenters({'presenter': 'impress'})
      ..isPptRunning = false;
    expect(state.presenterName, 'LibreOffice Impress');
  });

  test('the slide state names the program running the show', () {
    final state = PresentationState()
      ..updatePresenters({'presenter': 'powerpoint', 'presenters': ['powerpoint', 'wps']})
      ..updateFromSlideState({'current': 0, 'total': 0, 'presenter': 'wps'});
    expect(state.presenterName, 'WPS Office');
  });
}
