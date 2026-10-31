import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../powershell_runner.dart';

class SmtcController {
  static String getSmtcStatePSScript() {
    return '''
try {
    \$managerType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media, ContentType=WindowsRuntime]
    \$asyncOp = \$managerType::RequestAsync()

    Add-Type -AssemblyName System.Runtime.WindowsRuntime

    \$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
        \$_.Name -eq 'AsTask' -and \$_.GetParameters().Count -eq 1 -and \$_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' 
    })[0]

    \$asTask = \$asTaskGeneric.MakeGenericMethod(\$managerType)
    \$netTask = \$asTask.Invoke(\$null, @(\$asyncOp))
    # The three waits stay under the runner's 5 s timeout (1.5 + 1 + 1 s);
    # a runner killed by the timeout has to start PowerShell again.
    if (-not \$netTask.Wait(1500)) { throw "Timeout" }
    \$manager = \$netTask.Result

    \$session = \$manager.GetCurrentSession()
    if (\$session -ne \$null) {
        \$propsAsync = \$session.TryGetMediaPropertiesAsync()
        
        \$propsType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties, Windows.Media, ContentType=WindowsRuntime]
        \$asTask2 = \$asTaskGeneric.MakeGenericMethod(\$propsType)
        \$netTask2 = \$asTask2.Invoke(\$null, @(\$propsAsync))
        if (-not \$netTask2.Wait(1000)) { throw "Timeout" }
        \$props = \$netTask2.Result
        
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

        \$posMs = 0
        \$durMs = 0
        \$isPlaying = \$false
        try {
            \$tl = \$session.GetTimelineProperties()
            \$posMs = [int64]\$tl.Position.TotalMilliseconds
            \$durMs = [int64]\$tl.EndTime.TotalMilliseconds
            \$lastUpdated = \$tl.LastUpdatedTime
            
            \$playbackInfo = \$session.GetPlaybackInfo()
            if (\$playbackInfo -ne \$null) {
                \$isPlaying = (\$playbackInfo.PlaybackStatus -eq [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionPlaybackStatus]::Playing)
            }

            if (\$isPlaying -and \$lastUpdated -ne \$null) {
                \$now = [System.DateTimeOffset]::UtcNow
                \$diff = \$now - \$lastUpdated
                \$posMs += [int64]\$diff.TotalMilliseconds
            }
        } catch {}
        
        # The polling PowerShell process persists: reuse the cover while the
        # same track plays instead of reading it on every poll, and read it
        # again every 10 s. A read that fails or comes back empty keeps the
        # track's last cover: an empty one made the phone drop it. Players
        # update the title before the cover, so right after a track change
        # the old track's cover is not taken for the new one's: it is shown
        # meanwhile and read again on the next poll, for up to 10 s.
        \$trackKey = "\$(\$props.Title)|\$(\$props.Artist)|\$(\$props.AlbumTitle)"
        \$thumbBase64 = ""
        \$sameTrack = \$global:qrThumbKey -eq \$trackKey
        if (\$sameTrack) { \$thumbBase64 = \$global:qrThumb }
        if (\$sameTrack -and ((Get-Date) - \$global:qrThumbAt).TotalSeconds -lt 10) {
            # cached
        } elseif (\$props.Thumbnail -ne \$null) {
            try {
                \$thumbAsync = \$props.Thumbnail.OpenReadAsync()
                \$asTaskStream = \$asTaskGeneric.MakeGenericMethod([Windows.Storage.Streams.IRandomAccessStreamWithContentType])
                \$netTaskStream = \$asTaskStream.Invoke(\$null, @(\$thumbAsync))
                if (-not \$netTaskStream.Wait(1000)) { throw "Timeout" }
                \$stream = \$netTaskStream.Result

                \$asStreamMethod = ([System.IO.WindowsRuntimeStreamExtensions].GetMethods() | Where-Object { \$_.Name -eq 'AsStreamForRead' -and \$_.GetParameters().Count -eq 1 })[0]
                \$dotNetStream = \$asStreamMethod.Invoke(\$null, @(\$stream))

                \$memoryStream = New-Object System.IO.MemoryStream
                \$dotNetStream.CopyTo(\$memoryStream)
                \$read = [Convert]::ToBase64String(\$memoryStream.ToArray())

                \$dotNetStream.Close()
                \$memoryStream.Close()
                if (\$read.Length -gt 0) {
                    \$thumbBase64 = \$read
                    if (-not \$sameTrack) {
                        \$global:qrPrevThumb = \$global:qrThumb
                        \$global:qrThumbKey = \$trackKey
                        \$global:qrThumbFirst = Get-Date
                    }
                    \$global:qrThumb = \$read
                    \$global:qrThumbAt = Get-Date
                    # Still the previous track's cover: read again next poll.
                    if (\$read -eq \$global:qrPrevThumb -and ((Get-Date) - \$global:qrThumbFirst).TotalSeconds -lt 10) {
                        \$global:qrThumbAt = [DateTime]::MinValue
                    }
                }
            } catch {}
        }
        
        \$data = @{
            hasMedia = \$true
            title = \$props.Title
            artist = \$props.Artist
            positionMs = \$posMs
            durationMs = \$durMs
            isPlaying = \$isPlaying
            thumbnail = \$thumbBase64
        }
        \$data | ConvertTo-Json -Compress
    } else {
        Write-Output '{"hasMedia": false}'
    }
} catch {
    \$msg = \$_.Exception.Message
    \$data = @{
        hasMedia = \$false
        error = \$msg
    }
    \$data | ConvertTo-Json -Compress
}
''';
  }

  static Future<Map<String, dynamic>?> getSmtcState() async {
    try {
      final output = (await PowerShellRunner.execute(getSmtcStatePSScript(), isPolling: true)).trim();
      if (output.startsWith('{')) {
        return jsonDecode(output) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting SMTC state: $e');
      return null;
    }
  }
}
