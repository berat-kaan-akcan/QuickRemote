#!/usr/bin/env python3
"""QuickRemote <-> LibreOffice Impress bridge.

Reads one JSON request per line from stdin and writes one JSON reply per line
to stdout:  {"id": 1, "cmd": "next"}  ->  {"id": 1, "ok": true}
Requests with "noreply": true get no answer (used for high-frequency pointer
updates). Of those pointer updates only the newest waiting one is applied, so
a busy LibreOffice never falls behind the laser.

The argument is the name of the UNO pipe LibreOffice accepts connections on
(ooSetupConnectionURL or `soffice --accept=pipe,name=NAME;urp;`). A pipe is a
Unix socket only its owner can connect to; a TCP listener would let every
local user and sandboxed app run code through LibreOffice. A numeric argument
selects a localhost TCP port instead, for manual testing only.
"""
import json
import os
import queue
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

PEN_WIDTH = 150.0
HIGHLIGHTER_WIDTH = 600.0
HIGHLIGHTER_COLOR = 0xFFE600
MEDIA_SHAPES = ("com.sun.star.presentation.MediaShape", "com.sun.star.drawing.MediaShape")
# UserData entry marking the media triggers this bridge adds (see _prepare_pages).
TRIGGER_MARK = "quickremote-media"


class BridgeError(Exception):
    pass


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
            return {"state": "NOT_RUNNING"}
        doc, pres, ctrl = running
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
    def next(self, _args):
        self._require_running()[2].gotoNextEffect()

    def prev(self, _args):
        self._require_running()[2].gotoPreviousEffect()

    def start(self, _args):
        running = self._running()
        if running is not None:
            self._goto(running, 0)
            return
        doc = self._document()
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
            self._goto(running, min(max(0, number - 1), running[2].getSlideCount() - 1))
            return
        doc = self._document()
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
        # The slideshow reads a slide's animations when it loads the slide.
        self._try_prepare(doc, pres, first_pages)
        pres.startWithArguments(arguments)

    def _goto(self, running, index):
        doc, pres, ctrl = running
        self._try_prepare(doc, pres, lambda: self._upcoming(ctrl, index, ctrl.getSlideCount()), ctrl)
        ctrl.gotoSlideIndex(index)

    def end(self, _args):
        self._require_running()[1].end()
        self._reset_show_state()
        self._release_media()

    def _reset_show_state(self):
        self.blank_color = None
        self.slide_info = None
        self.media_state = None

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
        show = self._engine(ctrl)
        self._set(show, "PointerVisible", False)
        ctrl.UsePen = pen
        if pen:
            ctrl.PenColor = self.pen_color if color is None else color
            ctrl.PenWidth = width
        self._set(show, "SwitchEraserMode", eraser)
        self._set(show, "SwitchPenMode", not eraser)

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
        self._set(self._engine(ctrl), "PointerVisible", True)

    def laserOff(self, _args):
        self._set(self._engine(self._require_running()[2]), "PointerVisible", False)

    def pointer(self, args):
        pos = uno.createUnoStruct("com.sun.star.geometry.RealPoint2D",
                                  float(args["x"]), float(args["y"]))
        # One call on the cached engine; it answers False once its show is over.
        if self.pointer_engine is None or not self._set(self.pointer_engine, "PointerPosition", pos):
            self.pointer_engine = self._engine(self._require_running()[2])
            self._set(self.pointer_engine, "PointerPosition", pos)

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

    def release_if_ended(self):
        """Removes the media triggers once the show has ended. The server
        stops polling state() when no phone is connected, so without this a
        show ended later would leave them in the document, where saving
        would keep them."""
        if self.media is not None and self._running() is None:
            self._release_media()

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

    def _click_media(self, doc, slide, shape, double=False):
        window = None
        controllers = doc.getControllers()
        while window is None and controllers.hasMoreElements():
            controller = controllers.nextElement()
            # The full screen show runs in a frame of its own.
            if controller.ViewControllerName == "FullScreenPresentation":
                window = controller.getFrame().getComponentWindow()
        if window is None:
            raise BridgeError("MEDIA_NEEDS_FULLSCREEN")
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
                    newest_pointer[0] = request
                if not waiting:
                    work.put(_POINTER)
            else:
                work.put(request)
        work.put(None)

    def release_media_if_ended():
        if impress.media is None or impress.async_callback is None:
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
            release_media_if_ended()
            continue
        if request is None:
            release_media_if_ended()  # the server quit
            break
        if request is _POINTER:
            with lock:
                request, newest_pointer[0] = newest_pointer[0], None
        reply = handle(impress, request)
        if request.get("noreply"):
            continue
        reply["id"] = request.get("id")
        sys.stdout.write(json.dumps(reply) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
