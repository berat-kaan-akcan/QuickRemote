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
import '../../../theme/app_colors.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PillButton(
                  icon: Icons.play_arrow_rounded,
                  label: context.l10n.actionStart,
                  color: AppColors.success,
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
              const SizedBox(width: 8),
              PresentationTimer(controller: widget.timer),
              const SizedBox(width: 8),
              Expanded(
                child: PillButton(
                  icon: Icons.stop_rounded,
                  label: context.l10n.actionEnd,
                  color: AppColors.danger,
                  onTap: !widget.ws.isConnected ? null : () => _send(RemoteCommands.end),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Touchpad area
          Expanded(
            child: TouchpadGestureArea(
              sensitivity: _sensitivity,
              drawTool: _drawTool,
              onSendCommand: (cmd) => widget.ws.sendCommand(cmd),
              onSendTouchOrLaser: (type, dx, dy) => widget.ws.sendTouchOrLaser(type, dx, dy),
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          // Slide buttons at bottom
          Row(
            children: [
              Expanded(
                child: SlideButton(
                  icon: Icons.arrow_back_rounded,
                  label: context.l10n.actionPrev,
                  onTap: !widget.ws.isConnected ? null : () => _send(RemoteCommands.prev),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SlideButton(
                  icon: Icons.arrow_forward_rounded,
                  label: context.l10n.actionNext,
                  isPrimary: true,
                  onTap: !widget.ws.isConnected ? null : () => _send(RemoteCommands.next),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
