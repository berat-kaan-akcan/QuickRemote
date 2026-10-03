/// The presentation programs reached over COM: PowerPoint and WPS
/// Presentation, which implements the same object model.
class PresenterCom {
  PresenterCom._();

  /// PowerShell that sets `$ppt` to the running program's COM Application
  /// (`$null` when neither runs), preferring one with a running slideshow,
  /// and `$qrPresenter` to 'powerpoint' or 'wps'. WPS registers as
  /// KWPP.Application, or as PowerPoint.Application when it is set up to
  /// stand in for Microsoft Office. Its Name is "Microsoft PowerPoint" too
  /// (Version 12.0, WPS 12.2), so its install Path tells it apart.
  static const lookup = r'''
$ppt = $null
$qrPresenter = $null
$qrPptShow = $false
foreach ($qrId in @('PowerPoint.Application', 'KWPP.Application')) {
    $qrApp = $null
    try { $qrApp = [System.Runtime.InteropServices.Marshal]::GetActiveObject($qrId) } catch {}
    if ($qrApp -eq $null) { continue }
    $qrShow = $false
    try { $qrShow = $qrApp.SlideShowWindows.Count -gt 0 } catch {}
    if ($ppt -eq $null -or ($qrShow -and -not $qrPptShow)) {
        $qrPath = ''
        try { $qrPath = "$($qrApp.Path)" } catch {}
        $ppt = $qrApp
        $qrPptShow = $qrShow
        if ($qrId -eq 'KWPP.Application' -or $qrPath -match 'Kingsoft|WPS Office') {
            $qrPresenter = 'wps'
        } else {
            $qrPresenter = 'powerpoint'
        }
    }
}
''';

  /// The program running the slideshow at the last state poll ('powerpoint',
  /// 'wps'), or null when no show was running.
  static String? active;

  static bool get wpsActive => active == 'wps';

}
