"""Tests for the parts of wps_bridge.py that need no running WPS.

Run from the repo root: python3 -m unittest discover -s quick_remote_pc/test/python
"""
import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest

_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "linux", "wps_bridge.py")


def _load():
    spec = importlib.util.spec_from_file_location("wps_bridge", _PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


bridge = _load()


class Obj:
    """An RPC object: methods return (hr, value) or a bare hr."""

    def __init__(self, **methods):
        self.calls = []
        for name, result in methods.items():
            setattr(self, name, self._method(name, result))

    def _method(self, name, result):
        def method(*args):
            self.calls.append((name,) + args)
            return result(*args) if callable(result) else result
        return method


class CallTest(unittest.TestCase):
    def test_returns_the_value(self):
        self.assertEqual(bridge.call(Obj(get_Count=(0, 3)), "get_Count"), 3)

    def test_a_bare_hresult_returns_none(self):
        self.assertIsNone(bridge.call(Obj(Next=0), "Next"))

    def test_a_failed_call_raises(self):
        with self.assertRaises(bridge.BridgeError):
            bridge.call(Obj(get_Count=(-2147467259, 0)), "get_Count")
        with self.assertRaises(bridge.BridgeError):
            bridge.call(Obj(Next=-2147467259), "Next")

    def test_no_object_is_not_running(self):
        with self.assertRaisesRegex(bridge.BridgeError, "NOT_RUNNING"):
            bridge.call(None, "get_Count")


class FakeShow:
    """A running show: one view over a presentation of [total] slides."""

    def __init__(self, total=4, position=2, state=1, pointer=4):
        self.view = Obj(
            get_CurrentShowPosition=lambda: (0, self.position),
            get_State=lambda: (0, self.state),
            put_State=self._put_state,
            get_PointerType=lambda: (0, self.pointer),
            put_PointerType=self._put_pointer,
            Next=0, Previous=0, EraseDrawing=0, GotoSlide=0, Exit=0,
        )
        self.position, self.state, self.pointer = position, state, pointer
        slides = Obj(get_Count=(0, total), Item=lambda i: (0, Obj(
            get_HasNotesPage=(0, 0), get_Shapes=(0, Obj(get_Count=(0, 0))))))
        self.pres = Obj(get_Slides=(0, slides))

    def _put_state(self, value):
        self.state = value
        return 0

    def _put_pointer(self, value):
        self.pointer = value
        return 0


def _wps_with(show):
    wps = bridge.Wps()
    wps._show = lambda: (None, show.view, show.pres)
    return wps


class NavigationTest(unittest.TestCase):
    def test_ink_is_erased_before_the_show_moves(self):
        show = FakeShow()
        _wps_with(show).next({})
        self.assertEqual([c[0] for c in show.view.calls], ["EraseDrawing", "Next"])

    def test_the_setting_keeps_the_ink(self):
        show = FakeShow()
        _wps_with(show).prev({"clearInk": False})
        self.assertEqual([c[0] for c in show.view.calls], ["Previous"])

    def test_start_at_clamps_to_the_last_slide(self):
        show = FakeShow(total=4)
        _wps_with(show).startAt({"slide": 9, "clearInk": False})
        self.assertIn(("GotoSlide", 4), show.view.calls)


class BlankTest(unittest.TestCase):
    def test_blank_toggles_like_the_keys(self):
        show = FakeShow()
        wps = _wps_with(show)
        wps.blank({"color": 0})
        self.assertEqual(show.state, bridge.SHOW_BLACK)
        wps.blank({"color": 0xFFFFFF})
        self.assertEqual(show.state, bridge.SHOW_WHITE)
        wps.blank({"color": 0xFFFFFF})
        self.assertEqual(show.state, bridge.SHOW_RUNNING)


class StateTest(unittest.TestCase):
    def test_reports_the_slide(self):
        state = _wps_with(FakeShow(total=4, position=2)).state({})
        self.assertEqual((state["state"], state["current"], state["total"]), ("RUNNING", 2, 4))
        self.assertFalse(state["isBlackScreen"])

    def test_the_end_screen_counts_as_the_last_slide(self):
        state = _wps_with(FakeShow(total=4, position=5)).state({})
        self.assertEqual(state["current"], 4)
        self.assertTrue(state["isBlackScreen"])

    def test_without_a_show(self):
        wps = bridge.Wps()
        self.assertEqual(wps.state({})["state"], "NOT_RUNNING")
        with self.assertRaisesRegex(bridge.BridgeError, "NOT_RUNNING"):
            wps.next({})


class NotesTest(unittest.TestCase):
    @staticmethod
    def _shape(text, body):
        return Obj(
            get_HasTextFrame=(0, bridge.MSO_TRUE),
            get_TextFrame=(0, Obj(get_TextRange=(0, Obj(get_Text=(0, text))))),
            get_Type=(0, bridge.SHAPE_PLACEHOLDER if body else 1),
            get_PlaceholderFormat=(0, Obj(get_Type=(0, bridge.PLACEHOLDER_BODY))),
        )

    def _slide(self, shapes):
        collection = Obj(get_Count=(0, len(shapes)), Item=lambda i: (0, shapes[i - 1]))
        return Obj(get_HasNotesPage=(0, bridge.MSO_TRUE),
                   get_NotesPage=(0, Obj(get_Shapes=(0, collection))))

    def test_prefers_the_body_placeholder(self):
        slide = self._slide([self._shape("3", body=False), self._shape(" Not ", body=True)])
        self.assertEqual(bridge.slide_notes(slide), "Not")

    def test_an_empty_text_box_is_skipped(self):
        slide = self._slide([self._shape(None, body=True), self._shape("x", body=False)])
        self.assertEqual(bridge.slide_notes(slide), "x")

    def test_falls_back_to_other_text(self):
        self.assertEqual(bridge.slide_notes(self._slide([self._shape("x", body=False)])), "x")


class PenColorTest(unittest.TestCase):
    def test_applies_to_the_pen_now_or_when_chosen(self):
        color = Obj(put_RGB=0)
        show = FakeShow(pointer=bridge.POINTER_ARROW)
        show.view.get_PointerColor = lambda: (0, color)
        wps = _wps_with(show)
        wps.penColor({"bgr": 0xFF})
        self.assertEqual(color.calls, [])
        wps.pen({})
        self.assertEqual(show.pointer, bridge.POINTER_PEN)
        self.assertEqual(color.calls, [("put_RGB", 0xFF)])


class HandleTest(unittest.TestCase):
    def setUp(self):
        self.saved = bridge.createWppRpcInstance

    def tearDown(self):
        bridge.createWppRpcInstance = self.saved

    def test_reports_missing_pywpsrpc(self):
        bridge.createWppRpcInstance = None
        self.assertEqual(bridge.handle(bridge.Wps(), {"cmd": "next"}), {"ok": False, "error": "NO_RPC"})
        self.assertEqual(bridge.handle(bridge.Wps(), {"cmd": "ping"})["rpc"], False)

    def test_refuses_names_outside_the_allowlist(self):
        bridge.createWppRpcInstance = object()
        self.assertEqual(bridge.handle(bridge.Wps(), {"cmd": "reset"})["error"], "UNKNOWN_COMMAND")

    def test_no_request_but_open_starts_wps(self):
        started = []
        bridge.createWppRpcInstance = lambda: started.append(1) or (1, None)
        for cmd in ("state", "next", "start", "ping"):
            bridge.handle(bridge.Wps(), {"cmd": cmd})
        self.assertEqual(started, [])

    def test_open_refuses_a_missing_file(self):
        bridge.createWppRpcInstance = object()
        reply = bridge.handle(bridge.Wps(), {"cmd": "open", "path": "/nonexistent/x.pptx"})
        self.assertEqual(reply["error"], "NO_FILE")


class ProcessTest(unittest.TestCase):
    @unittest.skipUnless(sys.platform.startswith("linux"), "needs waitpid and the true command")
    def test_a_finished_child_is_not_alive(self):
        child = subprocess.Popen(["true"])
        while child.poll() is None:
            pass
        self.assertFalse(bridge.alive(child.pid))
        self.assertTrue(bridge.alive(os.getpid()))
        self.assertFalse(bridge.alive(None))

    def test_finds_the_wpp_child_of_the_launcher(self):
        with tempfile.TemporaryDirectory() as proc:
            for pid, comm, ppid in ((10, "bash", 1), (11, "wpp", 10), (12, "wpp", 99)):
                os.mkdir(os.path.join(proc, str(pid)))
                with open(os.path.join(proc, str(pid), "stat"), "w") as f:
                    f.write("%d (%s) S %d 0 0" % (pid, comm, ppid))
            self.assertEqual(bridge.child_named(10, "wpp", proc), 11)
            self.assertIsNone(bridge.child_named(12, "wpp", proc))


class ExportTest(unittest.TestCase):
    def _wps(self, export):
        slide = Obj(Export=export)
        slides = Obj(get_Count=(0, 3), Item=lambda _i: (0, slide))
        setup = Obj(get_SlideWidth=(0, 960.0), get_SlideHeight=(0, 540.0))
        pres = Obj(get_Slides=(0, slides), get_PageSetup=(0, setup))
        wps = bridge.Wps()
        wps._show = lambda: (None, None, pres)
        return wps, slide

    def test_writes_the_slide_and_answers_its_height(self):
        def export(path, _filter, _width, _height):
            with open(path, "wb") as f:
                f.write(b"\xff\xd8")
            return 0

        wps, slide = self._wps(export)
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "slide-2-640.jpg")
            self.assertEqual(wps.export({"index": 2, "width": 640, "path": path}), {"height": 360})
            self.assertEqual(slide.calls, [("Export", path, "JPG", 640, 360)])

    def test_an_export_that_writes_nothing_fails(self):
        wps, _slide = self._wps(0)
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(bridge.BridgeError) as caught:
                wps.export({"index": 1, "width": 320, "path": os.path.join(tmp, "a.jpg")})
        self.assertEqual(str(caught.exception), "NOT_EXPORTED")

    def test_refuses_a_bad_request(self):
        wps, slide = self._wps(0)
        for bad in ({"index": 4, "width": 320, "path": "/tmp/a.jpg"},
                    {"index": 1, "width": 320, "path": "a.jpg"},
                    {"index": 1, "width": 9000, "path": "/tmp/a.jpg"}):
            with self.assertRaises(bridge.BridgeError):
                wps.export(bad)
        self.assertEqual(slide.calls, [])

    def test_without_a_show_the_active_presentation_is_exported(self):
        def export(path, _filter, _width, _height):
            with open(path, "wb") as f:
                f.write(b"\xff\xd8")
            return 0

        wps, slide = self._wps(export)
        pres = wps._show()[2]
        wps._show = lambda: None
        wps._presentation = lambda: pres
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "slide-1-64.jpg")
            self.assertEqual(wps.export({"index": 1, "width": 64, "path": path}), {"height": 36})

    @unittest.skipUnless(sys.platform.startswith("linux"), "needs waitpid")
    def test_open_answers_the_slide_count(self):
        with tempfile.NamedTemporaryFile(suffix=".pptx") as f:
            pres = Obj(get_Slides=(0, Obj(get_Count=(0, 7))))
            presentations = Obj(Open=(0, pres))
            wps = bridge.Wps()
            wps.app = Obj(get_Presentations=(0, presentations))
            wps.wrapper_pid = os.getpid()
            wps.pid = 42
            self.assertEqual(wps.open({"path": f.name}), {"pid": 42, "total": 7})
            self.assertEqual(presentations.calls, [("Open", os.path.abspath(f.name))])

    @unittest.skipUnless(sys.platform.startswith("linux"), "needs waitpid")
    def test_open_replaces_a_wps_that_stopped_answering(self):
        with tempfile.NamedTemporaryFile(suffix=".pptx") as f:
            pres = Obj(get_Slides=(0, Obj(get_Count=(0, 2))))
            wps = bridge.Wps()
            wps.app = Obj(get_Presentations=(-2147483640, None))
            wps.wrapper_pid = os.getpid()
            events = []

            def start():
                events.append("start")
                wps.app = Obj(get_Presentations=(0, Obj(Open=(0, pres))))
                wps.wrapper_pid, wps.pid = os.getpid(), 43

            wps._stop_wps = lambda: events.append("stop") or wps.reset()
            wps._start_wps = start
            self.assertEqual(wps.open({"path": f.name}), {"pid": 43, "total": 2})
            self.assertEqual(events, ["stop", "start"])

    def test_deck_key_names_the_file_and_its_save(self):
        self.assertEqual(bridge.deck_key(""), "")
        with tempfile.NamedTemporaryFile(suffix=".pptx") as f:
            first = bridge.deck_key(f.name)
            self.assertTrue(first.startswith(f.name + "|"))
            os.utime(f.name, (1, 2))
            self.assertNotEqual(bridge.deck_key(f.name), first)


if __name__ == "__main__":
    unittest.main()


class RequestParsingTest(unittest.TestCase):
    def test_object_lines_only(self):
        self.assertEqual(bridge.parse_request('{"cmd": "ping"}'), {"cmd": "ping"})
        for line in ("[1]", "3", "null", "{broken", ""):
            self.assertIsNone(bridge.parse_request(line), line)

    def test_deep_nesting_does_not_raise(self):
        self.assertIsNone(bridge.parse_request("[" * 200000))

    def test_command_that_is_not_a_string_is_unknown(self):
        saved = bridge.createWppRpcInstance
        bridge.createWppRpcInstance = lambda: None
        try:
            for cmd in ([1], {"a": 1}, None):
                self.assertEqual(bridge.handle(bridge.Wps(), {"cmd": cmd}),
                                 {"ok": False, "error": "UNKNOWN_COMMAND"})
        finally:
            bridge.createWppRpcInstance = saved
