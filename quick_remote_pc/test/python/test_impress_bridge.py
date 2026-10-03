"""Tests for the parts of impress_bridge.py that need no running LibreOffice.

Run from the repo root: python3 -m unittest discover -s quick_remote_pc/test/python
"""
import importlib.util
import os
import socket
import sys
import tempfile
import unittest

_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "linux", "impress_bridge.py")


def _load():
    argv, sys.argv = sys.argv, ["impress_bridge.py", "quickremote_test_%d" % os.getpid()]
    try:
        spec = importlib.util.spec_from_file_location("impress_bridge", _PATH)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    finally:
        sys.argv = argv


bridge = _load()


class FakeImpress:
    def __init__(self, error=None):
        self.error = error
        self.resets = 0
        self.called = []

    def connect(self):
        pass

    def on_main_thread(self, fn):
        return fn()

    def reset(self):
        self.resets += 1

    def next(self, _request):
        if self.error:
            raise self.error
        self.called.append("next")

    def ping(self, _request):
        if self.error:
            raise self.error
        return {"connected": True}


class SlideToWindowTest(unittest.TestCase):
    def test_same_aspect_maps_corners(self):
        self.assertEqual(bridge.slide_to_window(28000, 15750, 1920, 1080, 0, 0), (0, 0))
        self.assertEqual(bridge.slide_to_window(28000, 15750, 1920, 1080, 28000, 15750), (1919, 1079))

    def test_narrower_slide_is_centred_horizontally(self):
        # 4:3 slide on a 16:9 screen: 1440 px wide, 240 px bars on both sides.
        self.assertEqual(bridge.slide_to_window(28000, 21000, 1920, 1080, 0, 0), (240, 0))
        self.assertEqual(bridge.slide_to_window(28000, 21000, 1920, 1080, 14000, 10500), (960, 540))

    def test_wider_slide_is_centred_vertically(self):
        # 16:9 slide on a 4:3 screen: 768 px high, 128 px bars above and below.
        self.assertEqual(bridge.slide_to_window(28000, 15750, 1024, 1024, 0, 0)[1], 224)


class HandleTest(unittest.TestCase):
    def setUp(self):
        self._uno = bridge.uno
        bridge.uno = object()  # pretend Python-UNO is installed

    def tearDown(self):
        bridge.uno = self._uno

    def test_runs_an_allowed_command(self):
        impress = FakeImpress()
        self.assertEqual(bridge.handle(impress, {"cmd": "next"}), {"ok": True})
        self.assertEqual(impress.called, ["next"])

    def test_refuses_names_outside_the_allowlist(self):
        # getattr must never reach internals such as reset or connect.
        for cmd in ("reset", "connect", "__init__", "_running", None, 3):
            reply = bridge.handle(FakeImpress(), {"cmd": cmd})
            self.assertEqual(reply, {"ok": False, "error": "UNKNOWN_COMMAND"}, cmd)

    def test_reports_missing_uno(self):
        bridge.uno = None
        self.assertEqual(bridge.handle(FakeImpress(), {"cmd": "next"}), {"ok": False, "error": "NO_UNO"})

    def test_ping_without_libreoffice_is_not_an_error(self):
        impress = FakeImpress(error=bridge.BridgeError("NO_CONNECTION"))
        self.assertEqual(bridge.handle(impress, {"cmd": "ping"}), {"ok": True, "connected": False})

    def test_bridge_errors_pass_through(self):
        impress = FakeImpress(error=bridge.BridgeError("NOT_RUNNING"))
        self.assertEqual(bridge.handle(impress, {"cmd": "next"}), {"ok": False, "error": "NOT_RUNNING"})

    def test_a_dead_connection_resets_the_bridge(self):
        class DisposedException(Exception):
            pass

        impress = FakeImpress(error=DisposedException("gone"))
        reply = bridge.handle(impress, {"cmd": "next"})
        self.assertFalse(reply["ok"])
        self.assertEqual(impress.resets, 1)


@unittest.skipIf(bridge.uno is None, "needs LibreOffice's Python-UNO")
class MainThreadCallTest(unittest.TestCase):
    def test_runs_the_function(self):
        call = bridge.MainThreadCall(lambda: 42)
        call.notify(None)
        self.assertTrue(call.done.is_set())
        self.assertEqual(call.result, 42)

    def test_a_cancelled_call_does_not_run(self):
        ran = []
        call = bridge.MainThreadCall(lambda: ran.append(1))
        call.cancelled = True
        call.notify(None)
        self.assertTrue(call.done.is_set())
        self.assertEqual(ran, [])


class ReleaseIfEndedTest(unittest.TestCase):
    def make(self, running):
        impress = bridge.Impress()
        impress.media = {"doc": None, "nodes": []}
        impress.released = 0
        impress._running = lambda: running
        impress._release_media = lambda: setattr(impress, "released", impress.released + 1)
        return impress

    def test_releases_after_the_show_ended(self):
        impress = self.make(running=None)
        impress.release_if_ended()
        self.assertEqual(impress.released, 1)

    def test_keeps_triggers_while_the_show_runs(self):
        impress = self.make(running=("doc", "pres", "ctrl"))
        impress.release_if_ended()
        self.assertEqual(impress.released, 0)


class LaserGeometryTest(unittest.TestCase):
    def test_show_on_the_second_monitor(self):
        geometry = bridge.show_geometry(1920, 0, 1920, 1080, (3840, 1080))
        self.assertEqual(geometry, (1920, 0, 1920, 1080, 3840, 1080))
        # Slide centre -> centre of the right half of the desktop.
        x, y = bridge.desktop_fraction(geometry, 28000, 15750, 0.5, 0.5)
        self.assertAlmostEqual(x, 2880 / 3840, places=3)
        self.assertAlmostEqual(y, 0.5, places=2)

    def test_without_an_x_root_the_show_fills_the_desktop(self):
        self.assertEqual(bridge.show_geometry(0, 0, 1536, 864, None), (0, 0, 1536, 864, 1536, 864))
        # A window outside the root: not an X client, its position is unknown.
        self.assertEqual(bridge.show_geometry(1920, 0, 1920, 1080, (1920, 1080)),
                         (0, 0, 1920, 1080, 1920, 1080))

    def test_letterboxed_slide(self):
        # 4:3 slide on a 16:9 screen: its left edge is 240 px in.
        geometry = (0, 0, 1920, 1080, 1920, 1080)
        self.assertAlmostEqual(bridge.desktop_fraction(geometry, 28000, 21000, 0, 0)[0], 240 / 1920)

    def test_park_stays_off_the_screen_corner(self):
        x, y = bridge.park_fraction((0, 0, 1920, 1080, 1920, 1080))
        self.assertLess(x * 1920, 1919)
        self.assertLess(y * 1080, 1079)


class FollowLaserTest(unittest.TestCase):
    class Ctrl:
        MouseVisible = False

    def make(self):
        impress = bridge.Impress()
        ctrl = self.Ctrl()
        impress.props = []
        impress._running = lambda: ("doc", "pres", ctrl)
        impress._slide_media_rects = lambda _ctrl: (28000, 15750, [(0.25, 0.25, 0.75, 0.75)])
        impress._show_geometry = lambda _doc, _ctrl: (0, 0, 1920, 1080, 1920, 1080)
        impress._engine = lambda _ctrl: "engine"
        impress._set = lambda _show, name, value: impress.props.append((name, value))
        return impress, ctrl

    def test_cursor_stands_in_for_the_laser_over_a_video(self):
        impress, ctrl = self.make()
        self.assertIsNone(impress._follow_laser(0.1, 0.1))

        event = impress._follow_laser(0.5, 0.5)
        self.assertEqual(event["event"], "cursor")
        self.assertAlmostEqual(event["x"], 0.5, places=2)
        self.assertEqual(impress.props, [("PointerVisible", False)])
        self.assertTrue(ctrl.MouseVisible)

        # Leaving the video parks the cursor and brings the laser back.
        park = impress._follow_laser(0.1, 0.5)
        self.assertGreater(park["x"], 0.99)
        self.assertEqual(impress.props[-1], ("PointerVisible", True))
        self.assertFalse(ctrl.MouseVisible)
        self.assertIsNone(impress._follow_laser(0.1, 0.6))


class NavigationDropsInkTest(unittest.TestCase):
    class Ctrl:
        def __init__(self):
            self.calls = []

        def setEraseAllInk(self, value):
            self.calls.append(("erase", value))

        def gotoNextEffect(self):
            self.calls.append("next")

        def gotoPreviousEffect(self):
            self.calls.append("prev")

    def test_ink_is_erased_before_the_show_moves(self):
        impress = bridge.Impress()
        ctrl = self.Ctrl()
        impress._require_running = lambda: ("doc", "pres", ctrl)
        impress.next({})
        impress.prev({})
        self.assertEqual(ctrl.calls, [("erase", True), "next", ("erase", True), "prev"])

    def test_the_setting_keeps_the_ink(self):
        impress = bridge.Impress()
        ctrl = self.Ctrl()
        impress._require_running = lambda: ("doc", "pres", ctrl)
        impress.next({"clearInk": False})
        self.assertEqual(ctrl.calls, ["next"])


class PipeIsTrustedTest(unittest.TestCase):
    def setUp(self):
        self.path = "/tmp/OSL_PIPE_%d_%s" % (os.getuid(), bridge.PIPE_NAME)

    def tearDown(self):
        if os.path.lexists(self.path):
            os.unlink(self.path)

    def test_missing_pipe_is_allowed(self):
        self.assertTrue(bridge.pipe_is_trusted())

    def test_own_socket_is_trusted(self):
        sock = socket.socket(socket.AF_UNIX)
        sock.bind(self.path)
        try:
            self.assertTrue(bridge.pipe_is_trusted())
        finally:
            sock.close()

    def test_a_non_socket_is_refused(self):
        with open(self.path, "w"):
            pass
        self.assertFalse(bridge.pipe_is_trusted())

    def test_a_symlink_is_refused(self):
        target = tempfile.NamedTemporaryFile()
        os.symlink(target.name, self.path)
        self.assertFalse(bridge.pipe_is_trusted())
        target.close()


if __name__ == "__main__":
    unittest.main()
