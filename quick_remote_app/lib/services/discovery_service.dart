import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart' as nsd;

class DiscoveredDevice {
  final String name;
  final String ip;
  final int port;

  DiscoveredDevice({required this.name, required this.ip, required this.port});
}

class DiscoveryService extends ChangeNotifier {
  final List<DiscoveredDevice> _devices = [];
  List<DiscoveredDevice> get devices => _devices;
  
  bool _isDiscovering = false;
  bool get isDiscovering => _isDiscovering;

  nsd.Discovery? _discovery;

  Future<void> startScanning() async {
    if (_isDiscovering) return;

    // Önceki discovery nesnesi kalmışsa (hata vb. durumlardan) veya manuel yenileme yapılıyorsa, temizle.
    await stopScanning();

    _isDiscovering = true;
    _devices.clear();
    notifyListeners();

    try {
      _discovery = await nsd.startDiscovery('_quickremote._tcp', ipLookupType: nsd.IpLookupType.v4);
      _discovery!.addListener(_updateDevices);
      // İlk cihazlar için
      _updateDevices();

      // UI'daki dönen ikonun sürekli dönmemesi için 3 saniye sonra _isDiscovering'i false yapalım.
      // Arkaplanda mDNS dinlemeye devam eder, böylece yeni cihaz gelirse anında listeye düşer.
      Future.delayed(const Duration(seconds: 3), () {
        if (_discovery != null && _isDiscovering) {
          _isDiscovering = false;
          notifyListeners();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("mDNS Discovery error: $e");
      }
      _isDiscovering = false;
      _discovery = null;
      notifyListeners();
    }
  }

  void _updateDevices() {
    if (_discovery == null) return;
    
    // Aynı IP adresinden birden fazla kayıt gelirse (sunucu aç-kapa yapıldığında eski kayıtlar mDNS önbelleğinde kalabilir),
    // Sadece en güncel (listede en sonda olan) kaydı tutmak için bir Map kullanalım.
    final Map<String, DiscoveredDevice> uniqueDevices = {};

    for (var service in _discovery!.services) {
      // Sadece IP adresi ve portu olan geçerli servisleri al
      if (service.host != null && service.port != null) {
        uniqueDevices[service.host!] = DiscoveredDevice(
          name: service.name ?? 'Bilinmeyen PC',
          ip: service.host!,
          port: service.port!,
        );
      }
    }
    
    _devices.clear();
    _devices.addAll(uniqueDevices.values);
    
    notifyListeners();
  }

  Future<void> stopScanning() async {
    _isDiscovering = false;
    
    final currentDiscovery = _discovery;
    _discovery = null;

    if (currentDiscovery != null) {
      try {
        currentDiscovery.removeListener(_updateDevices);
        await nsd.stopDiscovery(currentDiscovery);
      } catch (e) {
        if (kDebugMode) {
          print("mDNS stop error: $e");
        }
      }
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    stopScanning();
    super.dispose();
  }
}
