import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/server/auth_manager.dart';

void main() {
  late DateTime now;
  late AuthManager auth;

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    auth = AuthManager(clock: () => now);
  });

  void failTimes(String ip, int times) {
    for (var i = 0; i < times; i++) {
      auth.recordFailedAttempt(ip);
    }
  }

  group('generatePin', () {
    test('produces six digits without a leading zero', () {
      for (var i = 0; i < 200; i++) {
        expect(auth.generatePin(), matches(RegExp(r'^[1-9]\d{5}$')));
      }
    });
  });

  group('verifyPin', () {
    test('accepts only the exact PIN', () {
      expect(AuthManager.verifyPin('482913', '482913'), isTrue);
      expect(AuthManager.verifyPin('482914', '482913'), isFalse);
      expect(AuthManager.verifyPin('48291', '482913'), isFalse);
      expect(AuthManager.verifyPin('4829130', '482913'), isFalse);
      expect(AuthManager.verifyPin('', '482913'), isFalse);
    });

    test('never matches when no PIN is set', () {
      expect(AuthManager.verifyPin('', ''), isFalse);
    });
  });

  group('per-IP blocking', () {
    test('blocks after the maximum failures and unblocks after the timeout', () {
      failTimes('10.0.0.5', AuthManager.maxFailedAttemptsPerIp - 1);
      expect(auth.canAttemptAuth('10.0.0.5'), isTrue);

      auth.recordFailedAttempt('10.0.0.5');
      expect(auth.isIPBlocked('10.0.0.5'), isTrue);
      expect(auth.canAttemptAuth('10.0.0.5'), isFalse);
      expect(auth.canAttemptAuth('10.0.0.6'), isTrue, reason: 'other IPs are unaffected');

      now = now.add(AuthManager.ipBlockDuration + const Duration(seconds: 1));
      expect(auth.canAttemptAuth('10.0.0.5'), isTrue);
      expect(auth.getFailedAttempts('10.0.0.5'), 0);
    });

    test('a socket opened before the block cannot keep guessing', () {
      // The slot is taken while the IP is still allowed...
      expect(auth.tryReservePending('10.0.0.5'), isTrue);
      // ...then other sockets from the same IP exhaust its attempts.
      failTimes('10.0.0.5', AuthManager.maxFailedAttemptsPerIp);
      // The per-attempt check must refuse the still-open socket.
      expect(auth.canAttemptAuth('10.0.0.5'), isFalse);
    });

    test('a successful login clears the failure count', () {
      failTimes('10.0.0.5', 3);
      auth.recordSuccessfulAuth('10.0.0.5');
      expect(auth.getFailedAttempts('10.0.0.5'), 0);
    });
  });

  group('pending connection limits', () {
    test('caps unauthenticated sockets per IP and releases slots', () {
      for (var i = 0; i < AuthManager.maxPendingPerIp; i++) {
        expect(auth.tryReservePending('10.0.0.5'), isTrue);
      }
      expect(auth.tryReservePending('10.0.0.5'), isFalse);
      expect(auth.tryReservePending('10.0.0.6'), isTrue);

      auth.releasePending('10.0.0.5');
      expect(auth.tryReservePending('10.0.0.5'), isTrue);
    });

    test('caps unauthenticated sockets in total', () {
      var granted = 0;
      for (var i = 0; i < AuthManager.maxPendingTotal + 10; i++) {
        if (auth.tryReservePending('10.0.1.$i')) granted++;
      }
      expect(granted, AuthManager.maxPendingTotal);
    });

    test('refuses new sockets from a blocked IP', () {
      failTimes('10.0.0.5', AuthManager.maxFailedAttemptsPerIp);
      expect(auth.tryReservePending('10.0.0.5'), isFalse);
      expect(auth.pendingCount('10.0.0.5'), 0);
    });

    test('ignores releases without a reservation', () {
      auth.releasePending('10.0.0.9');
      for (var i = 0; i < AuthManager.maxPendingTotal; i++) {
        expect(auth.tryReservePending('10.0.2.$i'), isTrue);
      }
      expect(auth.tryReservePending('10.0.3.1'), isFalse);
    });
  });

  group('global rate limit', () {
    test('pauses pairing when failures come from many IPs', () {
      // Few failures per IP, so no single IP is ever blocked.
      for (var i = 0; i <= AuthManager.maxGlobalFailures; i++) {
        auth.recordFailedAttempt('10.0.4.$i');
      }
      expect(auth.isGloballyPaused, isTrue);
      expect(auth.canAttemptAuth('10.0.9.9'), isFalse);
      expect(auth.tryReservePending('10.0.9.9'), isFalse);

      now = now.add(AuthManager.globalPauseDuration + const Duration(seconds: 1));
      expect(auth.canAttemptAuth('10.0.9.9'), isTrue);
    });

    test('forgets failures older than the window', () {
      for (var i = 0; i < AuthManager.maxGlobalFailures; i++) {
        auth.recordFailedAttempt('10.0.5.$i');
      }
      now = now.add(AuthManager.globalFailureWindow + const Duration(seconds: 1));
      auth.recordFailedAttempt('10.0.6.1');
      expect(auth.isGloballyPaused, isFalse);
    });
  });

  test('reset clears every limit', () {
    failTimes('10.0.0.5', AuthManager.maxFailedAttemptsPerIp);
    auth.tryReservePending('10.0.0.7');
    auth.reset();
    expect(auth.canAttemptAuth('10.0.0.5'), isTrue);
    expect(auth.pendingCount('10.0.0.7'), 0);
  });
}
