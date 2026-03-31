## 0.1.0

- Initial release: file and HTTP loading for SLD/SE documents.
- `SldIo.parseFile` — load and parse from local file path.
- `SldIo.parseUrl` — load and parse from HTTP/HTTPS URL.
- `SldLoadResult` sealed union with `SldLoadSuccess` / `SldLoadFailure`.
- `SldLoadError` with typed error kinds: `fileNotFound`, `networkError`, `httpError`, `encodingError`, `ioError`.
