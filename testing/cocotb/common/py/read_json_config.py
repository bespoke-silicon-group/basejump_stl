#!/usr/bin/env python

import os
import sys
import json

config_file = sys.argv[1]
act         = sys.argv[2]

#===========================================================
# Read the json file and do some minor pre-processing.
#===========================================================

json_lines = []
with open( config_file, 'r' ) as fid:
  for line in fid:
    striped_line = line.strip()
    if not striped_line.startswith('#'):
      json_lines.append(striped_line)

#===========================================================
# Convert the pre-processed json file to a python dict.
#===========================================================

cfg = json.loads('\n'.join(json_lines))

#===========================================================
# Query and print the requested data.
#===========================================================

# Print a space separated string of all test modules.
if act == 'test_modules':
  print(' '.join(cfg[act]))

# Print a space separated string of all files.
elif act == 'filelist':
  print(' '.join(cfg[act]))

# Print a space separated string of all include directories.
elif act == 'include':
  print(' '.join(cfg[act]))

# Print a space separated string of all simulator compilation arguments
elif act == 'compile_args':
  print(' '.join(cfg[act]))

# Print a space separated string of parameterizations. Each parameterization is
# in the form "name%k0=v0%k1=v1...". This string is a % delimited string. The
# first delimited item is the name of the run. This corresponds to the 'name'
# json field of the parameterization. If the name doesn't exist, one is
# generated based on the parameters. The rest of the delimited items are
# parameters with k# being the name of the #th parameter and v# being the value
# of the #th parameter.
elif act == 'psweep':
  final_result = []
  for p in cfg[act]:
    name = None
    p_list = []
    for k,v in p.items():
      if k == 'name':
        name = v
      else:
        p_list.append('%s=%s' % (k,v))
    if not name:
      name = '_'.join([i.replace('=', '') for i in p_list])
    final_result.append('%'.join([name] + p_list))
  print(' '.join(final_result))

# Anything else just grab from the dict and print it
else:
  print(cfg[act])

