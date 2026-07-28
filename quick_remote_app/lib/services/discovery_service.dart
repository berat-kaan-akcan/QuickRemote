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
    
    _isDiscovering = true;
    _devices.clear();
    notifyListeners();

    try {
      _discovery = await nsd.startDiscovery('_quickremote._tcp', ipLookupType: nsd.IpLookupType.v4);
      _discovery!.addListener(() {
        _updateDevices();
      });
      // Ilk cihazlar için
      _updateDevices();
    } catch (e) {
      if (kDebugMode) {
        print("mDNS Discovery error: $e");
      }
      _isDiscovering = false;
      notifyListeners();
    }
  }

  void _updateDevices() {
    if (_discovery == null) return;
    _devices.clear();
    for (var service in _discovery!.services) {
      // Sadece IP adresi ve portu olan geçerli servisleri al
      if (service.host != null && service.port != null) {
        _devices.add(DiscoveredDevice(
          name: service.name ?? 'Bilinmeyen PC',
          ip: service.host!,
          port: service.port!,
        ));
      }
    }
    notifyListeners();
  }

  Future<void> stopScanning() async {
    if (!_isDiscovering || _discovery == null) return;
    
    _isDiscovering = false;
    await nsd.stopDiscovery(_discovery!);
    _discovery = null;
    notifyListeners();
  }
}
