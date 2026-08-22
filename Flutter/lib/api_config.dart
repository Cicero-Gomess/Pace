import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Configuração central da API do Pace.
///
/// - Web/Windows/macOS/Linux: acessa a API pelo próprio computador.
/// - Android físico: acessa o computador pelo IPv4 da rede Wi-Fi.
/// - Mídias em Base64 são renderizadas diretamente com [MemoryImage].
/// - URLs relativas e URLs antigas de localhost são normalizadas automaticamente.
class ApiConfig {
  ApiConfig._();

  static const String _desktopHost = '127.0.0.1';
  // IP padrão do computador que executa o backend na mesma rede do celular.
  // Pode ser sobrescrito sem editar código:
  // flutter run --dart-define=PACE_API_HOST=192.168.1.25
  static const String _androidPhysicalHost = String.fromEnvironment(
    'PACE_API_HOST',
    defaultValue: '192.168.1.8',
  );

  static const int _port = int.fromEnvironment(
    'PACE_API_PORT',
    defaultValue: 8000,
  );

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://$_desktopHost:$_port';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$_androidPhysicalHost:$_port';
    }

    return 'http://$_desktopHost:$_port';
  }

  static Uri uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }

  static String resolveMediaUrl(dynamic value) {
    final raw = value?.toString().trim() ?? '';

    if (raw.isEmpty) return '';

    if (raw.startsWith('data:image')) {
      return raw;
    }

    final baseUri = Uri.parse(baseUrl);

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final uri = Uri.tryParse(raw);
      if (uri == null) return raw;

      const localHosts = {
        '127.0.0.1',
        'localhost',
        '10.0.2.2',
      };

      if (localHosts.contains(uri.host)) {
        return uri
            .replace(
              scheme: baseUri.scheme,
              host: baseUri.host,
              port: baseUri.port,
            )
            .toString();
      }

      return raw;
    }

    final normalizedPath = raw.startsWith('/') ? raw : '/$raw';
    return '${baseUri.scheme}://${baseUri.host}:${baseUri.port}$normalizedPath';
  }

  static ImageProvider imageProvider(
    dynamic value, {
    String fallbackAsset = 'assets/user.png',
  }) {
    final raw = value?.toString().trim() ?? '';

    if (raw.isEmpty) {
      return AssetImage(fallbackAsset);
    }

    if (raw.startsWith('data:image')) {
      try {
        final commaIndex = raw.indexOf(',');

        if (commaIndex == -1 || commaIndex == raw.length - 1) {
          return AssetImage(fallbackAsset);
        }

        final base64Data = raw.substring(commaIndex + 1);
        return MemoryImage(base64Decode(base64Data));
      } catch (_) {
        return AssetImage(fallbackAsset);
      }
    }

    final resolved = resolveMediaUrl(raw);

    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return NetworkImage(resolved);
    }

    return AssetImage(fallbackAsset);
  }
}
