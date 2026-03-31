## ---------------------------------------------------------------------------
## flutter_map_sld_flutter_map
## ---------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS base

WORKDIR /app

# Copy core package (dependency)
COPY packages/flutter_map_sld/pubspec.yaml packages/flutter_map_sld/pubspec.yaml
COPY packages/flutter_map_sld/lib/ packages/flutter_map_sld/lib/

# Copy flutter_map package pubspec first for dependency caching
COPY packages/flutter_map_sld_flutter_map/pubspec.yaml packages/flutter_map_sld_flutter_map/pubspec.yaml
COPY packages/flutter_map_sld_flutter_map/pubspec_overrides.yaml packages/flutter_map_sld_flutter_map/pubspec_overrides.yaml
WORKDIR /app/packages/flutter_map_sld_flutter_map
RUN flutter pub get

# Copy the rest of the package
COPY packages/flutter_map_sld_flutter_map/ /app/packages/flutter_map_sld_flutter_map/

# Analyze
FROM base AS analyze
RUN flutter analyze

# Test
FROM base AS test
RUN flutter test

# Doc
FROM base AS doc
RUN dart doc

# Publish dry-run
FROM base AS publish-check
RUN flutter pub publish --dry-run
