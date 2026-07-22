/// Supported proxy protocol types.
enum ProxyType {
  httpProxy('HTTP Proxy', 'http'),
  shadowsocks('Shadowsocks', 'ss');

  const ProxyType(this.label, this.id);
  final String label;
  final String id;

  static ProxyType fromId(String id) {
    return ProxyType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => ProxyType.httpProxy,
    );
  }
}

/// Connection state for the active proxy tunnel.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// A saved proxy server profile.
class ProxyProfile {
  ProxyProfile({
    String? id,
    required this.name,
    required this.type,
    required this.host,
    required this.port,
    this.username,
    this.password,
    this.method,
    this.localPort = 10808,
    this.systemProxy = true,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  final String id;
  String name;
  ProxyType type;
  String host;
  int port;
  String? username;
  String? password;
  String? method;
  int localPort;
  bool systemProxy;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.id,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'method': method,
        'localPort': localPort,
        'systemProxy': systemProxy,
      };

  factory ProxyProfile.fromJson(Map<String, dynamic> json) {
    return ProxyProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ProxyType.fromId(json['type'] as String),
      host: json['host'] as String,
      port: json['port'] as int,
      username: json['username'] as String?,
      password: json['password'] as String?,
      method: json['method'] as String?,
      localPort: json['localPort'] as int? ?? 10808,
      systemProxy: json['systemProxy'] as bool? ?? true,
    );
  }

  ProxyProfile copyWith({
    String? name,
    ProxyType? type,
    String? host,
    int? port,
    String? username,
    String? password,
    String? method,
    int? localPort,
    bool? systemProxy,
  }) {
    return ProxyProfile(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      method: method ?? this.method,
      localPort: localPort ?? this.localPort,
      systemProxy: systemProxy ?? this.systemProxy,
    );
  }
}

/// Runtime connection info shown in the UI.
class ConnectionInfo {
  const ConnectionInfo({
    this.status = ConnectionStatus.disconnected,
    this.activeProfile,
    this.localAddress,
    this.bytesSent = 0,
    this.bytesReceived = 0,
    this.connectedSince,
    this.errorMessage,
  });

  final ConnectionStatus status;
  final ProxyProfile? activeProfile;
  final String? localAddress;
  final int bytesSent;
  final int bytesReceived;
  final DateTime? connectedSince;
  final String? errorMessage;

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isBusy =>
      status == ConnectionStatus.connecting ||
      status == ConnectionStatus.disconnecting;

  ConnectionInfo copyWith({
    ConnectionStatus? status,
    ProxyProfile? activeProfile,
    String? localAddress,
    int? bytesSent,
    int? bytesReceived,
    DateTime? connectedSince,
    String? errorMessage,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return ConnectionInfo(
      status: status ?? this.status,
      activeProfile: clearProfile ? null : (activeProfile ?? this.activeProfile),
      localAddress: localAddress ?? this.localAddress,
      bytesSent: bytesSent ?? this.bytesSent,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      connectedSince: connectedSince ?? this.connectedSince,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
