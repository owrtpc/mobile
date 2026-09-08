import 'dart:typed_data';

// Enforce the limit during streaming, before retaining each received chunk.
Future<Uint8List> readBoundedResponse(
  Stream<List<int>> stream,
  int maximumBytes,
) async {
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    if (chunk.length > maximumBytes - bytes.length) {
      throw const FormatException('Response exceeds the byte limit');
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}
