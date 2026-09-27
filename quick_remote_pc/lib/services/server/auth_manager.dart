import 'dart:math';

class AuthManager {
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _blockedIPs = {};
  static const int _maxFailedAttempts = 5;
  static const Duration _blockDuration = Duration(seconds: 60);

  String generatePin() {
    final rng = Random.secure();
    return (1000 + rng.nextInt(9000)).toString();
  }

  bool isIPBlocked(String ip) {
    final blockedUntil = _blockedIPs[ip];
    if (blockedUntil == null) return false;
    if (DateTime.now().isAfter(blockedUntil)) {
      _blockedIPs.remove(ip);
      _failedAttempts.remove(ip);
      return false;
    }
    return true;
  }

  void recordFailedAttempt(String ip) {
    _failedAttempts[ip] = (_failedAttempts[ip] ?? 0) + 1;
    if (_failedAttempts[ip]! >= _maxFailedAttempts) {
      _blockedIPs[ip] = DateTime.now().add(_blockDuration);
    }
  }

  void recordSuccessfulAuth(String ip) {
    _failedAttempts.remove(ip);
    _blockedIPs.remove(ip);
  }

  int getFailedAttempts(String ip) {
    return _failedAttempts[ip] ?? 0;
  }

  void reset() {
    _failedAttempts.clear();
    _blockedIPs.clear();
  }
}
