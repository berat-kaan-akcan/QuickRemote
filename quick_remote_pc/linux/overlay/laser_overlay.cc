// QuickRemote's laser and ink overlay for Linux: a see-through window above
// every other window (the slideshow, a video playing in it, a PDF viewer in
// full screen) that lets clicks through and never takes the focus.
//
// It runs as its own process with GDK_BACKEND=x11, since the Flutter window
// uses the Wayland backend and one GTK process cannot use both. On Wayland
// it is an XWayland override-redirect window, which KWin and Mutter keep
// above full-screen Wayland windows.
//
// Commands, one per line on stdin; positions are fractions of the monitor
// (0..1):
//   area X Y W H    use the monitor holding the middle of that window (the
//                   show's), in X root pixels; a bare "area": the primary
//                   one. A new monitor drops the ink.
//   show            the laser dot (it appears at the next move)
//   move X Y        the dot's position
//   hide            no laser dot
//   ink begin pen|highlighter RRGGBB X Y   a new stroke
//   ink to X Y      the stroke goes on to there
//   ink end         the stroke is done
//   ink clear       no ink
//   spotlight on|off  the screen darkened but for a circle at the laser's
//                   position (move), in place of the dot
//   blank RRGGBB|off  the whole screen in one color, above the ink
// The window is mapped only while it shows a dot or ink. The ink is kept by
// the app (lib/services/input/overlay_input_service.dart), which erases and
// brings it back by clearing and drawing the strokes again.
// It writes "ready W H" once the window exists, or "error <reason>" and
// exits with code 2 when the screen cannot show a see-through window. It
// exits when stdin closes (the app quit or crashed).

#include <gtk/gtk.h>

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

namespace {

// AppColors.laser (#FF6A3D).
constexpr double kLaserR = 1.0;
constexpr double kLaserG = 0x6A / 255.0;
constexpr double kLaserB = 0x3D / 255.0;

// See-through like a highlighter on paper.
constexpr double kHighlighterAlpha = 0.45;

// The spotlight: how dark the rest of the screen gets, and the circle's
// radius (fraction of the screen's height) with its soft edge.
constexpr double kShade = 0.6;
constexpr double kSpotRadius = 0.13;
constexpr double kSpotEdge = 0.15;

struct Point {
  double x;
  double y;
};

struct Stroke {
  bool highlighter;
  double r;
  double g;
  double b;
  double width;
  std::vector<Point> points;
};

struct Overlay {
  GtkWidget* window = nullptr;
  GdkRectangle monitor = {0, 0, 1920, 1080};
  // The dot's radius and its glow's, in window pixels.
  double radius = 10;
  double glow = 26;
  bool laser = false;
  bool has_position = false;
  double x = 0;
  double y = 0;
  // The area the dot was last drawn in, cleared on the next move.
  GdkRectangle drawn = {0, 0, 0, 0};
  std::vector<Stroke> strokes;
  bool stroking = false;
  bool spotlight = false;
  bool blank = false;
  double blank_r = 0;
  double blank_g = 0;
  double blank_b = 0;
  bool mapped = false;
};

Overlay overlay;

void reply(const char* line) {
  fputs(line, stdout);
  fputc('\n', stdout);
  fflush(stdout);
}

GdkRectangle dot_area() {
  const int extent = static_cast<int>(std::ceil(overlay.glow)) + 2;
  return {static_cast<int>(overlay.x) - extent, static_cast<int>(overlay.y) - extent,
          2 * extent, 2 * extent};
}

void queue_area(const GdkRectangle& area) {
  if (area.width > 0 && area.height > 0) {
    gtk_widget_queue_draw_area(overlay.window, area.x, area.y, area.width, area.height);
  }
}

// Pen and highlighter widths: about 4 and 22 px at 1080p.
double pen_width() { return std::fmax(2.0, overlay.monitor.height * 0.0035); }
double highlighter_width() { return std::fmax(10.0, overlay.monitor.height * 0.02); }

void draw_stroke(cairo_t* cr, const Stroke& stroke) {
  if (stroke.points.empty()) return;
  cairo_set_line_width(cr, stroke.width);
  cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND);
  cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND);
  cairo_move_to(cr, stroke.points[0].x, stroke.points[0].y);
  // A tap: a zero-length line, which the round cap makes a dot.
  if (stroke.points.size() == 1) cairo_line_to(cr, stroke.points[0].x, stroke.points[0].y);
  for (size_t i = 1; i < stroke.points.size(); ++i) cairo_line_to(cr, stroke.points[i].x, stroke.points[i].y);
  // One stroke of the whole path: a highlighter crossing itself does not
  // get darker there.
  cairo_set_source_rgba(cr, stroke.r, stroke.g, stroke.b, stroke.highlighter ? kHighlighterAlpha : 1.0);
  cairo_stroke(cr);
}

void draw_dot(cairo_t* cr) {
  cairo_pattern_t* glow = cairo_pattern_create_radial(
      overlay.x, overlay.y, overlay.radius * 0.6, overlay.x, overlay.y, overlay.glow);
  cairo_pattern_add_color_stop_rgba(glow, 0, kLaserR, kLaserG, kLaserB, 0.55);
  cairo_pattern_add_color_stop_rgba(glow, 1, kLaserR, kLaserG, kLaserB, 0);
  cairo_set_source(cr, glow);
  cairo_arc(cr, overlay.x, overlay.y, overlay.glow, 0, 2 * G_PI);
  cairo_fill(cr);
  cairo_pattern_destroy(glow);

  cairo_set_source_rgba(cr, kLaserR, kLaserG, kLaserB, 1);
  cairo_arc(cr, overlay.x, overlay.y, overlay.radius, 0, 2 * G_PI);
  cairo_fill(cr);

  // A light center, so the dot reads on a red or orange slide too.
  cairo_set_source_rgba(cr, 1, 1, 1, 0.85);
  cairo_arc(cr, overlay.x, overlay.y, overlay.radius * 0.4, 0, 2 * G_PI);
  cairo_fill(cr);
}

double spot_radius() { return overlay.monitor.height * kSpotRadius; }

// The spotlight's circle: where it is, or the middle before the first move.
Point spot_center() {
  if (overlay.has_position) return {overlay.x, overlay.y};
  return {overlay.monitor.width / 2.0, overlay.monitor.height / 2.0};
}

void draw_spotlight(cairo_t* cr) {
  const Point c = spot_center();
  const double outer = spot_radius();
  cairo_pattern_t* shade = cairo_pattern_create_radial(c.x, c.y, 0, c.x, c.y, outer);
  cairo_pattern_add_color_stop_rgba(shade, 1 - kSpotEdge, 0, 0, 0, 0);
  cairo_pattern_add_color_stop_rgba(shade, 1, 0, 0, 0, kShade);
  // Past the circle: the shade's last color.
  cairo_pattern_set_extend(shade, CAIRO_EXTEND_PAD);
  cairo_set_source(cr, shade);
  cairo_paint(cr);
  cairo_pattern_destroy(shade);
}

gboolean on_draw(GtkWidget*, cairo_t* cr, gpointer) {
  // Only the invalidated areas are drawn: clear them, then the ink, the
  // spotlight's shade or the blank screen above it, the dot on top.
  cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
  cairo_set_source_rgba(cr, 0, 0, 0, 0);
  cairo_paint(cr);
  cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
  for (const Stroke& stroke : overlay.strokes) draw_stroke(cr, stroke);
  if (overlay.blank) {
    cairo_set_source_rgb(cr, overlay.blank_r, overlay.blank_g, overlay.blank_b);
    cairo_paint(cr);
  } else if (overlay.spotlight) {
    draw_spotlight(cr);
  }
  if (overlay.laser && !overlay.spotlight && overlay.has_position) draw_dot(cr);
  return TRUE;
}

// Clicks go to the window below: the input shape is empty. GtkWindow sets
// the input shape back to the whole window on every size allocation
// (update_csd_shape), so it is emptied again after each one and on map;
// otherwise the overlay takes every click while it shows the ink.
void make_click_through(GtkWidget* widget) {
  GdkWindow* window = gtk_widget_get_window(widget);
  if (window == nullptr) return;
  cairo_region_t* empty = cairo_region_create();
  gdk_window_input_shape_combine_region(window, empty, 0, 0);
  cairo_region_destroy(empty);
}

void on_realize(GtkWidget* widget, gpointer) { make_click_through(widget); }

void on_size_allocate(GtkWidget* widget, GdkRectangle*, gpointer) { make_click_through(widget); }

void on_map(GtkWidget* widget, gpointer) { make_click_through(widget); }

// Mapped while there is something to show.
void update_mapped() {
  const bool wanted = overlay.laser || overlay.spotlight || overlay.blank || !overlay.strokes.empty();
  if (wanted == overlay.mapped) return;
  overlay.mapped = wanted;
  if (wanted) {
    gtk_widget_show(overlay.window);
    // Above windows mapped or raised since it was last shown.
    GdkWindow* window = gtk_widget_get_window(overlay.window);
    if (window != nullptr) gdk_window_raise(window);
  } else {
    gtk_widget_hide(overlay.window);
  }
}

void show() {
  if (overlay.laser) return;
  overlay.laser = true;
  overlay.has_position = false;
  update_mapped();
  // Above windows raised since (the show came to the front).
  GdkWindow* window = gtk_widget_get_window(overlay.window);
  if (window != nullptr) gdk_window_raise(window);
}

void hide() {
  if (!overlay.laser) return;
  overlay.laser = false;
  overlay.has_position = false;
  queue_area(overlay.drawn);
  overlay.drawn = {0, 0, 0, 0};
  update_mapped();
}

Point to_window(double fx, double fy) {
  fx = fx < 0 ? 0 : (fx > 1 ? 1 : fx);
  fy = fy < 0 ? 0 : (fy > 1 ? 1 : fy);
  return {fx * overlay.monitor.width, fy * overlay.monitor.height};
}

GdkRectangle spot_area() {
  const Point c = spot_center();
  const int extent = static_cast<int>(std::ceil(spot_radius())) + 2;
  return {static_cast<int>(c.x) - extent, static_cast<int>(c.y) - extent, 2 * extent, 2 * extent};
}

void move(double fx, double fy) {
  if (!overlay.laser && !overlay.spotlight) return;
  const Point point = to_window(fx, fy);
  overlay.x = point.x;
  overlay.y = point.y;
  overlay.has_position = true;
  queue_area(overlay.drawn);
  overlay.drawn = overlay.spotlight ? spot_area() : dot_area();
  queue_area(overlay.drawn);
}

void set_spotlight(bool on) {
  if (on == overlay.spotlight) return;
  overlay.spotlight = on;
  if (on) {
    overlay.has_position = false;
    overlay.drawn = spot_area();
  }
  update_mapped();
  gtk_widget_queue_draw(overlay.window);
  if (on) {
    GdkWindow* window = gtk_widget_get_window(overlay.window);
    if (window != nullptr) gdk_window_raise(window);
  }
}

void set_blank(bool on, unsigned rgb) {
  overlay.blank = on;
  overlay.blank_r = ((rgb >> 16) & 0xFF) / 255.0;
  overlay.blank_g = ((rgb >> 8) & 0xFF) / 255.0;
  overlay.blank_b = (rgb & 0xFF) / 255.0;
  update_mapped();
  gtk_widget_queue_draw(overlay.window);
  if (on) {
    GdkWindow* window = gtk_widget_get_window(overlay.window);
    if (window != nullptr) gdk_window_raise(window);
  }
}

GdkRectangle segment_area(const Point& a, const Point& b, double width) {
  const double pad = width / 2 + 2;
  const int x0 = static_cast<int>(std::floor(std::fmin(a.x, b.x) - pad));
  const int y0 = static_cast<int>(std::floor(std::fmin(a.y, b.y) - pad));
  const int x1 = static_cast<int>(std::ceil(std::fmax(a.x, b.x) + pad));
  const int y1 = static_cast<int>(std::ceil(std::fmax(a.y, b.y) + pad));
  return {x0, y0, x1 - x0, y1 - y0};
}

void ink_clear() {
  overlay.strokes.clear();
  overlay.stroking = false;
  gtk_widget_queue_draw(overlay.window);
  update_mapped();
}

void ink_begin(bool highlighter, unsigned rgb, const Point& at) {
  Stroke stroke;
  stroke.highlighter = highlighter;
  stroke.r = ((rgb >> 16) & 0xFF) / 255.0;
  stroke.g = ((rgb >> 8) & 0xFF) / 255.0;
  stroke.b = (rgb & 0xFF) / 255.0;
  stroke.width = highlighter ? highlighter_width() : pen_width();
  stroke.points.push_back(at);
  overlay.strokes.push_back(stroke);
  overlay.stroking = true;
  update_mapped();
  queue_area(segment_area(at, at, stroke.width));
}

void ink_to(const Point& to) {
  if (!overlay.stroking || overlay.strokes.empty()) return;
  Stroke& stroke = overlay.strokes.back();
  const Point from = stroke.points.back();
  stroke.points.push_back(to);
  queue_area(segment_area(from, to, stroke.width));
}

GdkMonitor* primary_monitor() {
  GdkDisplay* display = gdk_display_get_default();
  GdkMonitor* monitor = gdk_display_get_primary_monitor(display);
  return monitor != nullptr ? monitor : gdk_display_get_monitor(display, 0);
}

// Covers [monitor]: the window moves there (hidden meanwhile) and the dot
// takes its size. The ink, drawn for the old monitor, goes.
void use_monitor(GdkMonitor* monitor) {
  if (monitor == nullptr) return;
  GdkRectangle geometry;
  gdk_monitor_get_geometry(monitor, &geometry);
  if (gdk_rectangle_equal(&geometry, &overlay.monitor)) return;
  const bool laser = overlay.laser;
  if (laser) hide();
  overlay.strokes.clear();
  overlay.stroking = false;
  update_mapped();
  overlay.monitor = geometry;
  // About 1 % of the screen's height: 11 px at 1080p.
  overlay.radius = std::fmax(6.0, geometry.height / 100.0);
  overlay.glow = overlay.radius * 2.6;
  GtkWindow* window = GTK_WINDOW(overlay.window);
  gtk_widget_set_size_request(overlay.window, geometry.width, geometry.height);
  gtk_window_resize(window, geometry.width, geometry.height);
  gtk_window_move(window, geometry.x, geometry.y);
  if (laser) show();
}

// Numbers in the user's locale would break: gtk_init sets it, and Turkish
// (like many others) reads "0.5" as 0. So not sscanf: g_ascii_strtod.
bool read_numbers(const char* at, double* values, int count) {
  for (int i = 0; i < count; ++i) {
    char* end = nullptr;
    values[i] = g_ascii_strtod(at, &end);
    if (end == at || !std::isfinite(values[i])) return false;
    at = end;
  }
  return true;
}

// "area X Y W H": the monitor at the window's middle; anything else, the primary one.
void area(const char* args) {
  double values[4];
  if (!read_numbers(args, values, 4)) {
    use_monitor(primary_monitor());
    return;
  }
  const int x = static_cast<int>(values[0] + values[2] / 2);
  const int y = static_cast<int>(values[1] + values[3] / 2);
  use_monitor(gdk_display_get_monitor_at_point(gdk_display_get_default(), x, y));
}

// "begin pen|highlighter RRGGBB X Y", "to X Y", "end", "clear".
void ink(const char* args) {
  double at[2];
  if (strncmp(args, "begin ", 6) == 0) {
    const char* rest = args + 6;
    bool highlighter;
    if (strncmp(rest, "pen ", 4) == 0) {
      highlighter = false;
      rest += 4;
    } else if (strncmp(rest, "highlighter ", 12) == 0) {
      highlighter = true;
      rest += 12;
    } else {
      return;
    }
    char* end = nullptr;
    const unsigned long rgb = strtoul(rest, &end, 16);
    if (end == rest || !read_numbers(end, at, 2)) return;
    ink_begin(highlighter, static_cast<unsigned>(rgb & 0xFFFFFF), to_window(at[0], at[1]));
  } else if (strncmp(args, "to ", 3) == 0) {
    if (read_numbers(args + 3, at, 2)) ink_to(to_window(at[0], at[1]));
  } else if (strcmp(args, "end") == 0) {
    overlay.stroking = false;
  } else if (strcmp(args, "clear") == 0) {
    ink_clear();
  }
}

void handle(const char* line) {
  if (strcmp(line, "area") == 0) {
    use_monitor(primary_monitor());
  } else if (strncmp(line, "area ", 5) == 0) {
    area(line + 5);
  } else if (strcmp(line, "show") == 0) {
    show();
  } else if (strcmp(line, "hide") == 0) {
    hide();
  } else if (strncmp(line, "move ", 5) == 0) {
    double at[2];
    if (read_numbers(line + 5, at, 2)) move(at[0], at[1]);
  } else if (strncmp(line, "ink ", 4) == 0) {
    ink(line + 4);
  } else if (strcmp(line, "spotlight on") == 0) {
    set_spotlight(true);
  } else if (strcmp(line, "spotlight off") == 0) {
    set_spotlight(false);
  } else if (strcmp(line, "blank off") == 0) {
    set_blank(false, 0);
  } else if (strncmp(line, "blank ", 6) == 0) {
    char* end = nullptr;
    const unsigned long rgb = strtoul(line + 6, &end, 16);
    if (end != line + 6) set_blank(true, static_cast<unsigned>(rgb & 0xFFFFFF));
  }
}

// Reads every line waiting; a burst of moves is drawn once, at the last.
gboolean on_stdin(GIOChannel* channel, GIOCondition condition, gpointer) {
  for (;;) {
    gchar* line = nullptr;
    gsize terminator = 0;
    GIOStatus status = g_io_channel_read_line(channel, &line, nullptr, &terminator, nullptr);
    if (status == G_IO_STATUS_NORMAL && line != nullptr) {
      line[terminator] = '\0';
      handle(line);
      g_free(line);
      continue;
    }
    g_free(line);
    if (status == G_IO_STATUS_AGAIN) break;
    // End of input or an error: the app is gone.
    gtk_main_quit();
    return FALSE;
  }
  if (condition & (G_IO_HUP | G_IO_ERR)) {
    gtk_main_quit();
    return FALSE;
  }
  return TRUE;
}

}  // namespace

int main(int argc, char** argv) {
  if (!gtk_init_check(&argc, &argv)) {
    reply("error no-display");
    return 2;
  }
  GdkScreen* screen = gdk_screen_get_default();
  GdkVisual* visual = gdk_screen_get_rgba_visual(screen);
  // Without a compositor the window would be opaque and hide the screen.
  if (visual == nullptr || !gdk_screen_is_composited(screen)) {
    reply("error not-composited");
    return 2;
  }

  GdkMonitor* monitor = primary_monitor();
  if (monitor != nullptr) gdk_monitor_get_geometry(monitor, &overlay.monitor);
  overlay.radius = std::fmax(6.0, overlay.monitor.height / 100.0);
  overlay.glow = overlay.radius * 2.6;

  // A popup is override-redirect: the window manager neither places nor
  // focuses it, and it stays above managed windows.
  overlay.window = gtk_window_new(GTK_WINDOW_POPUP);
  GtkWindow* window = GTK_WINDOW(overlay.window);
  gtk_widget_set_visual(overlay.window, visual);
  gtk_widget_set_app_paintable(overlay.window, TRUE);
  gtk_window_set_accept_focus(window, FALSE);
  gtk_window_set_focus_on_map(window, FALSE);
  gtk_window_set_skip_taskbar_hint(window, TRUE);
  gtk_window_set_skip_pager_hint(window, TRUE);
  gtk_window_set_title(window, "QuickRemote laser");
  gtk_window_move(window, overlay.monitor.x, overlay.monitor.y);
  gtk_window_set_default_size(window, overlay.monitor.width, overlay.monitor.height);
  gtk_widget_set_size_request(overlay.window, overlay.monitor.width, overlay.monitor.height);
  g_signal_connect(overlay.window, "realize", G_CALLBACK(on_realize), nullptr);
  g_signal_connect_after(overlay.window, "size-allocate", G_CALLBACK(on_size_allocate), nullptr);
  g_signal_connect_after(overlay.window, "map", G_CALLBACK(on_map), nullptr);
  g_signal_connect(overlay.window, "draw", G_CALLBACK(on_draw), nullptr);
  gtk_widget_realize(overlay.window);

  GIOChannel* input = g_io_channel_unix_new(0);
  g_io_channel_set_flags(input, G_IO_FLAG_NONBLOCK, nullptr);
  g_io_add_watch(input, static_cast<GIOCondition>(G_IO_IN | G_IO_HUP | G_IO_ERR), on_stdin, nullptr);

  char ready[64];
  snprintf(ready, sizeof ready, "ready %d %d", overlay.monitor.width, overlay.monitor.height);
  reply(ready);
  gtk_main();
  return 0;
}
