#!/usr/bin/python

import optparse
import subprocess
import time
import os
import re
import sys
import random
import os.path

# ========== Global variables ==========
tb_file_name = "config_net_tb.v"
indent = "  " # indentation

spec_file_name = "sc_spec.in"
test_file_name = "sc_test.in"

l_inst_id = [] # list of unique decimals
d_inst_name = {} # dictionary of strings indexed by inst id
d_inst_data_bits = {} # dictionary of decimals indexed by inst id
d_inst_default = {} # dictionary of binary strings indexed by inst id

# scan chain test sequence
l_test_id = []
l_test_data = []
l_test_packet = []

# dictionary of verification sequences
d_reference = {}

# scan chain communication protocol parameters, applying to all nodes
valid_bit = '0' #
frame_bit = '0' #
len_width_lp = 8 # lenth field width in the scan chain
id_width_lp = 8 # id field width in the scan chain
frame_bit_size_lp = 1 # scan chain protocol frame bits size
data_frame_len_lp = 8 # scan chain protocol data frame length in bits
reset_len_lp = 10 # scan chain reset signal length in bits

#
reset_tb = "reset_tb"
clk_tb = "clk_tb"
clk_tb_period = 10 # time units
sim_time = 500 # time units

#
l_inst_config_in = [] # list of inputs struct config_in_s for all nodes
l_inst_data_o = [] # list of outputs data_o for all nodes
l_inst_bit_o = [] # list of outputs bit_o for all nodes

# ========== Functions ==========
def readme():
  print "  "
  print "  Name:"
  print "    gen_tb.py - python script to generate testbench for chained config_node instances"
  print "  "
  print "  Usage:"
  print "    gen_tb.py options testfile [number of tests]"
  print "  "
  print "  Example:"
  print "    gen_tb.py -w sc_test.in 10"
  print "    gen_tb.py -r sc_test.in"
  print "  "
  print "  Description:"
  print "    This script reads scan chain specifications from sc_spec.in file,"
  print "    generates random test sequence and creates config_net_tb.v testbench."
  print "  "
  print "    Use command ./gen_tb.py -w <testfile> <number of tests> to"
  print "    generate a new sequence of <number of tests> tests and writes the"
  print "    sequence to <testfile>."
  print "  "
  print "    You can extend the generated testfile to contain your specific test cases;"
  print "    then use command ./gen_tb.py -r <testfile> to read the modified file,"
  print "    and create testbench accordingly."

def dec2bin(dec, n): # Only works on non-negative number
  bin = ""
  while n > 0:
    bin = str(dec % 2) + bin
    dec >>= 1
    n -= 1
  return bin

def insert_frame_bits(data):
  framed_data = ""
  data = data[::-1] # reverse the string; in python data[0] is the msb of a string
  for idx in range(1, len(data) + 1): # 1, 2, 3 ... len(data)
    if idx % data_frame_len_lp == 0:
      framed_data = frame_bit + "_" + data[idx - 1] + framed_data
      if idx != len(data):
        framed_data = "_" + framed_data
    else:
      framed_data = data[idx - 1] + framed_data
  framed_data = frame_bit + "_" + framed_data
  return framed_data

def write_localparam(file, lhs, rhs):
  file.write(indent + "localparam " + lhs + " = " + rhs + ";\n")

def write_logic(file, name):
  file.write(indent + "logic " + name + ";\n")

def write_logic_vec(file, name, msb, lsb):
  file.write(indent + "logic [" + msb + " : " + lsb + "] " + name + ";\n")

def write_config_in_s(file, name):
  file.write(indent + "config_in_s " + name + ";\n")

def write_assign(file, lhs, rhs):
  file.write(indent + "assign " + lhs + " = " + rhs + ";\n")

def write_inst_node(file, id, data_bits, default, config_in, data_o, bit_o):
  file.write("\
  config_node        #(.id_p(" + id + "),\n\
                       .data_bits_p(" + data_bits + "),\n\
                       .default_p(" + data_bits + "'b" + default + ") )\n\
    inst_id_" + \
          id + "_dut(  .config_in(" + config_in + "),\n\
                       .data_o(" + data_o + "),\n\
                       .bit_o(" + bit_o + ") );\n ")

def write_relay_node(file, id, config_in, bit_o):
  file.write("\
  relay_node\n\
    relay_id_" + \
          id + "_dut(  .config_in(" + config_in + "),\n\
                       .bit_o(" + bit_o + ") );\n ")
# ========== ==========
# read scan chain specification file and parse
relay_nodes = 0
spec_file = open(spec_file_name, 'r')
for line in spec_file:
  line = line.rstrip('\n') # remove the newline character
  if line != "": # if not an empty line
    l_words = line.split() # split a line into a list of words on white spaces
    if (line[0] != '#') and (line[0] != ' '): # ignore lines starting with '#' or spaces
      if (l_words[1][0] == 'r'): # (id == 'r') indicates inserting a relay node
        l_inst_id.append('r')
        relay_nodes += 1
      else:
        inst_id = int(l_words[1])
        l_inst_id.append(inst_id)
        d_inst_name[inst_id] = l_words[0]
        d_inst_data_bits[inst_id] = int(l_words[2])
        d_inst_default[inst_id] = l_words[3]
spec_file.close()

# Argument list parsing
if (len(sys.argv) == 1):
  print "gen_tb.py expects at least 2 arguments."
  readme()
  sys.exit(1)
elif ( (sys.argv[1] == "-h") or (sys.argv[1] == "--help") ):
  readme()
  sys.exit(0)

if (len(sys.argv) > 2):
  test_file_name = sys.argv[2]
  if (sys.argv[1] == "-w"):
    number_of_tests = int(sys.argv[3])
    # randomly generate test id and test data
    generated_tests = 0
    while (generated_tests < number_of_tests):
      rand_idx = random.randint(0, len(l_inst_id) - 1)
      test_id = l_inst_id[rand_idx]
      if (test_id != 'r'):
        l_test_id.append(test_id)
        test_data_bits = d_inst_data_bits[test_id]
        randbits = random.getrandbits(test_data_bits)
        test_data = dec2bin(randbits, test_data_bits)
        l_test_data.append(test_data)
        generated_tests += 1
    # write random test cases to scan chain test file
    test_file = open(test_file_name, 'w')
    test_file.write("# This is a generated file with random test id and data.\n" + \
                    "# You can extend this file to contain your specific test cases.\n" + \
                    "# Use command ./gen_tb.py -r <this file name> if you would like to use the modified file.\n" + \
                    "# Use command ./gen_tb.py -w <this file name> <number of tests> will overwrite this file.\n\n" + \
                    "# <test id> <test data>\n")
    for test in range(0, number_of_tests):
      test_file.write(str(l_test_id[test]) + "\t\t" + l_test_data[test] + "\n")
    test_file.close()
    os.system("cat " + test_file_name)
    print "  "
    print str(number_of_tests) + " sets of random test id and data are generated and written into " + test_file_name
    sys.exit(0) # exit after making the test file
  elif (sys.argv[1] == "-r"):
    # read scan chain test file and parse
    test_file = open(test_file_name, 'r')
    for line in test_file:
      line = line.rstrip('\n') # remove the newline character
      if line != "": # if not an empty line
        l_words = line.split() # split a line into a list of words on white spaces
        if (line[0] != '#') and (line[0] != ' '): # ignore lines starting with '#' or spaces
          l_test_id.append(int(l_words[0]))
          l_test_data.append(l_words[1])
    test_file.close()

# create test string and calculate total bits
test_idx = 0
test_vector_bits = 0
for test_id in l_test_id:
  send_data = insert_frame_bits(l_test_data[test_idx])
  data_bits = d_inst_data_bits[test_id]
  send_data_bits = data_bits + (data_bits / data_frame_len_lp) + frame_bit_size_lp
  packet_len = send_data_bits + frame_bit_size_lp + id_width_lp + frame_bit_size_lp + len_width_lp + frame_bit_size_lp
  test_vector_bits += packet_len
  test_packet = send_data +\
                "_" + frame_bit +\
                "_" + dec2bin(test_id, id_width_lp) +\
                "_" + frame_bit +\
                "_" + dec2bin(packet_len, len_width_lp) +\
                "_" + valid_bit
  l_test_packet.append(test_packet)
  test_idx += 1

# create a dictionary indexed by test id
# if a new data item for an id is the same as its previous one, the new data is not appended as a new reference;
# because the verilog testbench is not able to detect signal change.
test_idx = 0
for test_id in l_test_id:
  test_data = l_test_data[test_idx]
  if d_reference.has_key(test_id):
    last_index = len(d_reference[test_id]) - 1
    # if a new data item for an id is the same as its previous one, the new data is not appended.
    if(d_reference[test_id][last_index] != test_data):
      d_reference[test_id].append(test_data)
  else:
    # if a new data item for an id is the same as its previous one, the new data is not appended.
    if(d_inst_default[test_id] == test_data):
      d_reference[test_id] = [d_inst_default[test_id]]
    else:
      d_reference[test_id] = [d_inst_default[test_id], test_data]
  test_idx += 1

# create reset string
reset_string = ""
for bit in range(0, reset_len_lp): # 0, 1, ..., reset_len_lp - 1
  reset_string += '1'

# the whole test vector begins with reset string
test_vector_bits += reset_len_lp
test_vector = reset_string
# the first test packet in l_test_packet is fed into the configuration network first
for packet in l_test_packet:
  # double underscore __ separates test packet for each node
  test_vector = packet + "__" + test_vector

# calculate the shift register width of the whole scan chain
shift_chain_width = 0
for key in d_inst_data_bits:
  data_bits = d_inst_data_bits[key]
  send_data_bits = data_bits + (data_bits / data_frame_len_lp) + frame_bit_size_lp
  shift_chain_width += send_data_bits + frame_bit_size_lp +\
                       id_width_lp + frame_bit_size_lp +\
                       len_width_lp + frame_bit_size_lp

# revise simulation time to ensure all test bits walks through the whole scan chain
sim_time += (test_vector_bits + shift_chain_width + relay_nodes) * clk_tb_period

tb_file = open(tb_file_name, 'w')
tb_file.write("module config_net_tb;\n\n")

# write localparam
write_localparam(tb_file, "len_width_lp       ", str(len_width_lp))
write_localparam(tb_file, "id_width_lp        ", str(id_width_lp))
write_localparam(tb_file, "frame_bit_size_lp  ", str(frame_bit_size_lp))
write_localparam(tb_file, "data_frame_len_lp  ", str(data_frame_len_lp))
write_localparam(tb_file, "reset_len_lp       ", str(reset_len_lp))

tb_file.write(indent + "// double underscore __ separates test packet for each node\n")
write_localparam(tb_file, "test_vector_bits_lp", str(test_vector_bits))
write_localparam(tb_file, "test_vector_lp     ", str(test_vector_bits) + "'b" + test_vector)

# write reference output sequence as localparams
tb_file.write("\n")
for key in d_reference:
  test_id = key
  data_bits = d_inst_data_bits[test_id]
  tests = len(d_reference[test_id])
  data_ref = ""
  for test in range(0, tests):
    data_ref = data_ref + str(data_bits) + "'b" + d_reference[test_id][test]
    if test != (tests - 1): data_ref = data_ref + ", "
  data_ref = "'{" + data_ref + "}"
  write_localparam(tb_file, "logic [" + str(data_bits - 1) + " : 0] data_o_" + str(test_id) + "_ref[" + str(tests) + "]", data_ref)

# write clock and reset signals
tb_file.write("\n" + indent + "//\n")
write_logic(tb_file, clk_tb)
write_logic(tb_file, reset_tb)

# input struct logic
inst_index = 0
relay_index = 0
for inst_id in l_inst_id:
  if (inst_id == 'r'):
    l_inst_config_in.append("relay_in_" + str(relay_index))
    relay_index += 1
  else:
    l_inst_config_in.append("config_in_" + str(inst_id))
  write_config_in_s(tb_file, str(l_inst_config_in[inst_index]))
  inst_index += 1

# output bits
inst_index = 0
for inst_id in l_inst_id:
  if inst_index != (len(l_inst_id) - 1): l_inst_bit_o.append(l_inst_config_in[inst_index + 1] + ".bit_i")
  inst_index += 1
l_inst_bit_o.append(" ") # the last bit_o is not connected

# declare output data
for inst_id in l_inst_id:
  if (inst_id != 'r'):
    l_inst_data_o.append("data_o_" + str(inst_id))
    write_logic_vec(tb_file, "data_o_" + str(inst_id), str(d_inst_data_bits[inst_id] - 1), '0')

# declare test vector logic
write_logic_vec(tb_file, "test_vector", str(test_vector_bits - 1), '0')

# instantiate and connect configuration nodes
inst_index = 0
relay_index = 0
for inst_id in l_inst_id:
  if (inst_id == 'r'):
    tb_file.write("\n" + indent + "// " + "Relay node " + str(relay_index) + "\n")
    write_relay_node(tb_file, str(relay_index), l_inst_config_in[inst_index], l_inst_bit_o[inst_index])
    relay_index += 1
  else:
    tb_file.write("\n" + indent + "// " + d_inst_name[inst_id] + "\n")
    write_inst_node(tb_file, str(inst_id), str(d_inst_data_bits[inst_id]), d_inst_default[inst_id],\
                             l_inst_config_in[inst_index],\
                             l_inst_data_o[inst_index - relay_index],\
                             l_inst_bit_o[inst_index])
  inst_index += 1

# assign clocks
tb_file.write("\n")
for config_in in l_inst_config_in:
  write_assign(tb_file, config_in + ".clk_i", clk_tb)

# write clock generator
tb_file.write("\n")
tb_file.write(indent + "// clock generator\n")
tb_file.write(indent + "initial begin\n" + \
              indent + indent + clk_tb + " = 1;\n" + \
              indent + indent + reset_tb + " = 1;\n" + \
              indent + indent + "#15 " + reset_tb + " = 0;\n" + \
              indent + "end\n" + \
              indent + "always #" + str(clk_tb_period / 2) + " begin\n" + \
              indent + indent + clk_tb + " = ~" + clk_tb + ";\n" + \
              indent + "end\n")

# instantiate config_driver to deliver configuration bits
tb_file.write("\n")
tb_file.write(indent + "// instantiate config_driver to deliver configuration bits\n")
tb_file.write(indent + "config_driver #(.test_vector_p(test_vector_lp),\n" + \
              indent + "                .test_vector_bits_p(test_vector_bits_lp) )\n" + \
              indent + "    inst_driver(.clk_i(" + clk_tb + "),\n" + \
              indent + "                .reset_i(" + reset_tb + "),\n" + \
              indent + "                .bit_o(" + l_inst_config_in[0] + ".bit_i) );\n")

# write output verification processes
tb_file.write("\n")
for key in d_reference:
  test_id = key
  data_bits = d_inst_data_bits[test_id]
  tests = len(d_reference[test_id])
  data_ref = ""
  for test in range(0, tests):
    data_ref = data_ref + str(data_bits) + "'b" + d_reference[test_id][test]
    if test != (tests - 1): data_ref = data_ref + ", "
  data_ref = "'{" + data_ref + "}"
  tb_file.write(indent + "// scan chain node " + d_inst_name[test_id] + " binding verification\n" + \
                indent + "bind inst_id_" + str(test_id) + "_dut bind_node #(.id_p(" + str(test_id) + "),\n" + \
                indent + "                                .data_bits_p(" + str(data_bits) + "),\n" + \
                indent + "                                .data_ref_len_p(" + str(tests) + "),\n" + \
                indent + "                                .data_ref_p(" + data_ref + ") )\n" + \
                indent + "                inst_id_" + str(test_id) + "_bind (config_in, data_o, bit_o);\n\n")

# write simulation ending condition
tb_file.write("\n")
tb_file.write(indent + "// simulation end\n")
tb_file.write(indent + "initial begin\n" + \
              indent + indent + "#" + str(sim_time) + " $finish;\n" + \
              indent + "end\n")

tb_file.write("\n//\n")
tb_file.write("endmodule\n\n")

tb_file.close()
