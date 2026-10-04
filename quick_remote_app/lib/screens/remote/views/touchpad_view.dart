import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../services/websocket_service.dart';
import '../../../services/presentation_timer_controller.dart';
import '../../../widgets/presentation_timer.dart';
import '../widgets/shared_buttons.dart';
import '../utils/slide_picker_sheet.dart';
import '../../../models/draw_tool.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/touchpad_gesture_area.dart';
import '../widgets/draw_tool_bar.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class TouchpadView extends StatefulWidget {
  final WebSocketService ws;
  final PresentationTimerController timer;

  const TouchpadView({
    super.key,
    required this.ws,
    required this.timer,
  });

  @override
  State<TouchpadView> createState() => _TouchpadViewState();
}

class _TouchpadViewState extends State<TouchpadView> {
  final double _sensitivity = 8.0;
  DrawTool _drawTool = DrawTool.laser;

  void _send(String command) {
    HapticFeedback.mediumImpact();
    widget.ws.sendCommand(command);
  }

  void _showStartSlideDialog(BuildContext context) {
    SlidePickerSheet.show(
      context,
      totalSlides: widget.ws.totalSlides,
      onSend: _send,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ContentWidth(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xs, AppSpace.page, AppSpace.sm),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    icon: Icons.play_arrow_rounded,
                    label: context.l10n.actionStart,
                    color: p.success,
                    showMenuHint: true,
                    onTap: !widget.ws.isConnected
                        ? null
                        : () {
                            HapticFeedback.heavyImpact();
                            _send(RemoteCommands.start);
                          },
                    onLongPress: !widget.ws.isConnected
                        ? null
                        : () {
                            HapticFeedback.heavyImpact();
                            _showStartSlideDialog(context);
                          },
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                PresentationTimer(controller: widget.timer),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: PillButton(
                    icon: Icons.stop_rounded,
                    label: context.l10n.actionEnd,
                    color: p.danger,
                    onTap: !widget.ws.isConnected ? null : () => _send(RemoteCommands.end),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            // Touchpad area
            Expanded(
              child: TouchpadGestureArea(
                sensitivity: _sensitivity,
                drawTool: _drawTool,
                onSendCommand: (cmd) => widget.ws.sendCommand(cmd),
                onSendTouchOrLaser: (type, dx, dy) => widget.ws.sendTouchOrLaser(type, dx, dy),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            // Draw tool selector
            DrawToolBar(
              activeTool: _drawTool,
              onToolSelected: (tool) => setState(() => _drawTool = tool),
              onClear: () {
                HapticFeedback.mediumImpact();
                _send(RemoteCommands.eraseAll);
              },
              onColorPickerRequested: (tool) {
                ColorPickerSheet.show(context, tool, _send);
              },
            ),
            const SizedBox(height: AppSpace.sm),
            // Slide buttons at bottom
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SlideButton(
                    icon: Icons.arrow_back_rounded,
                    label: context.l10n.actionPrev,
                    height: 76,
                    onTap: !widget.ws.isConnected ? null : () => _send(RemoteCommands.prev),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  flex: 3,
                  child: SlideButton(
                    icon: Icons.arrow_forward_rounded,
                    label: context.l10n.actionNext,
                    isPrimary: true,
                    height: 76,
                    onTap: !widget.ws.isConnected ? null : () => _send(RemoteCommands.next),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
