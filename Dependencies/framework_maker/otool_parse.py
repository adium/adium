#!/usr/bin/env python
import os
import re
import sys

class OtoolParser:
  def __init__(self, otool_output):
    self.data = otool_output.split('\n')
    self._library_path = self.data[0][0:-1]
    self._library_name = self._library_path.split('/')[-1]
    useless_data = re.compile(r' \(.*\)')
    libs = [useless_data.sub('',x.lstrip()) for x in self.data[2:-1] 
            if x.count('framework') == 0]
    self.base_libs = [x for x in libs if x.startswith('/usr/') and
                      x.endswith('dylib')]
    self.third_libs = [x for x in libs if x not in self.base_libs and
                       x.endswith('dylib')]
  
  def built_in_shlib_deps(self):
    return self.base_libs
    
  def library_path(self):
    return self._library_path
  
  def library_name(self):
    return self._library_name

  #def built_in_framework_deps(self):
  #  return None
  
  def third_party_shlib_deps(self):
    return self.third_libs
  
  #def third_party_framework_deps(self):
  #  return None

def otool_library(path, arch = None):
  command_str = 'otool -L '
  if arch:
    command_str += '-arch ' + arch + ' '
  command_str += path
  otool_file = os.popen(command_str)
  otool_data = otool_file.read()
  parser = OtoolParser(otool_data)
  return parser
  
if __name__ == '__main__':
  if len(sys.argv) != 2:
    print 'Usage:', sys.argv[0], '/path/to/library.dylib'
    sys.exit(1)
  parser = otool_library(sys.argv[1])
  print 'Library name:', parser.library_name()
  print 'Library path:', parser.library_path()
  print 'Non-base shlib dependencies:'
  for lib in parser.third_party_shlib_deps():
    print '  ' + lib
