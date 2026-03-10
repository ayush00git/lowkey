import 'dart:convert';
import 'package:pinenacl/x25519.dart';

/// Client-side X25519 + XSalsa20-Poly1305 (NaCl Box) crypto.
/// The server NEVER sees the shared secret — only public keys are exchanged.
class CryptoService {
  late final PrivateKey _privateKey;
  late final PublicKey _publicKey;
  Box? _box;

  CryptoService() {
    _privateKey = PrivateKey.generate();
    _publicKey = _privateKey.publicKey;
  }

  /// Our public key as base64 (sent to peer via server relay).
  String get publicKeyBase64 => base64Encode(Uint8List.fromList(_publicKey));

  /// Derive the shared secret from our private key + peer's public key.
  /// Both sides compute the same secret: X25519(myPrivate, theirPublic).
  void deriveSharedKey(String peerPublicKeyBase64) {
    final peerPk = PublicKey(Uint8List.fromList(base64Decode(peerPublicKeyBase64)));
    _box = Box(myPrivateKey: _privateKey, theirPublicKey: peerPk);
  }

  bool get hasKey => _box != null;

  /// Encrypt plaintext → base64 (nonce + ciphertext + MAC).
  String encryptMessage(String plaintext) {
    if (_box == null) throw StateError('Shared key not derived');
    final encrypted = _box!.encrypt(Uint8List.fromList(utf8.encode(plaintext)));
    return base64Encode(Uint8List.fromList(encrypted));
  }

  /// Decrypt base64 → plaintext (splits nonce from ciphertext).
  String decryptMessage(String ciphertext) {
    if (_box == null) throw StateError('Shared key not derived');
    final bytes = base64Decode(ciphertext);
    // First 24 bytes = nonce, rest = ciphertext + MAC
    final nonce = Uint8List.fromList(bytes.sublist(0, 24));
    final cipher = Uint8List.fromList(bytes.sublist(24));
    final encrypted = EncryptedMessage(nonce: nonce, cipherText: cipher);
    final decrypted = _box!.decrypt(encrypted);
    return utf8.decode(decrypted);
  }

  void clear() {
    _box = null;
  }
}
