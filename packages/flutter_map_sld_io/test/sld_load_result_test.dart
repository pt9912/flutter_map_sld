import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld_io/flutter_map_sld_io.dart';
import 'package:test/test.dart';

void main() {
  group('SldLoadResult', () {
    test('SldLoadSuccess holds parseResult', () {
      final parseResult = SldParseResult(
        document: SldDocument(layers: []),
      );
      final result = SldLoadSuccess(parseResult);

      expect(result, isA<SldLoadResult>());
      expect(result.parseResult.document, isNotNull);
    });

    test('SldLoadFailure holds error', () {
      const error = SldLoadError(
        kind: SldLoadErrorKind.fileNotFound,
        message: 'File not found',
      );
      const result = SldLoadFailure(error);

      expect(result, isA<SldLoadResult>());
      expect(result.error.kind, SldLoadErrorKind.fileNotFound);
    });

    test('pattern matching works exhaustively', () {
      final SldLoadResult result = SldLoadSuccess(
        SldParseResult(document: SldDocument(layers: [])),
      );

      final message = switch (result) {
        SldLoadSuccess(:final parseResult) =>
          'doc: ${parseResult.document != null}',
        SldLoadFailure(:final error) => 'error: ${error.message}',
      };

      expect(message, 'doc: true');
    });
  });

  group('SldLoadError', () {
    test('toString includes kind and message', () {
      const error = SldLoadError(
        kind: SldLoadErrorKind.httpError,
        message: 'HTTP 404',
        httpStatusCode: 404,
        uri: null,
      );

      expect(error.toString(), contains('httpError'));
      expect(error.toString(), contains('HTTP 404'));
    });

    test('has all SldLoadErrorKind values', () {
      expect(SldLoadErrorKind.values, hasLength(5));
    });
  });
}
