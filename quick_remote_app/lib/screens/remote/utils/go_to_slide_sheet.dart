import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
import '../../../utils/ui/app_popup_theme.dart';
import '../../../utils/ui/app_snackbar.dart';
import '../../../l10n/app_language.dart';
import '../../../services/websocket_service.dart';
import '../../../widgets/ui/ui.dart';
import '../widgets/slide_image.dart';

/// "Go to slide": a slide number on the phone's own number keyboard. A
/// running show jumps there; otherwise the show starts from it.
///
/// While the PC sends pictures of the running deck, a grid of the slides'
/// thumbnails takes the keyboard's place.
class GoToSlideSheet {
  GoToSlideSheet._();

  static Future<void> show(
    BuildContext context, {
    required int totalSlides,
    required void Function(String command) onSend,
    WebSocketService? ws,
  }) {
    return AppBottomSheet.show(
      context: context,
      builder: (ctx) => ws != null && showsGrid(ws)
          ? _SlideGrid(ws: ws, onSend: onSend)
          : _GoToSlide(totalSlides: totalSlides, onSend: onSend),
    );
  }

  static bool showsGrid(WebSocketService ws) =>
      ws.isPptRunning && ws.totalSlides > 0 && ws.hasSlideImages;
}

class _SlideGrid extends StatefulWidget {
  const _SlideGrid({required this.ws, required this.onSend});

  final WebSocketService ws;
  final void Function(String command) onSend;

  @override
  State<_SlideGrid> createState() => _SlideGridState();
}

class _SlideGridState extends State<_SlideGrid> {
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  void _pick(int slide) {
    HapticFeedback.mediumImpact();
    widget.onSend(RemoteCommands.startAt(slide));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBottomSheet.buildHeader(context.l10n.goToSlide, icon: Icons.grid_view_rounded),
        const SizedBox(height: AppSpace.sm),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          // Not under a SliverFillRemaining: a LayoutBuilder is fine here.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 400 ? 3 : 2;
              const gap = AppSpace.sm;
              final cellWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
              final rowExtent = cellWidth * 9 / 16 + 28;
              final total = ws.totalSlides;
              // Opens at the slide on screen.
              _scroll ??= ScrollController(
                initialScrollOffset: ((ws.currentSlide - 1) ~/ columns) * (rowExtent + gap),
              );
              return ListenableBuilder(
                listenable: ws,
                builder: (context, _) => GridView.builder(
                  controller: _scroll,
                  itemCount: total,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap,
                    mainAxisExtent: rowExtent,
                  ),
                  itemBuilder: (context, index) => _ThumbnailCell(
                    key: ValueKey(index + 1),
                    ws: ws,
                    slide: index + 1,
                    current: index + 1 == ws.currentSlide,
                    onTap: () => _pick(index + 1),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One slide of the grid: its thumbnail (a skeleton until it comes, the
/// empty frame when it cannot) and its number.
class _ThumbnailCell extends StatefulWidget {
  const _ThumbnailCell({
    super.key,
    required this.ws,
    required this.slide,
    required this.current,
    required this.onTap,
  });

  final WebSocketService ws;
  final int slide;
  final bool current;
  final VoidCallback onTap;

  @override
  State<_ThumbnailCell> createState() => _ThumbnailCellState();
}

class _ThumbnailCellState extends State<_ThumbnailCell> {
  @override
  void initState() {
    super.initState();
    widget.ws.requestThumbnail(widget.slide);
  }

  @override
  void dispose() {
    widget.ws.cancelThumbnail(widget.slide);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ws = widget.ws;
    final image = ws.thumbnail(widget.slide);
    final loading = image == null && !ws.thumbnailFailed(widget.slide);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: AppRadius.all(AppRadius.sm),
            border: widget.current ? Border.all(color: p.accent, width: 2) : null,
          ),
          child: loading
              ? Semantics(
                  button: true,
                  label: context.l10n.slidePreviewLabel(widget.slide),
                  child: GestureDetector(
                    onTap: widget.onTap,
                    child: const AspectRatio(aspectRatio: 16 / 9, child: Skeleton(height: double.infinity)),
                  ),
                )
              : SlideImage(slide: widget.slide, image: image, onTap: widget.onTap),
        ),
        const SizedBox(height: AppSpace.xxs),
        Text(
          '${widget.slide}',
          textAlign: TextAlign.center,
          style: AppType.labelSmall.copyWith(
            color: widget.current ? p.accent : p.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _GoToSlide extends StatefulWidget {
  const _GoToSlide({required this.totalSlides, required this.onSend});

  final int totalSlides;
  final void Function(String command) onSend;

  @override
  State<_GoToSlide> createState() => _GoToSlideState();
}

class _GoToSlideState extends State<_GoToSlide> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    final maxSlide = widget.totalSlides > 0 ? widget.totalSlides : 9999;
    if (parsed == null || parsed <= 0 || parsed > maxSlide) {
      AppSnackbar.show(
        context,
        message: context.l10n.slidePickerInvalid(maxSlide),
        type: SnackbarType.error,
      );
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onSend(RemoteCommands.startAt(parsed));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBottomSheet.buildHeader(context.l10n.goToSlide, icon: Icons.grid_view_rounded),
        const SizedBox(height: AppSpace.sm),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
          style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 20),
          decoration: AppPopupTheme.inputDecoration(context: context).copyWith(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          widget.totalSlides > 0 ? context.l10n.goToSlideRange(widget.totalSlides) : context.l10n.goToSlideNumber,
          style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: AppButton(
                label: context.l10n.cancel,
                variant: AppButtonVariant.outline,
                tone: AppTone.neutral,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              flex: 7,
              child: AppButton(
                label: context.l10n.goAction,
                icon: Icons.arrow_forward_rounded,
                onPressed: _controller.text.trim().isEmpty ? null : _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
