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

library ipaddr;

import "dart:math" show pow;
import "dart:collection" show IterableMixin, UnmodifiableListView;

part 'exceptions.dart';
part 'ipaddr4.dart';
part 'ipaddr6.dart';

const int IPV4LENGTH = 32;
const int IPV6LENGTH = 128;
final Set DECIMAL_DIGITS =
    new Set.from(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']);
final Set HEXTET_DIGITS = new Set.from('0123456789ABCDEFabcdef'.split(''));

/**
 * Take a string or int [address] and return an instance of [IPv4Address] or [IPv6Address]
 *
 * If the version is given explicitly, that will be returned, otherwise it tries to
 * create an IPv4Address then an IPv6Address
 *
 * Failure throws a [ValueError]
 */

IPAddress(var address, {int version: null}) {
  if (version == 4) {
    return new IPv4Address(address);
  } else if (version == 6) {
    return new IPv6Address(address);
  }

  try {
    return new IPv4Address(address);
  } catch (AddressValueError, NetmaskValueError) {}

  try {
    return new IPv6Address(address);
  } catch (AddressValueError, NetmaskValueError) {}

  throw new ValueError(
      "$address does not appear to be an IPv4 or IPv6 address");
}

/**
 * Take a string or integer and return a [IPv4Network] or [IPv6Network]
 *
 * If the version is given explicitly, that will be returned, otherwise it tries to
 * create an IPv4Address then an IPv6Address
 *
 * Throws [ValueError] if passed a bad network address
 */

IPNetwork(var address, {version: null, strict: false}) {
  if (version == 4) {
    return new IPv4Network(address, strict: strict);
  } else if (version == 6) {
    return new IPv6Network(address, strict: strict);
  }

  try {
    return new IPv4Network(address, strict: strict);
  } catch (e) {}

  try {
    return new IPv6Network(address, strict: strict);
  } catch (e) {}

  throw new ValueError(
      "$address does not appear to be an IPv4 or IPv6 network");
}
