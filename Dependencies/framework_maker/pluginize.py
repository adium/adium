#!/usr/bin/env python
import sys
import os
import re
import dircache
import shutil

class OtoolParser:
  def __init__(self, otool_output):
    self.data = otool_output.split('\n')
    self._library_path = self.data[0][0:-1]
    self._library_name = self._library_path.split('/')[-1]
    useless_data = re.compile(r' \(.*\)')
    libs = [useless_data.sub('',x.lstrip()) for x in self.data[1:-1] 
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

  def third_party_shlib_deps(self):
    return self.third_libs

def otool_library(path, arch = None):
  command_str = 'otool -L '
  if arch:
    command_str += '-arch ' + arch + ' '
  command_str += path
  otool_file = os.popen(command_str)
  otool_data = otool_file.read()
  parser = OtoolParser(otool_data)
  return parser

def otool_library(lib):
  '''Runs otool on the library at lib.
  
  Returns an otool_parse.OtoolParser.
  '''
  otool_file = os.popen('otool -L "' + lib +'"')
  otool_data = otool_file.read()
  return OtoolParser(otool_data)

def discover_all_dependencies(lib):
  '''Find all dependencies for library at path in lib.
  
  Returns a list of paths.
  '''
  dep_parser = otool_library(lib)
  return dep_parser.third_party_shlib_deps()

def lib_path_to_framework_and_version(library_path):
  library_name = library_path.split('/')[-1]
  # check to see if it's a "versionless" library name
  match = re.match(r'[A-Za-z]*\.dylib', library_name)
  library_name = library_name.replace('.dylib','')
  if match:
    return (library_name, 'A')
  # Note: these styles are named after where I noticed them, not necessarily
  # where they originate. -RAF
  regexes = [r'([A-Za-z0-9_-]*)-([0-9\.]*)$', #apr style
             r'([A-Za-z0-9_-]*[a-zA-Z])\.([0-9\.]*)$', #gnu style
             r'([A-Za-z0-9_-]*[a-zA-Z])([0-9\.]*)$', #sqlite style
             ]
  for regex in regexes:
    match = re.match(regex, library_name)
    if match:
      return match.groups()
  
  # If we get here, we need a new regex. Throw an exception.
  raise ValueError, ('Library ' + library_path + ' with name ' + library_name +
                     ' did not match any known format, please update the'
                     ' script.')

if __name__ == '__main__':
  if len(sys.argv) < 3:
    print 'Usage:', sys.argv[0], '/paths/to/libraries', 'output_plugin_dir'
    sys.exit(1)

  plugins_dir = sys.argv[1]
  output_dir = sys.argv[1]

  known_frameworks = [d[0:len(d)-len(".subproj")] for d in dircache.listdir("Frameworks/") if d.endswith(".subproj")]

  plugins = [plugins_dir+'/'+d for d in dircache.listdir(plugins_dir) if d.endswith('.so')]
  for library in plugins:
	libs_to_convert = discover_all_dependencies(library)
	libs_to_convert.sort()

	new_paths = []
	for l in libs_to_convert:
		is_known_framework = 0
		for known_framework in known_frameworks:
			if l.find(known_framework + "-") != -1 or l.find(known_framework + ".") != -1:
				is_known_framework = 1
				break
		
		if is_known_framework:
			new_path = lib_path_to_framework_and_version(l)
			
			new_path = '@executable_path/../Frameworks/' + new_path[0] + '.framework/Versions/' + new_path[1] + '/' + new_path[0]
		else:
			pos = output_dir.find(".subproj/") + len(".subproj/")

			new_path = l.replace(plugins_dir, "@executable_path/../Frameworks/" + output_dir[pos:-1])

		args = ['install_name_tool', '-change', l, new_path, library]		
		status = os.spawnvp(os.P_WAIT, 'install_name_tool', args)
		
		if status != 0:
			print 'Something went wrong. install_name_tool failed for ', l,
			print ' with status ', status
			sys.exit(1)