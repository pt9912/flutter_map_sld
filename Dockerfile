## ---------------------------------------------------------------------------
## Core: flutter_map_sld
## ---------------------------------------------------------------------------
FROM dart:stable AS base

WORKDIR /app

# Copy only pubspec first for dependency caching
COPY packages/flutter_map_sld/pubspec.yaml packages/flutter_map_sld/pubspec.yaml
WORKDIR /app/packages/flutter_map_sld
RUN dart pub get

# Copy the rest of the package
COPY packages/flutter_map_sld/ /app/packages/flutter_map_sld/

# Analyze
FROM base AS analyze
RUN dart analyze

# Test
FROM base AS test
RUN dart test

# Doc
FROM base AS doc
RUN dart doc

# Publish dry-run
FROM base AS publish-check
RUN dart pub publish --dry-run

## ---------------------------------------------------------------------------
## IO: flutter_map_sld_io
## ---------------------------------------------------------------------------
FROM dart:stable AS io-base

WORKDIR /app

# Copy core package (dependency)
COPY packages/flutter_map_sld/pubspec.yaml packages/flutter_map_sld/pubspec.yaml
COPY packages/flutter_map_sld/lib/ packages/flutter_map_sld/lib/

# Copy IO package pubspec first for dependency caching
COPY packages/flutter_map_sld_io/pubspec.yaml packages/flutter_map_sld_io/pubspec.yaml
COPY packages/flutter_map_sld_io/pubspec_overrides.yaml packages/flutter_map_sld_io/pubspec_overrides.yaml
WORKDIR /app/packages/flutter_map_sld_io
RUN dart pub get

# Copy the rest of the IO package
COPY packages/flutter_map_sld_io/ /app/packages/flutter_map_sld_io/

# Analyze
FROM io-base AS io-analyze
RUN dart analyze

# Test
FROM io-base AS io-test
RUN dart test

# Doc
FROM io-base AS io-doc
RUN dart doc

# Publish dry-run
FROM io-base AS io-publish-check
RUN dart pub publish --dry-run

## ---------------------------------------------------------------------------
## Flutter Adapter: flutter_map_sld_flutter_map
## ---------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-map-base

WORKDIR /app

# Copy core package (dependency)
COPY packages/flutter_map_sld/pubspec.yaml packages/flutter_map_sld/pubspec.yaml
COPY packages/flutter_map_sld/lib/ packages/flutter_map_sld/lib/

# Copy Flutter adapter package pubspec first for dependency caching
COPY packages/flutter_map_sld_flutter_map/pubspec.yaml packages/flutter_map_sld_flutter_map/pubspec.yaml
COPY packages/flutter_map_sld_flutter_map/pubspec_overrides.yaml packages/flutter_map_sld_flutter_map/pubspec_overrides.yaml
WORKDIR /app/packages/flutter_map_sld_flutter_map
RUN flutter pub get

# Copy the rest of the Flutter adapter package
COPY packages/flutter_map_sld_flutter_map/ /app/packages/flutter_map_sld_flutter_map/

# Analyze
FROM flutter-map-base AS flutter-map-analyze
RUN flutter analyze

# Test
FROM flutter-map-base AS flutter-map-test
RUN flutter test

# Doc
FROM flutter-map-base AS flutter-map-doc
RUN dart doc

# Publish dry-run
FROM flutter-map-base AS flutter-map-publish-check
RUN flutter pub publish --dry-run
