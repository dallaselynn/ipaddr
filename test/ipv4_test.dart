#!/usr/bin/env dart

//Copyright 2013 Dallas Lynn
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

library ipv4_test;

import 'dart:mirrors';
import 'dart:math';
import 'package:unittest/unittest.dart';
import 'package:ipaddr/ipaddr.dart';

void main() {
  final throwsValueError = throwsA(new isInstanceOf<ValueError>());
  final throwsNetmaskValueError =
      throwsA(new isInstanceOf<NetmaskValueError>());
  final throwsTypeError = throwsA(new isInstanceOf<TypeError>());
  final throwsRangeError = throwsA(new isInstanceOf<RangeError>());
  final throwsVersionError = throwsA(new isInstanceOf<VersionError>());

  var ipv4 = new IPv4Network('1.2.3.4/24');
  var ipv4_hostmask = new IPv4Network('10.0.0.1/0.255.255.255');
  var ipv4_2 = new IPv4Address(1);

  test('Version and prefixlen gets set', () {
    expect(new IPv4Address(1).version, equals(4));
    expect(new IPv4Address(1).max_prefixlen, equals(32));
    expect(new IPv4Address(1).ALL_ONES, equals(4294967295));
    expect(new IPv4Network(1).version, equals(4));
    expect(new IPv4Network(1).max_prefixlen, equals(32));
    expect(new IPv4Network(1).ALL_ONES, equals(4294967295));
  });

  test('ints too small and large throw address value error', () {
    expect(() => new IPv4Address(-1),
        throwsA(new isInstanceOf<AddressValueError>()));
    expect(() => new IPv4Address(4294967296),
        throwsA(new isInstanceOf<AddressValueError>()));
  });

  test('takes string constructor', () {
    var i = new IPv4Address('0.0.0.1');
    expect(i.version, equals(4));
    expect(i.toInt(), equals(1));
  });

  test('throws on bad string constructor', () {
    expect(() => new IPv4Address(''),
        throwsA(new isInstanceOf<AddressValueError>()));
    expect(() => new IPv4Address('poop'),
        throwsA(new isInstanceOf<AddressValueError>()));
    expect(() => new IPv4Network('127.0.0.1/1/1'),
        throwsA(new isInstanceOf<AddressValueError>()));
  });

  test('string representation of IPv4 class', () {
    expect(new IPv4Network('1.2.3.4/32').toString(), equals('1.2.3.4/32'));
    expect(new IPv4Network('1.2.3.4').toString(), equals('1.2.3.4/32'));
  });

  test('automasking', () {
    var addr1 = new IPv4Network('1.1.1.255/24');
    var addr1_masked = new IPv4Network('1.1.1.0/24');
    expect(addr1_masked,
        equals(addr1.masked())); /// addr1.masked() == '1.1.1.0/24'
  });

  test('address integer math', () {
    expect(
        new IPv4Address('1.1.1.1') + 255, equals(new IPv4Address('1.1.2.0')));
    expect(
        new IPv4Address('1.1.1.1') - 256, equals(new IPv4Address('1.1.0.1')));
  });

  test('invalid strings', () {
    expect(() => IPAddress(''), throwsValueError);
    expect(() => IPAddress("016.016.016.016"), throwsValueError);
    expect(() => IPAddress("016.016.016"), throwsValueError);
    expect(() => IPAddress("016.016"), throwsValueError);
    expect(() => IPAddress("016"), throwsValueError);
    expect(() => IPAddress("000.000.000.000"), throwsValueError);
    expect(() => IPAddress("000"), throwsValueError);
    expect(() => IPAddress("0x0a.0x0a.0x0a.0x0a"), throwsValueError);
    expect(() => IPAddress("0x0a.0x0a.0x0a"), throwsValueError);
    expect(() => IPAddress("0x0a.0x0a"), throwsValueError);
    expect(() => IPAddress("0x0a"), throwsValueError);
    expect(() => IPAddress("42.42.42.42.42"), throwsValueError);
    expect(() => IPAddress("42.42.42"), throwsValueError);
    expect(() => IPAddress("42.42"), throwsValueError);
    expect(() => IPAddress("42"), throwsValueError);
    expect(() => IPAddress("42..42.42"), throwsValueError);
    expect(() => IPAddress("42..42.42.42"), throwsValueError);
    expect(() => IPAddress("42.42.42.42."), throwsValueError);
    expect(() => IPAddress("42.42.42.42..."), throwsValueError);
    expect(() => IPAddress(".42.42.42.42"), throwsValueError);
    expect(() => IPAddress("...42.42.42.42"), throwsValueError);
    expect(() => IPAddress("42.42.42.-0"), throwsValueError);
    expect(() => IPAddress("42.42.42.+0"), throwsValueError);
    expect(() => IPAddress("."), throwsValueError);
    expect(() => IPAddress("..."), throwsValueError);
    expect(() => IPAddress("bogus"), throwsValueError);
    expect(() => IPAddress("bogus.com"), throwsValueError);
    expect(() => IPAddress("192.168.0.1.com"), throwsValueError);
    expect(() => IPAddress("12345.67899.-54321.-98765"), throwsValueError);
    expect(() => IPAddress("257.0.0.0"), throwsValueError);
    expect(() => IPAddress("42.42.42.-42"), throwsValueError);

    expect(() => new IPv4Network(''),
        throwsA(new isInstanceOf<AddressValueError>()));
    expect(() => new IPv4Network('google.com'),
        throwsA(new isInstanceOf<AddressValueError>()));
    expect(() => new IPv4Network('::1.2.3.4'),
        throwsA(new isInstanceOf<AddressValueError>()));
    expect(() => new IPv4Network(['1.2.3.0']),
        throwsA(new isInstanceOf<AddressValueError>()));
    expect(() => new IPv4Network(['1.2.3.0', 24, 0]),
        throwsA(new isInstanceOf<AddressValueError>()));
  });

  test('get network', () {
    expect(ipv4.network.toInt(), equals(16909056));
    expect(ipv4.network.toString(), equals('1.2.3.0'));
    expect(ipv4_hostmask.network.toString(), equals('10.0.0.0'));
  });

  test('IP from int', () {
    expect(ipv4.ip, equals(new IPv4Network(16909060).ip));

    expect(() => new IPv4Network(-1),
        throwsA(new isInstanceOf<AddressValueError>()));
    expect(() => new IPv4Network(pow(2, 32)),
        throwsA(new isInstanceOf<AddressValueError>()));

    expect(
        IPNetwork('1.2.3.4'), equals(IPNetwork(IPNetwork('1.2.3.4').toInt())));
    expect(IPNetwork(ipv4.ip).version, equals(4));
  });

  test('get ip', () {
    expect(ipv4.ip.toInt(), equals(16909060));
    expect(ipv4.ip.toString(), equals('1.2.3.4'));
    expect(ipv4_hostmask.ip.toString(), equals('10.0.0.1'));
  });

  test('get netmask', () {
    expect(ipv4.netmask.toInt(), equals(4294967040));
    expect(ipv4.netmask.toString(), equals('255.255.255.0'));
    expect(ipv4_hostmask.netmask.toString(), '255.0.0.0');
  });

  test('zero netmask', () {
    var ipv4_zero_netmask = new IPv4Network('1.2.3.4/0');

    expect(ipv4_zero_netmask.netmask.toInt(), equals(0));
    //TODO: very annoying that you can't easily test private methods...
    //expect(ipv4_zero_netmask._prefix_from_prefix_string('0'), equals(0));
  });

  test('get broadcast', () {
    expect(ipv4.broadcast.toInt(), equals(16909311));
    expect(ipv4.broadcast.toString(), equals('1.2.3.255'));
  });

  test('get prefixlen', () {
    expect(ipv4.prefixlen, equals(24));
    expect(ipv4_hostmask.prefixlen, equals(8));
  });

  test('get supernet', () {
    expect(ipv4.supernet().prefixlen, equals(23));
    expect(ipv4.supernet().network.toString(), equals('1.2.2.0'));
    expect(new IPv4Network('0.0.0.0/0').supernet(),
        equals(new IPv4Network('0.0.0.0/0')));
  });

  test('get supernet3', () {
    expect(ipv4.supernet(prefixlen_diff: 3).prefixlen, equals(21));
    expect(
        ipv4.supernet(prefixlen_diff: 3).network.toString(), equals('1.2.0.0'));
  });

  test('get supernet4', () {
    expect(() => ipv4.supernet(prefixlen_diff: 2, new_prefix: 1),
        throwsValueError);
    expect(() => ipv4.supernet(new_prefix: 25), throwsValueError);
    expect(ipv4.supernet(prefixlen_diff: 2),
        equals(ipv4.supernet(new_prefix: 22)));
  });

  test('iter subnets', () {
    expect(ipv4.subnet(), equals(ipv4.iter_subnets().toList()));
  });

  test('iter hosts', () {
    var n = IPNetwork('2.0.0.0/31');
    expect(n.broadcast.toInt(), equals(33554433));
    expect(n.network.toInt(), equals(33554432));
    expect([
      new IPv4Address('2.0.0.0'),
      new IPv4Address('2.0.0.1')
    ], n.iterhosts().toList());
  });

  test('fancy subnetting', () {
    expect(ipv4.subnet(prefixlen_diff: 3).toList(),
        equals(ipv4.subnet(new_prefix: 27).toList()));
    expect(() => ipv4.subnet(new_prefix: 23), throwsValueError);
    expect(
        () => ipv4.subnet(prefixlen_diff: 3, new_prefix: 27), throwsValueError);
  });

  test('get subnet', () {
    expect(ipv4.subnet()[0].prefixlen, equals(25));
    expect(ipv4.subnet()[0].network.toString(), equals('1.2.3.0'));
    expect(ipv4.subnet()[1].network.toString(), equals('1.2.3.128'));
  });

  test('get subnet for single 32', () {
    var ip = new IPv4Network('1.2.3.4/32');
    var subnets1 = ip.subnet().map((n) => n.toString()).toList();
    var subnets2 =
        ip.subnet(prefixlen_diff: 2).map((n) => n.toString()).toList();

    expect(subnets1, equals(['1.2.3.4/32']));
    expect(subnets1, equals(subnets2));
  });

  test('get subnet2', () {
    var ips = ipv4.subnet(prefixlen_diff: 2).map((n) => n.toString()).toList();
    expect(ips,
        equals(['1.2.3.0/26', '1.2.3.64/26', '1.2.3.128/26', '1.2.3.192/26']));
  });

  test('subnet fails for large CIDR diff', () {
    expect(() => ipv4.subnet(prefixlen_diff: 9), throwsValueError);
  });

  test('supernet fails for large cidr diff', () {
    expect(() => ipv4.supernet(prefixlen_diff: 25), throwsValueError);
  });

  test('subnet fails for negative CIDR diff', () {
    expect(() => ipv4.subnet(prefixlen_diff: -1), throwsValueError);
  });

  test('get num hosts', () {
    expect(ipv4.numhosts, equals(256));
    expect(ipv4.subnet()[0].numhosts, equals(128));
    expect(ipv4.supernet().numhosts, 512);
  });

  test('contains', () {
    expect(ipv4.contains(new IPv4Network('1.2.3.128/25')), isTrue);
    expect(ipv4.contains(new IPv4Network('1.2.4.1/24')), isFalse);
    expect(ipv4.contains(ipv4), isTrue);
    expect(ipv4.contains(new IPv4Address('1.2.3.37')), isTrue);
    expect(
        new IPv4Network('1.1.0.0/16').contains(new IPv4Network('1.0.0.0/15')),
        isFalse);
  });

  test('bad address', () {
    expect(() => new IPv4Network('poop'),
        throwsA(new isInstanceOf<AddressValueError>()));
    expect(() => new IPv4Network('1.2.3.256'),
        throwsA(new isInstanceOf<AddressValueError>()));
    expect(() => new IPv4Network('1.2.3.4/32/24'),
        throwsA(new isInstanceOf<AddressValueError>()));
    expect(() => new IPv4Network('10/8'),
        throwsA(new isInstanceOf<AddressValueError>()));
  });

  test('good netmask ipv4', () {
    expect(new IPv4Network('192.0.2.0/255.255.255.0').toString(),
        equals('192.0.2.0/24'));
    for (var i in new Iterable.generate(33)) {
      // Generate and re-parse the CIDR format (trivial).
      var net_str = "0.0.0.0/$i";
      var net = new IPv4Network(net_str);
      expect(net.toString(), equals(net_str));

      // parse some 2 element List inputs
      expect(new IPv4Network([0, i]).toString(), equals(net_str));
      expect(new IPv4Network(['0.0.0.0', i]).toString(), equals(net_str));
      expect(new IPv4Network([new IPv4Address('0.0.0.0'), i]).toString(),
          equals(net_str));

      // generate and re-parse the expanded netmask
      expect(new IPv4Network('0.0.0.0/${net.netmask}').toString(),
          equals(net_str));

      // zero prefix treated as decimal
      expect(new IPv4Network('0.0.0.0/0$i').toString(), equals(net_str));

      // Generate and re-parse the expanded hostmask.  The ambiguous cases
      // (/0 and /32) are treated as netmasks.

      if ([0, 32].contains(i)) {
        net_str = '0.0.0.0/${32 - i}';
      }
      expect(new IPv4Network('0.0.0.0/${net.hostmask}').toString(),
          equals(net_str));
    }
  });

  test('bad netmask', () {
    expect(() => new IPv4Network('1.2.3.4/'), throwsNetmaskValueError);
    expect(() => new IPv4Network('1.2.3.4/-1'), throwsNetmaskValueError);
    expect(() => new IPv4Network(['1.2.3.4', -1]), throwsNetmaskValueError);
    expect(() => new IPv4Network('1.2.3.4/+1'), throwsNetmaskValueError);
    expect(() => new IPv4Network('1.2.3.4/0x1'), throwsNetmaskValueError);
    expect(() => new IPv4Network('1.2.3.4/33'), throwsNetmaskValueError);
    expect(() => new IPv4Network(['1.2.3.4', 33]), throwsNetmaskValueError);
    expect(() => new IPv4Network('1.2.3.4/254.254.255.256'),
        throwsNetmaskValueError);
    expect(
        () => new IPv4Network('1.1.1.1/240.255.0.0'), throwsNetmaskValueError);
    expect(() => new IPv4Network('1.1.1.1/255.254.128.0'),
        throwsNetmaskValueError);
    expect(
        () => new IPv4Network('1.1.1.1/0.1.127.255'), throwsNetmaskValueError);
    expect(() => new IPv4Network('1.2.3.4/1.a.2.3'), throwsNetmaskValueError);
    expect(() => new IPv4Network('1.1.1.1/::'), throwsNetmaskValueError);
    /// List constructors only accept integer prefixes at the moment
    expect(() => new IPv4Network(['0.0.0.0', '0']), throwsNetmaskValueError);
  });

  test('copy constructors', () {
    var v4addr = new BadStringIPv4Address('1.2.3.4');
    expect(v4addr.toString(), equals('<IPv4>'));
    expect(v4addr is IPv4Address, isTrue);
    expect(v4addr, equals(new IPv4Address(v4addr)));
  });

  test('nth', () {
    expect(ipv4[5].toString(), equals('1.2.3.5'));
    expect(() => ipv4[256], throwsRangeError);
  });

  test('get item', () {
    var addr = new IPv4Network('172.31.255.128/255.255.255.240');
    expect(addr.prefixlen, equals(28));
    var addr_list = addr.toList();

    expect('172.31.255.128', equals(addr_list[0].toString()));
    expect('172.31.255.128', equals(addr[0].toString()));
    expect('172.31.255.143', equals(addr[-1].toString()));
    // Dart doesn't support negative list indexing.
    //expect('172.31.255.143', equals(addr_list[-1].toString()));
    //expect(addr_list[-1], equals(addr[-1]));
  });

  test('equal', () {
    expect(ipv4, equals(new IPv4Network('1.2.3.4/24')));
    expect(ipv4 == new IPv4Network('1.2.3.4/23'), isFalse);
    expect(ipv4 == '', isFalse);
    expect(ipv4 == [], isFalse);
    expect(ipv4 == 2, isFalse);
    expect(IPNetwork('1.1.1.1/32'), equals(IPAddress('1.1.1.1')));
    expect(IPNetwork('1.1.1.1/24'), equals(IPAddress('1.1.1.1')));
    expect(IPNetwork('1.1.1.0/24') == IPAddress('1.1.1.1'), isFalse);
  });

  test('not equal', () {
    expect(ipv4 != new IPv4Network('1.2.3.4/24'), isFalse);
    expect(ipv4 != new IPv4Network('1.2.3.4/23'), isTrue);
    expect(ipv4 != '', isTrue);
    expect(ipv4 != [], isTrue);
    expect(ipv4 != 2, isTrue);
  });

  test('slash 32 constructor', () {
    expect(new IPv4Network('1.2.3.4/255.255.255.255').toString(),
        equals('1.2.3.4/32'));
  });

  test('slash 0 constructor', () {
    expect(new IPv4Network('1.2.3.4/0.0.0.0').toString(), equals('1.2.3.4/0'));
  });

  test('collapsing', () {
    // Test only IP addresses including some duplicates.
    var ip1 = new IPv4Address('1.1.1.0');
    var ip2 = new IPv4Address('1.1.1.1');
    var ip3 = new IPv4Address('1.1.1.2');
    var ip4 = new IPv4Address('1.1.1.3');
    var ip5 = new IPv4Address('1.1.1.4');
    var ip6 = new IPv4Address('1.1.1.0');

    // Check that addreses are subsumed properly.
    var collapsed = collapse_address_list([ip1, ip2, ip3, ip4, ip5, ip6]);
    expect(collapsed,
        equals([new IPv4Network('1.1.1.0/30'), new IPv4Network('1.1.1.4/32')]));

    // test a mix of IP addresses and networks including some duplicates
    ip1 = new IPv4Address('1.1.1.0');
    ip2 = new IPv4Address('1.1.1.1');
    ip3 = new IPv4Address('1.1.1.2');
    ip4 = new IPv4Address('1.1.1.3');
    ip5 = new IPv4Network('1.1.1.4/30');
    ip6 = new IPv4Network('1.1.1.4/30');
    // check that addreses are subsumed properly.
    collapsed = collapse_address_list([ip5, ip1, ip2, ip3, ip4, ip6]);
    expect(collapsed, equals([new IPv4Network('1.1.1.0/29')]));

    // test only IP networks
    ip1 = new IPv4Network('1.1.0.0/24');
    ip2 = new IPv4Network('1.1.1.0/24');
    ip3 = new IPv4Network('1.1.2.0/24');
    ip4 = new IPv4Network('1.1.3.0/24');
    ip5 = new IPv4Network('1.1.4.0/24');
    // stored in no particular order b/c we want CollapseAddr to call [].sort
    ip6 = new IPv4Network('1.1.0.0/22');
    // check that addreses are subsumed properly.
    collapsed = collapse_address_list([ip1, ip2, ip3, ip4, ip5, ip6]);
    expect(collapsed,
        equals([new IPv4Network('1.1.0.0/22'), new IPv4Network('1.1.4.0/24')]));

    // test that two addresses are supernet'ed properly
    collapsed = collapse_address_list([ip1, ip2]);
    expect(collapsed, equals([new IPv4Network('1.1.0.0/23')]));

    // test same IP networks
    var ip_same1 = new IPv4Network('1.1.1.1/32'),
        ip_same2 = new IPv4Network('1.1.1.1/32');
    expect(collapse_address_list([ip_same1, ip_same2]), equals([ip_same1]));

    // test same IP addresses
    ip_same1 = new IPv4Address('1.1.1.1');
    ip_same2 = new IPv4Address('1.1.1.1');
    expect(collapse_address_list([ip_same1, ip_same2]),
        equals([IPNetwork('1.1.1.1/32')]));
  });

  test('summarizing', () {
    var ip1 = IPAddress('1.1.1.0');
    var ip2 = IPAddress('1.1.1.255');

    var summary = summarize_address_range(ip1, ip2);
    var network = IPNetwork('1.1.1.0/24');

    expect(summary.first, equals(network));

    // test an  IPv4 range that isn't on a network byte boundary
    ip2 = IPAddress('1.1.1.8');
    expect(summarize_address_range(ip1, ip2),
        equals([IPNetwork('1.1.1.0/29'), IPNetwork('1.1.1.8')]));

    // test exception raised when first is greater than last
    // Python: ValueError
    expect(() =>
            summarize_address_range(IPAddress('1.1.1.0'), IPAddress('1.1.0.0')),
        throwsValueError);

    // test exception raised when first and last aren't IP addresses
    // Python: TypeError
    expect(() =>
            summarize_address_range(IPNetwork('1.1.1.0'), IPNetwork('1.1.0.0')),
        throwsVersionError);
  });

  test('address comparison', () {
    expect(new IPv4Address('1.1.1.1') <= new IPv4Address('1.1.1.1'), isTrue);
    expect(new IPv4Address('1.1.1.1') <= new IPv4Address('1.1.1.2'), isTrue);
  });

  test('network comparison', () {
    // ip1 and ip2 have the same network address
    var ip1 = new IPv4Network('1.1.1.0/24');
    var ip2 = new IPv4Network('1.1.1.1/24');
    var ip3 = new IPv4Network('1.1.2.0/24');

    expect(ip1 < ip3, isTrue);
    expect(ip3 > ip2, isTrue);

    expect(ip1.compare_networks(ip2), equals(0));
    expect(ip1.compare_networks(ip3), equals(-1));

    // Regression test for issue 19.
    ip1 = IPNetwork('10.1.2.128/25');
    expect(ip1 < ip1, isFalse);
    expect(ip1 > ip1, isFalse);

    ip2 = IPNetwork('10.1.3.0/24');

    expect(ip1 < ip2, isTrue);
    expect(ip2 < ip1, isFalse);
    expect(ip1 > ip2, isFalse);
    expect(ip2 > ip1, isTrue);

    ip3 = IPNetwork('10.1.3.0/25');

    expect(ip2 < ip3, isTrue);
    expect(ip3 < ip2, isFalse);
    expect(ip2 > ip3, isFalse);
    expect(ip3 > ip2, isTrue);

    //        # Regression test for issue 28.
    ip1 = IPNetwork('10.10.10.0/31');
    ip2 = IPNetwork('10.10.10.0');
    ip3 = IPNetwork('10.10.10.2/31');
    var ip4 = IPNetwork('10.10.10.2');

    var sorted = [ip1, ip2, ip3, ip4];
    var unsorted = [ip2, ip4, ip1, ip3];

    unsorted.sort((x, y) => x.compare_networks(y));
    expect(sorted, equals(unsorted));

    unsorted = [ip4, ip1, ip3, ip2];
    unsorted.sort((x, y) => x.compare_networks(y));
    expect(sorted, equals(unsorted));

    expect(() => ip1 < IPAddress('10.10.10.0'), throwsVersionError);
    expect(() => ip2 < IPAddress('10.10.10.0'), throwsVersionError);

    // <=, >=
    expect(IPNetwork('1.1.1.1') <= IPNetwork('1.1.1.1'), isTrue);
    expect(IPNetwork('1.1.1.1') <= IPNetwork('1.1.1.2'), isTrue);
    expect(IPNetwork('1.1.1.2') <= IPNetwork('1.1.1.1'), isFalse);
  });

  test('strict networks', () {
    expect(() => IPNetwork('192.168.1.1/24', strict: true), throwsValueError);
    expect(
        () => IPNetwork(['192.168.1.1', 24], strict: true), throwsValueError);
  });

  test('overlaps', () {
    var other = new IPv4Network('1.2.3.0/30');
    var other2 = new IPv4Network('1.2.2.0/24');
    var other3 = new IPv4Network('1.2.2.64/26');
    expect(ipv4.overlaps(other), isTrue);
    expect(ipv4.overlaps(other2), isFalse);
    expect(other2.overlaps(other3), isTrue);
  });

  test('ip version', () {
    expect(ipv4.version, equals(4));
  });

  test('max prefixlen length', () {
    expect(ipv4.max_prefixlen, equals(32));
  });

  test('IP type', () {
    var ipv4net = IPNetwork('1.2.3.4');
    var ipv4addr = IPAddress('1.2.3.4');

    expect(ipv4net.runtimeType, equals(IPv4Network));
    expect(ipv4addr.runtimeType, equals(IPv4Address));
  });

  test('reserved IPv4', () {
    // test networks
    expect(IPNetwork('224.1.1.1/31').is_multicast, isTrue);
    expect(IPNetwork('240.0.0.0').is_multicast, isFalse);
    expect(IPNetwork('192.168.1.1/17').is_private, isTrue);
    expect(IPNetwork('192.169.0.0').is_private, isFalse);
    expect(IPNetwork('10.255.255.255').is_private, isTrue);
    expect(IPNetwork('11.0.0.0').is_private, isFalse);
    expect(IPNetwork('172.31.255.255').is_private, isTrue);
    expect(IPNetwork('172.32.0.0').is_private, isFalse);

    expect(IPNetwork('169.254.100.200/24').is_link_local, isTrue);
    expect(IPNetwork('169.255.100.200/24').is_link_local, isFalse);
    expect(IPNetwork('127.100.200.254/32').is_loopback, isTrue);
    expect(IPNetwork('127.42.0.0/16').is_loopback, isTrue);
    expect(IPNetwork('128.0.0.0').is_loopback, isFalse);

    // test addresses
    expect(IPAddress('224.1.1.1').is_multicast, isTrue);
    expect(IPAddress('240.0.0.0').is_multicast, isFalse);

    expect(IPAddress('192.168.1.1').is_private, isTrue);
    expect(IPAddress('192.169.0.0').is_private, isFalse);
    expect(IPAddress('10.255.255.255').is_private, isTrue);
    expect(IPAddress('11.0.0.0').is_private, isFalse);
    expect(IPAddress('172.31.255.255').is_private, isTrue);
    expect(IPAddress('172.32.0.0').is_private, isFalse);

    expect(IPAddress('169.254.100.200').is_link_local, isTrue);
    expect(IPAddress('169.255.100.200').is_link_local, isFalse);

    expect(IPAddress('127.100.200.254').is_loopback, isTrue);
    expect(IPAddress('127.42.0.0').is_loopback, isTrue);
    expect(IPAddress('128.0.0.0').is_loopback, isFalse);
    expect(IPNetwork('0.0.0.0').is_unspecified, isTrue);
  });

  test('addr exclude', () {
    var addr1 = IPNetwork('10.1.1.0/24');
    var addr2 = IPNetwork('10.1.1.0/26');
    var addr3 = IPNetwork('10.2.1.0/24');
    var addr4 = IPAddress('10.1.1.0');

    expect(addr1.address_exclude(addr2),
        equals([IPNetwork('10.1.1.64/26'), IPNetwork('10.1.1.128/25')]));
    expect(() => addr1.address_exclude(addr3), throwsValueError);
    expect(() => addr1.address_exclude(addr4), throwsVersionError);
    expect(addr1.address_exclude(addr1), isEmpty);
  });

  test('hash', () {
    expect(IPNetwork('10.1.1.0/24').hashCode,
        equals(IPNetwork('10.1.1.0/24').hashCode));
    expect(
        IPAddress('10.1.1.0').hashCode, equals(IPAddress('10.1.1.0').hashCode));
    expect(IPAddress('1.2.3.4').hashCode,
        equals(IPAddress(IPAddress('1.2.3.4').toInt()).hashCode));

    var ip1 = IPAddress('10.1.1.0');

    var dummy = {};
    dummy[ipv4] = null;
    dummy[ip1] = null;

    expect(dummy.containsKey(ip1), isTrue);
  });

  test('copy constructor', () {
    var addr1 = IPNetwork('10.1.1.0/24');
    var addr2 = IPNetwork(addr1);
    var addr5 = new IPv4Address('1.1.1.1');

    expect(addr1, equals(addr2));
    expect(addr5, equals(new IPv4Address(addr5)));
  });

  test('int representation', () {
    expect(16909060, equals(ipv4.toInt()));
  });

  test('force version', () {
    expect(IPNetwork(1, version: 4).version, equals(4));
  });

  test('with_*', () {
    expect(ipv4.with_prefixlen, equals("1.2.3.4/24"));
    expect(ipv4.with_netmask, equals("1.2.3.4/255.255.255.0"));
    expect(ipv4.with_hostmask, equals("1.2.3.4/0.0.0.255"));
  });
}

/// test class with unparseable string representation
class BadStringIPv4Address extends IPv4Address {
  BadStringIPv4Address(address) : super(address);
  @override String toString() => '<IPv4>';
}
