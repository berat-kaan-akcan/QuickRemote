/// Presentation sites the PC recognizes in a browser tab from its title:
/// SLIDE_STATE's `site` (`PresenterCaps.site`). They are not in the auth
/// reply's `presenters`, nor ever a `presenter`: a phone from before them
/// names every program it does not know "PowerPoint".
abstract class WebPresenters {
  /// PowerPoint for the web (the free PowerPoint in the browser).
  static const powerpointWeb = 'powerpointWeb';

  /// Google Slides.
  static const googleSlides = 'googleSlides';

  static const values = [powerpointWeb, googleSlides];

  static bool isWeb(String? presenter) => values.contains(presenter);
}
