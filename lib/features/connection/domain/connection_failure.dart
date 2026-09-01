enum ConnectionFailureKind {
  invalidAddress,
  insecureTransport,
  routerUnreachable,
  timeout,
  tlsUntrusted,
  invalidCredentials,
  sessionExpired,
  permissionDenied,
  apiMissing,
  apiIncompatible,
  malformedResponse,
  backendFailure,
}

class ConnectionFailure implements Exception {
  const ConnectionFailure(this.kind);

  final ConnectionFailureKind kind;
}
