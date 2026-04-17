class ExpectedCode {
  const ExpectedCode({required this.value, required this.formatName});

  final String value;

  /// Stored as a name (e.g. "qrCode", "ean13") rather than an enum index
  /// so that upgrades to `mobile_scanner` that reorder the `BarcodeFormat`
  /// enum don't silently invalidate saved codes.
  final String formatName;
}
