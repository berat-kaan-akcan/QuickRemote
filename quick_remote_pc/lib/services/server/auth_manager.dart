import 'dart:collection';
import 'dart:io';
import 'dart:math';

/// PIN generation and rate limiting for the pairing handshake.
///
/// Limits apply per remote IP and globally, and they are checked both when a
/// socket opens and for every PIN attempt, so sockets opened before an IP was
/// blocked cannot keep guessing.
class AuthManager {
  AuthManager({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  static const pinLength = 6;

  static const maxFailedAttemptsPerIp = 5;
  static const ipBlockDuration = Duration(seconds: 60);

  /// Unauthenticated sockets allowed at once, per IP and in total.
  static const maxPendingPerIp = 3;
  static const maxPendingTotal = 32;

  /// More than [maxGlobalFailures] wrong PINs within [globalFailureWindow],
  /// from any number of IPs, pauses all new pairing for [globalPauseDuration].
  /// Clients that are already authenticated are not affected.
  static const maxGlobalFailures = 20;
  static const globalFailureWindow = Duration(seconds: 60);
  static const globalPauseDuration = Duration(seconds: 60);

  final DateTime Function() _now;
  final Random _rng = Random.secure();

  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _blockedIPs = {};
  final Map<String, int> _pending = {};
  int _pendingTotal = 0;
  final Queue<DateTime> _recentFailures = Queue();
  DateTime? _globalPauseUntil;

  /// The key that rate limits are counted under for [address].
  ///
  /// The server listens dual-stack, so IPv4 clients arrive as `::ffff:a.b.c.d`;
  /// those count as the plain IPv4 address. An IPv6 host can pick any address
  /// in its /64 (privacy extensions), so all of a /64 shares one key.
  static String clientKey(InternetAddress? address) {
    if (address == null) return '';
    if (address.type != InternetAddressType.IPv6) return address.address;
    final raw = address.rawAddress;
    final v4Mapped = raw.take(10).every((b) => b == 0) && raw[10] == 0xff && raw[11] == 0xff;
    if (v4Mapped) return raw.sublist(12).join('.');
    final groups = [for (var i = 0; i < 8; i += 2) ((raw[i] << 8) | raw[i + 1]).toRadixString(16)];
    return '${groups.join(':')}::/64';
  }

  String generatePin() {
    const min = 100000; // 10^(pinLength - 1): no leading zeros
    return (min + _rng.nextInt(900000)).toString();
  }

  bool isIPBlocked(String ip) {
    final blockedUntil = _blockedIPs[ip];
    if (blockedUntil == null) return false;
    if (_now().isAfter(blockedUntil)) {
      _blockedIPs.remove(ip);
      _failedAttempts.remove(ip);
      return false;
    }
    return true;
  }

  bool get isGloballyPaused {
    final until = _globalPauseUntil;
    if (until == null) return false;
    if (_now().isAfter(until)) {
      _globalPauseUntil = null;
      return false;
    }
    return true;
  }

  /// Whether [ip] may submit a PIN now. Call for every attempt.
  bool canAttemptAuth(String ip) => !isIPBlocked(ip) && !isGloballyPaused;

  /// Reserves a slot for a new unauthenticated socket from [ip]. Returns false
  /// when the connection must be refused. Every successful reservation must be
  /// matched by one [releasePending] call.
  bool tryReservePending(String ip) {
    if (!canAttemptAuth(ip)) return false;
    if (_pendingTotal >= maxPendingTotal) return false;
    final current = _pending[ip] ?? 0;
    if (current >= maxPendingPerIp) return false;
    _pending[ip] = current + 1;
    _pendingTotal++;
    return true;
  }

  void releasePending(String ip) {
    final current = _pending[ip];
    if (current == null) return;
    if (current <= 1) {
      _pending.remove(ip);
    } else {
      _pending[ip] = current - 1;
    }
    _pendingTotal--;
  }

  int pendingCount(String ip) => _pending[ip] ?? 0;

  /// Compares in constant time so response timing does not leak how many
  /// leading digits were right.
  static bool verifyPin(String candidate, String pin) {
    if (pin.isEmpty) return false;
    final a = candidate.codeUnits;
    final b = pin.codeUnits;
    var diff = a.length ^ b.length;
    for (var i = 0; i < b.length; i++) {
      diff |= (i < a.length ? a[i] : 0) ^ b[i];
    }
    return diff == 0;
  }

  /// Records a wrong PIN from [ip]. Returns true when this failure started a
  /// global pause; the caller should then replace the PIN, since someone is
  /// guessing it.
  bool recordFailedAttempt(String ip) {
    final now = _now();
    final failures = (_failedAttempts[ip] ?? 0) + 1;
    _failedAttempts[ip] = failures;
    if (failures >= maxFailedAttemptsPerIp) {
      _blockedIPs[ip] = now.add(ipBlockDuration);
    }

    _recentFailures.addLast(now);
    while (_recentFailures.isNotEmpty &&
        now.difference(_recentFailures.first) > globalFailureWindow) {
      _recentFailures.removeFirst();
    }
    if (_recentFailures.length > maxGlobalFailures) {
      _globalPauseUntil = now.add(globalPauseDuration);
      _recentFailures.clear();
      return true;
    }
    return false;
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
    _pending.clear();
    _pendingTotal = 0;
    _recentFailures.clear();
    _globalPauseUntil = null;
  }
}
