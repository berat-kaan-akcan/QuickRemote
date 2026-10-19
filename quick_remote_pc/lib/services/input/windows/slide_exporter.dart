import 'package:flutter/foundation.dart';

import '../../powershell_runner.dart';
import '../input_service.dart';
import '../slide_files.dart';
import 'presenter_com.dart';

/// Exports slides of the running show as JPEGs with COM `Slide.Export`.
///
/// Runs in the polling PowerShell, never the command one, so NEXT and PREV
/// never wait for an export. The file goes through [SlideFiles].
///
/// PowerPoint only: WPS 12.2 has COM calls that silently do nothing
/// (`Player`), and its `Export` has not been checked on a real WPS yet.
class SlideExporter {
  SlideExporter._();

  static Future<SlideImage?> export(int index, int width) async {
    if (index < 1 || width < 1) return null;
    try {
      final file = await SlideFiles.path(index, width);
      final output = await PowerShellRunner.execute(script(index, width, file), isPolling: true);
      final height = parseHeight(output);
      if (height == null) {
        await SlideFiles.discard(file);
        return null;
      }
      return await SlideFiles.read(file, width, height);
    } catch (e) {
      debugPrint('Slide export failed: $e');
      return null;
    }
  }

  /// The pixel height the script printed (`EXPORTED:<height>`), or null.
  @visibleForTesting
  static int? parseHeight(String output) {
    final match = RegExp(
      r'^EXPORTED:(\d{1,5})$',
      multiLine: true,
    ).firstMatch(output);
    final height = match == null ? null : int.parse(match.group(1)!);
    return height == null || height < 1 ? null : height;
  }

  /// The PowerShell exporting slide [index] at [width] pixels to [file],
  /// with the height that keeps the slide's proportions.
  @visibleForTesting
  static String script(int index, int width, String file) {
    // A single-quoted PowerShell string takes everything literally but '.
    final path = "'${file.replaceAll("'", "''")}'";
    return '${PresenterCom.lookup}'
        '''
try {
    if (\$ppt -ne \$null -and \$qrPresenter -eq 'powerpoint' -and \$ppt.SlideShowWindows.Count -gt 0) {
        \$presentation = \$ppt.SlideShowWindows.Item(1).Presentation
        if ($index -le \$presentation.Slides.Count) {
            \$setup = \$presentation.PageSetup
            \$height = [int][Math]::Round($width * \$setup.SlideHeight / \$setup.SlideWidth)
            \$path = $path
            Remove-Item -LiteralPath \$path -ErrorAction SilentlyContinue
            \$presentation.Slides.Item($index).Export(\$path, 'JPG', $width, \$height)
            if (Test-Path -LiteralPath \$path) { Write-Output "EXPORTED:\$height" }
        }
    }
} catch {}
''';
  }
}
