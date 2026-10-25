import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';

/// Conexión en tiempo real con Laravel Reverb (protocolo Pusher).
///
/// Las pantallas escuchan eventos con [on] y además mantienen un polling lento de respaldo,
/// así la app sigue funcionando si el servidor de tiempo real no está disponible.
class Realtime {
  Realtime._();
  static final instance = Realtime._();

  PusherChannelsClient? _client;
  StreamSubscription<void>? _connection;
  String? _token;
  final _channels = <String, PrivateChannel>{};

  /// true mientras el WebSocket está conectado.
  final connected = ValueNotifier(false);

  void connect(String token) {
    if (_token == token && _client != null) return;
    disconnect();
    _token = token;

    final client = PusherChannelsClient.websocket(
      options: PusherChannelsOptions.fromHost(
        scheme: AppConfig.reverbScheme,
        host: AppConfig.reverbHost,
        port: AppConfig.reverbPort,
        key: AppConfig.reverbKey,
        shouldSupplyMetadataQueries: true,
        metadata: PusherChannelsOptionsMetadata.byDefault(),
      ),
      minimumReconnectDelayDuration: const Duration(seconds: 3),
      connectionErrorHandler: (error, trace, refresh) {
        connected.value = false;
        refresh();
      },
    );
    _client = client;
    _connection = client.onConnectionEstablished.listen((_) {
      connected.value = true;
      for (final c in _channels.values) {
        c.subscribeIfNotUnsubscribed();
      }
    });
    client.connect();
  }

  void disconnect() {
    _connection?.cancel();
    _client?.dispose();
    _client = null;
    _connection = null;
    _token = null;
    _channels.clear();
    connected.value = false;
  }

  /// Eventos [event] del canal privado [channel] (sin el prefijo "private-").
  Stream<Map<String, dynamic>> on(String channel, String event) {
    final client = _client;
    if (client == null) return const Stream.empty();

    final ch = _channels.putIfAbsent(channel, () {
      final c = client.privateChannel(
        'private-$channel',
        authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse('${AppConfig.apiUrl}/broadcasting/auth'),
          headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'},
        ),
      );
      if (connected.value) c.subscribe();
      return c;
    });
    return ch.bind(event).map((e) => e.tryGetDataAsMap() ?? const {});
  }
}
