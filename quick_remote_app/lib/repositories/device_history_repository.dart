import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceHistoryRepository {
  static const String _key = 'recent_devices';

  /// Retrieves the list of recently connected devices from storage.
  Future<List<Map<String, dynamic>>> getRecentDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// Saves a new device or updates an existing one, keeping only the 5 most recent.
  Future<List<Map<String, dynamic>>> saveRecentDevice(String host, int port, String pin, String name) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> recentDevices = await getRecentDevices();

    final device = {'name': name, 'host': host, 'port': port, 'pin': pin};
    
    // Remove if already exists to push it to the top
    recentDevices.removeWhere((d) => d['host'] == host && d['port'] == port);
    recentDevices.insert(0, device);
    
    // Keep max 5 devices
    if (recentDevices.length > 5) {
      recentDevices.removeLast();
    }
    
    final strList = recentDevices.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_key, strList);
    
    return recentDevices;
  }

  /// Removes a device at the specified index.
  Future<List<Map<String, dynamic>>> removeRecentDevice(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> recentDevices = await getRecentDevices();
    
    if (index >= 0 && index < recentDevices.length) {
      recentDevices.removeAt(index);
      final strList = recentDevices.map((d) => jsonEncode(d)).toList();
      await prefs.setStringList(_key, strList);
    }
    
    return recentDevices;
  }
}
