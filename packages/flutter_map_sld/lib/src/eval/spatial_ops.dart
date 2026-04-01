import 'dart:math' as math;

import 'package:gml4dart/gml4dart.dart';

/// Returns the bounding envelope of a geometry.
GmlEnvelope geometryEnvelope(GmlGeometry geom) {
  return switch (geom) {
    GmlPoint(:final coordinate) => GmlEnvelope(
        lowerCorner: coordinate,
        upperCorner: coordinate,
      ),
    GmlLineString(:final coordinates) => _envelopeOfCoords(coordinates),
    GmlLinearRing(:final coordinates) => _envelopeOfCoords(coordinates),
    GmlPolygon(:final exterior) => _envelopeOfCoords(exterior.coordinates),
    GmlEnvelope() => geom,
    GmlBox(:final lowerCorner, :final upperCorner) => GmlEnvelope(
        lowerCorner: lowerCorner,
        upperCorner: upperCorner,
      ),
    GmlCurve(:final coordinates) => _envelopeOfCoords(coordinates),
    GmlSurface(:final patches) => _mergeEnvelopes(
        patches.map((p) => _envelopeOfCoords(p.exterior.coordinates))),
    GmlMultiPoint(:final points) => _mergeEnvelopes(
        points.map((p) => geometryEnvelope(p))),
    GmlMultiLineString(:final lineStrings) => _mergeEnvelopes(
        lineStrings.map((l) => geometryEnvelope(l))),
    GmlMultiPolygon(:final polygons) => _mergeEnvelopes(
        polygons.map((p) => geometryEnvelope(p))),
  };
}

/// Whether two envelopes intersect (share any area).
bool envelopeIntersects(GmlEnvelope a, GmlEnvelope b) {
  return a.lowerCorner.x <= b.upperCorner.x &&
      a.upperCorner.x >= b.lowerCorner.x &&
      a.lowerCorner.y <= b.upperCorner.y &&
      a.upperCorner.y >= b.lowerCorner.y;
}

/// Whether a point lies inside an envelope (inclusive).
bool pointInEnvelope(GmlPoint p, GmlEnvelope env) {
  final c = p.coordinate;
  return c.x >= env.lowerCorner.x &&
      c.x <= env.upperCorner.x &&
      c.y >= env.lowerCorner.y &&
      c.y <= env.upperCorner.y;
}

/// Whether a point lies inside a polygon (ray-casting algorithm).
///
/// Tests only the exterior ring. Interior rings (holes) are not considered.
bool pointInPolygon(GmlPoint p, GmlPolygon poly) {
  final ring = poly.exterior.coordinates;
  if (ring.isEmpty) return false;
  final px = p.coordinate.x;
  final py = p.coordinate.y;
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final xi = ring[i].x, yi = ring[i].y;
    final xj = ring[j].x, yj = ring[j].y;
    if ((yi > py) != (yj > py) &&
        px < (xj - xi) * (py - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}

/// Euclidean distance between two points.
double distancePointToPoint(GmlPoint a, GmlPoint b) {
  final dx = a.coordinate.x - b.coordinate.x;
  final dy = a.coordinate.y - b.coordinate.y;
  return math.sqrt(dx * dx + dy * dy);
}

/// Whether a line string intersects an envelope.
///
/// Checks if any segment of the line intersects the envelope rectangle,
/// or if any line vertex is inside the envelope.
bool lineIntersectsEnvelope(GmlLineString line, GmlEnvelope env) {
  final coords = line.coordinates;
  for (final c in coords) {
    if (c.x >= env.lowerCorner.x &&
        c.x <= env.upperCorner.x &&
        c.y >= env.lowerCorner.y &&
        c.y <= env.upperCorner.y) {
      return true;
    }
  }
  // Check each segment against envelope edges.
  for (var i = 0; i < coords.length - 1; i++) {
    if (_segmentIntersectsRect(
      coords[i].x, coords[i].y,
      coords[i + 1].x, coords[i + 1].y,
      env.lowerCorner.x, env.lowerCorner.y,
      env.upperCorner.x, env.upperCorner.y,
    )) {
      return true;
    }
  }
  return false;
}

/// Whether a geometry intersects another geometry.
///
/// Supported combinations: Point/Envelope, Point/Polygon, LineString/Envelope,
/// and envelope-based fallback for other types.
bool geometryIntersects(GmlGeometry a, GmlGeometry b) {
  // Point vs Envelope.
  if (a is GmlPoint && b is GmlEnvelope) return pointInEnvelope(a, b);
  if (a is GmlEnvelope && b is GmlPoint) return pointInEnvelope(b, a);

  // Point vs Polygon.
  if (a is GmlPoint && b is GmlPolygon) return pointInPolygon(a, b);
  if (a is GmlPolygon && b is GmlPoint) return pointInPolygon(b, a);

  // LineString vs Envelope.
  if (a is GmlLineString && b is GmlEnvelope) {
    return lineIntersectsEnvelope(a, b);
  }
  if (a is GmlEnvelope && b is GmlLineString) {
    return lineIntersectsEnvelope(b, a);
  }

  // Fallback: envelope intersection.
  return envelopeIntersects(geometryEnvelope(a), geometryEnvelope(b));
}

/// Whether geometry [inner] is fully within geometry [outer].
///
/// Supported: Point within Envelope, Point within Polygon.
/// Other combinations fall back to envelope containment.
bool geometryWithin(GmlGeometry inner, GmlGeometry outer) {
  if (inner is GmlPoint && outer is GmlEnvelope) {
    return pointInEnvelope(inner, outer);
  }
  if (inner is GmlPoint && outer is GmlPolygon) {
    return pointInPolygon(inner, outer);
  }
  // Fallback: check if inner's envelope is within outer's envelope.
  final innerEnv = geometryEnvelope(inner);
  final outerEnv = geometryEnvelope(outer);
  return innerEnv.lowerCorner.x >= outerEnv.lowerCorner.x &&
      innerEnv.upperCorner.x <= outerEnv.upperCorner.x &&
      innerEnv.lowerCorner.y >= outerEnv.lowerCorner.y &&
      innerEnv.upperCorner.y <= outerEnv.upperCorner.y;
}

/// Minimum distance between two geometries (point-to-point only).
///
/// For non-point types, uses the nearest envelope corner as approximation.
double geometryDistance(GmlGeometry a, GmlGeometry b) {
  final pa = _representativePoint(a);
  final pb = _representativePoint(b);
  return distancePointToPoint(pa, pb);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GmlEnvelope _envelopeOfCoords(List<GmlCoordinate> coords) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final c in coords) {
    if (c.x < minX) minX = c.x;
    if (c.x > maxX) maxX = c.x;
    if (c.y < minY) minY = c.y;
    if (c.y > maxY) maxY = c.y;
  }
  return GmlEnvelope(
    lowerCorner: GmlCoordinate(minX, minY),
    upperCorner: GmlCoordinate(maxX, maxY),
  );
}

GmlEnvelope _mergeEnvelopes(Iterable<GmlEnvelope> envs) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final e in envs) {
    if (e.lowerCorner.x < minX) minX = e.lowerCorner.x;
    if (e.lowerCorner.y < minY) minY = e.lowerCorner.y;
    if (e.upperCorner.x > maxX) maxX = e.upperCorner.x;
    if (e.upperCorner.y > maxY) maxY = e.upperCorner.y;
  }
  return GmlEnvelope(
    lowerCorner: GmlCoordinate(minX, minY),
    upperCorner: GmlCoordinate(maxX, maxY),
  );
}

GmlPoint _representativePoint(GmlGeometry geom) {
  if (geom is GmlPoint) return geom;
  final env = geometryEnvelope(geom);
  return GmlPoint(
    coordinate: GmlCoordinate(
      (env.lowerCorner.x + env.upperCorner.x) / 2,
      (env.lowerCorner.y + env.upperCorner.y) / 2,
    ),
  );
}

/// Cohen–Sutherland-style segment/rectangle intersection test.
bool _segmentIntersectsRect(
  double x1, double y1, double x2, double y2,
  double rxMin, double ryMin, double rxMax, double ryMax,
) {
  int outcode(double x, double y) {
    var code = 0;
    if (x < rxMin) code |= 1;
    if (x > rxMax) code |= 2;
    if (y < ryMin) code |= 4;
    if (y > ryMax) code |= 8;
    return code;
  }

  var oc1 = outcode(x1, y1);
  var oc2 = outcode(x2, y2);

  for (;;) {
    if ((oc1 | oc2) == 0) return true; // Both inside.
    if ((oc1 & oc2) != 0) return false; // Both in same outside zone.

    final ocOut = oc1 != 0 ? oc1 : oc2;
    double x, y;
    if ((ocOut & 8) != 0) {
      x = x1 + (x2 - x1) * (ryMax - y1) / (y2 - y1);
      y = ryMax;
    } else if ((ocOut & 4) != 0) {
      x = x1 + (x2 - x1) * (ryMin - y1) / (y2 - y1);
      y = ryMin;
    } else if ((ocOut & 2) != 0) {
      y = y1 + (y2 - y1) * (rxMax - x1) / (x2 - x1);
      x = rxMax;
    } else {
      y = y1 + (y2 - y1) * (rxMin - x1) / (x2 - x1);
      x = rxMin;
    }

    if (ocOut == oc1) {
      x1 = x;
      y1 = y;
      oc1 = outcode(x1, y1);
    } else {
      x2 = x;
      y2 = y;
      oc2 = outcode(x2, y2);
    }
  }
}
