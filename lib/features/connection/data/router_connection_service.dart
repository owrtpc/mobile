import '../../../core/network/json_rpc_client.dart';
import '../../../core/network/json_rpc_transport.dart';
import '../domain/connected_router.dart';
import '../domain/connection_failure.dart';
import '../domain/router_capabilities.dart';
import '../domain/router_endpoint.dart';

class RouterConnectionService {
  const RouterConnectionService({required this.transport});

  final JsonRpcTransport transport;

  Future<ConnectedRouter> connect({
    required String address,
    required String username,
    required String password,
  }) async {
    final RouterEndpoint endpoint;
    try {
      endpoint = RouterEndpoint.parse(address);
    } on InsecureRouterEndpointException {
      throw const ConnectionFailure(ConnectionFailureKind.insecureTransport);
    } on FormatException {
      throw const ConnectionFailure(ConnectionFailureKind.invalidAddress);
    }

    final client = JsonRpcClient(endpoint: endpoint.uri, transport: transport);
    String? sessionToken;
    try {
      final login = await client.call(
        session: JsonRpcClient.anonymousSession,
        object: 'session',
        method: 'login',
        parameters: {'username': username, 'password': password},
      );
      final rawSessionToken = login['ubus_rpc_session'];
      if (rawSessionToken is! String ||
          !RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(rawSessionToken)) {
        throw const ConnectionFailure(ConnectionFailureKind.malformedResponse);
      }
      sessionToken = rawSessionToken;

      final canRead = await _checkAccess(
        client,
        sessionToken,
        function: 'status',
      );
      if (!canRead) {
        throw const ConnectionFailure(ConnectionFailureKind.permissionDenied);
      }
      var canWrite = await _checkAccess(
        client,
        sessionToken,
        function: 'set_block',
      );
      if (canWrite) {
        canWrite = await _checkAccess(
          client,
          sessionToken,
          function: 'set_enabled',
        );
      }
      if (canWrite) {
        canWrite = await _checkAccess(
          client,
          sessionToken,
          function: 'add_time',
        );
      }

      final capabilityJson = await client.call(
        session: sessionToken,
        object: 'owrtpc',
        method: 'capabilities',
      );
      final capabilities = RouterCapabilities.fromJson(capabilityJson);
      if (!capabilities.isCompatible) {
        throw const ConnectionFailure(ConnectionFailureKind.apiIncompatible);
      }
      if (!capabilities.features.contains('profiles.read')) {
        throw const ConnectionFailure(ConnectionFailureKind.apiIncompatible);
      }

      return ConnectedRouter(
        endpoint: endpoint,
        username: username,
        sessionToken: sessionToken,
        capabilities: capabilities,
        canWrite: canWrite && capabilities.features.contains('profiles.write'),
      );
    } on ConnectionFailure {
      if (sessionToken != null) await _bestEffortSignOut(client, sessionToken);
      rethrow;
    } on UbusException catch (error) {
      if (sessionToken != null) await _bestEffortSignOut(client, sessionToken);
      if (sessionToken == null && error.code == 6) {
        throw const ConnectionFailure(ConnectionFailureKind.invalidCredentials);
      }
      if (sessionToken != null && error.code == 4) {
        throw const ConnectionFailure(ConnectionFailureKind.apiMissing);
      }
      if (error.code == 6) {
        throw const ConnectionFailure(ConnectionFailureKind.permissionDenied);
      }
      throw const ConnectionFailure(ConnectionFailureKind.backendFailure);
    } on JsonRpcTransportException catch (error) {
      if (sessionToken != null) await _bestEffortSignOut(client, sessionToken);
      throw ConnectionFailure(switch (error.kind) {
        JsonRpcTransportFailureKind.network =>
          ConnectionFailureKind.routerUnreachable,
        JsonRpcTransportFailureKind.tls => ConnectionFailureKind.tlsUntrusted,
        JsonRpcTransportFailureKind.timeout => ConnectionFailureKind.timeout,
        JsonRpcTransportFailureKind.httpStatus =>
          ConnectionFailureKind.routerUnreachable,
        JsonRpcTransportFailureKind.malformedResponse =>
          ConnectionFailureKind.malformedResponse,
      });
    } on JsonRpcProtocolException {
      if (sessionToken != null) await _bestEffortSignOut(client, sessionToken);
      throw const ConnectionFailure(ConnectionFailureKind.malformedResponse);
    } on FormatException {
      if (sessionToken != null) await _bestEffortSignOut(client, sessionToken);
      throw const ConnectionFailure(ConnectionFailureKind.malformedResponse);
    }
  }

  Future<void> signOut(ConnectedRouter router) async {
    if (router.isPreview) return;
    final client = JsonRpcClient(
      endpoint: router.endpoint.uri,
      transport: transport,
    );
    await _bestEffortSignOut(client, router.sessionToken);
  }

  Future<bool> _checkAccess(
    JsonRpcClient client,
    String sessionToken, {
    required String function,
  }) async {
    final response = await client.call(
      session: sessionToken,
      object: 'session',
      method: 'access',
      parameters: {
        'ubus_rpc_session': sessionToken,
        'scope': 'ubus',
        'object': 'owrtpc',
        'function': function,
      },
    );
    return response['access'] == true;
  }

  Future<void> _bestEffortSignOut(
    JsonRpcClient client,
    String sessionToken,
  ) async {
    try {
      await client.call(
        session: sessionToken,
        object: 'session',
        method: 'destroy',
        parameters: {'ubus_rpc_session': sessionToken},
      );
    } on Object {
      // The local session is discarded regardless of router reachability.
    }
  }
}
