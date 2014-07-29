This is a Dart port of [Google's Python IP address manipulation library](http://code.google.com/p/ipaddr-py/)

The test suite is also fully ported and passing with the excepton of tests for things 
noted below as unimplemented.

The following things are different from the Python version:

* Backwards compatibility is not supported for the old camel-case names 
  like CollapseAddrList, Contains, Subnet, Supernet, IsMulticast

* Exception names are changed because the Python version uses some built-in
  types that are also in dart but eg. don't take arguments or don't 
  mean the same thing.

* []/nth throws RangeError instead of IndexError

* everywhere there is an exception because of a 4/6 version conflict
  throws VersionError

* the Python version uses TypeError but Dart uses this for runtime type
  check failures.
  
* _get_networks_key is just _networks_key because it is a getter and 
  get _get_networks_key offends my taste buds

* Dart doesn't have some special class variables as Python does, so
  `__int__` is now `toInt()`
  `__hex__` is not implemented

The following are deficiencies to be addressed in future versions:
  
* It does not do bytes.

* get_mixed_type_key is not implemented so you currently can't sort a mixed list of 
  addresses and networks and it does not do mixed address comparisons.