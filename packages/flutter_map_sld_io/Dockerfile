FROM dart:stable AS base

WORKDIR /app

# Copy core package (dependency)
COPY packages/flutter_map_sld/pubspec.yaml packages/flutter_map_sld/pubspec.yaml
COPY packages/flutter_map_sld/lib/ packages/flutter_map_sld/lib/

# Copy IO package pubspec first for dependency caching
COPY packages/flutter_map_sld_io/pubspec.yaml packages/flutter_map_sld_io/pubspec.yaml
WORKDIR /app/packages/flutter_map_sld_io
RUN dart pub get

# Copy the rest of the IO package
COPY packages/flutter_map_sld_io/ /app/packages/flutter_map_sld_io/

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
