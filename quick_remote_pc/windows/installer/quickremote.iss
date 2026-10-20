; Inno Setup 6 script for QuickRemote PC (Windows x64).
;
; Per-user install (no admin, no UAC prompt) into %LOCALAPPDATA%\Programs.
; The firewall rule stays the app's own question: writing it here would need
; admin rights.
;
; Built by .github/workflows/release.yml:
;   ISCC.exe /DAppVersion=0.2.0 /DAppVersionNumeric=0.2.0
;            /DBuildDir=<repo>\quick_remote_pc\build\windows\x64\runner\Release
;            /DVcRuntimeDir=<...>\Microsoft.VC143.CRT
;            /DOutputDir=<dir> quickremote.iss
; BuildDir is the `flutter build windows --release` output. VcRuntimeDir holds
; the Visual C++ runtime DLLs (msvcp140.dll, vcruntime140.dll,
; vcruntime140_1.dll, ...): Flutter apps need them and a fresh Windows does not
; always have them.

#ifndef AppVersion
  #define AppVersion "0.0.0-dev"
#endif
#ifndef AppVersionNumeric
  #define AppVersionNumeric "0.0.0"
#endif
#ifndef BuildDir
  #define BuildDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef VcRuntimeDir
  #error Pass /DVcRuntimeDir=<folder with msvcp140.dll and vcruntime140*.dll>
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build\installer"
#endif

#define AppName "QuickRemote PC"
#define AppExe "quick_remote_pc.exe"
; The same value name and flag as the app's own "start at sign-in" setting
; (lib/services/desktop/windows_autostart.dart, _valueName); keep them equal.
#define RunKey "Software\Microsoft\Windows\CurrentVersion\Run"
#define RunValue "QuickRemotePC"

[Setup]
; Never change AppId: it ties upgrades and the uninstaller to earlier installs.
AppId={{A61E6E29-BF7F-4C0D-8496-84C09F7DF229}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=QuickRemote
AppPublisherURL=https://github.com/berat-kaan-akcan/QuickRemote
AppSupportURL=https://github.com/berat-kaan-akcan/QuickRemote/issues
AppUpdatesURL=https://github.com/berat-kaan-akcan/QuickRemote/releases
VersionInfoVersion={#AppVersionNumeric}
VersionInfoProductVersion={#AppVersionNumeric}
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=
DefaultDirName={autopf}\QuickRemote PC
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=QuickRemote-PC-{#AppVersion}-windows-x64-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Closes a running QuickRemote PC (Restart Manager) before its files are replaced.
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
turkish.AutoStart=Oturum açılınca başlat (simge durumunda)
english.AutoStart=Start when I sign in (minimized)
turkish.Startup=Başlangıç:
english.Startup=Startup:

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "autostart"; Description: "{cm:AutoStart}"; GroupDescription: "{cm:Startup}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#VcRuntimeDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "{#RunKey}"; ValueType: string; ValueName: "{#RunValue}"; ValueData: """{app}\{#AppExe}"" --minimized"; Tasks: autostart

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: dirifempty; Name: "{app}"

[Code]
// The Run value goes on uninstall whoever wrote it (this installer's task or
// the app's own setting), since it would start a program that is gone.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RegDeleteValue(HKEY_CURRENT_USER, '{#RunKey}', '{#RunValue}');
end;
