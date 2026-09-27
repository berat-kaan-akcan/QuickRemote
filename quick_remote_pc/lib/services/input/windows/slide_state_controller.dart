import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../powershell_runner.dart';
import '../../input_simulator.dart'; // For InputSimulator.onCommandError

class SlideStateController {
  static Future<Map<String, dynamic>?> getSlideState() async {
    const script = r'''
try {
    $ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if ($ppt -ne $null -and $ppt.SlideShowWindows.Count -gt 0) {
        $view = $ppt.SlideShowWindows.Item(1).View
        $current = $view.CurrentShowPosition
        $total = $ppt.ActivePresentation.Slides.Count
        
        $isBlackScreen = $false
        if ($current -gt $total) {
            $isBlackScreen = $true
            $current = $total
        }

        $notes = ""
        $hasMedia = $false
        $isMediaPlaying = $null
        $shapeTypes = ""

        if (-not $isBlackScreen) {
            $slide = $ppt.ActivePresentation.Slides.Item($current)
            if ($slide.HasNotesPage) {
                $shapes = $slide.NotesPage.Shapes
                foreach ($shape in $shapes) {
                    if ($shape.Type -eq 14 -or $shape.HasTextFrame) {
                        $text = $shape.TextFrame.TextRange.Text
                        if ($text -ne $null -and $text.Trim() -ne "") {
                            $notes += $text + "`n"
                        }
                    }
                }
            }

            for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
                try {
                    $s = $slide.Shapes.Item($i)
                    if ($s.Type -eq 16) {
                        $hasMedia = $true
                        try {
                            $p = $view.Player($s.Name)
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
            $shapeTypes = ($slide.Shapes | ForEach-Object { "$($_.Name):$($_.Type)" }) -join ", "
        }

        $data = @{
            current = $current
            total = $total
            notes = $notes.Trim()
            hasMedia = $hasMedia
            isMediaPlaying = $isMediaPlaying
            shapeTypes = $shapeTypes
            isBlackScreen = $isBlackScreen
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
        return {'error': 'POWERPOINT_NOT_RUNNING'};
      }
      if (output.isNotEmpty && output.startsWith('{')) {
        return jsonDecode(output) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Exception in getSlideState: $e');
      InputSimulator.onCommandError?.call('Slayt durumu alınamadı: $e');
    }
    return null;
  }
}
