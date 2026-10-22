import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../powershell_runner.dart';
import '../../input_simulator.dart'; // For InputSimulator.onCommandError
import '../input_service.dart' show RemoteError;
import 'presenter_com.dart';

/// Polls the running show of PowerPoint or WPS ([PresenterCom.lookup]).
class SlideStateController {
  static Future<Map<String, dynamic>?> getSlideState() async {
    const script = '${PresenterCom.lookup}'
        r'''
try {
    if ($ppt -ne $null -and $ppt.SlideShowWindows.Count -gt 0) {
        $view = $ppt.SlideShowWindows.Item(1).View
        $presentation = $ppt.SlideShowWindows.Item(1).Presentation
        $current = $view.CurrentShowPosition
        $total = $presentation.Slides.Count
        
        $atEnd = $false
        if ($current -gt $total) {
            $atEnd = $true
            $current = $total
        }
        # The show's own black or white screen (B, W; PpSlideShowState 3, 4,
        # PowerPoint 365 and WPS 12.1): no screen picture goes to the phones
        # then, as with the black slide after the last one.
        $showState = 0
        try { $showState = $view.State } catch {}
        $isBlackScreen = $atEnd -or $showState -eq 3 -or $showState -eq 4

        $notes = ""
        $hasMedia = $false
        $isMediaPlaying = $null

        if (-not $atEnd) {
            $slide = $presentation.Slides.Item($current)
            if ($slide.HasNotesPage) {
                $shapes = $slide.NotesPage.Shapes
                foreach ($shape in $shapes) {
                    # The notes body (placeholder type 2) and text boxes. The
                    # slide number (13), header, footer and date placeholders
                    # have text too: the slide number ended up in the notes.
                    $placeholder = -1
                    try { $placeholder = $shape.PlaceholderFormat.Type } catch {}
                    if ($placeholder -eq 2 -or ($placeholder -eq -1 -and $shape.HasTextFrame)) {
                        $text = $shape.TextFrame.TextRange.Text
                        if ($text -ne $null -and $text.Trim() -ne "") {
                            # Paragraphs end in CR, Shift+Enter breaks are VT:
                            # the phone drew both as boxes.
                            $notes += ($text -replace '\r\n?|\x0B', "`n") + "`n"
                        }
                    }
                }
            }

            for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
                try {
                    $s = $slide.Shapes.Item($i)
                    if ($s.Type -eq 16) {
                        $hasMedia = $true
                        # WPS's Player.State always reads 0 (playing): unknown.
                        if ($qrPresenter -eq 'wps') { continue }
                        try {
                            $p = $null
                            try { $p = $view.Player($s.Name) } catch {}
                            if ($p -eq $null) { $p = $view.Player($s.Id) }
                            if ($p -ne $null) {
                                if ($p.State -eq 0) {
                                    $isMediaPlaying = $true
                                } else {
                                    $isMediaPlaying = $false
                                }
                            }
                        } catch {}
                    }
                } catch {}
            }
        }

        # The deck id the phone's slide pictures belong to: the file and when
        # it was last saved (an unsaved presentation has no file).
        $deckKey = "$($presentation.FullName)"
        try { $deckKey += "|" + (Get-Item -LiteralPath $presentation.FullName).LastWriteTimeUtc.Ticks } catch {}

        $data = @{
            deckKey = $deckKey
            current = $current
            total = $total
            notes = $notes.Trim()
            hasMedia = $hasMedia
            isMediaPlaying = $isMediaPlaying
            isBlackScreen = $isBlackScreen
            presenter = $qrPresenter
        }
        $data | ConvertTo-Json -Compress
    } else {
        Write-Output "POWERPOINT_NOT_RUNNING"
    }
} catch {
    Write-Output "POWERPOINT_NOT_RUNNING"
}
''';
    try {
      final output = await PowerShellRunner.execute(script, isPolling: true);
      if (output.trim() == 'POWERPOINT_NOT_RUNNING') {
        PresenterCom.active = null;
        return {'error': 'POWERPOINT_NOT_RUNNING'};
      }
      if (output.isNotEmpty && output.startsWith('{')) {
        final state = jsonDecode(output) as Map<String, dynamic>;
        PresenterCom.active = state['presenter'] as String?;
        return state;
      }
    } catch (e) {
      debugPrint('Exception in getSlideState: $e');
      InputSimulator.onCommandError?.call(RemoteError.slideStateFailed, '$e');
    }
    return null;
  }
}
