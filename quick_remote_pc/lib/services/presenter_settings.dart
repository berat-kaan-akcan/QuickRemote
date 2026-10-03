/// Presentation preferences the platform input services read. The phone owns
/// them: it sends them after every connect and on change (SET_KEEP_INK), so
/// the PC does not store them.
class PresenterSettings {
  PresenterSettings._();

  /// Keep the ink on its slide on NEXT, PREV and jumps, so it shows again
  /// when the show comes back (what PowerPoint and Impress do by
  /// themselves). Off, the ink is erased before the show moves.
  static bool keepInkOnSlideChange = false;

  static bool get clearInkOnSlideChange => !keepInkOnSlideChange;
}
