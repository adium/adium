#!/usr/bin/env python
'''This module provides functions that shell out to install_name_tool to perform
black magic on dylibs and make them universal.
'''

import os
import sys

import otool_parse

LIPO_BINARY_NAME = 'lipo'
CREATE_FLAG = '-create'
ARCH_FLAG = '-arch'
OUTPUT_FLAG = '-output'

INSTALL_NAME_TOOL = 'install_name_tool'

# TODO(durin42) this function is begging to be refactored into lipo_files and
# find_and_replace_on_files, but I just need to get this into the repo.
def lipo_files(source_files, replace_paths, target_file):
  '''Collect the files located at the paths to the target path using lipo.
  
  Args: source_files: dict of arch:source file (single arch per source only)
        replace_paths: dict of replacements. Will replace any path or path
          fragment in shared library load paths. Key is replaced with value.
        target_file: target path
  
  Returns: nothing.
  '''
  args = [LIPO_BINARY_NAME, CREATE_FLAG, ]
  for arch, source in source_files.items():
    args.append(ARCH_FLAG)
    args.append(arch)
    args.append(source)
  args.append(OUTPUT_FLAG)
  args.append(target_file)
  status = os.spawnvp(os.P_WAIT, LIPO_BINARY_NAME, args)
  if status != 0:
    print 'The following command failed:'
    print ' '.join(args)
    sys.exit(status)
  
  # Gather all the third party deps, we don't want to replace paths to system
  # deps anyway.
  info = otool_parse.otool_library(target_file, 'i386')
  all_third_libs = info.third_party_shlib_deps()
  info = otool_parse.otool_library(target_file, 'ppc')
  all_third_libs.extend(info.third_party_shlib_deps())
  
  # run install_name_tool to change the file's own path
  args = [INSTALL_NAME_TOOL, '-id', target_file, target_file]
  status = os.spawnvp(os.P_WAIT, INSTALL_NAME_TOOL, args)
  if status != 0:
    print 'The following command failed:'
    print ' '.join(args)
    sys.exit(status)
  # Do find-and-replace on third-party lib paths using install_name_tool
  for old_path, new_path in replace_paths.items():
    for lib_path in all_third_libs:
      if old_path in lib_path:
        path_new = lib_path.replace(old_path, new_path)
        args = [INSTALL_NAME_TOOL, '-change', lib_path, path_new, target_file]
        status = os.spawnvp(os.P_WAIT, INSTALL_NAME_TOOL, args)
        if status != 0:
          print 'The following command failed:'
          print ' '.join(args)
          sys.exit(status)

def _print_usage():
  print 'Usage:', sys.argv[0], 'arch:/path/to/old_lib.dylib', 
  print 'arch:/path/to/old_lib.dylib', '/path/to_new.dylib',
  print '[oldpath:newpath] [oldpath:newpath]'
  print
  print 'You MUST pass full paths - partial ones will create malformed libs.'
  print 'You may pass partial paths for the replacements.'

if __name__ == '__main__':
  if len(sys.argv) < 3:
    _print_usage()
  replacement_arr = sys.argv[1:]
  platform_libs = {}
  for arg in sys.argv[1:]:
    replacement_arr.remove(arg)
    if arg.count(':') == 0:
      target_file = arg
      break
    arch, lib = arg.split(':')
    platform_libs[arch] = lib

  replacements = {}
  for repl in replacement_arr:
    old, new = repl.split(':')
    replacements[old] = new
  lipo_files(platform_libs, replacements, target_file)
