import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 加密服务类 - 用于加密敏感的连接信息
class EncryptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  static const String _keyStorageKey = 'ssh_client_encryption_key';
  static String? _cachedKey;
  
  /// 获取或生成加密密钥
  static Future<String> _getEncryptionKey() async {
    if (_cachedKey != null) return _cachedKey!;
    
    String? storedKey = await _storage.read(key: _keyStorageKey);
    
    if (storedKey == null) {
      // 生成新的256位密钥
      final random = Random.secure();
      final bytes = List<int>.generate(32, (i) => random.nextInt(256));
      storedKey = base64.encode(bytes);
      await _storage.write(key: _keyStorageKey, value: storedKey);
    }
    
    _cachedKey = storedKey;
    return storedKey;
  }
  
  /// 简单的XOR加密 (对于应用级别的数据保护已足够)
  static Future<String?> encrypt(String? plaintext) async {
    if (plaintext == null || plaintext.isEmpty) return null;
    
    try {
      final key = await _getEncryptionKey();
      final keyBytes = base64.decode(key);
      final plaintextBytes = utf8.encode(plaintext);
      
      // 生成随机IV
      final random = Random.secure();
      final iv = List<int>.generate(16, (i) => random.nextInt(256));
      
      // 扩展密钥以匹配明文长度
      final extendedKey = <int>[];
      for (int i = 0; i < plaintextBytes.length; i++) {
        extendedKey.add(keyBytes[i % keyBytes.length]);
      }
      
      // XOR加密
      final encrypted = <int>[];
      for (int i = 0; i < plaintextBytes.length; i++) {
        encrypted.add(plaintextBytes[i] ^ extendedKey[i] ^ iv[i % iv.length]);
      }
      
      // 将IV和加密数据组合
      final combined = [...iv, ...encrypted];
      return base64.encode(combined);
    } catch (e) {
      // 加密失败时返回原文（降级处理）
      return plaintext;
    }
  }
  
  /// 解密
  static Future<String?> decrypt(String? ciphertext) async {
    if (ciphertext == null || ciphertext.isEmpty) return null;
    
    try {
      final key = await _getEncryptionKey();
      final keyBytes = base64.decode(key);
      final combinedBytes = base64.decode(ciphertext);
      
      if (combinedBytes.length < 16) {
        // 可能是未加密的旧数据
        return ciphertext;
      }
      
      // 分离IV和加密数据
      final iv = combinedBytes.sublist(0, 16);
      final encryptedBytes = combinedBytes.sublist(16);
      
      // 扩展密钥
      final extendedKey = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        extendedKey.add(keyBytes[i % keyBytes.length]);
      }
      
      // XOR解密
      final decrypted = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ extendedKey[i] ^ iv[i % iv.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      // 解密失败时返回原文（可能是旧的未加密数据）
      return ciphertext;
    }
  }
  
  /// 加密连接信息的敏感字段
  static Future<Map<String, dynamic>> encryptConnectionData(Map<String, dynamic> data) async {
    final encrypted = Map<String, dynamic>.from(data);
    
    // 加密敏感字段
    if (encrypted['password'] != null) {
      encrypted['password'] = await encrypt(encrypted['password']);
    }
    
    if (encrypted['private_key'] != null) {
      encrypted['private_key'] = await encrypt(encrypted['private_key']);
    }
    
    // 添加加密标记
    encrypted['encrypted'] = 1;
    
    return encrypted;
  }
  
  /// 解密连接信息的敏感字段
  static Future<Map<String, dynamic>> decryptConnectionData(Map<String, dynamic> data) async {
    final decrypted = Map<String, dynamic>.from(data);
    
    // 检查是否为加密数据
    final isEncrypted = data['encrypted'] == 1;
    
    if (isEncrypted) {
      // 解密敏感字段
      if (decrypted['password'] != null) {
        decrypted['password'] = await decrypt(decrypted['password']);
      }
      
      if (decrypted['private_key'] != null) {
        decrypted['private_key'] = await decrypt(decrypted['private_key']);
      }
    }
    
    // 移除加密标记
    decrypted.remove('encrypted');
    
    return decrypted;
  }
  
  /// 清除缓存的密钥（用于测试或重置）
  static void clearCachedKey() {
    _cachedKey = null;
  }
  
  /// 重新生成加密密钥（会导致现有数据无法解密）
  static Future<void> regenerateKey() async {
    await _storage.delete(key: _keyStorageKey);
    _cachedKey = null;
  }
}