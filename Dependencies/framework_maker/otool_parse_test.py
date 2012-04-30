#!/usr/bin/env python
import unittest
import otool_parse

LIBSVN_WC = """/opt/svn/lib/libsvn_wc-1.0.dylib:
	/opt/svn/lib/libsvn_wc-1.0.dylib (compatibility version 1.0.0, current version 1.0.0)
	/opt/local/lib/libz.1.dylib (compatibility version 1.0.0, current version 1.2.3)
	/opt/svn/lib/libsvn_subr-1.0.dylib (compatibility version 1.0.0, current version 1.0.0)
	/opt/svn/lib/libsvn_delta-1.0.dylib (compatibility version 1.0.0, current version 1.0.0)
	/opt/svn/lib/libsvn_diff-1.0.dylib (compatibility version 1.0.0, current version 1.0.0)
	/opt/local/lib/libaprutil-1.0.dylib (compatibility version 3.0.0, current version 3.9.0)
	/opt/local/lib/libsqlite3.0.dylib (compatibility version 9.0.0, current version 9.6.0)
	/opt/local/lib/libexpat.1.dylib (compatibility version 7.0.0, current version 7.2.0)
	/opt/local/lib/libiconv.2.dylib (compatibility version 7.0.0, current version 7.0.0)
	/opt/local/lib/libapr-1.0.dylib (compatibility version 3.0.0, current version 3.9.0)
	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 88.3.9)
	/opt/local/lib/libintl.8.dylib (compatibility version 9.0.0, current version 9.1.0)
"""

class OtoolParserTest(unittest.TestCase):
  def test_third_party_shlibs(self):
    parser = otool_parse.OtoolParser(LIBSVN_WC)
    expected_shlibs = ['/opt/local/lib/libz.1.dylib',
                      '/opt/svn/lib/libsvn_subr-1.0.dylib',
                      '/opt/svn/lib/libsvn_delta-1.0.dylib',
                      '/opt/svn/lib/libsvn_diff-1.0.dylib',
                      '/opt/local/lib/libaprutil-1.0.dylib',
                      '/opt/local/lib/libsqlite3.0.dylib',
                      '/opt/local/lib/libexpat.1.dylib',
                      '/opt/local/lib/libiconv.2.dylib',
                      '/opt/local/lib/libapr-1.0.dylib',
                      '/opt/local/lib/libintl.8.dylib']
    actual_shlibs = parser.third_party_shlib_deps()
    expected_shlibs.sort()
    actual_shlibs.sort()
    self.assertEqual(expected_shlibs, actual_shlibs)
  
  def test_built_in_shlibs(self):
    expected_shlibs = ['/usr/lib/libSystem.B.dylib']
    parser = otool_parse.OtoolParser(LIBSVN_WC)
    actual_shlibs = parser.built_in_shlib_deps()
    expected_shlibs.sort()
    actual_shlibs.sort()
    self.assertEqual(expected_shlibs, actual_shlibs)
  
  def test_library_path(self):
    parser = otool_parse.OtoolParser(LIBSVN_WC)
    self.assertEqual('/opt/svn/lib/libsvn_wc-1.0.dylib',
                     parser.library_path())
  
  def test_library_name(self):
    parser = otool_parse.OtoolParser(LIBSVN_WC)
    self.assertEqual('libsvn_wc-1.0.dylib',
                     parser.library_name())
           
    
if __name__ == '__main__':
  unittest.main()
