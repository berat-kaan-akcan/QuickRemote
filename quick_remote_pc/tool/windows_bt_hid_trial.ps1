# QuickRemote: Windows Bluetooth klavye (HID) onarım denemesi.
#
# docs/raporlar/ACIK_ISLER_RAPOR.md, 2. iş. Windows, telefonun SDP kayıtlarını eşleşirken bir
# kez okuyor; telefon QuickRemote'un klavye kaydı yokken eşleştiyse Windows onu
# klavye olarak kabul etmiyor. Bu betik şunu dener: telefonun HID hizmetini
# BluetoothSetServiceState ile kapatıp açmak Windows'a kaydı yeniden okutuyor mu?
#
# Adımlar ve sorular: WINDOWS-DENEME.md, "Bluetooth klavye onarımı (BtHidRepair)".
#
# Çalıştırma (betiğin klasöründe):
#   powershell -ExecutionPolicy Bypass -File .\windows_bt_hid_trial.ps1
#   powershell -ExecutionPolicy Bypass -File .\windows_bt_hid_trial.ps1 -Address AA:BB:CC:DD:EE:FF
#   ... -ListOnly       yalnızca eşleşmiş cihazları listeler
#   ... -NoToggle       yalnızca durumu okur (kapat/aç yapmaz)
#
# Her şey geçici klasöre (%TEMP%) quickremote-bt-deneme-<tarih>.txt olarak da yazılır;
# dosyanın yolu en sonda yazdırılır.
# Windows PowerShell 5.1 ile çalışır (Windows'ta hazır gelir).

param(
  [string]$Address,
  [switch]$ListOnly,
  [switch]$NoToggle
)

$ErrorActionPreference = 'Stop'

$log = Join-Path ([System.IO.Path]::GetTempPath()) ("quickremote-bt-deneme-{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
Start-Transcript -Path $log | Out-Null

# -IgnoreWarnings: otherwise compiler warnings (fields only the marshaller sets) fail Add-Type.
Add-Type -IgnoreWarnings -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class QrBt
{
    public static readonly Guid Hid = new Guid("00001124-0000-1000-8000-00805F9B34FB");
    public const uint ERROR_MORE_DATA = 234;

    [StructLayout(LayoutKind.Sequential)]
    public struct SYSTEMTIME
    {
        public ushort Year, Month, DayOfWeek, Day, Hour, Minute, Second, Milliseconds;
    }

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

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct WSAQUERYSET
    {
        public int dwSize;
        public IntPtr lpszServiceInstanceName;
        public IntPtr lpServiceClassId;
        public IntPtr lpVersion;
        public IntPtr lpszComment;
        public int dwNameSpace;
        public IntPtr lpNSProviderId;
        public IntPtr lpszContext;
        public int dwNumberOfProtocols;
        public IntPtr lpafpProtocols;
        public IntPtr lpszQueryString;
        public int dwNumberOfCsAddrs;
        public IntPtr lpcsaBuffer;
        public int dwOutputFlags;
        public IntPtr lpBlob;
    }

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
    static extern uint BluetoothSetServiceState(IntPtr hRadio, ref DeviceInfo info, ref Guid service, uint flags);
    [DllImport("BluetoothApis.dll")]
    static extern uint BluetoothEnumerateInstalledServices(IntPtr hRadio, ref DeviceInfo info, ref uint count, [Out] Guid[] services);
    [DllImport("kernel32.dll")]
    static extern bool CloseHandle(IntPtr h);

    [DllImport("ws2_32.dll")]
    static extern int WSAStartup(ushort version, byte[] data);
    [DllImport("ws2_32.dll")]
    static extern int WSAGetLastError();
    [DllImport("ws2_32.dll", CharSet = CharSet.Unicode)]
    static extern int WSALookupServiceBeginW(ref WSAQUERYSET q, int flags, out IntPtr h);
    [DllImport("ws2_32.dll", CharSet = CharSet.Unicode)]
    static extern int WSALookupServiceNextW(IntPtr h, int flags, ref int length, IntPtr results);
    [DllImport("ws2_32.dll")]
    static extern int WSALookupServiceEnd(IntPtr h);

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

    // The first local radio; IntPtr.Zero when there is none.
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

    static DeviceInfo NewInfo(ulong address)
    {
        DeviceInfo info = new DeviceInfo();
        info.dwSize = (uint)Marshal.SizeOf(typeof(DeviceInfo));
        info.Address = address;
        return info;
    }

    // Windows' record of the device (name, connected, ...); 0 when found.
    public static uint Info(IntPtr radio, ulong address, out DeviceInfo info)
    {
        info = NewInfo(address);
        return BluetoothGetDeviceInfo(radio, ref info);
    }

    public static uint SetHid(IntPtr radio, ulong address, bool enable)
    {
        DeviceInfo info;
        uint err = Info(radio, address, out info);
        if (err != 0) return err;
        Guid hid = Hid;
        return BluetoothSetServiceState(radio, ref info, ref hid, enable ? 1u : 0u);
    }

    // The services Windows has installed (enabled) for the device.
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

    // An SDP service search for the HID UUID on the device: with flush, a
    // fresh SDP query over the air; without it, Windows' cached records.
    // Returns the number of records found, or -1 with the Winsock error.
    public static int SdpHid(ulong address, bool flush, out int err, List<string> names)
    {
        err = 0;
        byte[] wsa = new byte[512];
        int r = WSAStartup(0x0202, wsa);
        if (r != 0) { err = r; return -1; }

        IntPtr guid = Marshal.AllocHGlobal(16);
        IntPtr context = Marshal.StringToHGlobalUni("(" + Format(address) + ")");
        IntPtr buffer = IntPtr.Zero;
        IntPtr h = IntPtr.Zero;
        try
        {
            Marshal.StructureToPtr(Hid, guid, false);
            WSAQUERYSET q = new WSAQUERYSET();
            q.dwSize = Marshal.SizeOf(typeof(WSAQUERYSET));
            q.lpServiceClassId = guid;
            q.dwNameSpace = 16; // NS_BTH
            q.lpszContext = context;
            const int LUP_RETURN_NAME = 0x0010, LUP_RETURN_BLOB = 0x0200, LUP_FLUSHCACHE = 0x1000;
            int flags = LUP_RETURN_NAME | LUP_RETURN_BLOB | (flush ? LUP_FLUSHCACHE : 0);
            if (WSALookupServiceBeginW(ref q, flags, out h) != 0)
            {
                err = WSAGetLastError();
                if (err == 10108) { err = 0; return 0; } // WSASERVICE_NOT_FOUND: no such record
                return -1;
            }
            int size = 8192;
            buffer = Marshal.AllocHGlobal(size);
            int found = 0;
            while (true)
            {
                int length = size;
                if (WSALookupServiceNextW(h, flags, ref length, buffer) != 0)
                {
                    int e = WSAGetLastError();
                    if (e == 10110 || e == 10102 || e == 10108) break; // no more
                    if (e == 10014 && length > size)                    // buffer too small
                    {
                        Marshal.FreeHGlobal(buffer);
                        size = length;
                        buffer = Marshal.AllocHGlobal(size);
                        continue;
                    }
                    err = e;
                    return found > 0 ? found : -1;
                }
                found++;
                WSAQUERYSET res = (WSAQUERYSET)Marshal.PtrToStructure(buffer, typeof(WSAQUERYSET));
                string name = res.lpszServiceInstanceName == IntPtr.Zero ? "" : Marshal.PtrToStringUni(res.lpszServiceInstanceName);
                names.Add(name);
            }
            return found;
        }
        finally
        {
            if (h != IntPtr.Zero) WSALookupServiceEnd(h);
            if (buffer != IntPtr.Zero) Marshal.FreeHGlobal(buffer);
            Marshal.FreeHGlobal(guid);
            Marshal.FreeHGlobal(context);
        }
    }

    public static void Close(IntPtr h)
    {
        if (h != IntPtr.Zero) CloseHandle(h);
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
    5 { 'ERROR_ACCESS_DENIED: yönetici izni gerekiyor. PowerShell''i "Yönetici olarak çalıştır" ile açıp yeniden deneyin.' }
    87 { 'ERROR_INVALID_PARAMETER: Windows bu cihaz ya da hizmet için isteği geçersiz saydı.' }
    1060 { 'ERROR_SERVICE_DOES_NOT_EXIST: Windows bu cihazda HID hizmeti bilmiyor (kayıtlarında yok).' }
    1168 { 'ERROR_NOT_FOUND: Windows bu adreste eşleşmiş bir cihaz bulamadı.' }
    1167 { 'ERROR_DEVICE_NOT_CONNECTED: cihaz bağlı değil ya da menzilde değil.' }
    1460 { 'ERROR_TIMEOUT: telefon zamanında yanıt vermedi.' }
    10060 { 'WSAETIMEDOUT: telefon SDP sorgusuna zamanında yanıt vermedi.' }
    10050 { 'WSAENETDOWN: Bluetooth kapalı ya da adaptör yok.' }
    10108 { 'WSASERVICE_NOT_FOUND: bu kayıt yok.' }
    default {
      $msg = (New-Object System.ComponentModel.Win32Exception([int]$code)).Message
      "hata $code ($msg)"
    }
  }
}

function Show-Services([IntPtr]$radio, [UInt64]$addr) {
  $err = [uint32]0
  $services = [QrBt]::Installed($radio, $addr, [ref]$err)
  if ($err -ne 0) {
    Write-Host "  Kurulu hizmetler okunamadı: $(Get-ErrorText $err)"
    return $false
  }
  if ($services.Count -eq 0) { Write-Host '  Kurulu hizmet yok.' }
  $hasHid = $false
  foreach ($g in $services) {
    $mark = ''
    if ($g -eq [QrBt]::Hid) { $mark = '   <-- HID (klavye/fare)'; $hasHid = $true }
    Write-Host "  $g$mark"
  }
  Write-Host "  HID hizmeti kurulu mu: $(if ($hasHid) { 'EVET' } else { 'HAYIR' })"
  return $hasHid
}

function Show-PnpHid([UInt64]$addr) {
  $hex = ('{0:X12}' -f $addr)
  try {
    $devices = @(Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like "*$hex*" })
  } catch {
    Write-Host "  Aygıt Yöneticisi listesi okunamadı: $($_.Exception.Message)"
    return
  }
  if ($devices.Count -eq 0) { Write-Host "  Bu adres için Aygıt Yöneticisi'nde kayıt yok."; return }
  foreach ($d in $devices) {
    $hid = if ($d.InstanceId -like '*00001124-0000-1000-8000-00805F9B34FB*') { '   <-- HID' } else { '' }
    Write-Host ("  [{0}] {1} ({2}){3}" -f $d.Status, $d.FriendlyName, $d.Class, $hid)
    Write-Host ("      {0}" -f $d.InstanceId)
  }
}

function Show-Sdp([UInt64]$addr, [bool]$flush) {
  $names = New-Object 'System.Collections.Generic.List[string]'
  $err = 0
  $n = [QrBt]::SdpHid($addr, $flush, [ref]$err, $names)
  $kind = if ($flush) { 'telefondan şimdi okunan (taze)' } else { 'Windows önbelleğindeki' }
  if ($n -lt 0) {
    Write-Host "  $kind SDP kaydı okunamadı: $(Get-ErrorText $err)"
  } else {
    Write-Host "  $kind HID kaydı sayısı: $n $(if ($names.Count) { '(' + ($names -join ', ') + ')' })"
  }
  return $n
}

# --- Ortam ---------------------------------------------------------------

Write-Step 'Ortam'
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "  Windows: $($os.Caption) $($os.Version) (derleme $($os.BuildNumber))"
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "  Yönetici olarak mı çalışıyor: $(if ($admin) { 'EVET' } else { 'HAYIR' })"
Write-Host "  PowerShell: $($PSVersionTable.PSVersion)"

$radio = [QrBt]::Radio()
if ($radio -eq [IntPtr]::Zero) {
  Write-Host '  Bluetooth adaptörü bulunamadı ya da Bluetooth kapalı. Ayarlar > Bluetooth''dan açıp yeniden deneyin.' -ForegroundColor Red
  Stop-Transcript | Out-Null
  exit 1
}
try {
  Get-PnpDevice -Class Bluetooth -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object { $_.FriendlyName -notlike '*Enumerator*' -and ($_.InstanceId -like 'USB*' -or $_.InstanceId -like 'PCI*') } |
    ForEach-Object { Write-Host "  Adaptör: $($_.FriendlyName)" }
} catch { }

# --- Eşleşmiş cihazlar ---------------------------------------------------

Write-Step 'Eşleşmiş Bluetooth cihazları'
$devices = @([QrBt]::Paired())
if ($devices.Count -eq 0) {
  Write-Host '  Eşleşmiş cihaz yok. Önce telefonu Ayarlar > Bluetooth''dan eşleştirin.' -ForegroundColor Red
  Stop-Transcript | Out-Null
  exit 1
}
for ($i = 0; $i -lt $devices.Count; $i++) {
  $d = $devices[$i]
  Write-Host ("  {0}) {1}  {2}  bağlı: {3}  eşleşmiş: {4}" -f ($i + 1), [QrBt]::Format($d.Address), $d.Name, $d.Connected, $d.Authenticated)
}
if ($ListOnly) { Stop-Transcript | Out-Null; exit 0 }

if ($Address) {
  $addr = [QrBt]::Parse($Address)
} else {
  $choice = Read-Host 'Telefonun numarasını yazın (ör. 1) ve Enter''a basın'
  $index = 0
  if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $devices.Count) {
    Write-Host '  Geçersiz seçim.' -ForegroundColor Red
    Stop-Transcript | Out-Null
    exit 1
  }
  $addr = $devices[$index - 1].Address
}
$info = New-Object QrBt+DeviceInfo
$err = [QrBt]::Info($radio, $addr, [ref]$info)
if ($err -ne 0) {
  Write-Host "  $([QrBt]::Format($addr)): $(Get-ErrorText $err)" -ForegroundColor Red
  Stop-Transcript | Out-Null
  exit 1
}
Write-Host "  Seçilen: $($info.Name) ($([QrBt]::Format($addr))), bağlı: $($info.Connected)"

# --- Önce ------------------------------------------------------------------

Write-Step 'ÖNCE: Windows''un bu cihaz için kurduğu hizmetler'
$hidBefore = Show-Services $radio $addr
Write-Step 'ÖNCE: Aygıt Yöneticisi''ndeki kayıtlar'
Show-PnpHid $addr
Write-Step 'ÖNCE: SDP kayıtları (telefonda QuickRemote Bluetooth ekranı AÇIK olmalı)'
$cachedBefore = Show-Sdp $addr $false
$freshBefore = Show-Sdp $addr $true

if ($NoToggle) { Stop-Transcript | Out-Null; exit 0 }

# --- Kapat / aç --------------------------------------------------------------

Write-Step 'HID hizmetini KAPAT (BluetoothSetServiceState DISABLE)'
$e = [QrBt]::SetHid($radio, $addr, $false)
Write-Host "  Sonuç: $(Get-ErrorText $e)"
Start-Sleep -Seconds 3

Write-Step 'HID hizmetini AÇ (BluetoothSetServiceState ENABLE)'
$e2 = [QrBt]::SetHid($radio, $addr, $true)
Write-Host "  Sonuç: $(Get-ErrorText $e2)"
if (($e -eq 5 -or $e2 -eq 5) -and -not $admin) {
  Write-Host '  Yönetici izni gerekiyor. Betiği yönetici PowerShell''inde yeniden çalıştırın; sonucu da not edin (yönetici izni gerekiyorsa uygulamada UAC onayı çıkacak).' -ForegroundColor Yellow
}
Write-Host '  Windows''un sürücüyü kurması için 10 saniye bekleniyor...'
Start-Sleep -Seconds 10

# --- Sonra -----------------------------------------------------------------

Write-Step 'SONRA: Windows''un bu cihaz için kurduğu hizmetler'
$hidAfter = Show-Services $radio $addr
Write-Step 'SONRA: Aygıt Yöneticisi''ndeki kayıtlar'
Show-PnpHid $addr
Write-Step 'SONRA: SDP kayıtları'
$cachedAfter = Show-Sdp $addr $false

Write-Step 'Özet'
Write-Host "  Yönetici: $admin"
Write-Host "  DISABLE: $(Get-ErrorText $e)"
Write-Host "  ENABLE:  $(Get-ErrorText $e2)"
Write-Host "  HID kurulu, önce: $hidBefore, sonra: $hidAfter"
Write-Host "  Önbellekteki HID kaydı, önce: $cachedBefore, sonra: $cachedAfter; telefondan taze okunan: $freshBefore"
Write-Host ''
Write-Host '  Şimdi telefonda QuickRemote''un Bluetooth kumandası bağlanıyor mu, tuşlar slaytı değiştiriyor mu? Sonucu WINDOWS-DENEME.md''deki tabloya yazın.' -ForegroundColor Green
Write-Host "  Bu çıktının tamamı şu dosyada: $log"

[QrBt]::Close($radio)
Stop-Transcript | Out-Null
