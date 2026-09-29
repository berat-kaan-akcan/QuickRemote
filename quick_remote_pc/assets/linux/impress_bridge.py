#!/usr/bin/env python3
"""QuickRemote <-> LibreOffice Impress bridge.

Reads one JSON request per line from stdin and writes one JSON reply per line
to stdout:  {"id": 1, "cmd": "next"}  ->  {"id": 1, "ok": true}
Requests with "noreply": true get no answer (used for high-frequency pointer
updates).

The argument is the name of the UNO pipe LibreOffice accepts connections on
(ooSetupConnectionURL or `soffice --accept=pipe,name=NAME;urp;`). A pipe is a
Unix socket only its owner can connect to; a TCP listener would let every
local user and sandboxed app run code through LibreOffice. A numeric argument
selects a localhost TCP port instead, for manual testing only.
"""
import json
import os
import stat
import sys
import threading

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

        def notify(self, _data):
            try:
                self.result = self.fn()
            except Exception as e:  # noqa: BLE001 - re-raised in the caller
                self.error = e
            finally:
                self.done.set()

PEN_WIDTH = 150.0
HIGHLIGHTER_WIDTH = 600.0
HIGHLIGHTER_COLOR = 0xFFE600
MEDIA_SHAPES = ("com.sun.star.presentation.MediaShape", "com.sun.star.drawing.MediaShape")


class BridgeError(Exception):
    pass


class Impress:
    def __init__(self):
        self.ctx = None
        self.desktop = None
        self.async_callback = None
        self.pen_color = 0xFF0000
        self.blank_color = None
        # slide index -> True while we started its media
        self.media_playing = {}

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
        self.desktop = self.ctx.ServiceManager.createInstanceWithContext(
            "com.sun.star.frame.Desktop", self.ctx)
        self.async_callback = self.ctx.ServiceManager.createInstanceWithContext(
            "com.sun.star.awt.AsyncCallback", self.ctx)

    def reset(self):
        self.ctx = None
        self.desktop = None
        self.async_callback = None

    def on_main_thread(self, fn, timeout=5.0):
        call = MainThreadCall(fn)
        self.async_callback.addCallback(call, None)
        if not call.done.wait(timeout):
            raise BridgeError("TIMEOUT")
        if call.error is not None:
            raise call.error
        return call.result

    # ── Document / slideshow lookup ──
    def _presentation_docs(self):
        docs = []
        current = self.desktop.getCurrentComponent()
        if current is not None and current.supportsService(
                "com.sun.star.presentation.PresentationDocument"):
            docs.append(current)
        enum = self.desktop.getComponents().createEnumeration()
        while enum.hasMoreElements():
            doc = enum.nextElement()
            if doc is not None and doc not in docs and doc.supportsService(
                    "com.sun.star.presentation.PresentationDocument"):
                docs.append(doc)
        return docs

    def _running(self):
        for doc in self._presentation_docs():
            pres = doc.getPresentation()
            if pres.isRunning():
                ctrl = pres.getController()
                if ctrl is not None:
                    return doc, pres, ctrl
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

    @staticmethod
    def _set(ctrl, name, value):
        show = ctrl.getSlideShow()
        if show is None:
            raise BridgeError("NO_SLIDESHOW_ENGINE")
        prop = uno.createUnoStruct("com.sun.star.beans.PropertyValue")
        prop.Name = name
        prop.Value = value
        show.setProperty(prop)

    # ── State ──
    def state(self, _args):
        running = self._running()
        if running is None:
            return {"state": "NOT_RUNNING"}
        _doc, _pres, ctrl = running
        total = ctrl.getSlideCount()
        index = ctrl.getCurrentSlideIndex()
        # Past the last slide LibreOffice shows its "click to exit" screen.
        at_end = index < 0 or index >= total
        current = total if at_end else index + 1

        notes = ""
        has_media = False
        slide = None if at_end else ctrl.getCurrentSlide()
        if slide is not None:
            notes = self._notes(slide)
            has_media = any(True for _ in self._media_shapes(slide))

        is_playing = self.media_playing.get(index) if has_media else None
        return {
            "state": "RUNNING",
            "current": current,
            "total": total,
            "notes": notes,
            "hasMedia": has_media,
            "isMediaPlaying": is_playing,
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

    @staticmethod
    def _media_shapes(slide):
        for i in range(slide.getCount()):
            shape = slide.getByIndex(i)
            if shape.getShapeType() in MEDIA_SHAPES:
                yield shape

    # ── Navigation ──
    def next(self, _args):
        self._require_running()[2].gotoNextEffect()

    def prev(self, _args):
        self._require_running()[2].gotoPreviousEffect()

    def start(self, _args):
        running = self._running()
        if running is not None:
            running[2].gotoSlideIndex(0)
            return
        self._reset_show_state()
        self._document().getPresentation().start()

    def startAt(self, args):
        number = int(args["slide"])
        running = self._running()
        if running is not None:
            running[2].gotoSlideIndex(max(0, number - 1))
            return
        doc = self._document()
        pages = doc.getDrawPages()
        number = min(max(1, number), pages.getCount())
        prop = uno.createUnoStruct("com.sun.star.beans.PropertyValue")
        prop.Name = "FirstPage"
        prop.Value = pages.getByIndex(number - 1).getName()
        self._reset_show_state()
        doc.getPresentation().startWithArguments((prop,))

    def end(self, _args):
        self._require_running()[1].end()
        self._reset_show_state()

    def _reset_show_state(self):
        self.blank_color = None
        self.media_playing = {}

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
    def _ink(self, ctrl, pen, eraser=False, color=None, width=PEN_WIDTH):
        self._set(ctrl, "PointerVisible", False)
        ctrl.UsePen = pen
        if pen:
            ctrl.PenColor = self.pen_color if color is None else color
            ctrl.PenWidth = width
        self._set(ctrl, "SwitchEraserMode", eraser)
        self._set(ctrl, "SwitchPenMode", not eraser)

    def arrow(self, _args):
        self._ink(self._require_running()[2], pen=False)

    def pen(self, _args):
        self._ink(self._require_running()[2], pen=True)

    def highlighter(self, _args):
        self._ink(self._require_running()[2], pen=True,
                  color=HIGHLIGHTER_COLOR, width=HIGHLIGHTER_WIDTH)

    def eraser(self, _args):
        self._ink(self._require_running()[2], pen=True, eraser=True)

    def eraseAll(self, _args):
        self._require_running()[2].setEraseAllInk(True)

    def penColor(self, args):
        self.pen_color = int(args["rgb"])
        running = self._running()
        if running is not None and running[2].UsePen:
            running[2].PenColor = self.pen_color

    def laserOn(self, _args):
        ctrl = self._require_running()[2]
        ctrl.UsePen = False
        self._set(ctrl, "PointerVisible", True)

    def laserOff(self, _args):
        self._set(self._require_running()[2], "PointerVisible", False)

    def pointer(self, args):
        ctrl = self._require_running()[2]
        pos = uno.createUnoStruct("com.sun.star.geometry.RealPoint2D",
                                  float(args["x"]), float(args["y"]))
        self._set(ctrl, "PointerPosition", pos)

    # ── Embedded media ──
    def _current_media(self):
        ctrl = self._require_running()[2]
        slide = ctrl.getCurrentSlide()
        shapes = list(self._media_shapes(slide)) if slide is not None else []
        if not shapes:
            raise BridgeError("NO_MEDIA")
        return ctrl, ctrl.getCurrentSlideIndex(), shapes[0]

    def mediaToggle(self, _args):
        ctrl, index, shape = self._current_media()
        show = ctrl.getSlideShow()
        if self.media_playing.get(index):
            show.stopShapeActivity(shape)
            self.media_playing[index] = False
        else:
            show.startShapeActivity(shape)
            self.media_playing[index] = True

    def mediaRewind(self, _args):
        ctrl, index, shape = self._current_media()
        ctrl.getSlideShow().stopShapeActivity(shape)
        self.media_playing[index] = False

    def ping(self, _args):
        return {"connected": True}


COMMANDS = {
    "state", "next", "prev", "start", "startAt", "end", "blank",
    "arrow", "pen", "highlighter", "eraser", "eraseAll", "penColor",
    "laserOn", "laserOff", "pointer", "mediaToggle", "mediaRewind", "ping",
}


def handle(impress, request):
    if uno is None:
        return {"ok": False, "error": "NO_UNO"}
    cmd = request.get("cmd")
    if cmd not in COMMANDS:
        return {"ok": False, "error": "UNKNOWN_COMMAND"}
    try:
        impress.connect()
        result = impress.on_main_thread(lambda: getattr(impress, cmd)(request)) or {}
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


def main():
    impress = Impress()
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            request = json.loads(line)
        except ValueError:
            continue
        reply = handle(impress, request)
        if request.get("noreply"):
            continue
        reply["id"] = request.get("id")
        sys.stdout.write(json.dumps(reply) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
