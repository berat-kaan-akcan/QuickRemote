// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() async {
  var p = await Process.start('powershell', ['-NoProfile', '-NonInteractive', '-Command', '-']);
  p.stdout.transform(systemEncoding.decoder).transform(const LineSplitter()).listen(print);
  p.stderr.transform(systemEncoding.decoder).transform(const LineSplitter()).listen((e) => print('ERR: $e'));
  
  final script = '''
try {
    \$ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if (\$ppt -ne \$null -and \$ppt.SlideShowWindows.Count -gt 0) {
        \$ppt.SlideShowWindows.Item(1).View.PointerColor.RGB = 255
    } else {
        Write-Output "ERROR: Slayt gösterisi aktif değil."
    }
} catch {
    Write-Output "ERROR: \$(\$_.Exception.Message)"
}
''';

  p.stdin.writeln(script);
  p.stdin.writeln('Write-Output "___PS_DONE___"');
  
  await Future.delayed(Duration(seconds:2));
  p.kill();
}
