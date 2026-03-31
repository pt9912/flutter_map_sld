/// An OGC expression that can be evaluated against feature properties.
sealed class Expression {
  const Expression();

  /// Evaluates this expression against the given [properties].
  dynamic evaluate(Map<String, dynamic> properties);
}

/// A reference to a feature attribute by name.
final class PropertyName extends Expression {
  const PropertyName(this.name);

  /// The property/attribute name.
  final String name;

  @override
  dynamic evaluate(Map<String, dynamic> properties) => properties[name];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PropertyName && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// A constant literal value.
final class Literal extends Expression {
  const Literal(this.value);

  /// The literal value (typically a String or num).
  final dynamic value;

  @override
  dynamic evaluate(Map<String, dynamic> properties) => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Literal && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
