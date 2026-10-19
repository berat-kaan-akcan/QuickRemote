import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../services/websocket_service.dart';
import '../../../services/presentation_timer_controller.dart';
import '../../../widgets/presentation_timer.dart';
import '../widgets/shared_buttons.dart';
import '../../../models/draw_tool.dart';
import '../widgets/tool_popover.dart';
import '../widgets/touchpad_gesture_area.dart';
import '../widgets/draw_tool_bar.dart';
import '../utils/show_info.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class TouchpadView extends StatefulWidget {
  final WebSocketService ws;
  final PresentationTimerController timer;

  /// The ink (BGR) the user last sent to the pen and the highlighter, kept
  /// by the remote while the tabs change.
  final Map<DrawTool, int> inks;
  final void Function(DrawTool tool, int bgr) onInk;

  const TouchpadView({
    super.key,
    required this.ws,
    required this.timer,
    required this.inks,
    required this.onInk,
  });

  @override
  State<TouchpadView> createState() => _TouchpadViewState();
}

class _TouchpadViewState extends State<TouchpadView> {
  final double _sensitivity = 8.0;
  DrawTool _drawTool = DrawTool.laser;

  /// The tool whose colors (or note) show above the bar; null: none.
  DrawTool? _popoverFor;

  void _send(String command) {
    HapticFeedback.mediumImpact();
    widget.ws.sendCommand(command);
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final show = ShowInfo.of(ws);
    final connected = ws.isConnected;
    final swatches = {
      for (final (_, color, bgr) in inkSwatches(context)) bgr: color,
    };
    final inks = show.colorsAvailable
        ? {
            for (final MapEntry(key: tool, value: bgr) in widget.inks.entries)
              if (swatches[bgr] != null) tool: swatches[bgr]!,
          }
        : const <DrawTool, Color>{};
    final popoverFor = show.running ? _popoverFor : null;

    return ContentWidth(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.xxs,
          AppSpace.page,
          AppSpace.sm,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ShowToggleButton(
                    compact: true,
                    running: show.running,
                    startLabel: context.l10n.actionStart,
                    endLabel: context.l10n.actionEnd,
                    onTap: !connected
                        ? null
                        : () {
                            HapticFeedback.heavyImpact();
                            _send(
                              show.running
                                  ? RemoteCommands.end
                                  : RemoteCommands.start,
                            );
                          },
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                PresentationTimer(controller: widget.timer, tall: true),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Expanded(
              child: TouchpadGestureArea(
                sensitivity: _sensitivity,
                drawTool: _drawTool,
                inks: inks,
                enabled: show.running,
                onSendCommand: (cmd) => widget.ws.sendCommand(cmd),
                onSendTouchOrLaser: (type, dx, dy) =>
                    widget.ws.sendTouchOrLaser(type, dx, dy),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Reveal(
              child: popoverFor == null
                  ? null
                  : ToolPopover(
                      // The pen is the second of five keys, the highlighter the third.
                      anchor: popoverFor == DrawTool.pen ? 0.3 : 0.5,
                      child: show.colorsAvailable
                          ? InkPicker(
                              tool: popoverFor,
                              selected: widget.inks[popoverFor],
                              onPicked: (bgr) {
                                // Pen and highlighter keep separate colors.
                                _send(
                                  popoverFor == DrawTool.pen
                                      ? RemoteCommands.penColor(bgr)
                                      : RemoteCommands.highlighterColor(bgr),
                                );
                                widget.onInk(popoverFor, bgr);
                                setState(() => _popoverFor = null);
                              },
                              onClose: () => setState(() => _popoverFor = null),
                            )
                          : const NoColorNote(),
                    ),
            ),
            DrawToolBar(
              activeTool: _drawTool,
              inks: inks,
              enabled: show.running,
              onToolSelected: (tool) => setState(() {
                _drawTool = tool;
                _popoverFor = null;
              }),
              onClear: () {
                HapticFeedback.mediumImpact();
                _send(RemoteCommands.eraseAll);
              },
              onColorPickerRequested: (tool) => setState(
                () => _popoverFor = _popoverFor == tool ? null : tool,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            SlideNavRow(
              prevLabel: context.l10n.actionPrev,
              nextLabel: context.l10n.actionNext,
              onPrev: !connected ? null : () => _send(RemoteCommands.prev),
              onNext: !connected ? null : () => _send(RemoteCommands.next),
            ),
          ],
        ),
      ),
    );
  }
}
