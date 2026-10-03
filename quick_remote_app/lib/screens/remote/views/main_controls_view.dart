import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../services/websocket_service.dart';
import '../../../services/presentation_timer_controller.dart';
import '../../../widgets/presentation_timer.dart';
import '../widgets/shared_buttons.dart';
import '../utils/remote_dialogs.dart';
import '../utils/slide_picker_sheet.dart';
import '../../../l10n/app_language.dart';

class MainControlsView extends StatefulWidget {
  final WebSocketService ws;
  final PresentationTimerController timer;

  const MainControlsView({
    super.key,
    required this.ws,
    required this.timer,
  });

  @override
  State<MainControlsView> createState() => _MainControlsViewState();
}

class _MainControlsViewState extends State<MainControlsView> {
  String? _activeScreen; // 'BLACK' or 'WHITE' or null

  void _send(String command) {
    HapticFeedback.mediumImpact();
    
    if (command == RemoteCommands.blackScreen) {
      setState(() {
        _activeScreen = _activeScreen == 'BLACK' ? null : 'BLACK';
      });
    } else if (command == RemoteCommands.whiteScreen) {
      setState(() {
        _activeScreen = _activeScreen == 'WHITE' ? null : 'WHITE';
      });
    } else {
      if ([RemoteCommands.next, RemoteCommands.prev, RemoteCommands.start, RemoteCommands.end].contains(command) || command.startsWith('START_AT')) {
         setState(() { _activeScreen = null; });
      }
    }
    
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
    final ws = widget.ws;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    PresentationTimer(
                      controller: widget.timer,
                      fontSize: 16.0,
                      iconSize: 20.0,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F38),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.slideshow_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              // 0: a show the PC sees but cannot read (a WPS it did not open).
                              ws.isPptRunning && ws.currentSlide == 0 && ws.totalSlides == 0
                                  ? context.l10n.slideshowOpen
                                  : context.l10n.slideCounter(ws.currentSlide, ws.totalSlides > 0 ? ws.totalSlides.toString() : '?'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (ws.isPptRunning && ws.slideNotes.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => RemoteDialogs.showNotesDialog(context, ws.slideNotes),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.notes_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      context.l10n.notes,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!ws.isPptRunning) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                context.l10n.presentationNotOpen(ws.presenterNames.join(context.l10n.listOr)),
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: ActionButton(
                                  icon: Icons.play_arrow_rounded,
                                  label: context.l10n.actionStart,
                                  color: const Color(0xFF4CAF50),
                                  onTap: !ws.isConnected ? null : () {
                                    _send(RemoteCommands.start);
                                  },
                                  onLongPress: !ws.isConnected ? null : () {
                                    HapticFeedback.heavyImpact();
                                    _showStartSlideDialog(context);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ActionButton(
                                  icon: Icons.stop_rounded,
                                  label: context.l10n.actionEnd,
                                  color: const Color(0xFFFF5252),
                                  onTap: !ws.isConnected ? null : () => _send(RemoteCommands.end),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ActionButton(
                                  icon: Icons.visibility_off_rounded,
                                  label: context.l10n.blackScreen,
                                  color: Colors.grey,
                                  isActive: _activeScreen == 'BLACK',
                                  onTap: !ws.isConnected ? null : () => _send(RemoteCommands.blackScreen),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ActionButton(
                                  icon: Icons.visibility_rounded,
                                  label: context.l10n.whiteScreen,
                                  color: Colors.white,
                                  isActive: _activeScreen == 'WHITE',
                                  onTap: !ws.isConnected ? null : () => _send(RemoteCommands.whiteScreen),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SlideButton(
                                  icon: Icons.arrow_back_rounded,
                                  label: context.l10n.actionPrev,
                                  onTap: !ws.isConnected ? null : () => _send(RemoteCommands.prev),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SlideButton(
                                  icon: Icons.arrow_forward_rounded,
                                  label: context.l10n.actionNext,
                                  isPrimary: true,
                                  onTap: !ws.isConnected ? null : () => _send(RemoteCommands.next),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

