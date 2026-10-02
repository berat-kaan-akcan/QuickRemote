import 'dart:io';

/// Absolute path of [name] from the system directories, like the Windows
/// side starts PowerShell from System32: a `python3` or `soffice` earlier in
/// PATH (~/.local/bin, a project venv) is not picked up. Falls back to the
/// bare name, resolved through PATH, when it is installed somewhere else.
String systemExecutable(String name, {List<String> extraDirs = const []}) {
  for (final dir in ['/usr/bin', '/usr/local/bin', '/bin', ...extraDirs]) {
    final path = '$dir/$name';
    if (File(path).existsSync()) return path;
  }
  return name;
}

/// `soffice` of distribution packages, then of LibreOffice's own installers
/// (/opt/libreofficeX.Y), which add no PATH entry.
String get sofficeExecutable {
  final opt = Directory('/opt');
  final optDirs = opt.existsSync()
      ? [
          for (final entry in opt.listSync())
            if (entry is Directory && entry.path.contains('libreoffice')) '${entry.path}/program',
        ]
      : <String>[];
  return systemExecutable('soffice', extraDirs: ['/usr/lib/libreoffice/program', ...optDirs]);
}
