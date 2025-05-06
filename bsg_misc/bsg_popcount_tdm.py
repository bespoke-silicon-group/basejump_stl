#!/usr/bin/env python3
import math
import sys

"""
Popcount TDM Generator

Katharine Lundblad 04/13/2023

Popcount takes a binary value and counts the number of ones for a specified width.
This version attempts to use a more optimized adder tree in order to add partial sums
and balance delays using the Three Dimensional Method (TDM). In order to run, open
the command line and include the .py file, the number of widths separated by spaces and
the .v file you would like to be created 

ie. 'python .\bsg_popcount_tdm.py 1 2 4 8 bsg_popcount_tdm.py'
"""

fid = None
twire_ctr = 0


############################################################
# BIT
#
class BIT:

  def __init__(self, name, delay):
    self.name = name
    self.delay = delay

  def __str__(self):
    return f'{self.name}'
  
  def __repr__(self):
    return f'{self.name}'



############################################################
# WIRE initializes an array logic for a wire 
#
def WIRE( name=None, dim=(1,), inst=True, delay=0.0 ):
  global twire_ctr             # wire counter
  if not name:
    name = f't{twire_ctr}_n'   # creates wire variable in verilog
    twire_ctr += 1           

  if inst:
    fid.write(f'        wire ')        
    for d in dim:
      fid.write(f'[{d-1}:0]')  # initializes size of logic inverilog
    fid.write(f' {name};\n')

  if len(dim) == 1:
    return [BIT(f'{name}[{i}]', delay) for i in range(dim[0])] # returns bit object for single bit
  else:
    return [WIRE(f'{name}[{i}]', dim[1:], False, delay) for i in range(dim[0])] 



############################################################
# AND2 - A two input AND gate, assigns AND of x and y to z
#        and calculates the output delay using gate delay 
#        and input delays
#
def AND2( x, y, z=None ):
  z = WIRE()[0] if not z else z                   # initializes logic for z if not fed to input
  fid.write(f'        assign {z} = {x} & {y};\n') # writes assign AND gate to z to verilog file
  z.delay = max(x.delay, y.delay) + 0.5           # calculates delay of max of 2 inputs + 0.5 AND delay
  return z



############################################################
# OR3 - 3 input OR gate, assigns the OR of w, x, and y to 
#       z, calculates output delay 
#
def OR3( w, x, y, z=None ):
  z = WIRE()[0] if not z else z
  fid.write(f'        assign {z} = {w} | {x} | {y};\n')
  z.delay = max(w.delay, x.delay, y.delay) + 0.5 # OR3 gate delay is 0.5
  return z


############################################################
# XOR2 - 2 input XOR gate, assigns the XOR of x and y and
#        assigns to z, calculates output delay
#
def XOR2( x, y, z=None ):
  z = WIRE()[0] if not z else z
  fid.write(f'        assign {z} = {x} ^ {y};\n') 
  z.delay = max(x.delay, y.delay) + 1 # XOR2 gate delay is 1
  return z



############################################################
# ASSIGN - assign statement, assigns x to z logic, sets z
#          delay to the x delay
#
def ASSIGN( x, z=None ):
  z = WIRE()[0] if not z else z
  fid.write(f'        assign {z} = {x};\n') 
  z.delay = x.delay + 0.0
  return z



############################################################
# TIELO - tie logic low, assigns z to 1'b0
#
def TIELO( z=None ):
  z = WIRE()[0] if not z else z
  fid.write(f'        assign {z} = 1\'b0;\n') 
  return z



############################################################
# TIEHI - tie logic high, assigns z to 1'b1
#
def TIEHI( z=None ):
  z = WIRE()[0] if not z else z
  fid.write(f'        assign {z} = 1\'b1;\n')
  return z



############################################################
# HA (Half Adder) - takes the sum of x and y, returns sum 
#                   and carry out
#
def HA( x, y, s=None, c=None ):
  s = WIRE()[0] if not s else s
  c = WIRE()[0] if not c else c
  return ( XOR2(x, y, s), AND2(x, y, c) )



############################################################
# FA (Full Adder) - takes sum of x and y with z as carry-in
#                   returns the sum and carryout
#
#   Note: z is faster to s than x or y!
#
def FA( x, y, z, s=None, c=None ):
  s = WIRE()[0] if not s else s
  c = WIRE()[0] if not c else c
  # slower logic (x, y) calculated in an earlier XOR gate in order to balance the delays of x, y and z
  return ( XOR2(XOR2(x, y), z, s), OR3(AND2(x, y), AND2(x, z), AND2(y, z), c) )



############################################################
# TDM - Three Dimensional Method for adding the 1's of a 
#       binary value, takes a list of lists and returns a 
#       sum (s), carry (c), and the final sum (s + c)
#
def TDM( columns, s=None, c=None, sum=None):
  
  s = WIRE(dim=(len(columns),)) if not s else s        # create empty array if sum not passed in
  c = WIRE(dim=(len(columns),)) if not c else c
  sum = WIRE(dim=(len(columns),)) if not sum else sum

  for i,col in enumerate(columns):
    inputs = col

    foobar = WIRE(f'COLUMN{i}',dim=(len(inputs),))
    for qi,q in enumerate(inputs):
      ASSIGN(q, foobar[qi])


    if len(inputs) == 0:                               # sum and carry are zero if input is width 0
      TIELO( s[i] )
      TIELO( c[i] )

    while (len(inputs) > 0):
      inputs = sorted(inputs, key=lambda y: y.delay)   # sorting input bits by delay

      if len(inputs) == 1:                             # sum is input if input is width 1, no carry
        ASSIGN( inputs.pop(0), s[i] )
        TIELO( c[i] )

      elif len(inputs) == 2:                           # sum tied to bit 0 and carry tied to bit 1
        ASSIGN( inputs.pop(0), s[i] )
        ASSIGN( inputs.pop(0), c[i] )

      elif len(inputs) == 3:                           # half adder adds bits 1 and 0 and assigns to sum
        (_,carry) = HA( inputs.pop(0), inputs.pop(0), s[i], None )
        ASSIGN( inputs.pop(0), c[i] )                  # bit 2 assigned to carry
        columns[i+1].append(carry)                     # result from half adder is appended to next radix

      elif len(inputs) == 4:                           # full adder assigns bits 2 to 0 to inputs and carry-in
        (_,carry) = FA( inputs.pop(0), inputs.pop(0), inputs.pop(0), s[i], None )
        ASSIGN( inputs.pop(0), c[i] )                  # bit 3 is assigned to carry
        columns[i+1].append(carry)                     # result from full adder is appended to next radix

      else:                                            
        (t,carry) = FA(inputs.pop(0), inputs.pop(0), inputs.pop(0))
        inputs.append(t)                               # for widths > 4, sum is added back to input array
        columns[i+1].append(carry)

  sum = s + c
  return sum



############################################################
# Print Begin Module - initializes logic for I/O and 
#                      creates verilog file, writes logic
#                      variables for input and output
#
def print_begin_module():
  global fid
  fid = open(f'bsg_popcount_tdm.v', 'w')    
  fid.write(f'// Popcount TDM Generator\n')
  fid.write(f'// Automatically generated using bsg_popcount_tdm.py\n')
  fid.write(f'// DO NOT MODIFY\n')
  fid.write(f'// This generator can create a popcount adder tree based on\n')
  fid.write(f'// how many widths were specified in the main .py file\n')
  fid.write(f'\n')
  fid.write(f'module bsg_popcount_tdm #(parameter `BSG_INV_PARAM(width_p=4))\n') # initializes module
  fid.write(f'    (input [width_p-1:0] i\n')                                     # defines input and output logic
  fid.write(f'     , output [$clog2(width_p+1)-1:0] o\n')                        # generates count size based on input width
  fid.write(f'    );\n' )
  fid.write(f'\n')



############################################################
# Print Generate - initializes the list of lists or 
#                  columns to do the adding, calls TDM to 
#                  create the adder trees for any number of
#                  widths, creates if statments in verilog
#                  and stores the final sum 
#
def print_generate(width_p_arr):
    # initialize variables for the TDM adder for the first width
    num_columns_arr = [math.ceil(math.log2(i+1)) for i in width_p_arr] # populates array with number of columns for each corresponding width
    columns = [[] for i in range(num_columns_arr[0])]                  # create empty columns
    bits_lp = WIRE("i", dim=(width_p_arr[0],), inst=False)             # initialize array for input bits
    columns[0] = [bits_lp[i] for i in range(width_p_arr[0])]           # set elements of input bits to first column
    s_o = WIRE('s_o', dim=(num_columns_arr[0],), inst=False)           # initialize the sum list
    c_o = WIRE('c_o', dim=(num_columns_arr[0],), inst=False)           # initialize the carry list
    sum_o = WIRE('sum_o', dim=(num_columns_arr[0],), inst=False)       # initialize the final sum list (sum + carry)
    
    # if statement to check if the first width matches input and calls TDM
    fid.write(f'    if (width_p == {width_p_arr[0]}) begin: width_{width_p_arr[0]} \n')
    fid.write(f'        wire [$clog2(width_p+1)-1:0] s_o;\n')
    fid.write(f'        wire [$clog2(width_p+1)-1:0] c_o;\n')
    TDM(columns, s_o, c_o, sum_o)
    fid.write(f'        assign o = s_o + c_o;\n') # adds the final sum and carry values
    print_max_delay(s_o, c_o)
    fid.write(f'    end\n')
    fid.write(f'\n')
    
    # generates an else if statement for the rest of the widths and calls TDM
    if (len(width_p_arr) > 1):
      for j in range(1, len(width_p_arr)):
        s_o = WIRE('s_o', dim=(num_columns_arr[j],), inst=False)
        c_o = WIRE('c_o', dim=(num_columns_arr[j],), inst=False) 

        sum_o = WIRE('sum_o', dim=(num_columns_arr[j],), inst=False)
        fid.write(f'    else if (width_p == {width_p_arr[j]}) begin: width_{width_p_arr[0]} \n')
        fid.write(f'        wire [$clog2(width_p+1)-1:0] s_o;\n')
        fid.write(f'        wire [$clog2(width_p+1)-1:0] c_o;\n')
        columns = [[] for i in range(num_columns_arr[j])]                                   
        bits_lp = WIRE("i", dim=(width_p_arr[j],), inst=False)                          
        columns[0] = [bits_lp[i] for i in range(width_p_arr[j])]   
        TDM(columns, s_o, c_o, sum_o)
        fid.write(f'        assign o = s_o + c_o;\n') # adds the final sum and carry values
        print_max_delay(s_o, c_o)
        fid.write(f'    end\n')
        fid.write(f'\n')
    fid.write(f'\n')



############################################################
# Print End Module - gets the max delay of a single TDM 
#                    tree
def print_max_delay(s_o, c_o):
  max_s = 0
  for s in s_o:
    max_s = max(max_s, s.delay)                  # calculates maximum delay (critical path) of sum 
    fid.write(f'        // {s} --> {s.delay}\n') # adds delay to comments in verilog
  max_c = 0
  for c in c_o:
    max_c = max(max_c, c.delay)
    fid.write(f'        // {c} --> {c.delay}\n')
  fid.write(f'\n')
  fid.write(f'        // max S --> {max_s}\n')
  fid.write(f'        // max C --> {max_c}\n')
  fid.write(f'\n')



############################################################
# Print End Module - ends the verilog module, closes file
#
def print_end_module():
  fid.write(f'endmodule // bsg_popcount_tdm\n')
  fid.close()



############################################################
# Generate popcount -- Uses TDM to count the number of ones
#                      for a given width 
#
def popcount_gen(width_p_arr):
  print_begin_module()  # creates and writes "popcount_tdm.v"
  print_generate(width_p_arr)
  print_end_module()                                 



############################################################
# Generate popcount -- Check if a string can be converted  
#                      to an integer
# 
def is_int(s):
  try:
    int(s)
    return True
  except ValueError:
    return False



############################################################
# Get Widths -- Accepts a command line argument like 
#               ".\bsg_popcount_tdm.py 1 2 4 8 file.v"
#               and creates output file and array of widths
# 
def get_widths():
  args = sys.argv[1:] # Get command line arguments excluding the script name
  width_p_arr = []    # create empty list to store the integers
  file_name = None    # create a variable to store the file name

  for arg in args:                 # Loop through the command line arguments
    if is_int(arg):                # Check if the argument is an integer
      width_p_arr.append(int(arg)) # add integer width to list
    else:
      file_name = arg              # if the argument is not a width, it is a filename

  return width_p_arr



if __name__ == '__main__':
  width_p_arr = get_widths() # default array before command line is implemented
  popcount_gen(width_p_arr)  # generates a "popcount_tdm.v" file for width of 8
