import 'dart:convert';
import 'dart:io';

import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:http/http.dart' as http;

import 'sld_load_result.dart';

/// File and HTTP loading utilities for SLD/SE documents.
///
/// All methods return [SldLoadResult] — a sealed union of
/// [SldLoadSuccess] and [SldLoadFailure]. Transport errors are reported
/// as [SldLoadFailure]; XML-level issues are in [SldLoadSuccess.parseResult].
class SldIo {
  const SldIo._();

  /// Reads and parses an SLD/SE file at the given [path].
  ///
  /// Returns [SldLoadFailure] with [SldLoadErrorKind.fileNotFound] if the
  /// file does not exist, or [SldLoadErrorKind.ioError] for other I/O errors.
  static Future<SldLoadResult> parseFile(String path) async {
    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      final parseResult = SldDocument.parseBytes(bytes);
      return SldLoadSuccess(parseResult);
    } on PathNotFoundException {
      return SldLoadFailure(SldLoadError(
        kind: SldLoadErrorKind.fileNotFound,
        message: 'File not found: $path',
        uri: Uri.file(path, windows: Platform.isWindows),
      ));
    } on FileSystemException catch (e) {
      return SldLoadFailure(SldLoadError(
        kind: SldLoadErrorKind.ioError,
        message: 'I/O error reading $path: ${e.message}',
        uri: Uri.file(path, windows: Platform.isWindows),
      ));
    }
  }

  /// Fetches and parses an SLD/SE document from the given [uri].
  ///
  /// An optional [client] can be provided for testing or connection reuse.
  /// If not provided, a short-lived client is created and closed after use.
  ///
  /// Returns [SldLoadFailure] with:
  /// - [SldLoadErrorKind.httpError] for non-200 responses
  /// - [SldLoadErrorKind.networkError] for connection failures
  /// - [SldLoadErrorKind.encodingError] if the response is not valid UTF-8
  static Future<SldLoadResult> parseUrl(
    Uri uri, {
    http.Client? client,
  }) async {
    final ownClient = client == null;
    final c = client ?? http.Client();
    try {
      final http.Response response;
      try {
        response = await c.get(uri);
      } on http.ClientException catch (e) {
        return SldLoadFailure(SldLoadError(
          kind: SldLoadErrorKind.networkError,
          message: 'Network error: ${e.message}',
          uri: uri,
        ));
      } on SocketException catch (e) {
        return SldLoadFailure(SldLoadError(
          kind: SldLoadErrorKind.networkError,
          message: 'Network error: ${e.message}',
          uri: uri,
        ));
      }

      if (response.statusCode != 200) {
        return SldLoadFailure(SldLoadError(
          kind: SldLoadErrorKind.httpError,
          message: 'HTTP ${response.statusCode}',
          httpStatusCode: response.statusCode,
          uri: uri,
        ));
      }

      final String body;
      try {
        body = utf8.decode(response.bodyBytes);
      } on FormatException catch (e) {
        return SldLoadFailure(SldLoadError(
          kind: SldLoadErrorKind.encodingError,
          message: 'UTF-8 decoding failed: ${e.message}',
          uri: uri,
        ));
      }

      final parseResult = SldDocument.parseXmlString(body);
      return SldLoadSuccess(parseResult);
    } finally {
      if (ownClient) c.close();
    }
  }
}
