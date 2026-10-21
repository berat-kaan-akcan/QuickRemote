#!/usr/bin/env python3
"""QuickRemote <-> WPS Presentation bridge (Linux).

Reads one JSON request per line from stdin and writes one JSON reply per line
to stdout, like impress_bridge.py:  {"id": 1, "cmd": "next"}  ->  {"id": 1, "ok": true}

WPS's RPC interface (the pywpsrpc package) cannot attach to a WPS the user
started: getWppApplication() always starts a WPS of its own
(`wpp -automation`). So the bridge controls only the WPS it started for an
"open" request. Files the user opens later go to that WPS as well, as long as
no other WPS was running before it. No request but "open" starts WPS; without
one they answer NOT_RUNNING, and the server falls back to key presses.
"""
import json
import os
import signal
import sys

try:
    from pywpsrpc.rpcwppapi import createWppRpcInstance
except ImportError:
    createWppRpcInstance = None

S_OK = 0

# The PowerPoint object model's constants, which WPS shares.
SHOW_RUNNING = 1
SHOW_BLACK = 3
SHOW_WHITE = 4
SHOW_DONE = 5
POINTER_ARROW = 1
POINTER_PEN = 2
POINTER_AUTO_ARROW = 4
POINTER_ERASER = 5
PLAYER_PLAYING = 0
SHAPE_PLACEHOLDER = 14
SHAPE_MEDIA = 16
PLACEHOLDER_BODY = 2
MSO_TRUE = -1


# Slide pictures for the phone (export).
EXPORT_MIN_WIDTH = 16
EXPORT_MAX_WIDTH = 4096


class BridgeError(Exception):
    pass


def export_height(slide_width, slide_height, width):
    """The pixel height of a slide exported width pixels wide."""
    if not slide_width or not slide_height or slide_width <= 0 or slide_height <= 0:
        return round(width * 9 / 16)
    return max(1, round(width * slide_height / slide_width))


def export_request(args, total):
    """(index, width, path) of a valid export request for a show of total
    slides, else None. The path must be an absolute .jpg file name."""
    index, width, path = args.get("index"), args.get("width"), args.get("path")
    if (not isinstance(index, int) or not isinstance(width, int) or isinstance(index, bool)
            or not 1 <= index <= total or not EXPORT_MIN_WIDTH <= width <= EXPORT_MAX_WIDTH
            or not isinstance(path, str) or not os.path.isabs(path)
            or not path.endswith(".jpg") or "\0" in path):
        return None
    return index, width, path


def deck_key(path):
    """What tells the presentation's slide pictures apart: its file and when
    the file was last saved ("" for a presentation never saved)."""
    if not path:
        return ""
    try:
        return "%s|%d" % (path, int(os.path.getmtime(path) * 1000))
    except OSError:
        return path


def call(obj, name, *args):
    """Calls an RPC method; pywpsrpc returns (hr, value) or a bare hr."""
    if obj is None:
        raise BridgeError("NOT_RUNNING")
    ret = getattr(obj, name)(*args)
    if isinstance(ret, tuple):
        if ret[0] != S_OK:
            raise BridgeError("%s failed (0x%08x)" % (name, ret[0] & 0xFFFFFFFF))
        return ret[1] if len(ret) == 2 else ret[1:]
    if ret != S_OK:
        raise BridgeError("%s failed (0x%08x)" % (name, ret & 0xFFFFFFFF))
    return None


def item(collection, index):
    return call(collection, "Item", index)


def alive(pid):
    """Whether process [pid] runs (a zombie child does not count)."""
    if not pid:
        return False
    try:
        # The RPC library forks WPS from this process: reap it once it exits.
        if os.waitpid(pid, os.WNOHANG)[0] == pid:
            return False
    except ChildProcessError:
        pass
    try:
        with open("/proc/%d/stat" % pid) as f:
            return f.read().rsplit(")", 1)[1].split()[0] != "Z"
    except (OSError, IndexError):
        return False


def child_named(pid, name, proc="/proc"):
    """The child of [pid] called [name]: /usr/bin/wpp is a shell script that
    runs the real binary, whose windows carry the binary's pid."""
    try:
        entries = os.listdir(proc)
    except OSError:
        return None
    for entry in entries:
        if not entry.isdigit():
            continue
        try:
            with open("%s/%s/stat" % (proc, entry)) as f:
                stat = f.read()
        except OSError:
            continue
        comm = stat[stat.find("(") + 1:stat.rfind(")")]
        fields = stat.rsplit(")", 1)[1].split()
        if comm == name and len(fields) > 1 and fields[1] == str(pid):
            return int(entry)
    return None


def slide_notes(slide):
    """The text of the notes page's body placeholder (all its text shapes
    when it has none)."""
    try:
        if call(slide, "get_HasNotesPage") != MSO_TRUE:
            return ""
    except BridgeError:
        pass
    shapes = call(call(slide, "get_NotesPage"), "get_Shapes")
    body, others = [], []
    for i in range(1, call(shapes, "get_Count") + 1):
        shape = item(shapes, i)
        try:
            if call(shape, "get_HasTextFrame") != MSO_TRUE:
                continue
            text = call(call(call(shape, "get_TextFrame"), "get_TextRange"), "get_Text").strip()
        except BridgeError:
            continue
        if not text:
            continue
        try:
            is_body = (call(shape, "get_Type") == SHAPE_PLACEHOLDER and
                       call(call(shape, "get_PlaceholderFormat"), "get_Type") == PLACEHOLDER_BODY)
        except BridgeError:
            is_body = False
        (body if is_body else others).append(text)
    return "\n".join(body or others)


def media_shapes(slide):
    shapes = call(slide, "get_Shapes")
    for i in range(1, call(shapes, "get_Count") + 1):
        shape = item(shapes, i)
        try:
            if call(shape, "get_Type") == SHAPE_MEDIA:
                yield shape
        except BridgeError:
            continue


class Wps:
    def __init__(self):
        self.app = None
        self.rpc = None
        self.wrapper_pid = None
        self.pid = None
        self.pen_color = None

    def reset(self):
        self.app = None
        self.rpc = None
        self.wrapper_pid = None
        self.pid = None

    def _check_alive(self):
        if self.app is not None and not alive(self.wrapper_pid):
            self.reset()

    def _application(self):
        self._check_alive()
        if self.app is None:
            raise BridgeError("NOT_RUNNING")
        return self.app

    def _start_wps(self):
        hr, rpc = createWppRpcInstance()
        if hr != S_OK or rpc is None:
            raise BridgeError("WPS_START_FAILED")
        hr, app = rpc.getWppApplication()
        if hr != S_OK or app is None:
            raise BridgeError("WPS_START_FAILED")
        hr, pid = rpc.getProcessPid()
        self.rpc, self.app = rpc, app
        self.wrapper_pid = pid if hr == S_OK and pid > 0 else None
        self.pid = child_named(self.wrapper_pid, "wpp") if self.wrapper_pid else None

    def _stop_wps(self):
        for pid in (self.pid, self.wrapper_pid):
            if pid:
                try:
                    os.kill(pid, signal.SIGTERM)
                except OSError:
                    pass
        self.reset()

    def _show(self):
        """(window, view, presentation) of the running show, or None."""
        self._check_alive()
        if self.app is None:
            return None
        windows = call(self.app, "get_SlideShowWindows")
        if call(windows, "get_Count") == 0:
            return None
        window = item(windows, 1)
        return window, call(window, "get_View"), call(window, "get_Presentation")

    def _require_show(self):
        show = self._show()
        if show is None:
            raise BridgeError("NOT_RUNNING")
        return show

    def _presentation(self):
        app = self._application()
        if call(call(app, "get_Presentations"), "get_Count") == 0:
            raise BridgeError("NO_PRESENTATION")
        return call(app, "get_ActivePresentation")

    # ── Requests ──
    def ping(self, _args):
        self._check_alive()
        return {"connected": self.app is not None, "pid": self.pid}

    def open(self, args):
        path = args.get("path")
        if not isinstance(path, str) or not os.path.isfile(path):
            raise BridgeError("NO_FILE")
        self._check_alive()
        if self.app is None:
            self._start_wps()
        try:
            presentations = call(self.app, "get_Presentations")
        except BridgeError:
            # A WPS whose windows the user closed keeps running and answers
            # nothing: end it and start another.
            self._stop_wps()
            self._start_wps()
            presentations = call(self.app, "get_Presentations")
        pres = call(presentations, "Open", os.path.abspath(path))
        try:
            total = call(call(pres, "get_Slides"), "get_Count")
        except BridgeError:
            total = None
        return {"pid": self.pid, "total": total}

    def state(self, _args):
        show = self._show()
        if show is None:
            return {"state": "NOT_RUNNING", "pid": self.pid}
        _window, view, pres = show
        total = call(call(pres, "get_Slides"), "get_Count")
        current = call(view, "get_CurrentShowPosition")
        show_state = call(view, "get_State")
        # Past the last slide the show displays its black "end" screen.
        at_end = current > total or show_state == SHOW_DONE
        notes, has_media, playing = "", False, None
        if not at_end and current >= 1:
            slide = item(call(pres, "get_Slides"), current)
            try:
                notes = slide_notes(slide)
            except BridgeError:
                notes = ""
            for shape in media_shapes(slide):
                has_media = True
                player = self._player(view, shape)
                if player is not None:
                    playing = call(player, "get_State") == PLAYER_PLAYING
                break
        return {
            "state": "RUNNING",
            "current": min(current, total),
            "total": total,
            "notes": notes,
            "hasMedia": has_media,
            "isMediaPlaying": playing,
            "isBlackScreen": at_end or show_state in (SHOW_BLACK, SHOW_WHITE),
            "pid": self.pid,
            "deckKey": self._deck_key(pres),
        }

    @staticmethod
    def _deck_key(pres):
        try:
            return deck_key(call(pres, "get_FullName"))
        except Exception:  # noqa: BLE001 - the slide state matters more than the id
            return ""

    def export(self, args):
        """Writes slide "index" of the running show (without one, of the
        active presentation: a take-over matches the user's show against
        them) to "path" as a JPEG "width" pixels wide (Slide.Export, verified
        on WPS 11.1.0.11723) and answers its height. The picture is the slide
        as the document holds it: the animation step, ink and a playing video
        do not show."""
        show = self._show()
        pres = show[2] if show is not None else self._presentation()
        slides = call(pres, "get_Slides")
        request = export_request(args, call(slides, "get_Count"))
        if request is None:
            raise BridgeError("BAD_REQUEST")
        index, width, path = request
        setup = call(pres, "get_PageSetup")
        height = export_height(call(setup, "get_SlideWidth"), call(setup, "get_SlideHeight"), width)
        if os.path.exists(path):
            os.remove(path)
        call(item(slides, index), "Export", path, "JPG", width, height)
        # A call can succeed without doing anything (WPS's Player does).
        if not os.path.isfile(path):
            raise BridgeError("NOT_EXPORTED")
        return {"height": height}

    @staticmethod
    def _player(view, shape):
        for key in ("get_Id", "get_Name"):
            try:
                return call(view, "Player", call(shape, key))
            except BridgeError:
                continue
        return None

    def next(self, args):
        view = self._require_show()[1]
        self._drop_ink(view, args)
        call(view, "Next")

    def prev(self, args):
        view = self._require_show()[1]
        self._drop_ink(view, args)
        call(view, "Previous")

    @staticmethod
    def _drop_ink(view, args):
        """WPS keeps a slide's ink and shows it again when the show returns,
        like PowerPoint: erase it first unless the request says "clearInk": false."""
        if args.get("clearInk", True):
            call(view, "EraseDrawing")

    def start(self, args):
        show = self._show()
        if show is not None:
            self._goto(show[1], 1, args)
            return
        # Run() uses the presentation's own show settings, like F5.
        call(call(self._presentation(), "get_SlideShowSettings"), "Run")

    def startAt(self, args):
        number = int(args["slide"])
        show = self._show()
        if show is None:
            call(call(self._presentation(), "get_SlideShowSettings"), "Run")
            show = self._require_show()
        _window, view, pres = show
        total = call(call(pres, "get_Slides"), "get_Count")
        self._goto(view, min(max(1, number), total), args)

    def _goto(self, view, index, args):
        self._drop_ink(view, args)
        call(view, "GotoSlide", index)

    def end(self, _args):
        call(self._require_show()[1], "Exit")

    def blank(self, args):
        target = SHOW_BLACK if int(args["color"]) == 0 else SHOW_WHITE
        view = self._require_show()[1]
        # The same blank key again returns to the slide, like B and W.
        new = SHOW_RUNNING if call(view, "get_State") == target else target
        call(view, "put_State", new)

    def arrow(self, _args):
        self._pointer(POINTER_AUTO_ARROW)

    def pen(self, args):
        """Takes the color in "bgr" first, when given."""
        if args.get("bgr") is not None:
            self.pen_color = int(args["bgr"])
        view = self._pointer(POINTER_PEN)
        if self.pen_color is not None:
            self._set_color(view, self.pen_color)

    def eraser(self, _args):
        self._pointer(POINTER_ERASER)

    def eraseAll(self, _args):
        call(self._require_show()[1], "EraseDrawing")

    def laserOn(self, _args):
        # WPS's laser pen (Ctrl+R) is not in its object model: the server
        # presses that key in a focused show, and moves the visible arrow
        # pointer instead when the show is not focused.
        self._pointer(POINTER_ARROW)

    def laserOff(self, _args):
        self._pointer(POINTER_AUTO_ARROW)

    def _pointer(self, kind):
        view = self._require_show()[1]
        call(view, "put_PointerType", kind)
        return view

    def penColor(self, args):
        """BGR, like PowerPoint's PointerColor.RGB. Applies now when drawing,
        otherwise when the pen is next chosen."""
        self.pen_color = int(args["bgr"])
        show = self._show()
        if show is not None and call(show[1], "get_PointerType") == POINTER_PEN:
            self._set_color(show[1], self.pen_color)

    def pointerColor(self, args):
        """Recolors the tool drawing now (the highlighter after Ctrl+I)."""
        self._set_color(self._require_show()[1], int(args["bgr"]))

    @staticmethod
    def _set_color(view, bgr):
        call(call(view, "get_PointerColor"), "put_RGB", bgr)

    def _current_player(self):
        _window, view, pres = self._require_show()
        current = call(view, "get_CurrentShowPosition")
        if current > call(call(pres, "get_Slides"), "get_Count"):
            raise BridgeError("NO_MEDIA")
        for shape in media_shapes(item(call(pres, "get_Slides"), current)):
            player = self._player(view, shape)
            if player is not None:
                return player
        raise BridgeError("NO_MEDIA")

    def mediaToggle(self, _args):
        player = self._current_player()
        call(player, "Pause" if call(player, "get_State") == PLAYER_PLAYING else "Play")

    def mediaRewind(self, _args):
        player = self._current_player()
        call(player, "Pause")
        call(player, "put_CurrentPosition", 0)


COMMANDS = {
    "ping", "open", "state", "next", "prev", "start", "startAt", "end", "blank",
    "arrow", "pen", "eraser", "eraseAll", "laserOn", "laserOff", "penColor",
    "pointerColor", "mediaToggle", "mediaRewind", "export",
}


def handle(wps, request):
    cmd = request.get("cmd")
    if createWppRpcInstance is None:
        if cmd == "ping":
            return {"ok": True, "rpc": False, "connected": False}
        return {"ok": False, "error": "NO_RPC"}
    if cmd not in COMMANDS:
        return {"ok": False, "error": "UNKNOWN_COMMAND"}
    try:
        result = getattr(wps, cmd)(request) or {}
        result["ok"] = True
        if cmd == "ping":
            result["rpc"] = True
        return result
    except BridgeError as e:
        return {"ok": False, "error": str(e)}
    except Exception as e:  # noqa: BLE001 - any RPC failure
        return {"ok": False, "error": "%s: %s" % (type(e).__name__, e)}


def main():
    wps = Wps()
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
        reply = handle(wps, request)
        if request.get("noreply"):
            continue
        reply["id"] = request.get("id")
        sys.stdout.write(json.dumps(reply) + "\n")
        sys.stdout.flush()
    # The RPC library crashes in Python's shutdown; WPS itself stays open.
    sys.stdout.flush()
    os._exit(0)


if __name__ == "__main__":
    main()
