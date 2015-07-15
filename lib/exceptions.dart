//   Copyright 2013 Dallas Lynn
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

part of ipaddr;

/// Exceptions are considered conditions that you can plan ahead for and catch.
/// Errors are conditions that you don’t expect or plan for.
/// Technically these should all be Exceptions I think, for now they follow the ipaddr error names.

class NetmaskValueError implements Exception {
  final String message;

  NetmaskValueError._(this.message);
  NetmaskValueError.invalidPrefixLength(prefixlen)
      : this._('$prefixlen is not a valid prefix length');
  NetmaskValueError.invalidNetmask(netmask)
      : this._('$netmask is not a valid netmask');

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
