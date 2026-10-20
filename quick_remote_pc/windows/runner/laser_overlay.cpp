#include "laser_overlay.h"

#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <optional>
#include <string>
#include <utility>
#include <variant>

// GDI+ uses min and max, which NOMINMAX takes away.
namespace Gdiplus {
using std::max;
using std::min;
}  // namespace Gdiplus
#include <objidl.h>
#include <gdiplus.h>
#include <magnification.h>

namespace {

constexpr wchar_t kWindowClass[] = L"QuickRemoteLaserOverlay";

// AppColors.laser (#FF6A3D).
constexpr double kLaserR = 1.0;
constexpr double kLaserG = 0x6A / 255.0;
constexpr double kLaserB = 0x3D / 255.0;

// See-through like a highlighter on paper (as on Linux).
constexpr BYTE kHighlighterAlpha = 115;

// The spotlight: how dark the rest of the screen gets (of 255), and the
// circle's radius (fraction of the screen's height) with its soft edge, as
// on Linux.
constexpr double kShade = 0.6;
constexpr double kSpotRadius = 0.13;
constexpr double kSpotEdge = 0.15;

// The magnifier: twice as large, a circle a third of the screen's height
// across, its picture refreshed 30 times a second (a video plays under it).
constexpr float kZoom = 2.0f;
constexpr double kZoomSize = 0.32;
constexpr UINT kZoomRefreshMs = 33;
constexpr UINT_PTR kZoomTimer = 1;

// Another "always on top" window (a notification, the touch keyboard) can
// come above it; the overlay goes back on top this often while it moves.
constexpr ULONGLONG kRaiseEveryMs = 1000;

std::optional<double> NumberArg(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) return std::nullopt;
  if (const auto* d = std::get_if<double>(&it->second)) return *d;
  if (const auto* i = std::get_if<int32_t>(&it->second)) return static_cast<double>(*i);
  if (const auto* l = std::get_if<int64_t>(&it->second)) return static_cast<double>(*l);
  return std::nullopt;
}

bool BoolArg(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) return false;
  const auto* value = std::get_if<bool>(&it->second);
  return value != nullptr && *value;
}

// Premultiplied BGRA of the laser colour at [alpha] (0..1).
uint32_t Premultiplied(double r, double g, double b, double alpha) {
  alpha = std::clamp(alpha, 0.0, 1.0);
  const auto channel = [alpha](double c) { return static_cast<uint32_t>(std::lround(c * alpha * 255)); };
  return (static_cast<uint32_t>(std::lround(alpha * 255)) << 24) | (channel(r) << 16) | (channel(g) << 8) |
         channel(b);
}

// Shows the bitmap in [dc] in [window] at [x], [y]; only [dirty] changed,
// when given.
void Present(HWND window, HDC dc, int x, int y, int width, int height, const RECT* dirty) {
  POINT position = {x, y};
  SIZE size = {width, height};
  POINT source = {0, 0};
  BLENDFUNCTION blend = {AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
  UPDATELAYEREDWINDOWINFO info = {};
  info.cbSize = sizeof(info);
  info.pptDst = &position;
  info.psize = &size;
  info.hdcSrc = dc;
  info.pptSrc = &source;
  info.pblend = &blend;
  info.dwFlags = ULW_ALPHA;
  info.prcDirty = dirty;
  UpdateLayeredWindowIndirect(window, &info);
}

}  // namespace

LaserOverlay* LaserOverlay::instance_ = nullptr;

LaserOverlay::LaserOverlay(flutter::BinaryMessenger* messenger) {
  instance_ = this;
  Gdiplus::GdiplusStartupInput startup;
  Gdiplus::GdiplusStartup(&gdiplus_token_, &startup, nullptr);
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.quickremote.quick_remote_pc/overlay", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) { HandleMethodCall(call, std::move(result)); });
}

LaserOverlay::~LaserOverlay() {
  channel_->SetMethodCallHandler(nullptr);
  if (zoom_host_ != nullptr) {
    KillTimer(zoom_host_, kZoomTimer);
    DestroyWindow(zoom_host_);
  }
  if (magnification_) MagUninitialize();
  instance_ = nullptr;
  for (Layer* layer : {&dot_, &ink_, &shade_}) {
    if (layer->window != nullptr) DestroyWindow(layer->window);
    Free(*layer);
  }
  if (gdiplus_token_ != 0) Gdiplus::GdiplusShutdown(gdiplus_token_);
}

void LaserOverlay::HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
  const std::string& method = call.method_name();
  const auto point = [args]() -> std::optional<std::pair<double, double>> {
    if (args == nullptr) return std::nullopt;
    const auto x = NumberArg(*args, "x");
    const auto y = NumberArg(*args, "y");
    if (!x || !y) return std::nullopt;
    return std::make_pair(*x, *y);
  };
  if (method == "area") {
    if (!EnsureWindows()) {
      result->Success(flutter::EncodableValue(false));
      return;
    }
    std::optional<RECT> area;
    if (args != nullptr) {
      const auto x = NumberArg(*args, "x");
      const auto y = NumberArg(*args, "y");
      const auto width = NumberArg(*args, "width");
      const auto height = NumberArg(*args, "height");
      if (x && y && width && height) {
        area = RECT{static_cast<LONG>(*x), static_cast<LONG>(*y), static_cast<LONG>(*x + *width),
                    static_cast<LONG>(*y + *height)};
      }
    }
    UseMonitor(area ? &*area : nullptr);
    result->Success(flutter::EncodableValue(true));
    return;
  }
  if (dot_.window == nullptr) {
    // "area" comes first; without it there is nothing to draw on.
    result->Success();
    return;
  }
  if (method == "show") {
    laser_ = true;
    // The dot appears where the first move puts it.
    dot_.visible = false;
  } else if (method == "move") {
    if (const auto at = point()) Move(at->first, at->second);
  } else if (method == "hide") {
    Hide();
  } else if (method == "inkBegin") {
    const auto at = point();
    const auto rgb = args == nullptr ? std::nullopt : NumberArg(*args, "rgb");
    if (at && rgb) {
      InkBegin(BoolArg(*args, "highlighter"), static_cast<uint32_t>(*rgb), ToScreen(at->first, at->second));
    }
  } else if (method == "inkTo") {
    if (const auto at = point()) InkTo(ToScreen(at->first, at->second));
  } else if (method == "inkEnd") {
    stroking_ = false;
  } else if (method == "inkClear") {
    InkClear();
  } else if (method == "spotlight") {
    SetSpotlight(args != nullptr && BoolArg(*args, "on"));
  } else if (method == "zoom") {
    SetZoom(args != nullptr && BoolArg(*args, "on"));
  } else if (method == "blank") {
    const auto rgb = args == nullptr ? std::nullopt : NumberArg(*args, "rgb");
    SetBlank(rgb.has_value(), rgb ? static_cast<uint32_t>(*rgb) : 0);
  } else {
    result->NotImplemented();
    return;
  }
  result->Success();
}

bool LaserOverlay::EnsureWindows() {
  if (dot_.window != nullptr) return true;
  HINSTANCE instance = GetModuleHandle(nullptr);
  WNDCLASSEXW window_class = {};
  window_class.cbSize = sizeof(window_class);
  window_class.lpfnWndProc = DefWindowProcW;
  window_class.hInstance = instance;
  window_class.lpszClassName = kWindowClass;
  // A second registration fails harmlessly: the class is there already.
  RegisterClassExW(&window_class);
  // Layered: per-pixel alpha. Transparent: clicks go to the window below.
  // No-activate and tool window: it never takes the focus (the show's keys
  // go to the focused window) and has no taskbar button.
  const DWORD style = WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOPMOST | WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW;
  ink_.window = CreateWindowExW(style, kWindowClass, L"QuickRemote ink", WS_POPUP, 0, 0, 1, 1, nullptr, nullptr,
                                instance, nullptr);
  shade_.window = CreateWindowExW(style, kWindowClass, L"QuickRemote shade", WS_POPUP, 0, 0, 1, 1, nullptr, nullptr,
                                  instance, nullptr);
  dot_.window = CreateWindowExW(style, kWindowClass, L"QuickRemote laser", WS_POPUP, 0, 0, 1, 1, nullptr, nullptr,
                                instance, nullptr);
  if (dot_.window == nullptr || ink_.window == nullptr || shade_.window == nullptr) {
    for (Layer* layer : {&dot_, &ink_, &shade_}) {
      if (layer->window != nullptr) DestroyWindow(layer->window);
      layer->window = nullptr;
    }
    return false;
  }
  return true;
}

void LaserOverlay::UseMonitor(const RECT* area) {
  HMONITOR monitor = area != nullptr ? MonitorFromRect(area, MONITOR_DEFAULTTOPRIMARY)
                                     : MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO info = {};
  info.cbSize = sizeof(info);
  if (!GetMonitorInfoW(monitor, &info)) return;
  if (EqualRect(&info.rcMonitor, &monitor_) && dot_.dc != nullptr) return;
  monitor_ = info.rcMonitor;
  // The ink was drawn for the old monitor.
  InkClear();
  Free(ink_);
  RenderDot();
  // The shade, if any, covers the new monitor.
  if (shade_.visible) {
    ShowWindow(shade_.window, SW_HIDE);
    shade_.visible = false;
  }
  Free(shade_);
  spot_known_ = false;
  if (spotlight_ || blank_) RedrawShade(RECT{0, 0, monitor_.right - monitor_.left, monitor_.bottom - monitor_.top});
}

POINT LaserOverlay::ToScreen(double fx, double fy) const {
  fx = std::isfinite(fx) ? std::clamp(fx, 0.0, 1.0) : 0.5;
  fy = std::isfinite(fy) ? std::clamp(fy, 0.0, 1.0) : 0.5;
  const double width = static_cast<double>(monitor_.right - monitor_.left);
  const double height = static_cast<double>(monitor_.bottom - monitor_.top);
  return POINT{static_cast<LONG>(std::lround(fx * width)), static_cast<LONG>(std::lround(fy * height))};
}

void LaserOverlay::Move(double fx, double fy) {
  if (zoom_) {
    MoveZoom(ToScreen(fx, fy));
    return;
  }
  if (spotlight_) {
    const RECT before = SpotArea();
    spot_ = ToScreen(fx, fy);
    spot_known_ = true;
    RedrawShade(before);
    RedrawShade(SpotArea());
    return;
  }
  if (!laser_ || dot_.dc == nullptr) return;
  const POINT at = ToScreen(fx, fy);
  const int x = static_cast<int>(monitor_.left + at.x) - dot_.width / 2;
  const int y = static_cast<int>(monitor_.top + at.y) - dot_.height / 2;
  if (!dot_.visible) {
    Present(dot_.window, dot_.dc, x, y, dot_.width, dot_.height, nullptr);
    ShowWindow(dot_.window, SW_SHOWNOACTIVATE);
    dot_.visible = true;
    raised_at_ = 0;
  }
  const ULONGLONG now = GetTickCount64();
  const bool raise = now - raised_at_ >= kRaiseEveryMs;
  if (raise) raised_at_ = now;
  SetWindowPos(dot_.window, raise ? HWND_TOPMOST : nullptr, x, y, 0, 0,
               SWP_NOSIZE | SWP_NOACTIVATE | (raise ? 0 : SWP_NOZORDER));
}

void LaserOverlay::Hide() {
  laser_ = false;
  dot_.visible = false;
  ShowWindow(dot_.window, SW_HIDE);
}

void LaserOverlay::Restack() {
  // Each goes to the top of the topmost windows: the last one ends on top.
  for (Layer* layer : {&ink_, &shade_, &dot_}) {
    if (layer->visible) {
      SetWindowPos(layer->window, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }
  }
}

bool LaserOverlay::EnsureZoom() {
  if (zoom_view_ != nullptr) return true;
  if (!magnification_) {
    magnification_ = MagInitialize() != FALSE;
    if (!magnification_) return false;
  }
  HINSTANCE instance = GetModuleHandle(nullptr);
  // A magnifier's host must be layered (and opaque); transparent: clicks
  // go through it, as through the rest of the overlay.
  zoom_host_ = CreateWindowExW(WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOPMOST | WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW,
                               kWindowClass, L"QuickRemote zoom", WS_POPUP, 0, 0, 1, 1, nullptr, nullptr, instance,
                               nullptr);
  if (zoom_host_ == nullptr) return false;
  SetLayeredWindowAttributes(zoom_host_, 0, 255, LWA_ALPHA);
  zoom_view_ = CreateWindowExW(0, WC_MAGNIFIER, L"QuickRemote zoom view", WS_CHILD | WS_VISIBLE, 0, 0, 1, 1, zoom_host_,
                               nullptr, instance, nullptr);
  if (zoom_view_ == nullptr) {
    DestroyWindow(zoom_host_);
    zoom_host_ = nullptr;
    return false;
  }
  MAGTRANSFORM transform = {};
  transform.v[0][0] = kZoom;
  transform.v[1][1] = kZoom;
  transform.v[2][2] = 1.0f;
  MagSetWindowTransform(zoom_view_, &transform);
  // The overlay's own windows stay out of the magnified picture.
  HWND own[] = {zoom_host_, dot_.window, ink_.window, shade_.window};
  MagSetWindowFilterList(zoom_view_, MW_FILTERMODE_EXCLUDE, 4, own);
  return true;
}

void LaserOverlay::SetZoom(bool on) {
  if (on == zoom_) return;
  if (on && !EnsureZoom()) return;
  zoom_ = on;
  if (!on) {
    KillTimer(zoom_host_, kZoomTimer);
    ShowWindow(zoom_host_, SW_HIDE);
    zoom_visible_ = false;
    return;
  }
  // No dot under the magnifier.
  if (dot_.visible) {
    ShowWindow(dot_.window, SW_HIDE);
    dot_.visible = false;
  }
  const double height = static_cast<double>(monitor_.bottom - monitor_.top);
  zoom_size_ = static_cast<int>(std::lround(height * kZoomSize));
  SetWindowPos(zoom_host_, nullptr, 0, 0, zoom_size_, zoom_size_, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
  SetWindowPos(zoom_view_, nullptr, 0, 0, zoom_size_, zoom_size_, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
  // Round; the window owns the region from here on.
  SetWindowRgn(zoom_host_, CreateEllipticRgn(0, 0, zoom_size_ + 1, zoom_size_ + 1), TRUE);
  SetTimer(zoom_host_, kZoomTimer, kZoomRefreshMs, &LaserOverlay::OnZoomTick);
  // The magnifier appears where the first move puts it.
  zoom_visible_ = false;
}

void LaserOverlay::MoveZoom(POINT at) {
  if (zoom_view_ == nullptr) return;
  const LONG x = monitor_.left + at.x;
  const LONG y = monitor_.top + at.y;
  const LONG half = zoom_size_ / 2;
  // What it shows: the part of the screen under it, at its middle.
  const LONG reach = static_cast<LONG>(std::lround(static_cast<double>(zoom_size_) / (2.0 * kZoom)));
  RECT source = {x - reach, y - reach, x + reach, y + reach};
  MagSetWindowSource(zoom_view_, source);
  const ULONGLONG now = GetTickCount64();
  const bool raise = !zoom_visible_ || now - zoom_raised_at_ >= kRaiseEveryMs;
  if (raise) zoom_raised_at_ = now;
  SetWindowPos(zoom_host_, raise ? HWND_TOPMOST : nullptr, static_cast<int>(x - half), static_cast<int>(y - half), 0,
               0, SWP_NOSIZE | SWP_NOACTIVATE | (raise ? 0 : SWP_NOZORDER));
  if (!zoom_visible_) {
    ShowWindow(zoom_host_, SW_SHOWNOACTIVATE);
    zoom_visible_ = true;
  }
}

void CALLBACK LaserOverlay::OnZoomTick(HWND, UINT, UINT_PTR, DWORD) {
  // The picture under it changes (a video, the next slide): draw it again.
  if (instance_ != nullptr && instance_->zoom_visible_) InvalidateRect(instance_->zoom_view_, nullptr, FALSE);
}

void LaserOverlay::SetSpotlight(bool on) {
  if (on == spotlight_) return;
  spotlight_ = on;
  if (on) {
    // No dot under the spotlight; the circle starts in the middle.
    if (dot_.visible) {
      ShowWindow(dot_.window, SW_HIDE);
      dot_.visible = false;
    }
    spot_known_ = false;
  }
  RedrawShade(RECT{0, 0, monitor_.right - monitor_.left, monitor_.bottom - monitor_.top});
}

void LaserOverlay::SetBlank(bool on, uint32_t rgb) {
  blank_ = on;
  blank_rgb_ = rgb & 0xFFFFFF;
  RedrawShade(RECT{0, 0, monitor_.right - monitor_.left, monitor_.bottom - monitor_.top});
}

RECT LaserOverlay::SpotArea() const {
  const double height = static_cast<double>(monitor_.bottom - monitor_.top);
  const LONG extent = static_cast<LONG>(std::ceil(height * kSpotRadius)) + 2;
  POINT c = spot_;
  if (!spot_known_) c = POINT{(monitor_.right - monitor_.left) / 2, (monitor_.bottom - monitor_.top) / 2};
  return RECT{c.x - extent, c.y - extent, c.x + extent, c.y + extent};
}

void LaserOverlay::RedrawShade(RECT dirty) {
  if (!spotlight_ && !blank_) {
    if (shade_.visible) {
      ShowWindow(shade_.window, SW_HIDE);
      shade_.visible = false;
    }
    return;
  }
  const int width = static_cast<int>(monitor_.right - monitor_.left);
  const int height = static_cast<int>(monitor_.bottom - monitor_.top);
  if (shade_.dc == nullptr && !Allocate(shade_, width, height)) return;
  const RECT bounds = {0, 0, width, height};
  if (!IntersectRect(&dirty, &dirty, &bounds)) return;

  // Premultiplied: the blank screen is opaque, the shade is black.
  const uint32_t solid = 0xFF000000u | blank_rgb_;
  const uint32_t shade = static_cast<uint32_t>(std::lround(kShade * 255)) << 24;
  const double outer = height * kSpotRadius;
  const double inner = outer * (1 - kSpotEdge);
  POINT c = spot_;
  if (!spot_known_) c = POINT{width / 2, height / 2};
  for (LONG row = dirty.top; row < dirty.bottom; ++row) {
    uint32_t* line = shade_.bits + static_cast<size_t>(row) * static_cast<size_t>(width);
    for (LONG column = dirty.left; column < dirty.right; ++column) {
      uint32_t pixel = solid;
      if (!blank_) {
        const double d = std::hypot(static_cast<double>(column - c.x) + 0.5, static_cast<double>(row - c.y) + 0.5);
        if (d >= outer) {
          pixel = shade;
        } else if (d <= inner) {
          pixel = 0;
        } else {
          const double alpha = kShade * (d - inner) / (outer - inner);
          pixel = static_cast<uint32_t>(std::lround(alpha * 255)) << 24;
        }
      }
      line[column] = pixel;
    }
  }

  Present(shade_.window, shade_.dc, static_cast<int>(monitor_.left), static_cast<int>(monitor_.top), width, height,
          shade_.visible ? &dirty : nullptr);
  if (!shade_.visible) {
    ShowWindow(shade_.window, SW_SHOWNOACTIVATE);
    shade_.visible = true;
    Restack();
  }
}

void LaserOverlay::InkBegin(bool highlighter, uint32_t rgb, POINT at) {
  const double height = static_cast<double>(monitor_.bottom - monitor_.top);
  // About 4 and 22 px at 1080p, as on Linux.
  const float width =
      static_cast<float>(highlighter ? std::max(10.0, height * 0.02) : std::max(2.0, height * 0.0035));
  strokes_.push_back(Stroke{highlighter, rgb & 0xFFFFFF, width, {at}});
  stroking_ = true;
  const LONG pad = static_cast<LONG>(std::ceil(width / 2)) + 2;
  RedrawInk(RECT{at.x - pad, at.y - pad, at.x + pad, at.y + pad});
}

void LaserOverlay::InkTo(POINT to) {
  if (!stroking_ || strokes_.empty()) return;
  Stroke& stroke = strokes_.back();
  const POINT from = stroke.points.back();
  stroke.points.push_back(to);
  const LONG pad = static_cast<LONG>(std::ceil(stroke.width / 2)) + 2;
  RedrawInk(RECT{std::min(from.x, to.x) - pad, std::min(from.y, to.y) - pad, std::max(from.x, to.x) + pad,
                 std::max(from.y, to.y) + pad});
}

void LaserOverlay::InkClear() {
  strokes_.clear();
  stroking_ = false;
  if (ink_.visible) {
    ShowWindow(ink_.window, SW_HIDE);
    ink_.visible = false;
  }
  if (ink_.bits != nullptr) {
    std::fill(ink_.bits, ink_.bits + static_cast<size_t>(ink_.width) * static_cast<size_t>(ink_.height), 0u);
  }
}

void LaserOverlay::RedrawInk(RECT dirty) {
  const int width = static_cast<int>(monitor_.right - monitor_.left);
  const int height = static_cast<int>(monitor_.bottom - monitor_.top);
  if (ink_.dc == nullptr && !Allocate(ink_, width, height)) return;
  const RECT bounds = {0, 0, width, height};
  if (!IntersectRect(&dirty, &dirty, &bounds)) return;

  {
    // GDI+ draws straight into the window's bitmap, premultiplied as the
    // layered window wants it.
    Gdiplus::Bitmap bitmap(width, height, width * 4, PixelFormat32bppPARGB, reinterpret_cast<BYTE*>(ink_.bits));
    Gdiplus::Graphics graphics(&bitmap);
    const Gdiplus::Rect clip(static_cast<INT>(dirty.left), static_cast<INT>(dirty.top),
                             static_cast<INT>(dirty.right - dirty.left), static_cast<INT>(dirty.bottom - dirty.top));
    graphics.SetClip(clip);
    graphics.SetCompositingMode(Gdiplus::CompositingModeSourceCopy);
    Gdiplus::SolidBrush clear(Gdiplus::Color(0, 0, 0, 0));
    graphics.FillRectangle(&clear, clip);
    graphics.SetCompositingMode(Gdiplus::CompositingModeSourceOver);
    graphics.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
    for (const Stroke& stroke : strokes_) {
      const BYTE alpha = stroke.highlighter ? kHighlighterAlpha : 255;
      const Gdiplus::Color color(alpha, static_cast<BYTE>(stroke.rgb >> 16), static_cast<BYTE>(stroke.rgb >> 8),
                                 static_cast<BYTE>(stroke.rgb));
      if (stroke.points.size() == 1) {
        // A tap: a dot.
        Gdiplus::SolidBrush brush(color);
        const float r = stroke.width / 2;
        graphics.FillEllipse(&brush, static_cast<float>(stroke.points[0].x) - r,
                             static_cast<float>(stroke.points[0].y) - r, stroke.width, stroke.width);
        continue;
      }
      // One path per stroke: a highlighter crossing itself does not get
      // darker there.
      Gdiplus::GraphicsPath path;
      for (size_t i = 1; i < stroke.points.size(); ++i) {
        path.AddLine(static_cast<INT>(stroke.points[i - 1].x), static_cast<INT>(stroke.points[i - 1].y),
                     static_cast<INT>(stroke.points[i].x), static_cast<INT>(stroke.points[i].y));
      }
      Gdiplus::Pen pen(color, stroke.width);
      pen.SetStartCap(Gdiplus::LineCapRound);
      pen.SetEndCap(Gdiplus::LineCapRound);
      pen.SetLineJoin(Gdiplus::LineJoinRound);
      graphics.DrawPath(&pen, &path);
    }
    graphics.Flush(Gdiplus::FlushIntentionSync);
  }

  Present(ink_.window, ink_.dc, static_cast<int>(monitor_.left), static_cast<int>(monitor_.top), width, height,
          ink_.visible ? &dirty : nullptr);
  if (!ink_.visible) {
    ShowWindow(ink_.window, SW_SHOWNOACTIVATE);
    ink_.visible = true;
    Restack();
  }
}

bool LaserOverlay::Allocate(Layer& layer, int width, int height) {
  Free(layer);
  BITMAPINFO bitmap_info = {};
  bitmap_info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bitmap_info.bmiHeader.biWidth = width;
  bitmap_info.bmiHeader.biHeight = -height;  // top-down
  bitmap_info.bmiHeader.biPlanes = 1;
  bitmap_info.bmiHeader.biBitCount = 32;
  bitmap_info.bmiHeader.biCompression = BI_RGB;
  void* bits = nullptr;
  HDC screen = GetDC(nullptr);
  layer.dc = CreateCompatibleDC(screen);
  layer.bitmap = CreateDIBSection(screen, &bitmap_info, DIB_RGB_COLORS, &bits, nullptr, 0);
  ReleaseDC(nullptr, screen);
  if (layer.dc == nullptr || layer.bitmap == nullptr || bits == nullptr) {
    Free(layer);
    return false;
  }
  layer.old_bitmap = SelectObject(layer.dc, layer.bitmap);
  // A new DIB section is all zero: fully transparent.
  layer.bits = static_cast<uint32_t*>(bits);
  layer.width = width;
  layer.height = height;
  return true;
}

void LaserOverlay::Free(Layer& layer) {
  if (layer.dc != nullptr) {
    if (layer.old_bitmap != nullptr) SelectObject(layer.dc, layer.old_bitmap);
    DeleteDC(layer.dc);
  }
  if (layer.bitmap != nullptr) DeleteObject(layer.bitmap);
  layer.dc = nullptr;
  layer.bitmap = nullptr;
  layer.old_bitmap = nullptr;
  layer.bits = nullptr;
  layer.width = 0;
  layer.height = 0;
}

void LaserOverlay::RenderDot() {
  const double height = static_cast<double>(monitor_.bottom - monitor_.top);
  // About 1 % of the screen's height: 11 px at 1080p, as on Linux.
  radius_ = std::max(6.0, height / 100.0);
  const double glow = radius_ * 2.6;
  const int size = static_cast<int>(std::ceil(glow * 2)) + 4;
  if (dot_.visible) {
    // The next move shows the new bitmap.
    dot_.visible = false;
    ShowWindow(dot_.window, SW_HIDE);
  }
  if (!Allocate(dot_, size, size)) return;

  // The glow fades out from the dot; the dot has a light centre, so it reads
  // on a red or orange slide too (as linux/overlay/laser_overlay.cc draws it).
  const double centre = size / 2.0;
  for (int row = 0; row < size; ++row) {
    for (int column = 0; column < size; ++column) {
      const double d = std::hypot(column + 0.5 - centre, row + 0.5 - centre);
      uint32_t pixel = 0;
      if (d <= radius_ * 0.4) {
        // White over the laser at 85 %.
        const double w = 0.85;
        pixel = Premultiplied(w + (1 - w) * kLaserR, w + (1 - w) * kLaserG, w + (1 - w) * kLaserB, 1);
      } else if (d <= radius_) {
        pixel = Premultiplied(kLaserR, kLaserG, kLaserB, std::min(1.0, radius_ - d + 0.5));
      } else if (d <= glow) {
        const double from = radius_ * 0.6;
        const double t = (d - from) / (glow - from);
        pixel = Premultiplied(kLaserR, kLaserG, kLaserB, 0.55 * (1 - t));
      }
      dot_.bits[row * size + column] = pixel;
    }
  }
}
