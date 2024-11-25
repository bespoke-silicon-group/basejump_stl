#!/usr/bin/python
# example file that invokes memory generator to generate SRAM collatoral
#

import os
import sys
import stat
import json
from patch_memgen import patch_memgen

#===============================================================================
# main()
#===============================================================================

def main():

  # Read json config file
  memgen_cfg = patch_memgen(sys.argv[1])

  matching_mems = [memory for memory in memgen_cfg['memories'] if memory['name'] == sys.argv[2]]

  if len(matching_mems) == 1:

    mem = matching_mems[0]

    # Optional entries in the json file (default to none)
    banks  = mem['banks']  if 'banks'  in mem else None
    slices = mem['slices'] if 'slices' in mem else None
    mvt    = mem['mvt'] if 'mvt' in mem else "BASE"

    # Generate files
    gen_spec_file( mem['name'], mem['width'], mem['depth'], mem['mux'], mem['mask'], mem['type'], banks, slices, mvt)
    gen_lib_to_db_file( mem['name'] )
    gen_hcell_file( mem['name'] )
    gen_run_me_file( mem['name'], mem['type'] )

  else:
    print('Error: found %d memories matching name %s!' % (len(matching_mems), sys.argv[2]))
    sys.exit(1)

#===============================================================================
# gen_spec_file( name, width, depth, mux, mask, banks, slices )
#===============================================================================

def gen_spec_file( name, width, depth, mux, mask, type, banks, slices, mvt):

  ### PVT Corners
  corners = []
  #corners.append( 'ffa_sigcmin_0p66v_0p88v_125c' )
  #corners.append( 'ffa_sigcmin_0p66v_0p88v_m40c' )
  #corners.append( 'ffa_sigcmin_0p77v_0p88v_125c' )
  #corners.append( 'ffa_sigcmin_0p77v_0p88v_m40c' )
  corners.append( 'ffa_sigcmin_0p88v_0p88v_125c' )
  corners.append( 'ffa_sigcmin_0p88v_0p88v_m40c' )
  #corners.append( 'ffa_sigcmin_0p945v_0p945v_125c' )
  #corners.append( 'ffa_sigcmin_0p945v_0p945v_m40c' )
  #corners.append( 'nn_nominal_0p60v_0p80v_25c' )
  #corners.append( 'nn_nominal_0p70v_0p80v_25c' )
  corners.append( 'nn_nominal_0p80v_0p80v_25c' )
  #corners.append( 'nn_nominal_0p90v_0p90v_25c' )
  #corners.append( 'ssa_sigcmax_0p54v_0p72v_125c' )
  #corners.append( 'ssa_sigcmax_0p54v_0p72v_m40c' )
  #corners.append( 'ssa_sigcmax_0p63v_0p72v_125c' )
  #corners.append( 'ssa_sigcmax_0p63v_0p72v_m40c' )
  corners.append( 'ssa_sigcmax_0p72v_0p72v_125c' )
  corners.append( 'ssa_sigcmax_0p72v_0p72v_m40c' )
  #corners.append( 'ssa_sigcmax_0p81v_0p81v_125c' )
  #corners.append( 'ssa_sigcmax_0p81v_0p81v_m40c' )

  ### Configuration Flags
  with open('memory.spec', 'w') as fid:
    fid.write( 'instname = %s\n'        % name                           )  ;# [string] the name of the memory instance
    fid.write( 'words = %d\n'           % depth                          )  ;# [int] number of words (memory depth)
    fid.write( 'bits = %d\n'            % width                          )  ;# [int] number of bits (memory width)
    fid.write( 'mux = %d\n'             % mux                            )  ;# [int] multiplexer width (valid values changes depending on type and size)
    fid.write( 'mvt = %s\n'             % mvt                            )  ;# [BASE,HP] multi-vt selection (BASE==mainly RVT, HP==mainly LVT)
    fid.write( 'frequency = %f\n'       % 1.0                            )  ;# [float] frequency (MHz) for dynamic power
    fid.write( 'activity_factor = %d\n' % 50                             )  ;# [int] activity factor % for dynamic power
    fid.write( 'pipeline = %s\n'        % 'off'                          )  ;# [on,off] additional output path pipeline stage
    fid.write( 'write_mask = %s\n'      % ('on' if mask != 0 else 'off') )  ;# [on,off] add write mask
    fid.write( 'redundancy = %s\n'      % 'off'                          )  ;# [on,off] add redundant column(s)
    fid.write( 'bmux = %s\n'            % 'off'                          )  ;# [on,off] add BIST multiplexer
    fid.write( 'scan = %s\n'            % 'off'                          )  ;# [on,off] generate a scan chanin
    fid.write( 'ser = %s\n'             % 'none'                         )  ;# [none,1bd1bc,2bd1bc] soft error repair
    fid.write( 'power_gating = %s\n'    % 'off'                          )  ;# [on,off] add external power graing signals
    fid.write( 'atf = %s\n'             % 'off'                          )  ;# [on,off] advanced test features
    if type != '1hdsram':
      fid.write( 'vmin_assist = %s\n'   % 'off'                          )  ;# [on,off] low voltage assist features
    fid.write( 'eol_guardband = %d\n'   % 0                              )  ;# [0,2,5,10] end of life guardband for ageing degradation
    fid.write( 'c4obs = %s\n'           % 'off'                          )  ;# [on,off] c4 full obstruction

    if type != '2rf': fid.write( 'write_thru = %s\n'    % 'off' )  ;# [on,off] enable write through (updates output)
    if type != '2rf': fid.write( 'lren_bankmask = %s\n' % 'off' )  ;# [on,off] left/right bank mask enables

    if  banks: fid.write( 'flexible_banking = %d\n' %  banks )  ;# [int] number of banks (valid values changes depending on type and size)
    if slices: fid.write( 'flexible_slice = %d\n'   % slices )  ;# [int] number of slices (valid values changes depending on type and size)

    fid.write( 'pwr_gnd_rename = %s\n'   % 'vddpe:VDDP,vddce:VDDC,vsse:VSS' )  ;# [string old:new] rename power and ground pins (Vperif, Vcore, Ground)
    fid.write( 'check_instname = %s\n'   % 'off'                            )  ;# [on,off] enforces certain limitations on the instance name
    fid.write( 'corners = %s\n'          % ','.join(corners)                )  ;# [listed above] pvt corners to generate

#===============================================================================
# gen_lib_to_db_file( name ):
#===============================================================================

def gen_lib_to_db_file( name ):

  ### Library compiler lib to db script
  with open('lib_to_db.tcl', 'w') as fid:
    fid.write( 'set liberty_files [glob -nocomplain -directory . %s_*.lib*]' % (name)                        + '\n' )
    fid.write( 'foreach lib_file $liberty_files {'                                                           + '\n' )
    fid.write( '  puts "Info: Compiling liberty file $lib_file"'                                             + '\n' )
    fid.write( '  read_lib $lib_file'                                                                        + '\n' )
    fid.write( '  write_lib [get_attribute [get_libs *] name] -format db -output "[file tail $lib_file].db"' + '\n' )
    fid.write( '  remove_lib -all'                                                                           + '\n' )
    fid.write( '}'                                                                                           + '\n' )
    fid.write( 'exit'                                                                                        + '\n' )

#===============================================================================
# gen_hcell_file( name ):
#===============================================================================

def gen_hcell_file( name ):

  with open(name + '.hcell', 'w') as fid:
    fid.write( '{0} {0}\n'.format(name) )

#===============================================================================
# gen_run_me_file( name, type ):
#===============================================================================

def gen_run_me_file( name, type ):

  ### Get the library compiler shell path
  lc_shell_exe = os.environ['LC_SHELL']

  ### Get the correct memory compile binary
  if type == '1rf':
    memgen_exe = os.environ['PREP_MEMGEN_RF']
  elif type == '2rf':
    memgen_exe = os.environ['PREP_MEMGEN_2RF']
  elif type == '1sram':
    memgen_exe = os.environ['PREP_MEMGEN_SRAM']
  elif type == '1hdsram':
    memgen_exe = os.environ['PREP_MEMGEN_HDSRAM']

  ### View Generators
  views = []
  #views.append( 'aocv' )
  #views.append( 'apache_avm' )
  views.append( 'ascii' )
  #views.append( 'bitmap' )
  #views.append( 'cpf' )
  #views.append( 'ctl' )
  #views.append( 'fastscan' )
  views.append( 'gds2' )
  views.append( 'lef-fp' )
  #views.append( 'liberty' )
  views.append( 'lvs' )
  #views.append( 'memorybist' )
  #views.append( 'postscript' )
  #views.append( 'tmax' )
  views.append( 'verilog' )
  #views.append( 'verilog_rtl' )

  with open('run_me', 'w') as fid:
    fid.write(' '.join([memgen_exe] + views + ['-spec', 'memory.spec']) + '\n')
    fid.write(' '.join([memgen_exe] + ['liberty', '-libertyviewstyle', 'nldm'] + ['-spec', 'memory.spec']) + '\n')
    fid.write(' '.join([memgen_exe] + ['liberty', '-libertyviewstyle', 'ccs_tn'] + ['-spec', 'memory.spec']) + '\n')
    fid.write(' '.join([lc_shell_exe, '-f', 'lib_to_db.tcl']) + '\n')

  os.chmod('run_me', stat.S_IRWXU)

### Run main()
if __name__ == '__main__':
  main()
