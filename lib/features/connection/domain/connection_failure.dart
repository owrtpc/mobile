enum ConnectionFailureKind {
  invalidAddress,
  insecureTransport,
  routerUnreachable,
  timeout,
  tlsUntrusted,
  invalidCredentials,
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
