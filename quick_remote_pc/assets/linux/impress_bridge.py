#!/usr/bin/env python3
"""QuickRemote <-> LibreOffice Impress bridge.

Reads one JSON request per line from stdin and writes one JSON reply per line
to stdout:  {"id": 1, "cmd": "next"}  ->  {"id": 1, "ok": true}
Requests with "noreply": true get no answer (used for high-frequency pointer
updates). Of those pointer updates only the newest waiting one is applied, so
a busy LibreOffice never falls behind the laser; it carries the positions of
the ones it stands for, which a highlighter stroke draws.

The argument is the name of the UNO pipe LibreOffice accepts connections on
(ooSetupConnectionURL or `soffice --accept=pipe,name=NAME;urp;`). A pipe is a
Unix socket only its owner can connect to; a TCP listener would let every
local user and sandboxed app run code through LibreOffice. A numeric argument
selects a localhost TCP port instead, for manual testing only.
"""
import contextlib
import json
import os
import queue
import stat
import sys
import threading
import time

TARGET = sys.argv[1] if len(sys.argv) > 1 else "quickremote"
if TARGET.isdigit():
    PIPE_NAME = None
    URL = "uno:socket,host=localhost,port=%s;urp;StarOffice.ComponentContext" % TARGET
else:
    PIPE_NAME = TARGET
    URL = "uno:pipe,name=%s;urp;StarOffice.ComponentContext" % TARGET


def pipe_is_trusted():
    """LibreOffice creates the pipe as /tmp/OSL_PIPE_<uid>_<name> (or under
    /var/tmp). Refuse a socket at that path that another user created first:
    it would impersonate LibreOffice."""
    uid = os.getuid()
    for base in ("/tmp", "/var/tmp"):
        try:
            st = os.lstat("%s/OSL_PIPE_%d_%s" % (base, uid, PIPE_NAME))
        except FileNotFoundError:
            continue
        return stat.S_ISSOCK(st.st_mode) and st.st_uid == uid
    return True  # not there yet: resolve() fails with NO_CONNECTION

try:
    import uno
except ImportError:
    for _p in ("/usr/lib/libreoffice/program", "/usr/lib64/libreoffice/program",
               "/opt/libreoffice/program", "/usr/lib/python3/dist-packages"):
        if os.path.isdir(_p) and _p not in sys.path:
            sys.path.append(_p)
    try:
        import uno
    except ImportError:
        uno = None

if uno is not None:
    import unohelper
    from com.sun.star.awt import XCallback
    from com.sun.star.beans import NamedValue

    class MainThreadCall(unohelper.Base, XCallback):
        """Runs a function on LibreOffice's main (GUI) thread.

        Slideshow calls made from a remote UNO thread deadlock with the Qt/KDE
        VCL plugin. Calls issued inside notify() carry the main thread's URP
        identity, so LibreOffice executes them on its main thread.
        """

        def __init__(self, fn):
            self.fn = fn
            self.done = threading.Event()
            self.result = None
            self.error = None
            # Set when the caller gave up: a busy LibreOffice may get to the
            # call seconds later, and a late "next" must not move the show.
            self.cancelled = False

        def notify(self, _data):
            if self.cancelled:
                self.done.set()
                return
            try:
                self.result = self.fn()
            except Exception as e:  # noqa: BLE001 - re-raised in the caller
                self.error = e
            finally:
                self.done.set()

    def _const(name):
        return uno.getConstantByName("com.sun.star." + name)

    ON_CLICK = _const("animations.EventTrigger.ON_CLICK")
    ON_DBL_CLICK = _const("animations.EventTrigger.ON_DBL_CLICK")
    RESTART_WHEN_NOT_ACTIVE = _const("animations.AnimationRestart.WHEN_NOT_ACTIVE")
    TOGGLE_PAUSE = _const("presentation.EffectCommands.TOGGLEPAUSE")
    PLAY = _const("presentation.EffectCommands.PLAY")
    NODE_ON_CLICK = _const("presentation.EffectNodeType.ON_CLICK")
    NODE_INTERACTIVE_SEQUENCE = _const("presentation.EffectNodeType.INTERACTIVE_SEQUENCE")
    PRESET_MEDIA_CALL = _const("presentation.EffectPresetClass.MEDIACALL")
    MOUSE_LEFT = _const("awt.MouseButton.LEFT")
    ROUND_CAP = uno.Enum("com.sun.star.drawing.LineCap", "ROUND")
    ROUND_JOINT = uno.Enum("com.sun.star.drawing.LineJoint", "ROUND")

PEN_WIDTH = 150.0
HIGHLIGHTER_WIDTH = 600.0
HIGHLIGHTER_COLOR = 0xFFE600
# Highlighter strokes drawn as shapes (see _strokes_possible): see-through in
# percent, the shapes' Name (tells a stroke left behind by a crash from the
# author's shapes), and the version from which a running show draws a shape
# added to its slide (measured on 26.8; older versions keep the ink).
HIGHLIGHT_TRANSPARENCE = 50
HIGHLIGHT_NAME = "quickremote-highlight"
STROKE_MIN_VERSION = (26, 8)
# A stroke point closer than this to the previous one (1/100 mm) is skipped.
STROKE_MIN_STEP = 30
# A change to the slide on screen makes the show draw the slide again, which
# takes ~150 ms (measured on 26.8); a move it gets meanwhile is lost.
REDRAW_SECONDS = 0.3
# The show changes slides a moment after gotoNextEffect returns; the shapes of
# the slide it left wait this long for it (see _erase_left).
LEAVE_SECONDS = 1.0
# Half the side of the eraser's square, in slide units (1/100 mm). LibreOffice's
# default is 100, a 2 mm square that barely covers a pen stroke.
ERASER_SIZE = 600
MEDIA_SHAPES = ("com.sun.star.presentation.MediaShape", "com.sun.star.drawing.MediaShape")
# UserData entry marking the media triggers this bridge adds (see _prepare_pages).
TRIGGER_MARK = "quickremote-media"
PRESENTATION_DOC = "com.sun.star.presentation.PresentationDocument"
DRAWING_DOC = "com.sun.star.drawing.DrawingDocument"
# Opens a PDF in Impress, one slide per page (LibreOffice opens PDFs in Draw).
PDF_IMPORT_FILTER = "impress_pdf_import"


def is_pdf_url(url):
    return url.lower().split("?", 1)[0].endswith(".pdf")


class BridgeError(Exception):
    pass


def x11_root_size():
    """Size of the X root window, the whole desktop in X pixels, or None
    without an X server. LibreOffice under X11 or XWayland reports window
    positions in these pixels."""
    if not os.environ.get("DISPLAY"):
        return None
    try:
        import ctypes
        import ctypes.util
        x11 = ctypes.CDLL(ctypes.util.find_library("X11") or "libX11.so.6")
        x11.XOpenDisplay.restype = ctypes.c_void_p
        x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
        x11.XDefaultScreen.argtypes = [ctypes.c_void_p]
        x11.XDisplayWidth.argtypes = [ctypes.c_void_p, ctypes.c_int]
        x11.XDisplayHeight.argtypes = [ctypes.c_void_p, ctypes.c_int]
        x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
        display = x11.XOpenDisplay(None)
        if not display:
            return None
        try:
            screen = x11.XDefaultScreen(display)
            return x11.XDisplayWidth(display, screen), x11.XDisplayHeight(display, screen)
        finally:
            x11.XCloseDisplay(display)
    except Exception:  # noqa: BLE001 - no libX11: treated as no X server
        return None


def show_geometry(win_x, win_y, win_w, win_h, root):
    """(window x, y, width, height, desktop width, height) in pixels. Without
    an X root the window's position means nothing (Wayland clients do not
    know it): the show is taken to fill the desktop."""
    if root is None or win_x + win_w > root[0] or win_y + win_h > root[1]:
        return 0, 0, win_w, win_h, win_w, win_h
    return win_x, win_y, win_w, win_h, root[0], root[1]


def desktop_fraction(geometry, slide_w, slide_h, x, y):
    """Maps a laser position (fractions of the slide) to fractions of the
    desktop, the coordinates of the absolute virtual pointer."""
    win_x, win_y, win_w, win_h, desk_w, desk_h = geometry
    px, py = slide_to_window(slide_w, slide_h, win_w, win_h, x * slide_w, y * slide_h)
    return (min(max((win_x + px) / desk_w, 0.0), 1.0),
            min(max((win_y + py) / desk_h, 0.0), 1.0))


def park_fraction(geometry):
    """A spot in the show's bottom right corner, out of the audience's way,
    for the cursor once it no longer stands in for the laser. Two pixels in,
    so it does not touch a screen corner that triggers desktop actions."""
    win_x, win_y, win_w, win_h, desk_w, desk_h = geometry
    return (win_x + win_w - 3) / desk_w, (win_y + win_h - 3) / desk_h


def point_in_rects(rects, x, y):
    return any(x0 <= x <= x1 and y0 <= y <= y1 for x0, y0, x1, y1 in rects)


def slide_to_window(slide_w, slide_h, win_w, win_h, x, y):
    """Maps a slide position (1/100 mm) to slideshow window pixels. The slide
    is scaled to fit and centred, as in sd's SlideShowView::getTransformation."""
    out_w, out_h = win_w, win_h
    if slide_w * win_h > slide_h * win_w:
        out_h = win_w * slide_h // slide_w
    elif slide_w * win_h < slide_h * win_w:
        out_w = win_h * slide_w // slide_h
    left = (win_w - out_w) // 2
    top = (win_h - out_h) // 2
    return (round(left + x * (out_w - 1) / slide_w),
            round(top + y * (out_h - 1) / slide_h))


class Impress:
    def __init__(self):
        self.ctx = None
        self.desktop = None
        self.async_callback = None
        self.toolkit = None
        self.version = None
        self.pen_color = 0xFF0000
        self.highlighter_color = HIGHLIGHTER_COLOR
        # "pen" or "highlighter" while one of them draws, for the color commands.
        self.ink_tool = None
        # The highlighter draws shapes instead of ink, see _strokes_possible.
        self.strokes_on = False
        # The stroke being drawn: {"doc", "shape", "points", "size"}.
        self.stroke = None
        # Highlighter shapes in the document being shown, see _highlights_of.
        self.highlights = None
        # time.monotonic() until which the show redraws a slide the bridge
        # changed, see settle().
        self.redraw_until = 0.0
        self.blank_color = None
        # (document, presentation, controller) of the running slideshow.
        self.show = None
        # XSlideShow the laser pointer moves on.
        self.pointer_engine = None
        # (controller, slide index, notes, has media) of the slide state() saw.
        self.slide_info = None
        # Media triggers added to the document being shown, see _prepare_pages.
        self.media = None
        # [controller, slide index, playing] of the current slide's media.
        self.media_state = None
        self.click_side = 1
        self.laser_on = False
        # Newest laser position, fractions of the slide.
        self.laser_pos = (0.5, 0.5)
        # The OS cursor stands in for the laser over a video, see _follow_laser.
        self.cursor_shown = False
        # MouseVisible of the show before the cursor stood in for the laser.
        self.mouse_visible = None
        # (controller, slide index, slide width, height, media rectangles)
        self.media_rects = None
        # (controller, show_geometry()) of the full screen show.
        self.geometry = None
        # PDF URL -> the Impress document it was imported into.
        self.pdf_imports = {}

    # ── Connection ──
    def connect(self):
        if self.desktop is not None:
            return
        if PIPE_NAME is not None and not pipe_is_trusted():
            raise BridgeError("UNTRUSTED_PIPE")
        local = uno.getComponentContext()
        resolver = local.ServiceManager.createInstanceWithContext(
            "com.sun.star.bridge.UnoUrlResolver", local)
        try:
            self.ctx = resolver.resolve(URL)
        except Exception:
            raise BridgeError("NO_CONNECTION")
        smgr = self.ctx.ServiceManager
        self.desktop = smgr.createInstanceWithContext("com.sun.star.frame.Desktop", self.ctx)
        self.async_callback = smgr.createInstanceWithContext(
            "com.sun.star.awt.AsyncCallback", self.ctx)
        self.toolkit = smgr.createInstanceWithContext("com.sun.star.awt.Toolkit", self.ctx)

    def reset(self):
        self.ctx = None
        self.desktop = None
        self.async_callback = None
        self.toolkit = None
        self.version = None
        self.show = None
        self.pointer_engine = None
        self.slide_info = None
        self.media = None
        self.media_state = None
        self.laser_on = False
        self.cursor_shown = False
        self.mouse_visible = None
        self.media_rects = None
        self.geometry = None
        self.pdf_imports = {}
        self.strokes_on = False
        self.stroke = None
        self.highlights = None

    def on_main_thread(self, fn, timeout=5.0):
        call = MainThreadCall(fn)
        self.async_callback.addCallback(call, None)
        if not call.done.wait(timeout):
            call.cancelled = True
            raise BridgeError("TIMEOUT")
        if call.error is not None:
            raise call.error
        return call.result

    # ── Document / slideshow lookup ──
    def _presentation_docs(self):
        docs = []
        current = self.desktop.getCurrentComponent()
        if current is not None and current.supportsService(
                PRESENTATION_DOC):
            docs.append(current)
        enum = self.desktop.getComponents().createEnumeration()
        while enum.hasMoreElements():
            doc = enum.nextElement()
            if doc is not None and doc not in docs and doc.supportsService(
                    PRESENTATION_DOC):
                docs.append(doc)
        return docs

    def _running(self):
        # Checking the cached controller is one call; looking the show up again
        # walks every open component (~20 ms), too slow for pointer updates.
        if self.show is not None:
            if self.show[2].isRunning():
                return self.show
            self.show = None
        for doc in self._presentation_docs():
            pres = doc.getPresentation()
            if pres.isRunning():
                ctrl = pres.getController()
                if ctrl is not None:
                    self.show = (doc, pres, ctrl)
                    return self.show
        return None

    def _require_running(self):
        running = self._running()
        if running is None:
            raise BridgeError("NOT_RUNNING")
        return running

    def _document(self):
        docs = self._presentation_docs()
        if not docs:
            raise BridgeError("NO_DOCUMENT")
        return docs[0]

    def _show_document(self):
        """The document a new show starts from: a PDF in the frontmost Draw
        window opened as a presentation (a PDF exported from slides is shown
        like them), otherwise the presentation _document() finds."""
        pdf = self._pdf_in_draw()
        if pdf is None:
            return self._document()
        doc = self.pdf_imports.get(pdf)
        if doc is not None:
            try:
                if doc.getCurrentController() is not None:
                    return doc  # imported before and still open
            except Exception:  # noqa: BLE001 - closed since
                pass
        doc = self._import_pdf(pdf)
        self.pdf_imports[pdf] = doc
        return doc

    def _pdf_in_draw(self):
        current = self.desktop.getCurrentComponent()
        if (current is None or not current.supportsService(DRAWING_DOC)
                or current.supportsService(PRESENTATION_DOC)):
            return None
        url = current.getURL()
        return url if is_pdf_url(url) else None

    def _import_pdf(self, url):
        prop = uno.createUnoStruct("com.sun.star.beans.PropertyValue")
        prop.Name = "FilterName"
        prop.Value = PDF_IMPORT_FILTER
        doc = self.desktop.loadComponentFromURL(url, "_blank", 0, (prop,))
        if doc is None or not doc.supportsService(PRESENTATION_DOC):
            raise BridgeError("PDF_IMPORT_FAILED")
        return doc

    @staticmethod
    def _engine(ctrl):
        show = ctrl.getSlideShow()
        if show is None:
            raise BridgeError("NO_SLIDESHOW_ENGINE")
        return show

    @staticmethod
    def _set(show, name, value):
        prop = uno.createUnoStruct("com.sun.star.beans.PropertyValue")
        prop.Name = name
        prop.Value = value
        return show.setProperty(prop)

    # ── State ──
    def state(self, _args):
        running = self._running()
        if running is None:
            self._release_media()
            self._release_highlights()
            return {"state": "NOT_RUNNING"}
        doc, pres, ctrl = running
        self._erase_left(ctrl)
        total = ctrl.getSlideCount()
        index = ctrl.getCurrentSlideIndex()
        # Past the last slide LibreOffice shows its "click to exit" screen.
        at_end = index < 0 or index >= total
        current = total if at_end else index + 1

        notes = ""
        has_media = False
        if not at_end:
            info = self.slide_info
            if info is None or info[0] is not ctrl or info[1] != index:
                moved = info is not None and info[0] is ctrl
                slide = ctrl.getCurrentSlide()
                media = self.media
                if media is not None and not media["doc"] == doc:
                    media = None
                if moved and media is not None and media["stale"]:
                    # Slides the show left behind load with triggers next time.
                    media["stale"] = [page for page in media["stale"] if slide == page]
                # Also covers shows started in LibreOffice itself.
                self._try_prepare(doc, pres, lambda: self._upcoming(ctrl, index, total), ctrl)
                info = (ctrl, index,
                        self._notes(slide) if slide is not None else "",
                        self._has_media(doc, slide))
                self.slide_info = info
            notes, has_media = info[2], info[3]

        return {
            "state": "RUNNING",
            "current": current,
            "total": total,
            "notes": notes,
            "hasMedia": has_media,
            "isMediaPlaying": self._media_playing(ctrl, index)[2] if has_media else None,
            "isBlackScreen": at_end or bool(ctrl.isPaused()),
        }

    @staticmethod
    def _notes(slide):
        texts = []
        notes_page = slide.getNotesPage()
        for i in range(notes_page.getCount()):
            shape = notes_page.getByIndex(i)
            if shape.getShapeType() == "com.sun.star.presentation.NotesShape":
                text = shape.getString().strip()
                if text:
                    texts.append(text)
        return "\n".join(texts)

    def _has_media(self, doc, slide):
        if slide is None:
            return False
        media = self.media
        # Usually known from preparing the slide's triggers.
        if media is not None and media["doc"] == doc:
            known = media["pages"].get(slide.getName())
            if known is not None:
                return known
        return any(True for _ in self._media_shapes(slide))

    @staticmethod
    def _media_shapes(slide):
        for i in range(slide.getCount()):
            shape = slide.getByIndex(i)
            if shape.getShapeType() in MEDIA_SHAPES:
                yield shape

    # ── Navigation ──
    def next(self, args):
        ctrl = self._require_running()[2]
        with self._dropping_ink(ctrl, args):
            ctrl.gotoNextEffect()

    def prev(self, args):
        ctrl = self._require_running()[2]
        with self._dropping_ink(ctrl, args):
            ctrl.gotoPreviousEffect()

    @staticmethod
    def _drop_ink(ctrl):
        ctrl.setEraseAllInk(True)

    @contextlib.contextmanager
    def _dropping_ink(self, ctrl, args):
        """Erases the ink before the show moves on, and the highlighter
        shapes of the slide it left after, unless the request says
        "clearInk": false. LibreOffice keeps a slide's ink and shows it again
        when the show comes back, and an animation step leaves it on screen.
        Removing the shapes before that would redraw the slide, which loses
        the move, so they go once the show is elsewhere (_erase_left)."""
        clear = args.get("clearInk", True)
        if clear:
            self._drop_ink(ctrl)
        highlights = self.highlights
        left = ctrl.getCurrentSlide() if clear and highlights is not None else None
        yield
        if left is not None:
            shapes = [shape for page, shape in highlights["shapes"] if page == left]
            if shapes:
                highlights["leaving"].append((left, shapes, time.monotonic()))

    def settle(self):
        """Waits until the show has drawn a slide the bridge changed again."""
        wait = self.redraw_until - time.monotonic()
        if wait > 0:
            time.sleep(wait)

    def start(self, args):
        running = self._running()
        if running is not None:
            self._goto(running, 0, args)
            return
        doc = self._show_document()
        pres = doc.getPresentation()
        custom = pres.getPropertyValue("CustomShow")
        if custom:
            # The configured custom show, as LibreOffice's own F5 does.
            self._start(doc, pres, (),
                        lambda: self._pages(doc.getCustomPresentations().getByName(custom), 0))
        else:
            # Without FirstPage the show starts at the slide selected in the editor.
            pages = doc.getDrawPages()
            self._start(doc, pres, (self._first_page(pages.getByIndex(0)),),
                        lambda: self._pages(pages, 0))

    def startAt(self, args):
        number = int(args["slide"])
        running = self._running()
        if running is not None:
            self._goto(running, min(max(0, number - 1), running[2].getSlideCount() - 1), args)
            return
        doc = self._show_document()
        pages = doc.getDrawPages()
        number = min(max(1, number), pages.getCount())
        self._start(doc, doc.getPresentation(), (self._first_page(pages.getByIndex(number - 1)),),
                    lambda: self._pages(pages, number - 1))

    @staticmethod
    def _first_page(page):
        prop = uno.createUnoStruct("com.sun.star.beans.PropertyValue")
        prop.Name = "FirstPage"
        prop.Value = page.getName()
        return prop

    def _start(self, doc, pres, arguments, first_pages):
        self._reset_show_state()
        self._release_media()
        self._release_highlights()
        # The slideshow reads a slide's animations when it loads the slide.
        self._try_prepare(doc, pres, first_pages)
        pres.startWithArguments(arguments)

    def _goto(self, running, index, args):
        doc, pres, ctrl = running
        with self._dropping_ink(ctrl, args):
            self._try_prepare(doc, pres, lambda: self._upcoming(ctrl, index, ctrl.getSlideCount()), ctrl)
            ctrl.gotoSlideIndex(index)

    def end(self, _args):
        self._require_running()[1].end()
        self._reset_show_state()
        self._release_media()
        self._release_highlights()

    def _reset_show_state(self):
        self.blank_color = None
        self.ink_tool = None
        self.strokes_on = False
        self.stroke = None
        self.slide_info = None
        self.media_state = None
        self.laser_on = False
        self.cursor_shown = False
        self.mouse_visible = None
        self.media_rects = None
        self.geometry = None

    def blank(self, args):
        color = int(args["color"])
        ctrl = self._require_running()[2]
        # Pressing the same blank key again returns to the slide, like PowerPoint.
        if ctrl.isPaused() and self.blank_color == color:
            ctrl.resume()
            self.blank_color = None
        else:
            ctrl.blankScreen(color)
            self.blank_color = color

    # ── Ink / pointer ──
    def _ink(self, ctrl, pen, eraser=False, color=None, width=PEN_WIDTH, tool=None):
        self.ink_tool = tool
        self.laser_on = False
        self.strokes_on = False
        self.stroke = None
        self._hide_cursor(ctrl)
        show = self._engine(ctrl)
        self._set(show, "PointerVisible", False)
        ctrl.UsePen = pen
        if pen:
            ctrl.PenColor = self.pen_color if color is None else color
            ctrl.PenWidth = width
        self._set(show, "SwitchEraserMode", eraser)
        self._set(show, "SwitchPenMode", not eraser)
        if eraser:
            # Also switches to erase mode, so it comes after PenWidth, which
            # switches erase mode off.
            self._set(show, "EraseInk", ERASER_SIZE)

    def arrow(self, _args):
        doc, _pres, ctrl = self._require_running()
        park = self._park(doc, ctrl)
        self._ink(ctrl, pen=False)
        return park

    def pen(self, _args):
        self._ink(self._require_running()[2], pen=True, tool="pen")

    def highlighter(self, _args):
        doc, _pres, ctrl = self._require_running()
        if self._strokes_possible(doc, ctrl):
            # The pointer stays still; strokeBegin, pointer and strokeEnd draw.
            self._ink(ctrl, pen=False, tool="highlighter")
            self.strokes_on = True
            return {"strokes": True}
        self._ink(ctrl, pen=True, tool="highlighter",
                  color=self.highlighter_color, width=HIGHLIGHTER_WIDTH)
        return None

    def eraser(self, _args):
        self._ink(self._require_running()[2], pen=True, eraser=True)

    def eraseAll(self, _args):
        ctrl = self._require_running()[2]
        self._drop_ink(ctrl)
        if self.highlights is not None:
            slide = ctrl.getCurrentSlide()
            self._erase_highlights(slide, ctrl, [shape for page, shape in self.highlights["shapes"]
                                                 if page == slide])
        # The ink is gone from the canvas, but the screen shows that only on
        # the show's next update, which an idle show may never run.
        # LibreOffice's own E key runs one at once, as this does.
        self._engine(ctrl).update(0.0)

    def penColor(self, args):
        self.pen_color = int(args["rgb"])
        self._recolor("pen", self.pen_color)

    def highlighterColor(self, args):
        self.highlighter_color = int(args["rgb"])
        self._recolor("highlighter", self.highlighter_color)

    def _recolor(self, tool, color):
        """Applies a color to the tool drawing now; otherwise the tool takes
        it when it is next chosen."""
        running = self._running()
        if running is not None and self.ink_tool == tool and running[2].UsePen:
            running[2].PenColor = color

    def laserOn(self, _args):
        ctrl = self._require_running()[2]
        self.strokes_on = False
        self.stroke = None
        ctrl.UsePen = False
        self._set(self._engine(ctrl), "PointerVisible", True)
        self.laser_on = True
        # The laser may start where the last gesture left it, over a video.
        return self._follow_laser(*self.laser_pos)

    def laserOff(self, _args):
        doc, _pres, ctrl = self._require_running()
        park = self._park(doc, ctrl)
        self.laser_on = False
        self.strokes_on = False
        self.stroke = None
        self._hide_cursor(ctrl)
        self._set(self._engine(ctrl), "PointerVisible", False)
        return park

    def pointer(self, args):
        x, y = float(args["x"]), float(args["y"])
        self.laser_pos = (x, y)
        if self.stroke is not None:
            # Every position since the last update, not only the newest one.
            self._extend_stroke(args.get("trail") or [(x, y)])
            return None
        pos = uno.createUnoStruct("com.sun.star.geometry.RealPoint2D", x, y)
        # One call on the cached engine; it answers False once its show is over.
        if self.pointer_engine is None or not self._set(self.pointer_engine, "PointerPosition", pos):
            self.pointer_engine = self._engine(self._require_running()[2])
            self._set(self.pointer_engine, "PointerPosition", pos)
        if self.laser_on:
            return self._follow_laser(x, y)
        return None

    # ── Highlighter strokes ──
    # LibreOffice's ink is opaque (PenColor has no alpha), so a highlighter
    # stroke hides the text under it. Where the show allows it, the
    # highlighter draws a semi-transparent line shape on the slide instead.
    # A running show draws a changed slide again from its start (measured on
    # 26.8): the slide's transition plays again, so it is switched off until
    # the show ends, and its animations start over, so slides with animations
    # or media keep the ink. The shapes go like the ink (_dropping_ink), and
    # _release_highlights takes them and the transitions back when the show
    # ends, so they never reach the saved file.
    def _strokes_possible(self, doc, ctrl):
        if self._version() < STROKE_MIN_VERSION:
            return False
        slide = ctrl.getCurrentSlide()
        return (slide is not None and not self._has_animations(slide)
                and not self._has_media(doc, slide))

    @classmethod
    def _has_animations(cls, slide):
        """Whether any sequence of the slide (the main one, triggers) has an effect."""
        root = slide.getAnimationNode()
        return root is not None and any(cls._children(seq) for seq in cls._children(root))

    def strokeBegin(self, _args):
        if not self.strokes_on:
            return
        doc, _pres, ctrl = self._require_running()
        slide = ctrl.getCurrentSlide()
        if slide is None:
            return
        highlights = self._highlights_of(doc)
        self._erase_left(ctrl)
        with self._no_undo(doc):
            self._hold_transition(highlights, slide)
            shape = doc.createInstance("com.sun.star.drawing.PolyLineShape")
            slide.add(shape)
            shape.Name = HIGHLIGHT_NAME
            shape.LineColor = self.highlighter_color
            shape.LineWidth = int(HIGHLIGHTER_WIDTH)
            shape.LineTransparence = HIGHLIGHT_TRANSPARENCE
            shape.LineCap = ROUND_CAP
            shape.LineJoint = ROUND_JOINT
        highlights["shapes"].append((slide, shape))
        self.stroke = {"doc": doc, "shape": shape, "points": [],
                       "size": (slide.Width, slide.Height)}
        self._extend_stroke([self.laser_pos])

    def strokeEnd(self, _args):
        self.stroke = None

    def _extend_stroke(self, positions):
        """Adds positions (fractions of the slide) to the stroke's line."""
        stroke = self.stroke
        points = stroke["points"]
        width, height = stroke["size"]
        added = False
        for x, y in positions:
            point = (round(float(x) * width), round(float(y) * height))
            if points and (abs(point[0] - points[-1][0]) < STROKE_MIN_STEP
                           and abs(point[1] - points[-1][1]) < STROKE_MIN_STEP):
                continue
            points.append(point)
            added = True
        if not added:
            return
        line = [uno.createUnoStruct("com.sun.star.awt.Point", x, y) for x, y in points]
        if len(line) == 1:
            # A line of one point draws nothing; a tap leaves a dot.
            line.append(uno.createUnoStruct("com.sun.star.awt.Point", points[0][0] + 1, points[0][1]))
        with self._no_undo(stroke["doc"]):
            stroke["shape"].PolyPolygon = (tuple(line),)
        self._redrawn()

    def _redrawn(self):
        """Notes a change to the slide on screen, see settle()."""
        self.redraw_until = time.monotonic() + REDRAW_SECONDS

    def _highlights_of(self, doc):
        highlights = self.highlights
        if highlights is not None and not highlights["doc"] == doc:
            self._release_highlights()
            highlights = None
        if highlights is None:
            highlights = self.highlights = {
                "doc": doc,
                "shapes": [],       # (slide, shape) pairs
                "transitions": [],  # (slide, TransitionType, TransitionSubtype) held off
                "leaving": [],      # (slide, shapes, time) to erase, see _erase_left
                "modified": bool(doc.isModified()),
            }
        return highlights

    @staticmethod
    def _hold_transition(highlights, slide):
        """Switches the slide's transition off, which every stroke update
        would otherwise play again."""
        if any(held[0] == slide for held in highlights["transitions"]):
            return
        kind = slide.TransitionType
        highlights["transitions"].append((slide, kind, slide.TransitionSubtype))
        if kind:
            slide.TransitionType = 0
            slide.TransitionSubtype = 0

    @staticmethod
    @contextlib.contextmanager
    def _no_undo(doc):
        """Keeps the bridge's changes off the document's undo stack."""
        manager = doc.getUndoManager()
        manager.lock()
        try:
            yield
        finally:
            manager.unlock()

    def _erase_left(self, ctrl):
        """Erases the shapes of the slides the show moved away from, see
        _dropping_ink. A slide still on screen after LEAVE_SECONDS stayed
        (PREV on the first slide), and its shapes go all the same."""
        highlights = self.highlights
        if highlights is None or not highlights["leaving"]:
            return
        current = ctrl.getCurrentSlide()
        now = time.monotonic()
        waiting = []
        for entry in highlights["leaving"]:
            slide, shapes, since = entry
            if slide == current and now - since < LEAVE_SECONDS:
                waiting.append(entry)
            else:
                self._erase_highlights(slide, ctrl, shapes)
        highlights["leaving"] = waiting

    def _erase_highlights(self, slide, ctrl, shapes):
        """Removes the given highlighter shapes from slide."""
        highlights = self.highlights
        if self.stroke is not None and self.stroke["shape"] in shapes:
            self.stroke = None
        with self._no_undo(highlights["doc"]):
            for shape in shapes:
                try:
                    slide.remove(shape)
                except Exception:  # noqa: BLE001 - deleted meanwhile
                    pass
        highlights["shapes"] = [entry for entry in highlights["shapes"] if entry[1] not in shapes]
        if shapes and slide == ctrl.getCurrentSlide():
            self._redrawn()

    def _release_highlights(self):
        highlights, self.highlights, self.stroke = self.highlights, None, None
        if highlights is None:
            return
        doc = highlights["doc"]
        try:
            with self._no_undo(doc):
                for page, shape in highlights["shapes"]:
                    try:
                        page.remove(shape)
                    except Exception:  # noqa: BLE001 - deleted meanwhile
                        pass
                for page, kind, subtype in highlights["transitions"]:
                    if kind:
                        page.TransitionType = kind
                        page.TransitionSubtype = subtype
            if not highlights["modified"] and doc.isModified():
                doc.setModified(False)
        except Exception:  # noqa: BLE001 - the document was closed meanwhile
            pass

    # ── Laser over videos ──
    # A video plays in a window of its own above the slide, so the laser and
    # the ink, drawn on the slide, disappear behind it. The OS cursor shows
    # above every window: over a video the server moves it to the laser
    # position (an absolute virtual pointer) and the laser hides. The replies
    # carry {"event": "cursor", "x", "y"} in fractions of the desktop.
    def _follow_laser(self, x, y):
        running = self._running()
        if running is None:
            return None
        doc, _pres, ctrl = running
        slide_w, slide_h, rects = self._slide_media_rects(ctrl)
        if point_in_rects(rects, x, y):
            geometry = self._show_geometry(doc, ctrl)
            if geometry is None:
                return None
            if not self.cursor_shown:
                self.cursor_shown = True
                self._set(self._engine(ctrl), "PointerVisible", False)
                # LibreOffice hides an idle cursor after a while.
                self.mouse_visible = bool(ctrl.MouseVisible)
                ctrl.MouseVisible = True
            fx, fy = desktop_fraction(geometry, slide_w, slide_h, x, y)
            return {"event": "cursor", "x": fx, "y": fy}
        if not self.cursor_shown:
            return None
        park = self._park(doc, ctrl)
        self._hide_cursor(ctrl)
        self._set(self._engine(ctrl), "PointerVisible", True)
        return park

    def _park(self, doc, ctrl):
        """The reply that moves a cursor standing in for the laser away."""
        if not self.cursor_shown:
            return None
        geometry = self._show_geometry(doc, ctrl)
        if geometry is None:
            return None
        fx, fy = park_fraction(geometry)
        return {"event": "cursor", "x": fx, "y": fy}

    def _hide_cursor(self, ctrl):
        """Ends the cursor standing in for the laser; the caller parks it."""
        if not self.cursor_shown:
            return
        self.cursor_shown = False
        if self.mouse_visible is not None:
            ctrl.MouseVisible = self.mouse_visible
            self.mouse_visible = None

    def _slide_media_rects(self, ctrl):
        """(slide width, height, media rectangles in fractions of the slide)
        of the slide on screen."""
        index = ctrl.getCurrentSlideIndex()
        cached = self.media_rects
        if cached is None or cached[0] is not ctrl or cached[1] != index:
            slide = ctrl.getCurrentSlide()
            width, height, rects = 1, 1, []
            if slide is not None:
                width, height = slide.Width, slide.Height
                for shape in self._media_shapes(slide):
                    pos, size = shape.getPosition(), shape.getSize()
                    rects.append((pos.X / width, pos.Y / height,
                                  (pos.X + size.Width) / width, (pos.Y + size.Height) / height))
            cached = self.media_rects = (ctrl, index, width, height, rects)
        return cached[2:]

    def _show_geometry(self, doc, ctrl):
        cached = self.geometry
        if cached is not None and cached[0] is ctrl:
            return cached[1]
        frame = self._fullscreen_frame(doc)
        if frame is None:
            return None  # a windowed show: its position is not worth guessing
        outer = frame.getContainerWindow().getPosSize()
        inner = frame.getComponentWindow().getPosSize()
        geometry = show_geometry(outer.X + inner.X, outer.Y + inner.Y,
                                 inner.Width, inner.Height, x11_root_size())
        self.geometry = (ctrl, geometry)
        return geometry

    # ── Embedded media ──
    # LibreOffice does not implement XSlideShow.startShapeActivity, and its
    # slideshow has no other call that pauses a video. Animation triggers can:
    # while the show runs, clicking a media shape toggles pause and
    # double-clicking rewinds it; _click_media clicks for the phone. Shapes
    # that already have a click trigger keep theirs. _release_media removes
    # the triggers again, so they never reach the saved file.
    #
    # The slideshow reads a slide's animations when it shows or prefetches
    # the slide, so triggers are added to the next few slides ahead of the
    # show. Not to all slides up front: looking at every shape of a large
    # presentation takes seconds.
    PREPARE_AHEAD = 3

    def _try_prepare(self, doc, pres, pages, ctrl=None):
        """Prepares the pages that pages() returns. Media control is optional
        for the callers, so failures are only reported."""
        try:
            self._prepare_pages(self._media_control(doc, pres), pages(), ctrl)
        except Exception as e:  # noqa: BLE001 - reported, not fatal
            print("media triggers failed: %s: %s" % (type(e).__name__, e), file=sys.stderr)

    def _upcoming(self, ctrl, index, total):
        """The slide at show index and the ones after it."""
        return [ctrl.getSlideByIndex(i) for i in range(index, min(index + self.PREPARE_AHEAD, total))]

    def _pages(self, pages, first):
        """The page at first in an XIndexAccess of pages and the ones after it."""
        return [pages.getByIndex(i)
                for i in range(first, min(first + self.PREPARE_AHEAD, pages.getCount()))]

    def _media_control(self, doc, pres):
        media = self.media
        if media is not None:
            if media["doc"] == doc:
                return media
            self._release_media()
        self.media = {
            "doc": doc,
            "pages": {},      # page name -> whether it has media, for pages looked at
            "nodes": [],      # (animation root, trigger) pairs to remove later
            "shapes": [],     # media shapes a click toggles (our trigger or the author's)
            "rewindable": [], # of those, the ones our double-click trigger rewinds
            "stale": [],      # pages the show loaded before their triggers existed
            "autoplay": bool(pres.getPropertyValue("AllowAnimations")),
        }
        return self.media

    def _prepare_pages(self, media, pages, ctrl=None):
        """Adds media triggers to pages; ctrl is given while the show runs."""
        doc = media["doc"]
        was_modified = doc.isModified()
        changed = []
        for page in pages:
            name = page.getName()
            if name in media["pages"]:
                continue
            shapes = list(self._media_shapes(page))
            media["pages"][name] = bool(shapes)
            if not shapes:
                continue
            root = page.getAnimationNode()
            triggers = self._click_triggers(root)
            added = False
            for shape in shapes:
                mine = [seq for source, _trigger, seq, ours in triggers if ours and source == shape]
                # Triggers of the author (PowerPoint adds a click-to-pause to
                # every video) keep working; ours only fill the gaps.
                authors = {trigger for source, trigger, _seq, ours in triggers
                           if not ours and source == shape}
                if mine:
                    # Left by an earlier bridge process: adopt them.
                    media["nodes"] += [(root, seq) for seq in mine]
                else:
                    # Rewind like PowerPoint: PLAY starts from the beginning,
                    # then pause on the first frame. A paused player needs a
                    # moment to show that frame, hence the delay.
                    for trigger, commands, preset in (
                            (ON_CLICK, ((TOGGLE_PAUSE, 0.0),), "ooo-media-toggle-pause"),
                            (ON_DBL_CLICK, ((PLAY, 0.0), (TOGGLE_PAUSE, 0.25)), "ooo-media-play")):
                        if trigger not in authors:
                            seq = self._media_trigger(shape, trigger, commands, preset)
                            root.appendChild(seq)
                            media["nodes"].append((root, seq))
                            added = True
                media["shapes"].append(shape)
                if ON_DBL_CLICK not in authors:
                    media["rewindable"].append(shape)
            if added:
                changed.append(page)
        if not was_modified and doc.isModified():
            doc.setModified(False)
        if ctrl is not None and changed:
            show = self._engine(ctrl)
            for page in changed:
                # Drops a prefetched copy of the page (LibreOffice 24.8+).
                self._set(show, "HintSlideChanged", page)
            # Loaded without triggers: the slide on screen and, where the hint
            # is unknown, the prefetched next one. A click there would advance
            # the show instead.
            loaded = [ctrl.getCurrentSlide()]
            next_index = ctrl.getNextSlideIndex()
            if self._version() < (24, 8) and next_index >= 0:
                loaded.append(ctrl.getSlideByIndex(next_index))
            media["stale"] += [page for page in changed
                               if any(page == slide for slide in loaded if slide is not None)]

    def _version(self):
        """LibreOffice's (major, minor) version; (0, 0) if unreadable."""
        if self.version is None:
            provider = self.ctx.ServiceManager.createInstanceWithContext(
                "com.sun.star.configuration.ConfigurationProvider", self.ctx)
            prop = uno.createUnoStruct("com.sun.star.beans.PropertyValue")
            prop.Name = "nodepath"
            prop.Value = "/org.openoffice.Setup/Product"
            product = provider.createInstanceWithArguments(
                "com.sun.star.configuration.ConfigurationAccess", (prop,))
            try:
                self.version = tuple(int(part) for part in
                                     product.getByName("ooSetupVersion").split(".")[:2])
            except ValueError:
                self.version = (0, 0)
        return self.version

    def needs_release(self):
        return self.media is not None or self.highlights is not None

    def release_if_ended(self):
        """Removes the media triggers and highlighter shapes once the show
        has ended. The server stops polling state() when no phone is
        connected, so without this a show ended later would leave them in
        the document, where saving would keep them."""
        if self.needs_release() and self._running() is None:
            self._release_media()
            self._release_highlights()

    def _release_media(self):
        media, self.media, self.media_state = self.media, None, None
        if media is None or not media["nodes"]:
            return
        doc = media["doc"]
        try:
            was_modified = doc.isModified()
            for root, seq in media["nodes"]:
                root.removeChild(seq)
            if not was_modified and doc.isModified():
                doc.setModified(False)
        except Exception:  # noqa: BLE001 - the document was closed meanwhile
            pass

    def _new_node(self, service):
        return self.ctx.ServiceManager.createInstanceWithContext(
            "com.sun.star.animations." + service, self.ctx)

    def _media_trigger(self, shape, trigger, commands, preset):
        """An interactive sequence running (command, delay in seconds) steps
        on shape, one after the other, when the trigger event hits the shape.
        Laid out like the ones Impress itself creates."""
        steps = self._new_node("SequenceTimeContainer")
        for command, delay in commands:
            cmd = self._new_node("Command")
            cmd.Command = command
            cmd.Target = shape
            cmd.Begin = delay
            steps.appendChild(cmd)
        effect = self._new_node("ParallelTimeContainer")
        effect.UserData = (NamedValue("node-type", NODE_ON_CLICK),
                           NamedValue("preset-class", PRESET_MEDIA_CALL),
                           NamedValue("preset-id", preset))
        effect.appendChild(steps)
        group = self._new_node("ParallelTimeContainer")
        group.Begin = 0.0
        group.appendChild(effect)
        event = uno.createUnoStruct("com.sun.star.animations.Event")
        event.Source = shape
        event.Trigger = trigger
        click = self._new_node("ParallelTimeContainer")
        click.Begin = event
        click.appendChild(group)
        seq = self._new_node("SequenceTimeContainer")
        seq.UserData = (NamedValue("node-type", NODE_INTERACTIVE_SEQUENCE),
                        NamedValue(TRIGGER_MARK, True))
        # Re-arms the trigger after each click.
        seq.Restart = RESTART_WHEN_NOT_ACTIVE
        seq.appendChild(click)
        return seq

    @classmethod
    def _click_triggers(cls, root):
        """(shape, event trigger, sequence, added by us) for each click and
        double-click trigger of a slide."""
        found = []
        for seq in cls._children(root):
            ours = any(value.Name == TRIGGER_MARK for value in seq.UserData)
            for node in [seq] + cls._children(seq):
                begin = node.Begin
                for event in begin if isinstance(begin, tuple) else (begin,):
                    trigger = getattr(event, "Trigger", None)
                    if trigger in (ON_CLICK, ON_DBL_CLICK):
                        found.append((event.Source, trigger, seq, ours))
        return found

    @staticmethod
    def _children(node):
        children = []
        if hasattr(node, "createEnumeration"):
            enum = node.createEnumeration()
            while enum.hasMoreElements():
                children.append(enum.nextElement())
        return children

    def _current_media(self):
        doc, pres, ctrl = self._require_running()
        if ctrl.isPaused():
            # A click on a blanked show only brings the slide back.
            raise BridgeError("SCREEN_BLANKED")
        slide = ctrl.getCurrentSlide()
        shapes = list(self._media_shapes(slide)) if slide is not None else []
        if not shapes:
            raise BridgeError("NO_MEDIA")
        media = self._media_control(doc, pres)
        # Reached without state() seeing it, e.g. a jump in LibreOffice itself.
        self._prepare_pages(media, [slide], ctrl)
        if any(slide == page for page in media["stale"]):
            # Show the slide again so its triggers load; its media restarts.
            media["stale"] = [page for page in media["stale"] if not slide == page]
            ctrl.gotoSlideIndex(ctrl.getCurrentSlideIndex())
            self.media_state = None
            raise BridgeError("MEDIA_RELOADED")
        shape = shapes[0]
        if not any(shape == known for known in media["shapes"]):
            # Added during the show, so without triggers: a click would
            # advance the show instead.
            raise BridgeError("NO_MEDIA_TRIGGER")
        return doc, ctrl, slide, shape, media

    def _media_playing(self, ctrl, index):
        """[controller, index, playing] for the current slide. LibreOffice starts
        a slide's media when it shows the slide (if animations are allowed);
        after that only our clicks change it."""
        state = self.media_state
        if state is None or state[0] is not ctrl or state[1] != index:
            autoplay = self.media["autoplay"] if self.media is not None else True
            state = self.media_state = [ctrl, index, autoplay]
        return state

    @staticmethod
    def _fullscreen_frame(doc):
        controllers = doc.getControllers()
        while controllers.hasMoreElements():
            controller = controllers.nextElement()
            # The full screen show runs in a frame of its own.
            if controller.ViewControllerName == "FullScreenPresentation":
                return controller.getFrame()
        return None

    def _click_media(self, doc, slide, shape, double=False):
        frame = self._fullscreen_frame(doc)
        if frame is None:
            raise BridgeError("MEDIA_NEEDS_FULLSCREEN")
        window = frame.getComponentWindow()
        area = window.getPosSize()
        pos, size = shape.getPosition(), shape.getSize()
        x = pos.X + size.Width / 2
        if not double:
            # Two quick clicks on one spot would make a double click (rewind).
            self.click_side = -self.click_side
            x += self.click_side * size.Width / 6
        event = uno.createUnoStruct("com.sun.star.awt.MouseEvent")
        event.Source = window
        event.Buttons = MOUSE_LEFT
        event.ClickCount = 1
        event.X, event.Y = slide_to_window(slide.Width, slide.Height, area.Width, area.Height,
                                           x, pos.Y + size.Height / 2)
        for _ in range(2 if double else 1):
            self.toolkit.mousePress(event)
            self.toolkit.mouseRelease(event)

    def mediaToggle(self, _args):
        doc, ctrl, slide, shape, _media = self._current_media()
        self._click_media(doc, slide, shape)
        state = self._media_playing(ctrl, ctrl.getCurrentSlideIndex())
        state[2] = not state[2]

    def mediaRewind(self, _args):
        doc, ctrl, slide, shape, media = self._current_media()
        if not any(shape == rewindable for rewindable in media["rewindable"]):
            # The author's double-click trigger does something else.
            raise BridgeError("NO_MEDIA_TRIGGER")
        self._click_media(doc, slide, shape, double=True)
        self._media_playing(ctrl, ctrl.getCurrentSlideIndex())[2] = False

    def ping(self, _args):
        return {"connected": True}


COMMANDS = {
    "state", "next", "prev", "start", "startAt", "end", "blank",
    "arrow", "pen", "highlighter", "eraser", "eraseAll", "penColor", "highlighterColor",
    "laserOn", "laserOff", "pointer", "strokeBegin", "strokeEnd", "mediaToggle", "mediaRewind",
    "ping",
}


SLOW_COMMANDS = {"start", "startAt"}
# Commands that move the show, which a redraw of the slide would swallow.
MOVES = {"next", "prev", "start", "startAt"}


def handle(impress, request):
    if uno is None:
        return {"ok": False, "error": "NO_UNO"}
    cmd = request.get("cmd")
    if cmd not in COMMANDS:
        return {"ok": False, "error": "UNKNOWN_COMMAND"}
    try:
        impress.connect()
        if cmd in MOVES:
            impress.settle()
        # Starting may first import a PDF, which takes a while for long ones.
        timeout = 60.0 if cmd in SLOW_COMMANDS else 5.0
        result = impress.on_main_thread(lambda: getattr(impress, cmd)(request), timeout) or {}
        result["ok"] = True
        return result
    except BridgeError as e:
        if str(e) == "NO_CONNECTION" and cmd == "ping":
            return {"ok": True, "connected": False}
        return {"ok": False, "error": str(e)}
    except Exception as e:  # noqa: BLE001 - any UNO failure
        name = type(e).__name__
        # LibreOffice was closed or the bridge died: reconnect next time.
        if "Disposed" in name or "RuntimeException" in name or "Connection" in name:
            impress.reset()
        return {"ok": False, "error": "%s: %s" % (name, e)}


# Queued in place of pointer updates; stands for the newest one.
_POINTER = object()


def main():
    impress = Impress()
    work = queue.SimpleQueue()
    lock = threading.Lock()
    newest_pointer = [None]

    def read_requests():
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            try:
                request = json.loads(line)
            except ValueError:
                continue
            if not isinstance(request, dict):
                continue
            if request.get("cmd") == "pointer" and request.get("noreply"):
                with lock:
                    waiting = newest_pointer[0] is not None
                    # A stroke needs every position the update stands for.
                    request["trail"] = newest_pointer[0]["trail"] if waiting else []
                    request["trail"].append((request.get("x"), request.get("y")))
                    newest_pointer[0] = request
                if not waiting:
                    work.put(_POINTER)
            else:
                work.put(request)
        work.put(None)

    def release_if_ended():
        if not impress.needs_release() or impress.async_callback is None:
            return
        try:
            impress.on_main_thread(impress.release_if_ended)
        except Exception:  # noqa: BLE001 - LibreOffice gone or busy: try later
            pass

    threading.Thread(target=read_requests, daemon=True).start()
    while True:
        try:
            request = work.get(timeout=5)
        except queue.Empty:
            release_if_ended()
            continue
        if request is None:
            release_if_ended()  # the server quit
            break
        if request is _POINTER:
            with lock:
                request, newest_pointer[0] = newest_pointer[0], None
        reply = handle(impress, request)
        if request.get("noreply"):
            # Pointer updates answer only to move the cursor (_follow_laser).
            if "event" not in reply:
                continue
            reply = {key: value for key, value in reply.items() if key != "ok"}
        else:
            reply["id"] = request.get("id")
        sys.stdout.write(json.dumps(reply) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
