import unittest

import frameworkize

TESTS = [('/opt/local/lib/libapr-1.0.dylib'   , ('libapr', '1.0')),
         ('/opt/local/lib/libaprutil-1.0.dylib' , ('libaprutil', '1.0')),
         ('/opt/local/lib/libexpat.1.dylib'   , ('libexpat', '1')),
         ('/opt/local/lib/libiconv.2.dylib'   , ('libiconv', '2')),
         ('/opt/local/lib/libintl.8.dylib'    , ('libintl', '8')),
         ('/opt/local/lib/libsqlite3.0.dylib'   , ('libsqlite', '3.0')),
         ('/opt/local/lib/libz.1.dylib'     , ('libz', '1')),
         ('/opt/svn/lib/libsvn_delta-1.0.dylib' , ('libsvn_delta', '1.0')),
         ('/opt/svn/lib/libsvn_diff-1.0.dylib'  , ('libsvn_diff', '1.0')),
         ('/opt/svn/lib/libsvn_subr-1.0.dylib'  , ('libsvn_subr', '1.0')),
         ('/opt/svn/lib/libsvn_wc-1.0.dylib'  , ('libsvn_wc', '1.0')),
         ('/opt/local/lib/libintl.dylib'    , ('libintl', 'A')),
        ]


class FrameworkNamingTest(unittest.TestCase):
  def test_naming(self):
    for path, expected_result in TESTS:
      self.assertEqual(frameworkize.lib_path_to_framework_and_version(path), 
                       expected_result)
    self.assertRaises(ValueError, 
                      frameworkize.lib_path_to_framework_and_version, '&&&')

if __name__ == '__main__':
  unittest.main()
