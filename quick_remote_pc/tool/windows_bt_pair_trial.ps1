# QuickRemote: Windows'ta telefonu programla yeniden eşleştirme denemesi.
#
# docs/raporlar/WINDOWS_BT_ONARIM.md, (a2) yolu. Soru: telefonu Windows'tan
# kaldırdıktan sonra "Cihaz ekle" penceresi olmadan, programla eşleştirmek
# telefonu klavye yapar mı? İki değişken denenir:
#
#   Win32  BluetoothRegisterForAuthenticationEx + BluetoothAuthenticateDeviceEx
#          (geri çağrıda BluetoothSendAuthenticationResponseEx), ardından
#          BluetoothSetServiceState(HID, ENABLE)
#   WinRT  BluetoothDevice.FromBluetoothAddressAsync +
#          DeviceInformation.Pairing.Custom.PairAsync
#
# Linux'ta yazıldı, Windows'ta hiç çalıştırılmadı: derleme hatası da bir
# sonuçtur, çıktı dosyasını olduğu gibi saklayın.
#
# Çalıştırma (betiğin klasöründe, normal PowerShell; yönetici DEĞİL):
#   powershell -ExecutionPolicy Bypass -File .\windows_bt_pair_trial.ps1 -Mode List
#   ... -Mode Status -Address AA:BB:CC:DD:EE:FF    yalnızca durumu okur
#   ... -Mode Remove -Address AA:BB:CC:DD:EE:FF    yalnızca kaldırır
#   ... -Mode Win32  -Address AA:BB:CC:DD:EE:FF    kaldırır, Win32 ile eşleştirir
#   ... -Mode WinRT  -Address AA:BB:CC:DD:EE:FF    kaldırır, WinRT ile eşleştirir
#   ... -NoRemove         eşleştirmeden önce kaldırmaz (zaten kaldırılmışsa)
#   ... -NoHidEnable      Win32'den sonra HID hizmetini kendisi açmaz
#   ... -AuthRequirement 3    BLUETOOTH_AUTHENTICATION_REQUIREMENTS (0-5)
#
# Eşleştirme sırasında PC tarafındaki onayı betik KENDİSİ verir ve kodu
# ekrana yazar; telefondaki kodla aynı olduğuna bakıp telefonda onaylayın.
# (Uygulamada kod pencerede gösterilip kullanıcıya sorulacak; bu yalnızca deneme.)
#
# Her şey %TEMP%\quickremote-bt-eslestirme-<tarih>.txt dosyasına da yazılır.
# Windows PowerShell 5.1 ile çalışır.

param(
  [ValidateSet('List', 'Status', 'Remove', 'Win32', 'WinRT')]
  [string]$Mode = 'List',
  [string]$Address,
  [switch]$NoRemove,
  [switch]$NoHidEnable,
  [ValidateRange(0, 5)]
  [int]$AuthRequirement = 3
)

$ErrorActionPreference = 'Stop'

$log = Join-Path ([System.IO.Path]::GetTempPath()) ("quickremote-bt-eslestirme-{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
Start-Transcript -Path $log | Out-Null

Add-Type -IgnoreWarnings -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class QrPair
{
    public static readonly Guid Hid = new Guid("00001124-0000-1000-8000-00805F9B34FB");
    public const uint ERROR_MORE_DATA = 234;

    // Lines written by the authentication callback (another thread); the
    // script prints them again so that they reach the transcript.
    public static readonly List<string> Events = new List<string>();

    static void Note(string text)
    {
        string line = DateTime.Now.ToString("HH:mm:ss.fff") + "  " + text;
        lock (Events) Events.Add(line);
        Console.WriteLine("  " + line);
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct SYSTEMTIME
    {
        public ushort Year, Month, DayOfWeek, Day, Hour, Minute, Second, Milliseconds;
    }

    // BLUETOOTH_DEVICE_INFO: 560 bytes.
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DeviceInfo
    {
        public uint dwSize;
        public ulong Address;
        public uint ClassOfDevice;
        public bool Connected;
        public bool Remembered;
        public bool Authenticated;
        public SYSTEMTIME LastSeen;
        public SYSTEMTIME LastUsed;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 248)]
        public string Name;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct SearchParams
    {
        public uint dwSize;
        public bool fReturnAuthenticated;
        public bool fReturnRemembered;
        public bool fReturnUnknown;
        public bool fReturnConnected;
        public bool fIssueInquiry;
        public byte cTimeoutMultiplier;
        public IntPtr hRadio;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct FindRadioParams
    {
        public uint dwSize;
    }

    // PFN_AUTHENTICATION_CALLBACK_EX
    delegate bool AuthCallback(IntPtr param, IntPtr callbackParams);

    [DllImport("BluetoothApis.dll", SetLastError = true)]
    static extern IntPtr BluetoothFindFirstRadio(ref FindRadioParams p, out IntPtr hRadio);
    [DllImport("BluetoothApis.dll", SetLastError = true)]
    static extern bool BluetoothFindRadioClose(IntPtr hFind);
    [DllImport("BluetoothApis.dll", SetLastError = true)]
    static extern IntPtr BluetoothFindFirstDevice(ref SearchParams p, ref DeviceInfo info);
    [DllImport("BluetoothApis.dll", SetLastError = true)]
    static extern bool BluetoothFindNextDevice(IntPtr hFind, ref DeviceInfo info);
    [DllImport("BluetoothApis.dll", SetLastError = true)]
    static extern bool BluetoothFindDeviceClose(IntPtr hFind);
    [DllImport("BluetoothApis.dll")]
    static extern uint BluetoothGetDeviceInfo(IntPtr hRadio, ref DeviceInfo info);
    [DllImport("BluetoothApis.dll")]
    static extern uint BluetoothRemoveDevice(ref ulong address);
    [DllImport("BluetoothApis.dll")]
    static extern uint BluetoothSetServiceState(IntPtr hRadio, ref DeviceInfo info, ref Guid service, uint flags);
    [DllImport("BluetoothApis.dll")]
    static extern uint BluetoothEnumerateInstalledServices(IntPtr hRadio, ref DeviceInfo info, ref uint count, [Out] Guid[] services);
    [DllImport("BluetoothApis.dll")]
    static extern uint BluetoothRegisterForAuthenticationEx(ref DeviceInfo info, out IntPtr registration, AuthCallback callback, IntPtr param);
    [DllImport("BluetoothApis.dll")]
    static extern bool BluetoothUnregisterAuthentication(IntPtr registration);
    [DllImport("BluetoothApis.dll")]
    static extern uint BluetoothAuthenticateDeviceEx(IntPtr hwndParent, IntPtr hRadio, ref DeviceInfo info, IntPtr oobData, int authenticationRequirement);
    [DllImport("BluetoothApis.dll")]
    static extern uint BluetoothSendAuthenticationResponseEx(IntPtr hRadio, IntPtr response);
    [DllImport("kernel32.dll")]
    static extern bool CloseHandle(IntPtr h);

    public static string Format(ulong a)
    {
        byte[] b = BitConverter.GetBytes(a);
        return string.Format("{0:X2}:{1:X2}:{2:X2}:{3:X2}:{4:X2}:{5:X2}", b[5], b[4], b[3], b[2], b[1], b[0]);
    }

    public static ulong Parse(string s)
    {
        string hex = s.Replace(":", "").Replace("-", "").Replace(" ", "");
        if (hex.Length != 12) throw new ArgumentException("Bluetooth adresi 12 onaltılık rakam olmalı: " + s);
        return Convert.ToUInt64(hex, 16);
    }

    public static IntPtr Radio()
    {
        FindRadioParams p = new FindRadioParams();
        p.dwSize = (uint)Marshal.SizeOf(typeof(FindRadioParams));
        IntPtr radio;
        IntPtr find = BluetoothFindFirstRadio(ref p, out radio);
        if (find == IntPtr.Zero) return IntPtr.Zero;
        BluetoothFindRadioClose(find);
        return radio;
    }

    static DeviceInfo NewInfo(ulong address)
    {
        DeviceInfo info = new DeviceInfo();
        info.dwSize = (uint)Marshal.SizeOf(typeof(DeviceInfo));
        info.Address = address;
        return info;
    }

    public static int InfoSize()
    {
        return Marshal.SizeOf(typeof(DeviceInfo));
    }

    public static List<DeviceInfo> Paired()
    {
        List<DeviceInfo> list = new List<DeviceInfo>();
        SearchParams p = new SearchParams();
        p.dwSize = (uint)Marshal.SizeOf(typeof(SearchParams));
        p.fReturnAuthenticated = true;
        p.fReturnRemembered = true;
        p.fReturnConnected = true;
        DeviceInfo info = NewInfo(0);
        IntPtr find = BluetoothFindFirstDevice(ref p, ref info);
        if (find == IntPtr.Zero) return list;
        do
        {
            list.Add(info);
            info = NewInfo(0);
        } while (BluetoothFindNextDevice(find, ref info));
        BluetoothFindDeviceClose(find);
        return list;
    }

    public static uint Info(IntPtr radio, ulong address, out DeviceInfo info)
    {
        info = NewInfo(address);
        return BluetoothGetDeviceInfo(radio, ref info);
    }

    public static uint Remove(ulong address)
    {
        return BluetoothRemoveDevice(ref address);
    }

    public static uint EnableHid(IntPtr radio, ulong address)
    {
        DeviceInfo info;
        uint err = Info(radio, address, out info);
        if (err != 0) return err;
        Guid hid = Hid;
        return BluetoothSetServiceState(radio, ref info, ref hid, 1);
    }

    public static Guid[] Installed(IntPtr radio, ulong address, out uint err)
    {
        DeviceInfo info;
        err = Info(radio, address, out info);
        if (err != 0) return new Guid[0];
        uint count = 0;
        err = BluetoothEnumerateInstalledServices(radio, ref info, ref count, null);
        if (err != 0 && err != ERROR_MORE_DATA) return new Guid[0];
        Guid[] services = new Guid[count];
        if (count == 0) { err = 0; return services; }
        err = BluetoothEnumerateInstalledServices(radio, ref info, ref count, services);
        return services;
    }

    static IntPtr authRadio;
    static AuthCallback keepAlive;

    // BLUETOOTH_AUTHENTICATION_CALLBACK_PARAMS: deviceInfo (560 bytes), then
    // authenticationMethod, ioCapability, authenticationRequirements (int
    // each) and the Numeric_Value/Passkey union at 572.
    static bool OnAuthentication(IntPtr param, IntPtr p)
    {
        try
        {
            long address = Marshal.ReadInt64(p, 8);
            int method = Marshal.ReadInt32(p, 560);
            int ioCapability = Marshal.ReadInt32(p, 564);
            int requirements = Marshal.ReadInt32(p, 568);
            int value = Marshal.ReadInt32(p, 572);
            string[] names = { "?", "LEGACY (PIN)", "OOB", "NUMERIC_COMPARISON", "PASSKEY_NOTIFICATION", "PASSKEY" };
            string name = method >= 0 && method < names.Length ? names[method] : method.ToString();
            Note(string.Format("geri çağrı: yöntem {0}, ioCapability {1}, requirements {2}, KOD {3:D6}", name, ioCapability, requirements, value));
            if (method != 3 && method != 4)
            {
                Note("bu yöntem denemede yanıtlanmıyor (yalnızca sayı karşılaştırması)");
                return true;
            }
            if (method == 4) return true; // the code is only shown

            // BLUETOOTH_AUTHENTICATE_RESPONSE, 48 bytes: address (8),
            // authMethod (4), the union (32, numeric value first),
            // negativeResponse (1).
            IntPtr response = Marshal.AllocHGlobal(48);
            try
            {
                for (int i = 0; i < 48; i++) Marshal.WriteByte(response, i, 0);
                Marshal.WriteInt64(response, 0, address);
                Marshal.WriteInt32(response, 8, method);
                Marshal.WriteInt32(response, 12, value);
                Marshal.WriteByte(response, 44, 0);
                uint err = BluetoothSendAuthenticationResponseEx(authRadio, response);
                Note("BluetoothSendAuthenticationResponseEx (onay): " + err);
            }
            finally
            {
                Marshal.FreeHGlobal(response);
            }
        }
        catch (Exception e)
        {
            Note("geri çağrıda hata: " + e);
        }
        return true;
    }

    // Registers the callback, pairs, unregisters. Returns the result of
    // BluetoothAuthenticateDeviceEx; registerError is set when registering
    // failed (the pairing is then tried without a callback).
    public static uint PairWin32(IntPtr radio, ulong address, int requirement, out uint registerError, out long milliseconds)
    {
        authRadio = radio;
        keepAlive = OnAuthentication;
        DeviceInfo info = NewInfo(address);
        IntPtr registration;
        registerError = BluetoothRegisterForAuthenticationEx(ref info, out registration, keepAlive, IntPtr.Zero);
        Note("BluetoothRegisterForAuthenticationEx: " + registerError);
        System.Diagnostics.Stopwatch watch = System.Diagnostics.Stopwatch.StartNew();
        uint result;
        try
        {
            result = BluetoothAuthenticateDeviceEx(IntPtr.Zero, radio, ref info, IntPtr.Zero, requirement);
        }
        finally
        {
            watch.Stop();
            if (registerError == 0) BluetoothUnregisterAuthentication(registration);
        }
        milliseconds = watch.ElapsedMilliseconds;
        Note("BluetoothAuthenticateDeviceEx: " + result + " (" + milliseconds + " ms)");
        return result;
    }

    public static void Close(IntPtr h)
    {
        if (h != IntPtr.Zero) CloseHandle(h);
    }
}
'@

# The WinRT part is compiled only for -Mode WinRT: a compile error there (the
# references differ between Windows builds) must not stop the Win32 trial.
$winRtSource = @'
using System;
using System.Collections.Generic;
using Windows.Devices.Bluetooth;
using Windows.Devices.Enumeration;
using Windows.Foundation;

public static class QrWinRtPair
{
    public static readonly List<string> Events = new List<string>();

    static void Note(string text)
    {
        string line = DateTime.Now.ToString("HH:mm:ss.fff") + "  " + text;
        lock (Events) Events.Add(line);
        Console.WriteLine("  " + line);
    }

    static T Wait<T>(IAsyncOperation<T> operation)
    {
        return System.WindowsRuntimeSystemExtensions.AsTask(operation).GetAwaiter().GetResult();
    }

    public static string Pair(ulong address)
    {
        BluetoothDevice device = Wait(BluetoothDevice.FromBluetoothAddressAsync(address));
        if (device == null) return "cihaz bulunamadı (FromBluetoothAddressAsync null döndü)";
        DeviceInformation information = device.DeviceInformation;
        Note("cihaz: " + information.Name + ", eşleşmiş: " + information.Pairing.IsPaired + ", eşleşebilir: " + information.Pairing.CanPair);
        DeviceInformationCustomPairing custom = information.Pairing.Custom;
        custom.PairingRequested += (sender, args) =>
        {
            Note("PairingRequested: tür " + args.PairingKind + ", KOD " + args.Pin);
            args.Accept();
            Note("Accept() çağrıldı");
        };
        System.Diagnostics.Stopwatch watch = System.Diagnostics.Stopwatch.StartNew();
        DevicePairingResult result = Wait(custom.PairAsync(
            DevicePairingKinds.ConfirmOnly | DevicePairingKinds.ConfirmPinMatch | DevicePairingKinds.DisplayPin));
        watch.Stop();
        return "durum " + result.Status + ", koruma " + result.ProtectionLevelUsed + " (" + watch.ElapsedMilliseconds + " ms)";
    }
}
'@

function Write-Step([string]$text) {
  Write-Host ''
  Write-Host "== $text" -ForegroundColor Cyan
}

function Get-ErrorText([long]$code) {
  switch ($code) {
    0 { 'tamam' }
    5 { 'ERROR_ACCESS_DENIED (5): yönetici izni gerekiyor. Bunu not edin; sonra yönetici PowerShell''inde yeniden deneyin.' }
    87 { 'ERROR_INVALID_PARAMETER (87)' }
    259 { 'ERROR_NO_MORE_ITEMS (259): Windows cihazı zaten eşleşmiş sayıyor.' }
    1168 { 'ERROR_NOT_FOUND (1168): Windows bu adreste hatırlanan bir cihaz bulamadı.' }
    1167 { 'ERROR_DEVICE_NOT_CONNECTED (1167): cihaz bağlı değil ya da menzilde değil.' }
    1223 { 'ERROR_CANCELLED (1223): kullanıcı vazgeçti.' }
    1244 { 'ERROR_NOT_AUTHENTICATED (1244): eşleştirme başarısız (onay verilmedi, süre doldu ya da telefon kesti).' }
    1460 { 'ERROR_TIMEOUT (1460): telefon zamanında yanıt vermedi.' }
    default {
      $msg = (New-Object System.ComponentModel.Win32Exception([int]$code)).Message
      "hata $code ($msg)"
    }
  }
}

function Stop-Trial([int]$code) {
  Write-Host ''
  Write-Host "  Bu çıktının tamamı şu dosyada: $log"
  Stop-Transcript | Out-Null
  exit $code
}

function Show-Device([IntPtr]$radio, [UInt64]$addr) {
  $info = New-Object QrPair+DeviceInfo
  $err = [QrPair]::Info($radio, $addr, [ref]$info)
  if ($err -ne 0) {
    Write-Host "  Windows'un kaydı: yok ($(Get-ErrorText $err))"
    return $false
  }
  Write-Host "  Windows'un kaydı: $($info.Name), eşleşmiş: $($info.Authenticated), hatırlanan: $($info.Remembered), bağlı: $($info.Connected)"
  return ($info.Authenticated -or $info.Remembered)
}

function Show-Services([IntPtr]$radio, [UInt64]$addr) {
  $err = [uint32]0
  $services = [QrPair]::Installed($radio, $addr, [ref]$err)
  if ($err -ne 0) {
    Write-Host "  Kurulu hizmetler okunamadı: $(Get-ErrorText $err)"
    return $false
  }
  $hasHid = $false
  foreach ($g in $services) {
    $mark = ''
    if ($g -eq [QrPair]::Hid) { $mark = '   <-- HID (klavye/fare)'; $hasHid = $true }
    Write-Host "  $g$mark"
  }
  Write-Host "  HID hizmeti kurulu mu: $(if ($hasHid) { 'EVET' } else { 'HAYIR' })"
  return $hasHid
}

function Show-PnpHid([UInt64]$addr) {
  $hex = ('{0:X12}' -f $addr)
  try {
    $found = @(Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like "*$hex*" })
  } catch {
    Write-Host "  Aygıt Yöneticisi listesi okunamadı: $($_.Exception.Message)"
    return
  }
  if ($found.Count -eq 0) { Write-Host "  Bu adres için Aygıt Yöneticisi'nde kayıt yok."; return }
  foreach ($d in $found) {
    $hid = if ($d.InstanceId -like '*00001124-0000-1000-8000-00805F9B34FB*') { '   <-- HID' } else { '' }
    Write-Host ("  [{0}] {1} ({2}){3}" -f $d.Status, $d.FriendlyName, $d.Class, $hid)
    Write-Host ("      {0}" -f $d.InstanceId)
  }
}

function Show-State([string]$title, [IntPtr]$radio, [UInt64]$addr) {
  Write-Step "$($title): Windows'un kaydı ve hizmetler"
  $known = Show-Device $radio $addr
  $hid = $false
  if ($known) { $hid = Show-Services $radio $addr }
  Write-Step "$($title): Aygıt Yöneticisi"
  Show-PnpHid $addr
  return $hid
}

# --- Ortam ---------------------------------------------------------------

Write-Step 'Ortam'
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "  Windows: $($os.Caption) $($os.Version) (derleme $($os.BuildNumber))"
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "  Yönetici olarak mı çalışıyor: $(if ($admin) { 'EVET' } else { 'HAYIR' })"
Write-Host "  PowerShell: $($PSVersionTable.PSVersion), 64 bit: $([Environment]::Is64BitProcess)"
Write-Host "  Kip: $Mode, AuthRequirement: $AuthRequirement, NoRemove: $NoRemove, NoHidEnable: $NoHidEnable"
Write-Host "  BLUETOOTH_DEVICE_INFO boyutu: $([QrPair]::InfoSize()) (560 olmalı)"
if (-not [Environment]::Is64BitProcess -or [QrPair]::InfoSize() -ne 560) {
  Write-Host '  Betik 64 bit PowerShell ve 560 baytlık yapı varsayıyor; geri çağrıdaki adresler yanlış olur. Durduruldu.' -ForegroundColor Red
  Stop-Trial 1
}

$radio = [QrPair]::Radio()
if ($radio -eq [IntPtr]::Zero) {
  Write-Host '  Bluetooth adaptörü bulunamadı ya da Bluetooth kapalı.' -ForegroundColor Red
  Stop-Trial 1
}

# --- Cihaz -----------------------------------------------------------------

Write-Step 'Eşleşmiş Bluetooth cihazları'
$devices = @([QrPair]::Paired())
if ($devices.Count -eq 0) { Write-Host '  Eşleşmiş cihaz yok.' }
for ($i = 0; $i -lt $devices.Count; $i++) {
  $d = $devices[$i]
  Write-Host ("  {0}) {1}  {2}  bağlı: {3}  eşleşmiş: {4}" -f ($i + 1), [QrPair]::Format($d.Address), $d.Name, $d.Connected, $d.Authenticated)
}
if ($Mode -eq 'List') { Stop-Trial 0 }

if ($Address) {
  $addr = [QrPair]::Parse($Address)
} else {
  if ($devices.Count -eq 0) {
    Write-Host '  Telefon listede yok (kaldırılmış olabilir): adresini -Address ile verin.' -ForegroundColor Red
    Stop-Trial 1
  }
  $choice = Read-Host 'Telefonun numarasını yazın (ör. 1) ve Enter''a basın'
  $index = 0
  if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $devices.Count) {
    Write-Host '  Geçersiz seçim.' -ForegroundColor Red
    Stop-Trial 1
  }
  $addr = $devices[$index - 1].Address
}
Write-Host "  Seçilen adres: $([QrPair]::Format($addr))  (sonraki çalıştırmalar için: -Address $([QrPair]::Format($addr)))"

$hidBefore = Show-State 'ÖNCE' $radio $addr
if ($Mode -eq 'Status') { Stop-Trial 0 }

# --- Kaldır ----------------------------------------------------------------

$removeResult = 'atlandı'
if (-not $NoRemove) {
  Write-Step 'KALDIR (BluetoothRemoveDevice)'
  $e = [QrPair]::Remove($addr)
  $removeResult = Get-ErrorText $e
  Write-Host "  Sonuç: $removeResult"
  Start-Sleep -Seconds 3
  [void](Show-State 'KALDIRDIKTAN SONRA' $radio $addr)
  if ($e -ne 0 -and $e -ne 1168) {
    Write-Host '  Kaldırılamadı; eşleştirme denenmiyor.' -ForegroundColor Red
    Stop-Trial 1
  }
}
if ($Mode -eq 'Remove') {
  Write-Host ''
  Write-Host '  Ayarlar > Bluetooth''ta telefonun listeden gittiğini gözle doğrulayın ve not edin.' -ForegroundColor Green
  Stop-Trial 0
}

# --- Eşleştir ----------------------------------------------------------------

Write-Host ''
Write-Host '  Şimdi telefonda QuickRemote > Bluetooth ekranını açın (açık kalsın, ekran kilitlenmesin).' -ForegroundColor Yellow
Write-Host '  Telefonu "görünür yap" DEMEYİN: adresle eşleştirmenin görünürlük istemediği de denenen şeylerden biri.' -ForegroundColor Yellow
[void](Read-Host '  Hazır olunca Enter''a basın')

$pairResult = ''
if ($Mode -eq 'Win32') {
  Write-Step "Win32: geri çağrı kaydet + BluetoothAuthenticateDeviceEx (requirement $AuthRequirement)"
  Write-Host '  Telefonda eşleştirme isteği çıkınca aşağıda yazan KOD ile karşılaştırıp telefonda onaylayın.'
  $registerError = [uint32]0
  $ms = [long]0
  $e = [QrPair]::PairWin32($radio, $addr, $AuthRequirement, [ref]$registerError, [ref]$ms)
  $pairResult = "kayıt: $(Get-ErrorText $registerError); eşleştirme: $(Get-ErrorText $e); $ms ms"
  Write-Host "  Sonuç: $pairResult"
  Write-Host '  Geri çağrı satırları:'
  foreach ($line in [QrPair]::Events) { Write-Host "    $line" }
  Start-Sleep -Seconds 5
  $hidAfterPair = Show-State 'EŞLEŞTİRDİKTEN SONRA (HID açılmadan)' $radio $addr
  if ($e -eq 0 -and -not $hidAfterPair -and -not $NoHidEnable) {
    Write-Step 'HID hizmetini AÇ (BluetoothSetServiceState ENABLE)'
    $e2 = [QrPair]::EnableHid($radio, $addr)
    Write-Host "  Sonuç: $(Get-ErrorText $e2)"
    $pairResult += "; HID ENABLE: $(Get-ErrorText $e2)"
  }
} else {
  Write-Step 'WinRT: derleme'
  $compiled = $false
  try {
    $runtime = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
    $refs = @(
      (Join-Path $runtime 'System.Runtime.dll'),
      (Join-Path $runtime 'System.Runtime.WindowsRuntime.dll'),
      (Join-Path $runtime 'System.Runtime.InteropServices.WindowsRuntime.dll'),
      (Join-Path $runtime 'System.Threading.Tasks.dll')
    )
    $metadata = Join-Path $env:windir 'System32\WinMetadata'
    foreach ($name in 'Windows.Foundation.winmd', 'Windows.Devices.winmd', 'Windows.Storage.winmd', 'Windows.Networking.winmd') {
      $path = Join-Path $metadata $name
      if (Test-Path $path) { $refs += $path } else { Write-Host "  yok: $path" }
    }
    foreach ($r in $refs) { Write-Host "  başvuru: $r" }
    Add-Type -IgnoreWarnings -TypeDefinition $winRtSource -ReferencedAssemblies $refs
    $compiled = $true
    Write-Host '  Derlendi.'
  } catch {
    Write-Host "  WinRT kodu derlenemedi: $($_.Exception.Message)" -ForegroundColor Red
    $_ | Format-List * -Force | Out-String | Write-Host
    $pairResult = 'WinRT kodu derlenemedi (hata yukarıda)'
  }
  if ($compiled) {
    Write-Step 'WinRT: FromBluetoothAddressAsync + Pairing.Custom.PairAsync'
    Write-Host '  Telefonda eşleştirme isteği çıkınca aşağıda yazan KOD ile karşılaştırıp telefonda onaylayın.'
    try {
      $pairResult = [QrWinRtPair]::Pair($addr)
    } catch {
      $pairResult = "istisna: $($_.Exception.GetBaseException().Message)"
      $_ | Format-List * -Force | Out-String | Write-Host
    }
    Write-Host "  Sonuç: $pairResult"
    Write-Host '  Olay satırları:'
    foreach ($line in [QrWinRtPair]::Events) { Write-Host "    $line" }
  }
}

Write-Host ''
Write-Host '  Windows''un sürücüleri kurması için 15 saniye bekleniyor...'
Start-Sleep -Seconds 15

$hidAfter = Show-State 'SONRA' $radio $addr

Write-Step 'Özet'
Write-Host "  Kip: $Mode, yönetici: $admin"
Write-Host "  Kaldırma: $removeResult"
Write-Host "  Eşleştirme: $pairResult"
Write-Host "  HID kurulu, önce: $hidBefore, sonra: $hidAfter"
Write-Host ''
Write-Host '  Şimdi elle bakılacaklar (docs/raporlar/WINDOWS_BT_ONARIM.md, deneme listesi):' -ForegroundColor Green
Write-Host '   - Telefonda kaç onay penceresi çıktı, Windows kendi bildirimini gösterdi mi?' -ForegroundColor Green
Write-Host '   - Telefonda QuickRemote''un Bluetooth kumandası açıldı mı, tuşlar slaytı değiştiriyor mu?' -ForegroundColor Green
Write-Host '   - Telefonun sesi (medya) bilgisayara yeniden bağlandı mı?' -ForegroundColor Green

[QrPair]::Close($radio)
Stop-Trial 0
