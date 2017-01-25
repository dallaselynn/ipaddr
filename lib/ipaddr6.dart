part of ipaddr;

/**
 *  Base IPv6 object.  Used by [IPv6Address] and [Ipv6Network]
 */

abstract class _BaseV6 {
  final int ALL_ONES = pow(2, IPV6LENGTH) - 1;
  final int HEXTET_COUNT = 8;
  final int _version = 6;
  final int max_prefixlen = IPV6LENGTH;

  int get version => _version;
  int toInt() => _ip;

  /**
   * Turn an IPv6 ip_str into an integer.
   *
   * [ip_str] is an IPv6 string, which is returned as a BigInteger
   *
   * Raises [AddressValueError] if [ip_str] isn't a valid IPv6 Address.
   */

  int _ip_int_from_string(String ip_str) {
    List<String> parts = ip_str.split(':');

    // An IPv6 address needs at least 2 colons (3 parts).
    if (parts.length < 3) {
      throw new AddressValueError(ip_str);
    }

    // If the address has an IPv4-style suffix, convert it to hexadecimal.
    if (parts.last.contains('.')) {
      int ipv4 = new IPv4Address(parts.removeLast())._ip;
      parts.add('${((ipv4 >> 16) & 0xFFFF).toRadixString(16)}');
      parts.add('${(ipv4 & 0xFFFF).toRadixString(16)}');
    }

    // An IPv6 address can't have more than 8 colons (9 parts).
    if (parts.length > HEXTET_COUNT + 1) {
      throw new AddressValueError(ip_str);
    }

    // Disregarding the endpoints, find '::' with nothing in between.
    // This indicates that a run of zeroes has been skipped
    // if there is more than 1 empty string there was a problem.
    if (parts.getRange(1, parts.length - 1).where((x) => x == '').length > 1) {
      // Can't have more than one '::'
      throw new AddressValueError(ip_str);
    }

    int parts_hi, parts_lo, parts_skipped;

    int skip_index =
        parts.sublist(1, parts.length - 1).indexOf(''); // -1 == None
    skip_index += 1; // set to its index in the actual list not the sublist...

    // parts_hi is the number of parts to copy from above/before the '::'
    // parts_lo is the number of parts to copy from below/after the '::'
    if (skip_index != 0) {
      // If we found a '::', then check if it also covers the endpoints.
      parts_hi = skip_index;
      parts_lo = parts.length - skip_index - 1;

      if (parts.first == '') {
        parts_hi -= 1;
        if (parts_hi != 0) {
          throw new AddressValueError(ip_str); // ^: requires ^::
        }
      }

      if (parts.last == '') {
        parts_lo -= 1;
        if (parts_lo != 0) {
          throw new AddressValueError(ip_str); // :$ requires ::$
        }
      }

      parts_skipped = HEXTET_COUNT - (parts_hi + parts_lo);
      if (parts_skipped < 1) {
        throw new AddressValueError(ip_str);
      }
    } else {
      // Otherwise, allocate the entire address to parts_hi.  The endpoints
      // could still be empty, but _parse_hextet() will check for that.
      if (parts.length != HEXTET_COUNT) {
        throw new AddressValueError(ip_str);
      }

      parts_hi = parts.length;
      parts_lo = 0;
      parts_skipped = 0;
    }

    // Now, parse the hextets into a 128-bit integer.
    try {
      int ip_int = 0;

      for (int i in new Iterable.generate(parts_hi)) {
        ip_int <<= 16;
        ip_int |= _parse_hextet(parts[i]);
      }

      ip_int <<= (16 * parts_skipped);

      // Python has negative indexing but Iterable.generate
      // just returns empty with a negative count instead of
      // counting up to 0.  We want everything from [-parts_lo to the end]
      for (String part in parts.sublist(parts.length - parts_lo)) {
        ip_int <<= 16;
        ip_int |= _parse_hextet(part);
      }

      return ip_int;
    } on ValueError {
      throw new AddressValueError(ip_str);
    }
  }

  /**
   * Convert an IPv6 hextet string into an integer.
   *
   * [hextet] is the number to parse.
   *
   * Returns the hextet as an integer.
   *
   * Raises ValueError: if the input isn't strictly a hex number from [0..FFFF].
   */

  int _parse_hextet(String hextet) {
    if (!HEXTET_DIGITS.containsAll(hextet.split(''))) {
      throw new ValueError('bad hextet: $hextet');
    }

    try {
      int hextet_int = int.parse(hextet, radix: 16);
    } on FormatException {
      throw new ValueError('can not parse hex integer from $hextet');
    }

    if (hextet.length > 4) {
      throw new ValueError('$hextet too long');
    }

    int hextet_int = int.parse(hextet, radix: 16);
    if (hextet_int > 0xFFFF) {
      throw new ValueError('$hextet_int out of range');
    }

    return hextet_int;
  }

  /**
   * Compresses a list of hextets.
   *
   * Compresses a list of strings, replacing the longest continuous
   * sequence of "0" in the list with "" and adding empty strings at
   * the beginning or at the end of the string such that subsequently
   * calling ":".join(hextets) will produce the compressed version of
   * the IPv6 address.
   *
   * hextets are the hextets to compress.
   */

  List<String> _compress_hextets(List<String> hextets) {
    int best_doublecolon_start = -1;
    int best_doublecolon_len = 0;
    int doublecolon_start = -1;
    int doublecolon_len = 0;

    for (int index in new Iterable.generate(hextets.length)) {
      if (hextets[index] == '0') {
        doublecolon_len += 1;
        if (doublecolon_start == -1) {
          // start of sequence of zeroes
          doublecolon_start = index;
        }

        if (doublecolon_len > best_doublecolon_len) {
          // This is the longest sequence of zeros so far.
          best_doublecolon_len = doublecolon_len;
          best_doublecolon_start = doublecolon_start;
        }
      } else {
        doublecolon_len = 0;
        doublecolon_start = -1;
      }
    }

    if (best_doublecolon_len > 1) {
      int best_doublecolon_end =
          (best_doublecolon_start + best_doublecolon_len);
      //  for zeroes at the end of the address
      if (best_doublecolon_end == hextets.length) {
        hextets.add('');
      }
      hextets.replaceRange(best_doublecolon_start, best_doublecolon_end, ['']);
      if (best_doublecolon_start == 0) {
        hextets.insert(0, '');
      }
    }

    return hextets;
  }

  /**
   * Turns a 128-bit integer into hexadecimal notation.
   *
   * ip_int is the IP address as an integer
   *
   * Returns the hexadecimal representation of the address.
   *
   * Raises ValueError if The address is bigger than 128 bits of all ones.
   */

  String _string_from_ip_int(int ip_int) {
    if (ip_int == null) {
      ip_int = _ip;
    }

    if (ip_int > ALL_ONES) {
      throw new ValueError('IPv6 address is too large');
    }

    /*
     * hex_str should be 32 length string representation like so:
     * 00000000000000000000000000000001
     * Go through it 4 characters at a time and cast to hex value,
     * append then compress to the hextets list.
     */

    String hex_str = ip_int.toRadixString(16).padLeft(32, '0');
    List<String> hextets = [];

    for (int x in [0, 4, 8, 12, 16, 20, 24, 28]) {
      hextets.add(
          int.parse(hex_str.substring(x, x + 4), radix: 16).toRadixString(16));
    }

    return _compress_hextets(hextets).join(':');
  }

  /**
   * Expand a shortened IPv6 address and return
   * the expanded version.
   */

  String _explode_shorthand_ip_string() {
    String ip_str;
    if (this is _BaseNet) {
      ip_str = ip.toString();
    } else {
      ip_str = this.toString();
    }

    int ip_int = _ip_int_from_string(ip_str);
    List<String> parts = [];

    for (int i in new Iterable.generate(HEXTET_COUNT)) {
      parts.add('${(ip_int & 0xFFFF).toRadixString(16).padLeft(4, '0')}');
      ip_int >>= 16;
    }

    parts = parts.reversed.toList();
    if (this is _BaseNet) {
      return '${parts.join(':')}/$prefixlen';
    }

    return parts.join(':');
  }

  String get exploded => _explode_shorthand_ip_string();

  /**
    * Test if the address is reserved for multicast use.
    *
    * See RFC 2373 2.7 for details.
    */
  bool get is_multicast => new IPv6Network('ff00::/8').contains(this);

  /**
   * Test if the address is otherwise IETF reserved.
   *
   * Returns true if the address is within one of the
   * reserved IPv6 Network ranges.
   */
  bool get is_reserved {
    final Set reserved = new Set.from([
      '::/8',
      '100::/8',
      '200::/7',
      '400::/6',
      '800::/5',
      '1000::/4',
      '4000::/3',
      '6000::/3',
      '8000::/3',
      'A000::/3',
      'C000::/3',
      'E000::/4',
      'F000::/5',
      'F800::/6',
      'FE00::/9'
    ]);

    return reserved.any((e) => new IPv6Network(e).contains(this));
  }

  /*
   * Test if the address is unspecified.
   * returns true if this is the unspecified address as defined in
   * RFC 2373 2.5.2.
   */
  bool get is_unspecified {
    // Python does getattr(self, 'prefixlen', 128) Dart has no elegant version
    int p;
    try {
      p = prefixlen;
    } catch (NoSuchMethodError) {
      p = 128;
    }

    return _ip == 0 && p == 128;
  }

  /**
    * Test if the address is a loopback address.
    * Returns true if the address is a loopback address as defined in
    * RFC 2373 2.5.3.
    */
  bool get is_loopback {
    int p;
    try {
      p = prefixlen;
    } catch (NoSuchMethodError) {
      p = 128;
    }

    return _ip == 1 && p == 128;
  }

  /**
    * Test if the address is reserved for link-local.
    * Returns true if the address is reserved per RFC 4291.
    */
  bool get is_link_local => new IPv6Network('fe80::/10').contains(this);

  /**
    * Test if the address is reserved for site-local.
    *
    *    Note that the site-local address space has been deprecated by RFC 3879.
    *    Use is_private to test if this address is in the space of unique local
    *    addresses as defined by RFC 4193.
    *
    *    Returns true if the address is reserved per RFC 3513 2.5.6.
    */
  bool get is_site_local => new IPv6Network('fec0::/10').contains(this);

  /**
    * Test if this address is allocated for private networks.
    * Returns true if the address is reserved per RFC 4193.
    */
  bool get is_private => new IPv6Network('fc00::/7').contains(this);

  /**
   * Return the IPv4 mapped address
   *
   * If the IPv6 Address is a v4 mapped address return the IPv4 mapped address
   * otherwise return null
   */
  get ipv4_mapped =>
      ((_ip >> 32) != 0xFFFF) ? null : new IPv4Address(_ip & 0xFFFFFFFF);

  /**
   * Tuple of embedded teredo IPs.
   *
   * Returns UnmodifiableListView of the (server, client) IPs or null if the
   * address doesn't appear to be a teredo address (doesn't start with
   * 2001::/32)
   */
  get teredo {
    if ((_ip >> 96) != 0x20010000) {
      return null;
    }

    return new UnmodifiableListView([
      new IPv4Address((_ip >> 64) & 0xFFFFFFFF),
      new IPv4Address(~_ip & 0xFFFFFFFF)
    ]);
  }

  /**
   * Return the IPv4 6to4 embedded address or null if the address
   * doesn't appear to contain a 6to4 embedded address.
   */
  get sixtofour => ((_ip >> 112) != 0x2002)
      ? null
      : new IPv4Address((_ip >> 80) & 0xFFFFFFFF);
}

class IPv6Address extends Object with _BaseV6, _BaseIP {
  int _ip;

  IPv6Address(var address) {
    if (address is int) {
      this._ip = address;
      if (address < 0 || address > ALL_ONES) {
        throw new AddressValueError(address.toString());
      }
      return;
    }

    if (address is IPv6Address) {
      this._ip = address._ip;
      return;
    }

    // TODO: bytes

    // Assume input argument to be string or any object representation
    // which converts into a formatted IP string.
    String addr_str = address.toString();

    this._ip = _ip_int_from_string(addr_str);
  }
}

class IPv6Network extends _BaseV6 with IterableMixin<_BaseIP>, _BaseNet {
  int _ip, prefixlen;
  IPv6Address ip, netmask;
  Map<String, Object> _cache = {};

  Iterator<_BaseIP> get iterator =>
      new NetworkIterator(network.toInt(), broadcast.toInt(), version);

  /* Generate Iterator over usable hosts in a network.
   *
   * This is like iterator except it doesn't return the network
   * or broadcast addresses.
   *
   */
  iterhosts() {
    int n =
        prefixlen == max_prefixlen - 1 ? network.toInt() : network.toInt() + 1;
    int b = prefixlen == max_prefixlen - 1
        ? broadcast.toInt()
        : broadcast.toInt() - 1;

    return new NetworkIterable(n, b, version);
  }

  IPv6Network(var address, {strict: false}) {
    if (address is int || address is IPv6Address) {
      this.ip = new IPv6Address(address);
      this._ip = ip._ip;
      this.prefixlen = max_prefixlen;
      this.netmask = new IPv6Address(ALL_ONES);
      return;
    }

    if (address is List) {
      if (address.length != 2) {
        throw new AddressValueError(address);
      }

      this.ip = new IPv6Address(address[0]);
      this._ip = this.ip._ip;
      this.prefixlen = _prefix_from_prefix_int(address[1]);
    } else {
      //  Assume input argument to be string or any object representation
      //  which converts into a formatted IP prefix string.
      List<String> addr = address.toString().split('/');

      if (addr.length > 2) {
        throw new AddressValueError(address);
      }

      this._ip = _ip_int_from_string(addr[0]);
      this.ip = new IPv6Address(this._ip);

      if (addr.length == 2) {
        this.prefixlen = _prefix_from_prefix_string(addr[1]);
      } else {
        this.prefixlen = max_prefixlen;
      }
    }

    this.netmask = new IPv6Address(_ip_int_from_prefix(prefixlen));

    if (strict) {
      if (ip != network) {
        throw new ValueError('$ip has host bits set');
      }
    }
  }

  String get with_netmask => with_prefixlen;
}
