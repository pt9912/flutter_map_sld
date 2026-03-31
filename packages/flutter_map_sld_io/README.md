# flutter_map_sld_io

File and HTTP loading for OGC **SLD/SE** styles. Adapter package for [`flutter_map_sld`](https://pub.dev/packages/flutter_map_sld).

Dart VM and server environments only (`dart:io` dependency).

## Features

- Load SLD from local file path (`SldIo.parseFile`)
- Load SLD from HTTP/HTTPS URL (`SldIo.parseUrl`)
- Typed error handling via sealed `SldLoadResult` union
- Transport errors separated from XML parse issues

## Usage

```dart
import 'package:flutter_map_sld_io/flutter_map_sld_io.dart';

// From file
final fileResult = await SldIo.parseFile('/path/to/style.sld');

// From URL
final urlResult = await SldIo.parseUrl(
  Uri.parse('https://example.com/style.sld'),
);

// Pattern matching
switch (urlResult) {
  case SldLoadSuccess(:final parseResult):
    final doc = parseResult.document;
    // use doc...
  case SldLoadFailure(:final error):
    print('${error.kind}: ${error.message}');
}
```

## Error kinds

| Kind | Trigger |
|------|---------|
| `fileNotFound` | File does not exist |
| `networkError` | DNS, timeout, connection refused |
| `httpError` | Non-200 HTTP status code |
| `encodingError` | Response is not valid UTF-8 |
| `ioError` | Other filesystem errors |

## Publishing

Automated publishing is configured via GitHub Actions for tag pattern `flutter_map_sld_io-v*`.

Configuration: https://pub.dev/packages/flutter_map_sld_io/admin

For the first version (or if automated publishing is unavailable), publish manually via Docker:

```bash
docker build --target io-publish-check -t flutter_map_sld_io:publish .
docker run --rm -it --net=host flutter_map_sld_io:publish sh -c 'dart pub publish'
```
