#!/usr/bin/env dart

library ipaddr_lib_all_tests;

import 'ipv4_test.dart' as ipv4;
import 'ipv6_test.dart' as ipv6;

void main() {
  ipv4.main();
  ipv6.main();
}