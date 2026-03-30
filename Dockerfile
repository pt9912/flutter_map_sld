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
