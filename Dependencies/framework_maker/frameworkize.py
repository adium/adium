#!/usr/bin/env python
import otool_parse

import sys
import os
import re
import dircache
import shutil

def otool_library(lib):
  '''Runs otool on the library at lib.
  
  Returns an otool_parse.OtoolParser.
  '''
  otool_file = os.popen('otool -L "' + lib +'"')
  otool_data = otool_file.read()
  return otool_parse.OtoolParser(otool_data)

def recursively_discover_all_dependencies(lib):
  '''Recursively find all dependencies for library at path in lib.
  
  Returns a list of paths.
  '''
  libraries = dict([(l,1) for l in lib])
  old_libraries = {}
  while libraries != old_libraries:
    old_libraries = libraries.copy()
    for lib in libraries.keys():
      dep_parser = otool_library(lib)
      for dep in dep_parser.third_party_shlib_deps():
        libraries[dep] = 1
  return old_libraries.keys()

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
    print 'Usage:', sys.argv[0], '/paths/to/libraries.dylib', 'output_dir'
    sys.exit(1)
  output_dir = sys.argv[-1]
  libs_to_convert = sys.argv[1:-1]
  libs_to_convert = recursively_discover_all_dependencies(libs_to_convert)
  libs_to_convert.sort()
  framework_names_and_versions = [lib_path_to_framework_and_version(l) for l 
                  in libs_to_convert]
  framework_names = [lib[0] for lib in framework_names_and_versions]
  framework_versions = [lib[1] for lib in framework_names_and_versions]
  
  framework_names_with_path = ['@executable_path/../Frameworks/' + l[0]
          + '.framework/Versions/' + l[1] +'/' + l[0] for l 
          in framework_names_and_versions]
  
  rlinks_fw_line = ('--rlinks_framework=[' + ' '.join(libs_to_convert)
            + ']:[' + ' '.join(framework_names_with_path) + ']')
  
  for lib,name,version in zip(libs_to_convert, framework_names, 
                framework_versions):
    #execute rtool a crapton of times
    header_path = '/'.join(lib.split('/')[0:-1]) + '/include/' + name
    if version != '' and version != 'A':
      header_path += '-'+version
    try:
      header_path = ' '.join([header_path+'/'+h for h in 
                              dircache.listdir(header_path)])
    except OSError, e:
      # the directory didn't exist, we don't care.
      pass
    args = ['rtool',
            '--framework_root=@executable_path/../Frameworks',
            '--framework_name='+name,
            '--framework_version='+version,
            '--library='+lib,
            '--builddir='+output_dir,
            '--headers='+header_path,
            '--headers_no_root',
            rlinks_fw_line,
             ]
    status = os.spawnvp(os.P_WAIT, 'rtool', args)
    if status != 0:
      print 'Something went wrong. rtool failed for ', lib,
      print ' with status ', status
      sys.exit(1)

  directories_to_visit = [output_dir+'/'+d for d in dircache.listdir(output_dir)
                          if d.endswith('.frwkproj')]
  for direct in directories_to_visit:
    frameworks = [direct+'/'+f for f in dircache.listdir(direct) if
                  f.endswith('.framework')]
    for f in frameworks:
      f_new = output_dir+'/'+f.split('/')[-1]
      try:
        shutil.rmtree(f_new)
      except Exception, e:
        pass
      shutil.move(f, f_new)
    shutil.rmtree(direct)
