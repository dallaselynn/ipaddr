# ipaddr

ipaddr is a Dart port of
[Google's ipaddr library](http://code.google.com/p/ipaddr-py/)
which is described as:
"An IPv4/IPv6 manipulation library in Python. This library is used to
create/poke/manipulate IPv4 and IPv6 addresses and prefixes."

Currently up to date with ipaddr-py's revision 669c0368e3e4ad5dbfd611640b461018592436b2

## Installation

Via pub in the usual way.

## Documentation

API docs here: 

## Tests

The test suite for all implemented functionality is fully ported.

To run the tests you can open it in Dart Editor and run `all_tests.dart`
to test everything or `ipv4_test.dart` or `ipv6_test.dart` individually.

From the command line you can do from the top-level project directory:
`dart test/all_tests.dart`


## Overview

Typically you just need one of the two top-level functions `IPAddress` or
`IPNetwork` which take a numeric or string argument and return an
`IPv4Address` or `IPv6Address` or an `IPv4Network` or `IPv6Network`, respectively.

## Examples

```dart
import 'package:ipaddr/ipaddr.dart';

/// top-level functions
var ip = IPAddress('1.2.3.4');
var network = IPNetwork('1.2.3.4/24');

/// or use the class directly if you like
IPv4Network v4\_net = new IPv4Network('1.2.3.4/24');
IPv6Network v6\_net = new IPv6Network('::2001:1/100');

/// can also use ints to construct
IPv4Address ipv4 = new IPv4Address(16909060)
IPv6Address ipv6 = new IPv6Address(1);
```

# Incompatibilities with the Python version

The following things are different from the Python version, usually because
Python built-in Exception types or class operators are used that mean something
else in Dart, or because Javascript.

* Backwards compatibility is not supported for the old camel-case names 
  like CollapseAddrList, Contains, Subnet, Supernet, IsMulticast

* []/nth throws RangeError instead of IndexError

* everywhere there is an exception because of a 4/6 version conflict
  throws VersionError

* the Python version uses TypeError but Dart uses this for runtime type
  check failures.
  
* `_get_networks_key` is just `_networks_key` because it is a getter and 
  `get _get_networks_key` offends my taste buds

* Dart doesn't have some special class variables as Python does, so
  `__int__` is now `toInt()`
  `__hex__` is not implemented

* It does not currently do bytes.

* `get_mixed_type_key` is not implemented so you currently can't sort a mixed list of 
  addresses and networks and it does not do mixed address comparisons.

* Recently the ability to construct from tuples was added to the Python version,
  this is not supported yet.
  

# IPv6
IPv6 support is fully implemented in the Dart version.
