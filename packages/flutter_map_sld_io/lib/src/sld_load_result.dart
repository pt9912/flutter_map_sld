import 'package:flutter_map_sld/flutter_map_sld.dart';

/// The result of loading an SLD document from a file or URL.
///
/// Use pattern matching to handle success and failure:
/// ```dart
/// switch (result) {
///   case SldLoadSuccess(:final parseResult):
///     // use parseResult.document
///   case SldLoadFailure(:final error):
///     // handle error
/// }
/// ```
sealed class SldLoadResult {
  const SldLoadResult();
}

/// A successfully loaded SLD document.
final class SldLoadSuccess extends SldLoadResult {
  const SldLoadSuccess(this.parseResult);

  /// The parse result from the core parser. May still contain parse issues.
  final SldParseResult parseResult;
}

/// A transport-level failure (file not found, network error, etc.).
final class SldLoadFailure extends SldLoadResult {
  const SldLoadFailure(this.error);

  /// Details about the transport error.
  final SldLoadError error;
}

/// Kinds of transport-level errors.
enum SldLoadErrorKind {
  /// File was not found at the given path.
  fileNotFound,

  /// A network-level error occurred (DNS, timeout, connection refused, etc.).
  networkError,

  /// The HTTP server returned a non-200 status code.
  httpError,

  /// The response bytes could not be decoded as UTF-8.
  encodingError,

  /// A general I/O error not covered by the other kinds.
  ioError,
}

/// A transport-level error that occurred before XML parsing could begin.
///
/// This is distinct from [SldParseIssue], which describes problems within
/// the XML content itself.
class SldLoadError {
  const SldLoadError({
    required this.kind,
    required this.message,
    this.httpStatusCode,
    this.uri,
  });

  /// The category of the error.
  final SldLoadErrorKind kind;

  /// Human-readable description of what went wrong.
  final String message;

  /// HTTP status code, if applicable (only for [SldLoadErrorKind.httpError]).
  final int? httpStatusCode;

  /// The URI that was being loaded, if applicable.
  final Uri? uri;

  @override
  String toString() => 'SldLoadError($kind: $message)';
}
