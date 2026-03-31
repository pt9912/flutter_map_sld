/// A GeoServer `<VendorOption>` key-value pair.
///
/// Vendor options are server-specific configuration parameters attached to
/// symbolizers. The model is intentionally decoupled from any specific
/// symbolizer type so it can be reused across `RasterSymbolizer`, `Rule`,
/// `UserStyle`, etc. in the future.
class VendorOption {
  const VendorOption({
    required this.name,
    required this.value,
  });

  /// The option name (from the `name` attribute).
  final String name;

  /// The option value (text content of the element).
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorOption && name == other.name && value == other.value;

  @override
  int get hashCode => Object.hash(name, value);
}
