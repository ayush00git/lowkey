import 'package:tor/tor.dart';

/// Manages the embedded Tor proxy lifecycle.
///
/// Starts Arti (Tor's Rust implementation) and exposes a local
/// SOCKS5 proxy port that other services can route traffic through.
class TorService {
  bool _started = false;

  bool get isRunning => _started;

  /// The local SOCKS5 proxy port (only valid after [start] completes).
  int get port => Tor.instance.port;

  /// Start the Tor proxy. Blocks until the circuit is bootstrapped.
  Future<void> start() async {
    if (_started) return;
    await Tor.init();
    await Tor.instance.start();
    _started = true;
  }

  /// Stop the Tor proxy.
  Future<void> stop() async {
    if (!_started) return;
    await Tor.instance.stop();
    _started = false;
  }
}
