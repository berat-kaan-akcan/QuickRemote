"""Tests for the parts of wps_bridge.py that need no running WPS.

Run from the repo root: python3 -m unittest discover -s quick_remote_pc/test/python
"""
import importlib.util
import os
import subprocess
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


if __name__ == "__main__":
    unittest.main()
