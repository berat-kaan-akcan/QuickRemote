#ifndef RUNNER_LASER_OVERLAY_H_
#define RUNNER_LASER_OVERLAY_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <cstdint>
#include <memory>
#include <vector>

// QuickRemote's laser and ink overlay on Windows, above every other window
// (the slideshow, a browser in full screen), letting clicks through and
// never taking the focus, so keys still reach the show. Three layered
// windows, from the bottom: the ink and the shade (the spotlight's, or a
// black or white screen), each as large as the monitor, and the dot in a
// small one that follows the laser.
//
// Dart talks to it over the "com.quickremote.quick_remote_pc/overlay"
// channel (lib/services/overlay/windows_laser_overlay.dart); positions are
// fractions of the monitor (0..1):
//   area {x, y, width, height}?  the monitor holding that window's middle
//                                (the primary one without); a new monitor
//                                drops the ink
//   show                         the laser dot, from the next move
//   move {x, y}                  the dot's position
//   hide                         no dot
//   inkBegin {highlighter, rgb, x, y}, inkTo {x, y}, inkEnd, inkClear
//   spotlight {on}               the screen darkened but for a circle at
//                                the laser (move), in place of the dot
//   blank {rgb}?                 the whole screen in one color; none: off
//   zoom {on}                    a round magnifier (twice) at the laser
//                                (move), in place of the dot
// The ink is kept by the app (lib/services/input/overlay_input_service.dart),
// which erases and brings it back by clearing and drawing strokes again.
class LaserOverlay {
 public:
  explicit LaserOverlay(flutter::BinaryMessenger* messenger);
  ~LaserOverlay();

  LaserOverlay(const LaserOverlay&) = delete;
  LaserOverlay& operator=(const LaserOverlay&) = delete;

 private:
  struct Stroke {
    bool highlighter;
    uint32_t rgb;
    float width;
    std::vector<POINT> points;
  };

  // A layered window and the bitmap it shows.
  struct Layer {
    HWND window = nullptr;
    HDC dc = nullptr;
    HBITMAP bitmap = nullptr;
    HGDIOBJ old_bitmap = nullptr;
    uint32_t* bits = nullptr;
    int width = 0;
    int height = 0;
    bool visible = false;
  };

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  bool EnsureWindows();
  void UseMonitor(const RECT* area);
  void Move(double fx, double fy);
  void Hide();
  POINT ToScreen(double fx, double fy) const;

  void InkBegin(bool highlighter, uint32_t rgb, POINT at);
  void InkTo(POINT to);
  void InkClear();
  // Draws the ink inside [dirty] (monitor pixels) and shows it.
  void RedrawInk(RECT dirty);

  // Draws the dot for the monitor's size into the dot layer.
  void RenderDot();
  void SetSpotlight(bool on);
  void SetBlank(bool on, uint32_t rgb);
  // Draws the shade inside [dirty] (monitor pixels) and shows it; hides it
  // when there is none.
  void RedrawShade(RECT dirty);
  RECT SpotArea() const;
  // Ink below the shade below the dot.
  void Restack();
  bool EnsureZoom();
  void SetZoom(bool on);
  void MoveZoom(POINT at);
  static void CALLBACK OnZoomTick(HWND window, UINT message, UINT_PTR id, DWORD time);
  static bool Allocate(Layer& layer, int width, int height);
  static void Free(Layer& layer);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  ULONG_PTR gdiplus_token_ = 0;
  RECT monitor_ = {0, 0, 0, 0};
  Layer dot_;
  Layer ink_;
  Layer shade_;
  bool spotlight_ = false;
  bool blank_ = false;
  uint32_t blank_rgb_ = 0;
  // The spotlight's centre (monitor pixels) and whether a move placed it.
  POINT spot_ = {0, 0};
  bool spot_known_ = false;
  // The magnifier: a layered host window holding the system's magnifier
  // control (Magnification API).
  HWND zoom_host_ = nullptr;
  HWND zoom_view_ = nullptr;
  bool zoom_ = false;
  bool zoom_visible_ = false;
  bool magnification_ = false;
  int zoom_size_ = 0;
  ULONGLONG zoom_raised_at_ = 0;
  // The one overlay, for the magnifier's refresh timer.
  static LaserOverlay* instance_;
  double radius_ = 10;
  bool laser_ = false;
  ULONGLONG raised_at_ = 0;
  std::vector<Stroke> strokes_;
  bool stroking_ = false;
};

#endif  // RUNNER_LASER_OVERLAY_H_
