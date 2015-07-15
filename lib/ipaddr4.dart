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

/**
 * Find a sequence of addresses
 *
 * [addresses] is a list of IPv4 or IPv6 addresses
 *
 * Returns an UnmodifiableListView with 2 elements - the first and last IP addresses
 * in the sequence
 */

_find_address_range(List <_BaseIP> addresses) {
  var first = addresses.first, last = addresses.first;
  for(var ip in addresses.getRange(1, addresses.length)) {
    if(ip._ip == last._ip + 1) {
      last = ip;
    } else {
      break;
    }
  }

  return new UnmodifiableListView([first, last]);
}


/**
 * Get the number of leading bits that are the same for two numbers.
 *
 * Takes two integers and the maximum number of bits to compare.
 *
 * Returns the number of leading bits that ar the same for two numbers.
 *
 */

int _get_prefix_length(int number1, int number2, int bits) {
  for(int i in new Iterable.generate(bits)) {
    if((number1 >> i) == (number2 >> i)) {
      return bits - i;
    }
  }

  return 0;
}


/**
 * Count the number of zero bits on the right hand side.
 *
 * [bits] is the maximum number of bits to count
 *
 * Returns the number of zero bits on the right hand side of [number]
 */

int _count_righthand_zero_bits(int number, int bits) {
  if(number == 0) {
    return bits;
  }

  for(var i in new Iterable.generate(bits)) {
    if((number >> i) % 2 > 0) {
      return i;
    }
  }
}


/**
 * Summarize a network range given the first and last IP addresses.

    Example:
        >>> summarize_address_range(IPv4Address('1.1.1.0'),
            IPv4Address('1.1.1.130'))
        [IPv4Network('1.1.1.0/25'), IPv4Network('1.1.1.128/31'),
        IPv4Network('1.1.1.130/32')]

    Args:
        first: the first IPv4Address or IPv6Address in the range.
        last: the last IPv4Address or IPv6Address in the range.

    Returns:
        The address range collapsed to a list of IPv4Network's or
        IPv6Network's.

    Raise:
        VersionError:
            If the first and last objects are not IP addresses.
            If the first and last objects are not the same version.
        ValueError:
            If the last object is not greater than the first.
            If the version is not 4 or 6.
*/

summarize_address_range(first, last) {
  if(first is! _BaseIP && last is! _BaseIP) {
    throw new VersionError('first and last must be IP addresses, not networks');
  }
  if(first.version != last.version) {
    throw new VersionError('$first and $last are not the same version');
  }
  if(first > last) {
    throw new ValueError('last IP address must be greater than the first');
  }

  var networks = [];
  var ip;

  int ip_bits = first.max_prefixlen;
  int first_ip = first._ip;
  int last_ip = last._ip;

  while(first_ip <= last_ip) {
    int nbits = _count_righthand_zero_bits(first_ip, ip_bits);
    int current = null;

    while(nbits >= 0) {
      int addend = pow(2, nbits) - 1;
      current = first_ip + addend;
      nbits -= 1;
      if(current <= last_ip) {
        break;
      }
    }

    int prefix = _get_prefix_length(first_ip, current, ip_bits);

    var net;
    if(first.version == 4) {
      net = new IPv4Network('$first/$prefix');
    } else if(first.version == 6) {
      net = new IPv6Network('$first/$prefix');
    } else {
      throw new ValueError('unknown IP version');
    }

    networks.add(net);
    if(current == net.ALL_ONES) {
      break;
    }

    first_ip = current + 1;
    first = IPAddress(first_ip, version:first.version);
  }

  return networks;
}


/**
 *
 * Loops through the addresses, collapsing concurrent netblocks.

    Example:

        ip1 = IPv4Network('1.1.0.0/24')
        ip2 = IPv4Network('1.1.1.0/24')
        ip3 = IPv4Network('1.1.2.0/24')
        ip4 = IPv4Network('1.1.3.0/24')
        ip5 = IPv4Network('1.1.4.0/24')
        ip6 = IPv4Network('1.1.0.1/22')

        _collapse_address_list_recursive([ip1, ip2, ip3, ip4, ip5, ip6]) ->
          [IPv4Network('1.1.0.0/22'), IPv4Network('1.1.4.0/24')]

        This shouldn't be called directly; it is called via
          collapse_address_list([]).

    Args:
        addresses: A list of IPv4Network's or IPv6Network's

    Returns:
        A list of IPv4Network's or IPv6Network's depending on what we were
        passed.
*/

_collapse_address_list_recursive(List<_BaseNet> addresses) {
  List<_BaseNet> ret_array = [];
  bool optimized = false;

  for(var cur_addr in addresses) {
    if(ret_array.isEmpty) {
      ret_array.add(cur_addr);
      continue;
    }
    if(ret_array.last.contains(cur_addr)) {
      optimized = true;
    } else if(cur_addr == ret_array.last.supernet().subnet()[1]) {
      ret_array.add(ret_array.removeLast().supernet());
      optimized = true;
    } else {
      ret_array.add(cur_addr);
    }
  }

  if(optimized) {
    return _collapse_address_list_recursive(ret_array);
  }

  return ret_array;
}


/**
 *
 * Collapse a list of IP objects.
 * Example:
 *  collapse_address_list([IPv4('1.1.0.0/24'), IPv4('1.1.1.0/24')]) ->
 *     [IPv4('1.1.0.0/23')]
 *
 * Args:
 *  addresses: A list of IPv4Network or IPv6Network objects.
 *
 * Returns:
 *   A list of IPv4Network or IPv6Network objects depending on what we
 *   were passed.
 *
 * Raises:
 *   TypeError: If passed a list of mixed version objects.
 */

collapse_address_list(List<dynamic> addresses) {
  int i = 0;
  var addrs = [], ips = [], nets = [];

  // split IP addresses and networks
  for(var ip in addresses) {
    if(ip is _BaseIP) {
      if(ips.isNotEmpty && ips.last.version != ip.version) {
        throw new VersionError("$ip and ${ips.last} are not of the same version");
      }
      ips.add(ip);
    } else if(ip.prefixlen == ip.max_prefixlen) {
      if(ips.isNotEmpty && ips.last.version != ip.version) {
        throw new VersionError("$ip and ${ips.last} are not of the same version");
      }
      ips.add(ip.ip);
    } else {
      if(nets.isNotEmpty && nets.last.version != ip.version) {
        throw new VersionError("$ip and ${ips.last} are not of the same version");
      }

      nets.add(ip);
    }
  }

  // sort and dedup
  ips = ips.toSet().toList();
  ips.sort((x,y) => x._ip.compareTo(y._ip));
  nets = nets.toSet().toList();
  nets.sort((x,y) => x.compare_networks(y));

  while(i < ips.length) {
    var range = _find_address_range(ips.sublist(i));
    var first = range[0], last = range[1];
    i = ips.indexOf(last) + 1;
    addrs.addAll(summarize_address_range(first, last));
  }

  addrs.addAll(nets);
  addrs.sort((x,y) => x.compare_networks(y));

  return _collapse_address_list_recursive(addrs);
}

abstract class _BaseV4 {
  final int ALL_ONES = pow(2, IPV4LENGTH) - 1;
  final int version = 4;
  final int max_prefixlen = IPV4LENGTH;

  int toInt() => _ip;

  /**
   *  Turn the given IP string into an integer for comparison.
   *
   *  [ip_str] is an IP, as a string
   *  raises [AddressValueError] if the string isn't a valid IPv4Address
   */

  int _ip_int_from_string(String ip) {
    List<String> octets = ip.split('.');
    if(octets.length != 4) {
      throw new AddressValueError(ip);
    }

    int packed_ip = 0;
    octets.forEach((oc) {
      try {
        packed_ip = (packed_ip << 8) | _parse_octet(oc);
      } catch(e) {
        throw new AddressValueError(ip);
      }
    });

    return packed_ip;
  }

  /**
   * Convert a decimal octet into an integer.
   *
   * [octet] is a string representing the number to parse
   * which is returned as an integer
   *
   * Raises [ValueError] if the octet isn't a decimal from 0 to 255
   */

  int _parse_octet(String octet) {
    /// In the Python version they check against the set of characters, "since int() allows a lot of bizarre stuff."
    /// Not sure if this is required in Dart of if we can just check if parse int succeeds.
    if(!DECIMAL_DIGITS.containsAll(octet.split(''))) {
      throw new ValueError('bad octet not in dd: $octet');
    }

    int octet_int = int.parse(octet, radix: 10);

    /// Disallow leading zeroes, because no clear standard exists on
    /// whether these should be interpreted as decimal or octal.
    if(octet_int > 255 || (octet.startsWith('0') && octet.length > 1)) {
      throw new ValueError('bad octet out of range: $octet');
    }

    return octet_int;
  }

  /**
     *  Turns a 32-bit integer into dotted decimal notation.
     *
     *  [ip] is an IP address in integer format
     *
     *  Returns a string of the IP in dotted decimal notation.
     */

    String _string_from_ip_int(int ip) {
      List octets = [];
      for(var _ in [1,2,3,4]) {
        octets.insert(0, (ip & 0xFF).toString());
        ip >>= 8;
      }

      return octets.join('.');
    }

    /**
     * Test if the address is otherwise IETF reserved.
     *
     * Returns true if the address is within the
     *   reserved IPv4 Network range.
     */
    bool get is_reserved => new IPv4Network('240.0.0.0/4').contains(this);

    /**
     * Test if this address is allocated for private networks.
     *
     * Returns true if the address is reserved per RFC 1918.
     */
    bool get is_private => (new IPv4Network('10.0.0.0/8').contains(this) ||
                            new IPv4Network('172.16.0.0/12').contains(this) ||
                            new IPv4Network('192.168.0.0/16').contains(this));

    /**
     * Test if the address is reserved for multicast use.
     *
     * Returns true if the address is multicast.
     * See RFC 3171 for details.
     */
    bool get is_multicast => new IPv4Network('224.0.0.0/4').contains(this);

    /**
     * Test if the address is unspecified.
     * Returns true if this is the unspecified address as defined in
     *  RFC 5735 3.
     */
    bool get is_unspecified => new IPv4Network('0.0.0.0').contains(this);


    /**
     * Test if the address is a loopback address.
     *
     * Returns true if the address is a loopback per RFC 3330.
     */
    bool get is_loopback => new IPv4Network('127.0.0.0/8').contains(this);

    /**
     * Test if the address is reserved for link-local.
     * Returns true if the address is link-local per RFC 3927.
     */
    bool get is_link_local => new IPv4Network('169.254.0.0/16').contains(this);

}


abstract class _BaseIP {
  // abstract instance members
  int get version;
  int get _ip;
  String _string_from_ip_int(ip_int);

  String toString() => _string_from_ip_int(_ip);
  bool operator ==(Object other) => (_ip == other._ip) && (version == other.version);

  // DIFFERENCE: Python version returns NotImplemented if other is not an int for +/-
  // integer add/sub not meant to support add/sub of addresses
  _BaseIP operator +(int other) => IPAddress((_ip + other), version: version);
  _BaseIP operator -(int other) => IPAddress(_ip - other, version:version);

  bool operator <=(_BaseIP other) => !(this > other);
  bool operator >=(_BaseIP other) => !(this < other);

  bool operator <(_BaseIP other) {
    if(version != other.version) {
      throw new VersionError('${this.toString()} and ${other.toString()} are not of the same version');
    }

    return _ip < other._ip;
  }

  bool operator >(_BaseIP other) {
    if(version != other.version) {
      throw new VersionError('');
    }

    return _ip > other._ip;
  }

  int get hashCode => _ip.toRadixString(16).hashCode;
}


abstract class _BaseNet {
  // abstract instance members
  // TODO: should be getters?  these are not really abstract.
  //int prefixlen, max_prefixlen, version;
  var ip, netmask;  // IPv4Address or IPv6Address
  int get ALL_ONES;
  Map<String, Object> _cache;
  int _ip_int_from_string(String ip_str);

  int get prefixlen;
  int get max_prefixlen;
  int get version;

  String toString() => "$ip/$prefixlen";
  int get hashCode => (network.toInt() ^ netmask.toInt()).hashCode;

  bool operator <(_BaseNet other) {
    if(version != other.version) {
      throw new VersionError('$this and $other are not of the same version');
    }

    if(!(other is _BaseNet)) {
      throw new VersionError('Networks can only be compared to each other');
    }
    
    if(network != other.network) {
      return network < other.network;
    }

    if(netmask != other.netmask) {
      return netmask < other.netmask;
    }

    return false;
  }

  bool operator >(_BaseNet other) {
    if(version != other.version) {
      throw new VersionError('$this and $other are not of the same version');
    }

    if(network != other.network) {
      return network > other.network;
    }

    if(netmask != other.netmask) {
      return netmask > other.netmask;
    }

    return false;
  }

  bool operator <=(_BaseNet other) => !(this > other);
  bool operator >=(_BaseNet other) => !(this < other);

  bool operator ==(Object other) {
    try {
      return (version == other.version) && (network == other.network) && (netmask.toInt() == other.netmask.toInt());
    } catch (e) {
      if(other is _BaseIP) {
        return (version == other.version) && (_ip == other._ip);
      } else {
        return false;
      }
    }
  }

  _BaseIP operator [](int n) {
    int network = this.network.toInt();
    int broadcast = this.broadcast.toInt();

    if(n >= 0) {
      if(network + n > broadcast) {
        throw new RangeError('');
      }
      return IPAddress(network + n, version:version);
    } else {
      n += 1;
      if(broadcast + n < network) {
        throw new RangeError('');
      }
      return IPAddress(broadcast + n, version:version);
    }
  }

  bool contains(var other) {
    // different versions never match
    if(version != other.version) {
      return false;
    }

    // other is a network
    if(other is _BaseNet) {
      return (network <= other.network && broadcast >= other.broadcast);
    } else {
      // other is an address
      return (network.toInt() <= other._ip && other._ip <= broadcast.toInt());
    }
  }

  // tell if this is partly contained in other.
  bool overlaps(_BaseNet other) {
    return (other.contains(network) || other.contains(broadcast) ||
        (this.contains(other.network) || this.contains(other.broadcast)));
  }

  _BaseIP get network {
    var x = _cache['network'];
    if(x == null) {
       x = IPAddress(_ip & netmask.toInt(), version:version);
       _cache['network'] = x;
    }

    return x;
  }

  _BaseIP get broadcast {
    var x = _cache['broadcast'];
    if(x == null) {
       x = IPAddress(_ip | hostmask.toInt(), version:version);
       _cache['broadcast'] = x;
    }

    return x;
  }

  _BaseIP get hostmask {
    var x = _cache['hostmask'];
    if(x == null) {
      x = IPAddress(netmask.toInt() ^ ALL_ONES, version:version);
      _cache['hostmask'] = x;
    }

    return x;
  }

  String get with_prefixlen => '$ip/$prefixlen';
  String get with_netmask => '$ip/$netmask';
  String get with_hostmask => '$ip/$hostmask';

  get numhosts => broadcast.toInt() - network.toInt() + 1;

  /**
   * Remove an address from a larger block.

  For example:

      addr1 = IPNetwork('10.1.1.0/24')
      addr2 = IPNetwork('10.1.1.0/26')
      addr1.address_exclude(addr2) =
          [IPNetwork('10.1.1.64/26'), IPNetwork('10.1.1.128/25')]

  or IPv6:

      addr1 = IPNetwork('::1/32')
      addr2 = IPNetwork('::1/128')
      addr1.address_exclude(addr2) = [IPNetwork('::0/128'),
          IPNetwork('::2/127'),
          IPNetwork('::4/126'),
          IPNetwork('::8/125'),
          ...
          IPNetwork('0:0:8000::/33')]

  Args:
      other: An IPvXNetwork object of the same type.

  Returns:
      A sorted list of IPvXNetwork objects addresses which is self
      minus other.

  Raises:
      TypeError: If self and other are of difffering address
        versions, or if other is not a network object.
      ValueError: If other is not completely contained by self.

  """
  */
  address_exclude(other) {
    if(version != other.version) {
      throw new VersionError("$this and $other are not of the same version");
    }

    if(other is! _BaseNet) {
      throw new VersionError("$other is not a network object");
    }

    if(!this.contains(other)) {
      throw new ValueError('$other not contained in $this');
    }

    if(other == this) {
      return [];
    }

    var ret_addrs = [];

    // Make sure we're comparing the network of other.
    other = IPNetwork('${other.network}/${other.prefixlen}', version:other.version);

    var range = this.subnet();
    var s1 = range[0], s2 = range[1];

    while(s1 != other && s2 != other) {
      if(s1.contains(other)) {
        ret_addrs.add(s2);
        range = s1.subnet();
        s1 = range[0];
        s2 = range[1];
      } else if(s2.contains(other)) {
        ret_addrs.add(s1);
        range = s2.subnet();
        s1 = range[0];
        s2 = range[1];
      } else {
        // If we got here, there's a bug somewhere.
        // Dart can't take assert messages yet.
        print('Error performing exclusion: s1: $s1 s2: $s2 other: $other');
        assert(false);
      }
    }

    if(s1 == other) {
      ret_addrs.add(s2);
    } else if(s2 == other) {
      ret_addrs.add(s1);
    } else {
      // If we got here, there's a bug somewhere.
      print('Error performing exclusion: s1: $s1 s2: $s2 other: $other');
      assert(false);
    }

    ret_addrs.sort((x,y) => x.compare_networks(y));
    return ret_addrs;
  }

  /**
   *
   Compare two IP objects.

   This is only concerned about the comparison of the integer
   representation of the network addresses.  This means that the
   host bits aren't considered at all in this method.  If you want
   to compare host bits, you can easily enough do a
   'HostA._ip < HostB._ip'

   Args:
       other: An IP object.

   Returns:
       If the IP versions of self and other are the same, returns:

       -1 if self < other:
         eg: IPv4('1.1.1.0/24') < IPv4('1.1.2.0/24')
         IPv6('1080::200C:417A') < IPv6('1080::200B:417B')
       0 if self == other
         eg: IPv4('1.1.1.1/24') == IPv4('1.1.1.2/24')
         IPv6('1080::200C:417A/96') == IPv6('1080::200C:417B/96')
       1 if self > other
         eg: IPv4('1.1.1.0/24') > IPv4('1.1.0.0/24')
         IPv6('1080::1:200C:417A/112') >
         IPv6('1080::0:200C:417A/112')

       If the IP versions of self and other are different, returns:

       -1 if self._version < other._version
         eg: IPv4('10.0.0.1/24') < IPv6('::1/128')
       1 if self._version > other._version
         eg: IPv6('::1/128') > IPv4('255.255.255.0/24')
   */

  int compare_networks(other) {
    if(version < other.version) {
      return -1;
    }

    if(version > other.version) {
      return 1;
    }

    if(network < other.network) {
      return -1;
    }

    if(network > other.network) {
      return 1;
    }

    if(netmask < other.netmask) {
      return -1;
    }

    if(netmask > other.netmask) {
      return 1;
    }

    return 0;
  }

  /**
   * Return prefix length from a bitwise netmask.
   *
   *  [ip]: An integer, the IP address, in expanded bitwise format.
   *  Returns the prefix length
   *  Raises [NetmaskValueError] if input is an invalid netmask.
   *
   */
  int _prefix_from_ip_int(int ip) {
    int prefixlen = max_prefixlen;
    while(prefixlen != 0) {
      if((ip & 1) != 0) {
        break;
      }
      ip >>= 1;
      prefixlen -= 1;
    }

    if(ip == (1 << prefixlen) -1) {
      return prefixlen;
    }

    throw new NetmaskValueError._('Bit pattern does not match /1*0*/');
  }


  /**
    * Turn a netmask/hostmask string into a prefix length.
    *
    * [ip_str] is a netmask or hostmask, formatted as an IP address
    *
    * Raise a [NetmaskValueError] if the input is not a netmask/hostmask
    *
    * Returns the prefix length as an integer.
    */
   int _prefix_from_ip_string(String ip_str) {
     int ip_int;
     try {
       ip_int = _ip_int_from_string(ip_str);
     } catch (AddressValueError) {
       throw new NetmaskValueError.invalidNetmask(ip_str);
     }

     try {
       return _prefix_from_ip_int(ip_int);
     } catch (NetmaskValueError) {}

     try {
       ip_int ^= ALL_ONES;
       return _prefix_from_ip_int(ip_int);
     } catch(Exception) {
       throw new NetmaskValueError.invalidNetmask(ip_str);
     }
   }

   /**
    * Turn a prefix length string into an integer.
    *
    * [prefixlen_str] is a decimal string containing the prefix length
    *
    * Raise a [NetmaskValueError] if the input malformed or out of range
    *
    */

   int _prefix_from_prefix_string(String prefixlen_str) {
     /// Again the digit check because of Python int() not sure if applies in Dart
     if(!DECIMAL_DIGITS.containsAll(prefixlen_str.split(''))) {
         throw new NetmaskValueError.invalidPrefixLength(prefixlen_str);
     }

     int prefixlen;
     try {
       prefixlen = int.parse(prefixlen_str);
     } catch(FormatException) {
       throw new NetmaskValueError.invalidPrefixLength(prefixlen_str);
     }

     if(!(0 <= prefixlen && prefixlen <= max_prefixlen)) {
       throw new NetmaskValueError.invalidPrefixLength(prefixlen_str);
     }

     return prefixlen;
   }

   /**
    *  Turn the prefix length netmask into a int for comparison.
    *
    *  [prefixlen]: An integer, the prefix length.
    */

   int _ip_int_from_prefix([int prefixlen]) {
     if(prefixlen == null) {
       prefixlen = prefixlen;
     }

     return ALL_ONES ^ (ALL_ONES >> prefixlen);
   }


   /* The subnets which join to make the current subnet.

   In the case that self contains only one IP
   (self.prefixlen == 32 for IPv4 or self.prefixlen == 128
   for IPv6), return a list with just ourself.

   Args:
       prefixlen_diff: An integer, the amount the prefix length
         should be increased by. This should not be set if
         new_prefix is also set.
       new_prefix: The desired new prefix length. This must be a
         larger number (smaller prefix) than the existing prefix.
         This should not be set if prefixlen_diff is also set.

   Returns:
       An iterator of IPv(4|6) objects.

   Raises:
       ValueError: The prefixlen_diff is too small or too large.
           OR
       prefixlen_diff and new_prefix are both set or new_prefix
         is a smaller number than the current prefix (smaller
         number means a larger network)
   */

   iter_subnets({int prefixlen_diff:1, int new_prefix:null}) {
     //TODO: move this test to the iterable/iterator so it returns a uniform thing instead
     // of a list here and SubnetIterable later.
     if(prefixlen == max_prefixlen) {
       return [this];
     }

     if(new_prefix != null) {
       if(new_prefix < prefixlen) {
         throw new ValueError('new prefix must be longer');
       }
       if(prefixlen_diff != 1) {
         throw new ValueError('cannot set prefixlen_diff and new_prefix');
       }
       prefixlen_diff = new_prefix - prefixlen;
     }

     if(prefixlen_diff < 0) {
       throw new ValueError('prefix length diff must be > 0');
     }

     int new_prefixlen = prefixlen + prefixlen_diff;

     if(new_prefixlen > max_prefixlen) {
       throw new ValueError('prefix length diff $new_prefixlen is invalid for netblock ${this.toString()}');
     }

     return new SubnetIterable(this, new_prefixlen);
   }

   subnet({prefixlen_diff:1, new_prefix:null}) => iter_subnets(prefixlen_diff:prefixlen_diff, new_prefix:new_prefix).toList();

  /*
   * The supernet containing the current network.
   * [prefixlen_diff] is the amount the prefix length of
   *  the network should be decreased by.  For example, given a
   * /24 network and a prefixlen_diff of 3, a supernet with a
   *  /21 netmask is returned.
   *
   * Raises [ValueError] If self.prefixlen - prefixlen_diff < 0.
   *  I.e., you have a negative prefix length.
   *  OR
   * If [prefixlen_diff] and [new_prefix] are both set or new_prefix is a
   *       larger number than the current prefix (larger number means a
   *       smaller network)
   */

   // The Python docstring claims it returns an IPv4Network object
   // but this is not true, it returns IPv6Network objects as well.
  _BaseNet supernet({int prefixlen_diff:1, int new_prefix}) {
    if(prefixlen == 0) {
      return this;
    }

    if(new_prefix != null) {
      if(new_prefix > prefixlen){
        throw new ValueError('new prefix must be shorter');
      }
      if(prefixlen_diff != 1) {
        throw new ValueError('cannot set prefixlen_diff and new_prefix');
      }

      prefixlen_diff = prefixlen - new_prefix;
    }

    if(prefixlen - prefixlen_diff < 0) {
      throw new ValueError('current prefixlen is $prefixlen, cannot have a prefixlen_diff of $prefixlen_diff');
    }

    return IPNetwork('$network/${prefixlen - prefixlen_diff}', version:version);
  }

  /// Return the network object with the host bits masked out
  masked() => IPNetwork('$network/$prefixlen', version:version);
}


class IPv4Address extends _BaseV4 with _BaseIP {
  int _ip;

  IPv4Address(address) {
    if(address is int) {
      this._ip = address;
      if(address < 0 || address > ALL_ONES) {
        throw new AddressValueError(address.toString());
      }
    //TODO: bytes input
    } else {
      this._ip = _ip_int_from_string(address.toString());
    }
  }
}

/**
 * Takes a network [network] and the network prefix
 * [new_prefixlen] and returns
 * IPv[4|6] Networks
 */

class SubnetIterator implements Iterator<_BaseNet> {
  final _BaseNet network;
  _BaseNet _cur, first;
  int new_prefixlen;

  SubnetIterator(network, new_prefixlen) :
    network = network
  {
    this.new_prefixlen = new_prefixlen;
    this.first = IPNetwork('${network.network}/$new_prefixlen');
  }

  _BaseNet get current => _cur;

  bool moveNext() {
    if(_cur == null) {
      _cur = first;
      return true;
    }

    var broadcast = _cur.broadcast;
    if(broadcast == network.broadcast) {
      return false;
    }

    var new_addr = IPAddress(broadcast.toInt() + 1, version:network.version);
    _cur = IPNetwork('$new_addr/$new_prefixlen', version:network.version);

    return true;
  }
}


class SubnetIterable extends IterableMixin<_BaseNet> {
  _BaseNet network;
  int new_prefixlen;
  SubnetIterable(this.network, this.new_prefixlen);
  Iterator<_BaseNet> get iterator => new SubnetIterator(network, new_prefixlen);
}


class NetworkIterator implements Iterator<_BaseIP> {
  int _cur;
  final int _network, _bcast, _version;

  NetworkIterator(int _network, int _bcast, int _version):
    _cur = _network,
    _network = _network,
    _bcast = _bcast,
    _version = _version;

  _BaseIP get current => IPAddress(_cur-1, version:_version);
  bool moveNext() {
    if(_cur <= _bcast) {
      _cur++;
      return true;
    }
    return false;
  }
}

class NetworkIterable extends Object with IterableMixin<_BaseIP> {
  final int _network, _broadcast, _version;
  NetworkIterable(this._network, this._broadcast, this._version);
  Iterator<_BaseIP> get iterator => new NetworkIterator(_network, _broadcast, _version);
}


class IPv4Network extends _BaseV4 with IterableMixin<_BaseIP>, _BaseNet {
  int _ip, prefixlen;
  IPv4Address ip, netmask;
  Map<String, Object> _cache = {};

  Iterator<_BaseIP> get iterator => new NetworkIterator(network.toInt(), broadcast.toInt(), version);

  /* Generate Iterator over usable hosts in a network.
   *
   * This is like iterator except it doesn't return the network
   * or broadcast addresses.
   *
   */
  iterhosts() {
    int n = prefixlen == max_prefixlen - 1 ? network.toInt() : network.toInt() + 1;
    int b = prefixlen == max_prefixlen - 1 ? broadcast.toInt() : broadcast.toInt() - 1;

    return new NetworkIterable(n, b, version);
  }

  IPv4Network(address, {bool strict: false}) {
    if(address is int) {
      this.ip = new IPv4Address(address);
      this._ip = ip._ip;
      this.prefixlen = max_prefixlen;
      this.netmask = new IPv4Address(ALL_ONES);
      return;
    }

    List<String> addr = address.toString().split('/');
    if(addr.length > 2) {
      throw new AddressValueError(address.toString());
    }

    this._ip = _ip_int_from_string(addr[0]);
    this.ip = new IPv4Address(_ip);

    if(addr.length == 2) {
      try {
        this.prefixlen = _prefix_from_prefix_string(addr[1]);
      } catch(NetmaskValueError) {
        this.prefixlen = _prefix_from_ip_string(addr[1]);
      }
    } else {
      this.prefixlen = max_prefixlen;
    }

    this.netmask = new IPv4Address(_ip_int_from_prefix(prefixlen));

    if(strict && (ip != network)) {
        throw new ValueError('$ip has host bits set');
    }
  }
}