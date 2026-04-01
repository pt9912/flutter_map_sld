## 0.2.1

- Added dartdoc comments to all public constructors.
- Added example file for pub.dev scoring.

## 0.2.0

- **WMS GetMap request building**: `WmsRequestBuilder` with WMS 1.1.1 and 1.3.0 support, correct SRS/CRS parameter, EPSG:4326 axis-order handling, and `SLD_BODY` parameter.
- **WMS GetCapabilities parsing**: `parseWmsCapabilities()` extracts layers and styles from GetCapabilities XML responses.
- **WMS style resolution**: `WmsStyleResolver` matches WMS layers to SLD `NamedLayer` and `UserStyle` by name.
- Added `xml` as direct dependency for capabilities parsing.

## 0.1.0

- Initial release: file and HTTP loading for SLD/SE documents.
- `SldIo.parseFile` — load and parse from local file path.
- `SldIo.parseUrl` — load and parse from HTTP/HTTPS URL.
- `SldLoadResult` sealed union with `SldLoadSuccess` / `SldLoadFailure`.
- `SldLoadError` with typed error kinds: `fileNotFound`, `networkError`, `httpError`, `encodingError`, `ioError`.
