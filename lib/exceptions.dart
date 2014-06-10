part of ipaddr;

/// Exceptions are considered conditions that you can plan ahead for and catch.
/// Errors are conditions that you don’t expect or plan for.
/// Technically these should all be Exceptions I think, for now they follow the ipaddr error names.

class NetmaskValueError implements Exception {
  final String message;

  NetmaskValueError._(this.message);
  NetmaskValueError.invalidPrefixLength(prefixlen): this._(
      '$prefixlen is not a valid prefix length');
  NetmaskValueError.invalidNetmask(netmask): this._(
      '$netmask is not a valid netmask');

  String toString() => "NetmaskValueError: $message";
}

class ValueError extends Error {
  final String message;
  ValueError(this.message);
  String toString() => "ValueError: $message";
}

class IndexError extends Error {
  final String message;
  IndexError(this.message);
  String toString() => "IndexError: $message";
}

// TODO: can probably take the 2 things that don't
// compare and always give back the same message.
class VersionError extends Error {
  final String message;
  VersionError(this.message);
  String toString() => "VersionError: $message";
}

/**
 * Exception thrown when a string or some other data does not have an expected
 * format and cannot be parsed or processed.
 */
class AddressValueError implements Exception {
  final String message;

  AddressValueError(this.message);

  String toString() => "AddressValueError: $message";
}