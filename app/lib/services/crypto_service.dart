import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

/// AES-256-GCM encryption/decryption for E2E chat messages.
class CryptoService {
  encrypt.Key? _key;

  /// Set the session encryption key (base64-encoded from the server).
  void setKey(String base64Key) {
    _key = encrypt.Key(base64Decode(base64Key));
  }

  bool get hasKey => _key != null;

  /// Encrypt plaintext → base64 string (IV prepended).
  String encryptMessage(String plaintext) {
    if (_key == null) throw StateError('Encryption key not set');

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    // Prepend IV to ciphertext so the receiver can extract it
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);

    return base64Encode(combined);
  }

  /// Decrypt base64 string → plaintext (extracts prepended IV).
  String decryptMessage(String ciphertext) {
    if (_key == null) throw StateError('Encryption key not set');

    final combined = base64Decode(ciphertext);
    final iv = encrypt.IV(Uint8List.fromList(combined.sublist(0, 16)));
    final encryptedBytes = combined.sublist(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.gcm));
    final encrypted = encrypt.Encrypted(Uint8List.fromList(encryptedBytes));

    return encrypter.decrypt(encrypted, iv: iv);
  }

  void clear() {
    _key = null;
  }
}
