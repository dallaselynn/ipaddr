#!/usr/bin/env dart
library ipv6_test;

import 'dart:math';
import 'package:unittest/unittest.dart';
import 'package:ipaddr/ipaddr.dart';

void main() {
  final throwsValueError = throwsA(new isInstanceOf<ValueError>());
  final throwsAddressValueError =
      throwsA(new isInstanceOf<AddressValueError>());
  final throwsNetmaskValueError =
      throwsA(new isInstanceOf<NetmaskValueError>());
  final throwsVersionError = throwsA(new isInstanceOf<VersionError>());

  var ipv6 = new IPv6Network('2001:658:22a:cafe:200:0:0:1/64');

  test('Auto Masking', () {
    var addr2 = new IPv6Network('2000:cafe::efac:100/96');
    var addr2_masked = new IPv6Network('2000:cafe::/96');
    expect(addr2_masked, equals(addr2.masked()));
  });

  test('address int math', () {
    expect(new IPv6Address('::1') + (pow(2, 16) - 2),
        equals(new IPv6Address('::ffff')));
    expect(new IPv6Address('::ffff') - (pow(2, 16) - 2),
        equals(new IPv6Address('::1')));
  });

  test('invalid strings', () {
    expect(() => IPAddress('3ffe::1.net'), throwsValueError);
    expect(() => IPAddress("3ffe::1::1"), throwsValueError);
    expect(() => IPAddress("1::2::3::4:5"), throwsValueError);
    expect(() => IPAddress("::7:6:5:4:3:2:"), throwsValueError);
    expect(() => IPAddress(":6:5:4:3:2:1::"), throwsValueError);
    expect(() => IPAddress("2001::db:::1"), throwsValueError);
    expect(() => IPAddress("FEDC:9878"), throwsValueError);
    expect(() => IPAddress("+1.+2.+3.4"), throwsValueError);
    expect(() => IPAddress("1.2.3.4e0"), throwsValueError);
    expect(() => IPAddress("::7:6:5:4:3:2:1:0"), throwsValueError);
    expect(() => IPAddress("7:6:5:4:3:2:1:0::"), throwsValueError);
    expect(() => IPAddress("9:8:7:6:5:4:3::2:1"), throwsValueError);
    expect(() => IPAddress("0:1:2:3::4:5:6:7"), throwsValueError);
    expect(() => IPAddress("3ffe:0:0:0:0:0:0:0:1"), throwsValueError);
    expect(() => IPAddress("3ffe::10000"), throwsValueError);
    expect(() => IPAddress("3ffe::goog"), throwsValueError);
    expect(() => IPAddress("3ffe::-0"), throwsValueError);
    expect(() => IPAddress("3ffe::+0"), throwsValueError);
    expect(() => IPAddress("3ffe::-1"), throwsValueError);
    expect(() => IPAddress(":"), throwsValueError);
    expect(() => IPAddress(":::"), throwsValueError);
    expect(() => IPAddress("::1.2.3"), throwsValueError);
    expect(() => IPAddress("::1.2.3.4.5"), throwsValueError);
    expect(() => IPAddress("::1.2.3.4:"), throwsValueError);
    expect(() => IPAddress("1.2.3.4::"), throwsValueError);
    expect(() => IPAddress("2001:db8::1:"), throwsValueError);
    expect(() => IPAddress(":2001:db8::1"), throwsValueError);
    expect(() => IPAddress(":1:2:3:4:5:6:7"), throwsValueError);
    expect(() => IPAddress("1:2:3:4:5:6:7:"), throwsValueError);
    expect(() => IPAddress(":1:2:3:4:5:6:"), throwsValueError);
    expect(() => IPAddress("192.0.2.1/32"), throwsValueError);
    expect(() => IPAddress("2001:db8::1/128"), throwsValueError);
    expect(() => IPAddress("02001:db8::"), throwsValueError);

    expect(() => new IPv6Network(''), throwsAddressValueError);
    expect(() => new IPv6Network('google.com'), throwsAddressValueError);
    expect(() => new IPv6Network('1.2.3.4'), throwsAddressValueError);
    expect(
        () => new IPv6Network('cafe:cafe::/128/190'), throwsAddressValueError);
    expect(() => new IPv6Network('1234:axy::b'), throwsAddressValueError);

    expect(() => new IPv6Address('1234:axy::b'), throwsAddressValueError);
    expect(() => new IPv6Address('2001:db8:::1'), throwsAddressValueError);
    expect(() => new IPv6Address('2001:888888::1'), throwsAddressValueError);
    expect(() => new IPv6Address(['2001:db8::']), throwsAddressValueError);
    expect(
        () => new IPv6Address(['2001:db8::', 32, 0]), throwsAddressValueError);
  });

  test('Get Network', () {
    expect(
        ipv6.network.toInt(), equals(42540616829182469433403647294022090752));
    expect(ipv6.network.toString(), equals('2001:658:22a:cafe::'));
    expect(ipv6.hostmask.toString(), equals('::ffff:ffff:ffff:ffff'));
  });

  test('Get IP From Int', () {
    var n = IPNetwork('2001:658:22a:cafe:200:0:0:1');

    expect(n, equals(IPNetwork(n.toInt())));

    int v6 = 42540616829182469433547762482097946625;

    expect(n.ip, equals(new IPv6Network(v6).ip));
    expect(() => new IPv6Network(pow(2, 128)), throwsAddressValueError);
    expect(() => new IPv6Network(-1), throwsAddressValueError);
    expect(IPNetwork(n.ip).version, equals(6));
  });

  test('Get IP', () {
    expect(ipv6.ip.toInt(), equals(42540616829182469433547762482097946625));
    expect(ipv6.ip.toString(), equals('2001:658:22a:cafe:200::1'));
  });

  test('Get Netmask', () {
    expect(
        ipv6.netmask.toInt(), equals(340282366920938463444927863358058659840));
    expect(ipv6.prefixlen, equals(64));
  });

  test('Zero Netmask', () {
    var ipv6_zero_netmask = new IPv6Network('::1/0');
    expect(ipv6_zero_netmask.netmask.toInt(), equals(0));
    //expect(ipv6_zero_netmask._prefix_from_prefix_string('0'), equals(0));
  });

  test('Get Broadcast', () {
    expect(
        ipv6.broadcast.toInt(), equals(42540616829182469451850391367731642367));
    expect(ipv6.broadcast.toString(),
        equals('2001:658:22a:cafe:ffff:ffff:ffff:ffff'));
  });

  test('Get Prefixlen', () {
    expect(ipv6.prefixlen, equals(64));
  });

  test('Get Supernet', () {
    expect(ipv6.supernet().prefixlen, equals(63));
    expect(ipv6.supernet().network.toString(), equals('2001:658:22a:cafe::'));
    expect(
        new IPv6Network('::0/0').supernet(), equals(new IPv6Network('::0/0')));
  });

  test('Get Supernet 3', () {
    expect(ipv6.supernet(prefixlen_diff: 3).prefixlen, equals(61));
    expect(ipv6.supernet(prefixlen_diff: 3).network.toString(),
        equals('2001:658:22a:caf8::'));
  });

  test('Get Supernet 4', () {
    expect(() => ipv6.supernet(prefixlen_diff: 2, new_prefix: 1),
        throwsValueError);
    expect(() => ipv6.supernet(new_prefix: 65), throwsValueError);
    expect(ipv6.supernet(prefixlen_diff: 2),
        equals(ipv6.supernet(new_prefix: 62)));
  });

  test('Iter Subnets', () {
    expect(ipv6.subnet(), equals(ipv6.iter_subnets().toList()));
  });

  test('Fancy Subnetting', () {
    expect(ipv6.subnet(prefixlen_diff: 4).toList(),
        equals(ipv6.subnet(new_prefix: 68).toList()));
    expect(() => ipv6.subnet(new_prefix: 63), throwsValueError);
    expect(
        () => ipv6.subnet(prefixlen_diff: 4, new_prefix: 68), throwsValueError);
  });

  test('Get Subnet', () {
    expect(ipv6.subnet()[0].prefixlen, equals(65));
  });

  test('get subnet for single 128', () {
    var ip = new IPv6Network('::1/128');
    var subnets1 = ip.subnet().map((n) => n.toString()).toList();
    var subnets2 =
        ip.subnet(prefixlen_diff: 2).map((n) => n.toString()).toList();

    expect(subnets1, equals(['::1/128']));
    expect(subnets1, equals(subnets2));
  });

  test('Subnet 2', () {
    var ipsv6 =
        ipv6.subnet(prefixlen_diff: 2).map((n) => n.toString()).toList();
    expect(ipsv6, equals([
      '2001:658:22a:cafe::/66',
      '2001:658:22a:cafe:4000::/66',
      '2001:658:22a:cafe:8000::/66',
      '2001:658:22a:cafe:c000::/66'
    ]));
  });

  test('subnet fails for large CIDR diff', () {
    expect(() => ipv6.subnet(prefixlen_diff: 65), throwsValueError);
  });

  test('supernet fails for large cidr diff', () {
    expect(() => ipv6.supernet(prefixlen_diff: 65), throwsValueError);
  });

  test('subnet fails for negative CIDR diff', () {
    expect(() => ipv6.subnet(prefixlen_diff: -1), throwsValueError);
  });

  test('get num hosts', () {
    expect(ipv6.numhosts, equals(18446744073709551616));
    expect(ipv6.subnet()[0].numhosts, equals(9223372036854775808));
    expect(ipv6.supernet().numhosts, equals(36893488147419103232));
  });

  test('contains', () {
    expect(ipv6.contains(ipv6), isTrue);
  });

  test('Bad Address', () {
    expect(() => new IPv6Network('poopv6'), throwsAddressValueError);
    expect(() => new IPv6Network('10/8'), throwsAddressValueError);
  });

  test('Good Netmask IPv6', () {
    expect(
        new IPv6Network('2001:db8::/32').toString(), equals('2001:db8::/32'));

    for (int i in new Iterable.generate(129)) {
      String net_str = '::/$i';
      expect(new IPv6Network(net_str).toString(), equals(net_str));

      /// Parse some 2-tuple inputs.
      expect(new IPv6Network([0, i]).toString(), equals(net_str));
      expect(new IPv6Network(['::', i]).toString(), equals(net_str));
      expect(new IPv6Network([new IPv6Address('::'), i]).toString(),
          equals(net_str));

      /// zero prefix is treated as decimal
      expect(new IPv6Network('::/0$i').toString(), equals(net_str));
    }
  });

  test('Bad Netmask', () {
    expect(() => new IPv6Network('::1/'), throwsNetmaskValueError);
    expect(() => new IPv6Network('::1/-1'), throwsNetmaskValueError);
    expect(() => new IPv6Network(['::1', '-1']), throwsNetmaskValueError);
    expect(() => new IPv6Network('::1/+1'), throwsNetmaskValueError);
    expect(() => new IPv6Network('::1/0x1'), throwsNetmaskValueError);
    expect(() => new IPv6Network('::1/129'), throwsNetmaskValueError);
    expect(() => new IPv6Network(['::1', '129']), throwsNetmaskValueError);
    expect(() => new IPv6Network('::1/1.2.3.4'), throwsNetmaskValueError);
    expect(() => new IPv6Network('::/::'), throwsNetmaskValueError);
    /// List constructors only accept integer prefixes at the moment
    expect(() => new IPv6Network(['::', '0']), throwsNetmaskValueError);
  });

  test('copy constructors', () {
    var v6addr = new BadStringIPv6Address('2001:db8::');
    expect(v6addr.toString(), equals('<IPv6>'));
    expect(v6addr, equals(new IPv6Address(v6addr)));
  });

  test('nth', () {
    expect(ipv6[5].toString(), equals('2001:658:22a:cafe::5'));
  });

  test('equal', () {
    expect(ipv6, equals(new IPv6Network('2001:658:22a:cafe:200::1/64')));
    expect(IPNetwork('::1/128'), equals(IPAddress('::1')));
    expect(IPNetwork('::1/127'), equals(IPAddress('::1')));
    expect(IPNetwork('::0/127') == IPAddress('::1'), isFalse);
    expect(ipv6 == new IPv6Network('2001:658:22a:cafe:200::1/63'), isFalse);
    expect(ipv6 == '', isFalse);
    expect(ipv6 == [], isFalse);
    expect(ipv6 == 2, isFalse);
  });

  test('not equal', () {
    expect(ipv6 != new IPv6Network('2001:658:22a:cafe:200::1/64'), isFalse);
    expect(ipv6 != new IPv6Network('2001:658:22a:cafe:200::1/63'), isTrue);
    expect(ipv6 != '', isTrue);
    expect(ipv6 != [], isTrue);
    expect(ipv6 != 2, isTrue);
  });

  test('Slash 128 Constructor', () {
    expect(new IPv6Network('::1/128').toString(), equals('::1/128'));
  });

  test('Collapsing', () {
    var ip1 = new IPv6Network('::2001:1/100');
    var ip2 = new IPv6Network('::2002:1/120');
    var ip3 = new IPv6Network('::2001:1/96');
    // test that ipv6 addresses are subsumed properly.
    var collapsed = collapse_address_list([ip1, ip2, ip3]);
    expect(collapsed, equals([ip3]));

    // the toejam test
    ip1 = IPAddress('1.1.1.1');
    ip2 = IPAddress('::1');

    expect(() => collapse_address_list([ip1, ip2]), throwsVersionError);
  });

  test('Summarizing', () {
    var ip1 = IPAddress('1::');
    var ip2 = IPAddress('1:ffff:ffff:ffff:ffff:ffff:ffff:ffff');
    // test a IPv6 is sumamrized properly
    expect(summarize_address_range(ip1, ip2)[0], equals(IPNetwork('1::/16')));

    // test an IPv6 range that isn't on a network byte boundary
    ip2 = IPAddress('2::');
    expect(summarize_address_range(ip1, ip2),
        equals([IPNetwork('1::/16'), IPNetwork('2::/128')]));

    expect(() => summarize_address_range(IPAddress('::'), IPNetwork('1.1.0.0')),
        throwsVersionError);
  });

  test('address comparison', () {
    expect(new IPv6Address('::1') <= new IPv6Address('::1'), isTrue);
    expect(new IPv6Address('::1') <= new IPv6Address('::2'), isTrue);
  });

  test('network comparison', () {
    var ip1 = new IPv6Network('2001::2000/96');
    var ip2 = new IPv6Network('2001::2001/96');
    var ip3 = new IPv6Network('2001:ffff::2000/96');

    expect(ip1 < ip3, isTrue);
    expect(ip3 > ip2, isTrue);

    expect(ip1.compare_networks(ip2), equals(0));
    expect(ip1.compare_networks(ip3), equals(-1));

    expect(IPNetwork('::1') <= IPNetwork('::1'), isTrue);
    expect(IPNetwork('::1') <= IPNetwork('::2'), isTrue);
    expect(IPNetwork('::2') <= IPNetwork('::1'), isFalse);
  });

  test('strict networks', () {
    expect(() => IPNetwork('::1/120', strict: true), throwsValueError);
    expect(() => IPNetwork(['::1', 120], strict: true), throwsValueError);
  });

  test('Embedded IPv4', () {
    var ipv4_string = '192.168.0.1';
    var ipv4 = new IPv4Network(ipv4_string);
    var v4compat_ipv6 = new IPv6Network('::$ipv4_string');
    expect(v4compat_ipv6.ip.toInt(), equals(ipv4.ip.toInt()));

    var v4mapped_ipv6 = new IPv6Network('::ffff:$ipv4_string');
    expect(v4mapped_ipv6.ip != ipv4.ip, isTrue);
    expect(
        () => new IPv6Network('2001:1.1.1.1:1.1.1.1'), throwsAddressValueError);
  });

  test('ip version', () {
    expect(ipv6.version, equals(6));
  });

  test('max prefixlen length', () {
    expect(ipv6.max_prefixlen, equals(128));
  });

  test('IP type', () {
    var ipv6net = IPNetwork('::1.2.3.4');
    var ipv6addr = IPAddress('::1.2.3.4');

    expect(ipv6net.runtimeType, equals(IPv6Network));
    expect(ipv6addr.runtimeType, equals(IPv6Address));
  });

  test('Reserved IPv6', () {
    expect(IPNetwork('ffff::').is_multicast, isTrue);
    expect(IPNetwork(pow(2, 128) - 1).is_multicast, isTrue);
    expect(IPNetwork('ff00::').is_multicast, isTrue);
    expect(IPNetwork('fdff::').is_multicast, isFalse);

    expect(IPNetwork('fecf::').is_site_local, isTrue);
    expect(IPNetwork('feff:ffff:ffff:ffff::').is_site_local, isTrue);
    expect(IPNetwork('fbf:ffff::').is_site_local, isFalse);
    expect(IPNetwork('ff00::').is_site_local, isFalse);

    expect(IPNetwork('fc00::').is_private, isTrue);
    expect(IPNetwork('fc00:ffff:ffff:ffff::').is_private, isTrue);
    expect(IPNetwork('fbff:ffff::').is_private, isFalse);
    expect(IPNetwork('fe00::').is_private, isFalse);

    expect(IPNetwork('fea0::').is_link_local, isTrue);
    expect(IPNetwork('febf:ffff::').is_link_local, isTrue);
    expect(IPNetwork('fe7f:ffff::').is_link_local, isFalse);
    expect(IPNetwork('fec0::').is_link_local, isFalse);

    expect(IPNetwork('0:0::0:01').is_loopback, isTrue);
    expect(IPNetwork('::1/127').is_loopback, isFalse);
    expect(IPNetwork('::').is_loopback, isFalse);
    expect(IPNetwork('::2').is_loopback, isFalse);

    expect(IPNetwork('0::0').is_unspecified, isTrue);
    expect(IPNetwork('::1').is_unspecified, isFalse);
    expect(IPNetwork('::/127').is_unspecified, isFalse);

    expect(IPAddress('ffff::').is_multicast, isTrue);
    expect(IPAddress(pow(2, 128) - 1).is_multicast, isTrue);
    expect(IPAddress('ff00::').is_multicast, isTrue);
    expect(IPAddress('fdff::').is_multicast, isFalse);

    expect(IPAddress('fecf::').is_site_local, isTrue);
    expect(IPAddress('feff:ffff:ffff:ffff::').is_site_local, isTrue);
    expect(IPAddress('fbf:ffff::').is_site_local, isFalse);
    expect(IPAddress('ff00::').is_site_local, isFalse);

    expect(IPAddress('fc00::').is_private, isTrue);
    expect(IPAddress('fc00:ffff:ffff:ffff::').is_private, isTrue);
    expect(IPAddress('fbff:ffff::').is_private, isFalse);
    expect(IPAddress('fe00::').is_private, isFalse);

    expect(IPAddress('fea0::').is_link_local, isTrue);
    expect(IPAddress('febf:ffff::').is_link_local, isTrue);
    expect(IPAddress('fe7f:ffff::').is_link_local, isFalse);
    expect(IPAddress('fec0::').is_link_local, isFalse);

    expect(IPAddress('0:0::0:01').is_loopback, isTrue);
    expect(IPAddress('::').is_loopback, isFalse);
    expect(IPAddress('::2').is_loopback, isFalse);

    expect(IPAddress('0::0').is_unspecified, isTrue);
    expect(IPAddress('::1').is_unspecified, isFalse);

    expect(IPAddress('100::').is_reserved, isTrue);
    expect(IPNetwork('4000::1/128').is_reserved, isTrue);
    expect(IPNetwork('fc00::').is_reserved, isFalse);
  });

  test('IPv4 Mapped', () {
    expect(IPAddress('::ffff:192.168.1.1').ipv4_mapped,
        equals(IPAddress('192.168.1.1')));
    expect(IPAddress('::c0a8:101').ipv4_mapped, equals(null));
    expect(IPAddress('::ffff:c0a8:101').ipv4_mapped,
        equals(IPAddress('192.168.1.1')));
  });

  test('hash', () {
    var ip = IPAddress('1::');
    var dummy = {};

    dummy[ipv6] = null;
    dummy[ip] = null;

    expect(dummy.containsKey(ip), isTrue);
  });

  test('copy constructor', () {
    var addr3 = IPNetwork('2001:658:22a:cafe:200::1/64');
    var addr4 = IPNetwork(addr3);
    var addr6 = new IPv6Address('2001:658:22a:cafe:200::1');

    expect(addr3, equals(addr4));
    expect(addr6, equals(new IPv6Address(addr6)));
  });

  test('Compress IPv6 Address', () {
    Map<String, String> test_addresses = {
      '1:2:3:4:5:6:7:8': '1:2:3:4:5:6:7:8/128',
      '2001:0:0:4:0:0:0:8': '2001:0:0:4::8/128',
      '2001:0:0:4:5:6:7:8': '2001::4:5:6:7:8/128',
      '2001:0:3:4:5:6:7:8': '2001:0:3:4:5:6:7:8/128',
      '0:0:3:0:0:0:0:ffff': '0:0:3::ffff/128',
      '0:0:0:4:0:0:0:ffff': '::4:0:0:0:ffff/128',
      '0:0:0:0:5:0:0:ffff': '::5:0:0:ffff/128',
      '1:0:0:4:0:0:7:8': '1::4:0:0:7:8/128',
      '0:0:0:0:0:0:0:0': '::/128',
      '0:0:0:0:0:0:0:0/0': '::/0',
      '0:0:0:0:0:0:0:1': '::1/128',
      '2001:0658:022a:cafe:0000:0000:0000:0000/66': '2001:658:22a:cafe::/66',
      '::1.2.3.4': '::102:304/128',
      '1:2:3:4:5:ffff:1.2.3.4': '1:2:3:4:5:ffff:102:304/128',
      '::7:6:5:4:3:2:1': '0:7:6:5:4:3:2:1/128',
      '::7:6:5:4:3:2:0': '0:7:6:5:4:3:2:0/128',
      '7:6:5:4:3:2:1::': '7:6:5:4:3:2:1:0/128',
      '0:6:5:4:3:2:1::': '0:6:5:4:3:2:1:0/128',
    };

    for (String uncompressed in test_addresses.keys) {
      String compressed = test_addresses[uncompressed];
      expect(compressed, equals(new IPv6Network(uncompressed).toString()));
    }
  });

  test('Explode ShortHand Ip Str', () {
    var addr1 = new IPv6Network('2001::1');
    var addr2 = new IPv6Address('2001:0:5ef5:79fd:0:59d:a0e5:ba1');

    expect(
        addr1.exploded, equals('2001:0000:0000:0000:0000:0000:0000:0001/128'));
    expect(new IPv6Network('::1/128').exploded,
        equals('0000:0000:0000:0000:0000:0000:0000:0001/128'));
    // issue 77
    expect(addr2.exploded, equals('2001:0000:5ef5:79fd:0000:059d:a0e5:0ba1'));
  });

  test('Int Representation', () {
    expect(ipv6.toInt(), equals(42540616829182469433547762482097946625));
  });

  test('Force Version', () {
    expect(IPNetwork(1, version: 6).version, equals(6));
  });

  test('With Star', () {
    expect(
        ipv6.with_prefixlen.toString(), equals('2001:658:22a:cafe:200::1/64'));
    expect(ipv6.with_netmask.toString(), equals('2001:658:22a:cafe:200::1/64'));
    expect(ipv6.with_hostmask.toString(),
        equals('2001:658:22a:cafe:200::1/::ffff:ffff:ffff:ffff'));
  });

  test('Teredo', () {
    var server = new IPv4Address('65.54.227.120');
    var client = new IPv4Address('192.0.2.45');
    var teredo_addr = '2001:0000:4136:e378:8000:63bf:3fff:fdd2';
    expect([server, client], equals(IPAddress(teredo_addr).teredo));
    String bad_addr = '2000::4136:e378:8000:63bf:3fff:fdd2';
    expect(IPAddress(bad_addr).teredo, isNull);
    bad_addr = '2001:0001:4136:e378:8000:63bf:3fff:fdd2';
    expect(IPAddress(bad_addr).teredo, isNull);

    teredo_addr = new IPv6Address('2001:0:5ef5:79fd:0:59d:a0e5:ba1');
    expect([
      new IPv4Address('94.245.121.253'),
      new IPv4Address('95.26.244.94')
    ], equals(teredo_addr.teredo));
  });

  test('Six to Four', () {
    var sixtofouraddr = IPAddress('2002:ac1d:2d64::1');
    var bad_addr = IPAddress('2000:ac1d:2d64::1');
    expect(new IPv4Address('172.29.45.100'), equals(sixtofouraddr.sixtofour));
    expect(bad_addr.sixtofour, isNull);
  });

  test('IPv6 Address Too Large', () {
    expect(new IPv6Address('::FFFF:192.0.2.1'),
        equals(new IPv6Address('::FFFF:c000:201')));
    expect(new IPv6Address('FFFF::192.0.2.1'),
        equals(new IPv6Address('FFFF::c000:201')));
  });
}

/// test class with unparseable string representation
class BadStringIPv6Address extends IPv6Address {
  BadStringIPv6Address(address) : super(address);
  @override String toString() => '<IPv6>';
}
