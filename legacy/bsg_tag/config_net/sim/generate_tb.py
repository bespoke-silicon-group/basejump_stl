#!/nbu_async/luzh/install/bin/python

import optparse
import subprocess
import time
import os
import re
import sys
import random
import os.path
import argparse

# ========== Global variables ==========
indent = "  " # indentation

l_inst_id = [] # list of unique decimals
d_inst_name = {} # dictionary of strings indexed by inst id
d_inst_data_bits = {} # dictionary of decimals indexed by inst id
d_inst_default = {} # dictionary of binary strings indexed by inst id
d_inst_pos = {} # a dict specifying config_node position in the relay_tree
l_inst_data_o = [] # list of outputs data_o for all nodes

#
d_relay_tree = {} # a tree describing relay nodes interconnections

# configuration network test sequence
l_test_id = []
l_test_data = []
l_test_packet = []

# dictionary of verification sequences
d_reference = {}

# configuration network communication protocol parameters, applying to all nodes
valid_bits = "10" #
frame_bit = '0' #
len_width_lp = 8 # lenth field width in a config_node
id_width_lp = 8 # id field width in a config_ndoe
valid_bit_size_lp = 2 # communication packet valid bits size
frame_bit_size_lp = 1 # communication packet frame bits size
data_frame_len_lp = 8 # communication packet data frame length in bits
reset_len_lp = 10 # communication packet reset signal length in bits
data_max_bits_lp = 32 # maximum number of allowed configurable bits in a single config_node

# reset, clock and simulation time
rst_cfg = "rst_cfg" # configuration setter reset
rst_dst = "rst_dst" # destination (logic to be configured) side reset
clk_cfg = "clk_cfg" # configuration network clock
clk_cfg_period = 30 # time units
clk_dst = "clk" # destination (logic to be configured) side clock
clk_dst_period = 10 # time units
sim_time = 500 # time units

# ========== Functions ==========
def readme():
  print "  \n\
    Name:\n\
      generate_tb.py - python script to generate testbench for chained config_node instances\n\
    \n\
    Usage:\n\
      generate_tb.py {-w <testfile> <number of tests> | -r <testfile> -o <tb file name>}\n\
    \n\
    Example:\n\
      generate_tb.py -w config_test.in 10\n\
      generate_tb.py -r config_test.in -o config_net_tb.v\n\
    \n\
    Description:\n\
      This script reads config network specifications from config_spec.in file,\n\
      generates a random configuraion network using relay_nodes, and\n\
      attach config_nodes to a randomly chosen relay_node. It also\n\
      generates random test sequence and creates config_net_tb.v\n\
      testbench.\n\
    \n\
      Use command ./generate_tb.py -w <testfile> <number of tests> to\n\
      generate a new sequence of <number of tests> tests and writes the\n\
      sequence to <testfile>.\n\
    \n\
      You can extend the generated testfile to contain your specific test cases;\n\
      then use command ./generate_tb.py -r <testfile> -o <tb file name> to read the\n\
      modified file, and create testbench accordingly."

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

def write_config_s(file, name):
  file.write(indent + "config_s " + name + ";\n")

def write_assign(file, lhs, rhs):
  file.write(indent + "assign " + lhs + " = " + rhs + ";\n")

def write_inst_node(file, id, data_bits, default, config_i, data_o):
  file.write("\
  config_node        #(.id_p(" + id + "),\n\
                       .data_bits_p(" + data_bits + "),\n\
                       .default_p(" + data_bits + "'b" + default + ") )\n\
    inst_id_" + \
          id + "_dut(  .clk(" + clk_dst + "),\n\
                       .reset(" + rst_dst + "),\n\
                       .config_i(" + config_i + "),\n\
                       .data_o(" + data_o + ") );\n")

def write_relay_node(file, id, config_i, config_o):
  file.write("\
  relay_node\n\
    relay_id_" + \
          id + "_dut(  .config_i(" + config_i + "),\n\
                       .config_o(" + config_o + ") );\n")
# ========== ==========
argparser = argparse.ArgumentParser()
argparser.add_argument("--spec",
                       type=argparse.FileType('r'),
                       metavar='Filename',
                       dest="spec_file",
                       required=True,
                       help="read configuration network specification file")

arg_tests_rw = argparser.add_mutually_exclusive_group()
arg_tests_rw.add_argument("--generate-tests",
                          type=argparse.FileType('w'),
                          metavar='Filename',
                          dest="generate_tests",
                          required=False,
                          help="write randomly generated test sequence to file")
arg_tests_rw.add_argument("--read-tests",
                          type=argparse.FileType('r'),
                          metavar='Filename',
                          dest="read_tests",
                          required=False,
                          help="read existing test sequence file")

argparser.add_argument("--number-of-tests",
                       type=int,
                       metavar='Integer',
                       default=10,
                       dest="number_of_tests",
                       required=False,
                       help="number of tests to be created with --generate-tests")

argparser.add_argument("--testbench",
                       type=argparse.FileType('w'),
                       metavar='Filename',
                       dest="testbench",
                       required=False,
                       help="generate configuration network SystemVerilog testbench file")

argparser.add_argument("--create-setter-file",
                       type=argparse.FileType('w'),
                       metavar='Filename',
                       dest="create_setter_file",
                       required=False,
                       help="generate configuration network setter vector according to --read-tests and write the vector to file")

argparser.add_argument("--create-probe-file",
                       type=argparse.FileType('w'),
                       metavar='Filename',
                       dest="create_probe_file",
                       required=False,
                       help="generate verification probes for each config_node according to --read-tests and write the probes to file")

try:
  args = argparser.parse_args()
except IOError, msg:
  argparser.error(str(msg))

# ========== ==========
# read specification file, parse relay nodes
spec_file = args.spec_file
relay_nodes = 0 # number of relay nodes in the configuration network
for line in spec_file:
  line = line.rstrip('\n') # remove the newline character
  if line != "": # if not an empty line
    l_words = line.split() # split a line into a list of words on white spaces
    if (line[0] != '#') and (line[0] != ' '): # ignore lines starting with '#' or spaces
      if (l_words[0] == 'r'): # type 'r' indicates a relay node
        relay_id = int(l_words[1]) # l_words[1] must be consecutive integers starting from 0
        if (relay_id != relay_nodes):
          print "ERROR spec file format: relay_id must be consecutive integers starting from 0!"
          print ">>> " + line
          sys.exit(1)
        else: # relay_nodes != 0
          if (l_words[1] != '0'): # no need to process relay node 0
            if (l_words[2] == 'x'): # position 'x' indicates a random branch
              branch_id = random.randint(0, relay_nodes - 1) # to which the new relay node is connected
            else:
              branch_id = int(l_words[2]) # l_words[2] must be an integer if not an 'x'
            if d_relay_tree.has_key(branch_id):
              d_relay_tree[branch_id].append(relay_id)
            else:
              d_relay_tree[branch_id] = [relay_id]
        relay_nodes += 1
      elif (l_words[0] == 'c'): # type 'c' indicates a config node
        inst_id = int(l_words[1])
        l_inst_id.append(inst_id)
        d_inst_name[inst_id] = l_words[3]
        d_inst_data_bits[inst_id] = int(l_words[4])
        d_inst_default[inst_id] = l_words[5]
      else:
        print "ERROR spec file format: type " + l_words[0] + " is not recognized!"
        print ">>> " + line
        sys.exit(1)

# randomize d_relay_tree if relay_nodes are not provided in spec file
if (relay_nodes == 0):
  relay_nodes = random.randint(1, 16) # generate random number [1..16] of relay nodes
  for relay_id in range(1, relay_nodes): # relay_id 0 is the root
    # because relay node id are consecutive integers, randint(0, relay_id - 1) makes all nodes are connected
    branch_id = random.randint(0, relay_id - 1) # to which the new relay is connected
    if d_relay_tree.has_key(branch_id):
      d_relay_tree[branch_id].append(relay_id)
    else:
      d_relay_tree[branch_id] = [relay_id]

spec_file.seek(0) # rewind to read from the beginning of spec file
# read specification file, attach config nodes
for line in spec_file:
  line = line.rstrip('\n') # remove the newline character
  if line != "": # if not an empty line
    l_words = line.split() # split a line into a list of words on white spaces
    if (line[0] != '#') and (line[0] != ' '): # ignore lines starting with '#' or spaces
      if (l_words[0] == 'c'): # type 'c' indicates a config node
        inst_id = int(l_words[1])
        if (l_words[2] == 'x'): # position 'x' indicates a random branch
          d_inst_pos[inst_id] = random.randint(0, relay_nodes - 1) # inclusive of 0 and (relay_nodes - 1)
        elif (int(l_words[2]) >= relay_nodes): # l_words[2] must be an integer if not an 'x'
          print "ERROR spec file format: config node branch id doesn't exist, " + l_words[2] + " >= number of relay nodes = " + str(relay_nodes) + "!"
          print ">>> " + line
          sys.exit(1)
        else:
          d_inst_pos[inst_id] = int(l_words[2])
spec_file.close()

# randomly generate test file or read an existing one
if (args.generate_tests != None):
  # randomly generate test id and test data
  test_file = args.generate_tests
  number_of_tests = args.number_of_tests
  generated_tests = 0
  while (generated_tests < number_of_tests):
    rand_idx = random.randint(0, len(l_inst_id) - 1)
    test_id = l_inst_id[rand_idx]
    l_test_id.append(test_id)
    test_data_bits = d_inst_data_bits[test_id]
    randbits = random.getrandbits(test_data_bits)
    test_data = dec2bin(randbits, test_data_bits)
    l_test_data.append(test_data)
    generated_tests += 1
  # write random test cases to test file
  test_file.write("# This is a generated file with random test id and data.\n" + \
                  "# You can extend this file to contain your specific test cases.\n" + \
                  "# Use command `./generate_tb.py -r <this file name> -o <tb file name>` if you would like to use the modified file.\n" + \
                  "# Use command `./generate_tb.py -w <this file name> <number of tests>` will overwrite this file.\n\n" + \
                  "# <test id> <test data>\n")
  for test in range(0, number_of_tests):
    test_file.write(str(l_test_id[test]) + "\t\t" + l_test_data[test] + "\n")
  test_file.close()
  os.system("cat " + test_file.name)
  print "  "
  print str(number_of_tests) + " sets of random test id and data are generated and written into " + test_file.name
  sys.exit(0) # exit after making the test file
elif (args.read_tests != None):
  # read existing test file and parse
  test_file = args.read_tests
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
  packet_len = send_data_bits + frame_bit_size_lp + \
               id_width_lp + frame_bit_size_lp + \
               len_width_lp + frame_bit_size_lp + \
               valid_bit_size_lp
  test_vector_bits += packet_len
  test_packet = send_data +\
                "_" + frame_bit +\
                "_" + dec2bin(test_id, id_width_lp) +\
                "_" + frame_bit +\
                "_" + dec2bin(packet_len, len_width_lp) +\
                "_" + frame_bit +\
                "_" + valid_bits
  l_test_packet.append(test_packet)
  test_idx += 1

# create a dictionary indexed by inst_id
# each node must be reset before random testing
for inst_id in l_inst_id: # initialize dictionary with config_node default values
  d_reference[inst_id] = [d_inst_default[inst_id]]
# if a new data item for an id is the same as its previous one, the new data is not appended as a new reference;
# because the verilog testbench is not able to detect signal change.
test_idx = 0
for test_id in l_test_id:
  test_data = l_test_data[test_idx]
  if d_reference.has_key(test_id): # extend an existing test sequence for a node having test_id
    last_index = len(d_reference[test_id]) - 1
    # if a new data item for an id is the same as its previous one, the new data is not appended.
    if(d_reference[test_id][last_index] != test_data):
      d_reference[test_id].append(test_data)
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

# write test vector to file
if (args.create_setter_file != None):
  setter_file = args.create_setter_file
  setter_file.write("# This is a file giving test input bit vector.\n" + \
                    "# The left-most bit is the first bit feeding into the configuration network first.\n" + \
                    "# You can modify this file to contain some specific testing pattern.\n" + \
                    "# Be sure you know how to modulate data and add headers, and change the vector bits value accordingly.\n")
  setter_file.write("vector bits: " + str(test_vector_bits) + "\n\n")
  setter_file.write(test_vector[::-1]) # the reversed string, for easy parsing in SystemVerilog testbench file
  setter_file.close()

# calculate the shift register length of the whole configuration network
shift_chain_length = 0
for key in d_inst_data_bits:
  data_bits = d_inst_data_bits[key]
  send_data_bits = data_bits + (data_bits / data_frame_len_lp) + frame_bit_size_lp
  shift_chain_length += send_data_bits + frame_bit_size_lp +\
                       id_width_lp + frame_bit_size_lp +\
                       len_width_lp + frame_bit_size_lp +\
                       valid_bit_size_lp

# revise simulation time to ensure all test bits walks through the whole configuration network
sim_time += (test_vector_bits + shift_chain_length + relay_nodes) * clk_cfg_period
# double the simulation time just to exercise config nodes longer
sim_time = sim_time * 2

# open and write expected change sequences to probe file
if (args.create_probe_file != None):
  probe_file = args.create_probe_file
  probe_file.write("# This is a file with all config_node IDs and their expect output sequences in testbench.\n" + \
                   "# The ID value of each config_node is given in decimal after \"config id: \".\n" + \
                   "# The number of test sets for a config_node is given in decimal after \"test sets: \".\n" + \
                   "# Below the ID line come expected configuration value change sequences in binary after \"reference: \".\n" + \
                   "# Each line is an expected output string and the first reference is the reset value of that config_node.\n" + \
                   "# Binary values of two adjacent reference lines are not allowed to be identical.\n" + \
                   "# \n" + \
                   "# The instance of config_node_bind module reads this file and test simulation outputs using this file's outputs as reference.\n" + \
                   "# Parsing of this file in VCS simulation is based on the first letter of each line.\n" + \
                   "# If this file becomes more complex in syntax, the parser should also be extended.")
  for key in d_reference:
    test_id = key
    probe_file.write("\n\nconfig id: " + str(test_id))
    tests = len(d_reference[test_id])
    probe_file.write("\ntest sets: " + str(tests))
    for test in range(0, tests):
      probe_file.write("\nreference: " + d_reference[test_id][test])
  probe_file.close()

# generate testbench file
if (args.testbench == None): sys.exit(0) # Do not generate testbench file

tb_file = args.testbench
tb_file.write("module config_net_tb;\n\n")

# write localparam
write_localparam(tb_file, "len_width_lp       ", str(len_width_lp))
write_localparam(tb_file, "id_width_lp        ", str(id_width_lp))
write_localparam(tb_file, "valid_bit_size_lp  ", str(valid_bit_size_lp))
write_localparam(tb_file, "frame_bit_size_lp  ", str(frame_bit_size_lp))
write_localparam(tb_file, "data_frame_len_lp  ", str(data_frame_len_lp))
write_localparam(tb_file, "reset_len_lp       ", str(reset_len_lp))
write_localparam(tb_file, "data_max_bits_lp   ", str(data_max_bits_lp))

tb_file.write(indent + "// double underscore __ separates test packet for each node\n")
write_localparam(tb_file, "test_vector_bits_lp", str(test_vector_bits))
write_localparam(tb_file, "test_vector_lp     ", str(test_vector_bits) + "'b" + test_vector)

# write clock and reset signals
tb_file.write("\n" + indent + "//\n")
write_logic(tb_file, clk_cfg)
write_logic(tb_file, rst_cfg)
write_logic(tb_file, clk_dst)
write_logic(tb_file, rst_dst)

# write config_s signals
write_config_s(tb_file, "config_root_i")
write_config_s(tb_file, "config_snooper_o")

# declare relay node outputs struct
for relay_id in range(0, relay_nodes):
  write_config_s(tb_file, "relay_" + str(relay_id) + "_o")

# declare output data
for inst_id in l_inst_id:
  if (inst_id != 'r'):
    l_inst_data_o.append("data_" + str(inst_id) + "_o")
    write_logic_vec(tb_file, "data_" + str(inst_id) + "_o", str(d_inst_data_bits[inst_id] - 1), '0')

# declare test vector logic
write_logic_vec(tb_file, "test_vector", str(test_vector_bits - 1), '0')

# declare snooper output logic
write_logic_vec(tb_file, "config_snooped_id", str(data_max_bits_lp - 1), '0')
write_logic_vec(tb_file, "config_snooped_data", str(data_max_bits_lp - 1), '0')

# write relay node tree structure to testbench file
tb_file.write("\n" + indent + "// " + "The relay node tree is generated as follows:\n")
for key in d_relay_tree:
  tb_file.write(indent + "// branch node " + str(key) + ": " + str(d_relay_tree[key]) + "\n")
# creat relay node tree
tb_file.write("\n" + indent + "// " + "Relay node 0 (root) \n")
write_relay_node(tb_file, "0", "config_root_i", "relay_0_o")
for key in d_relay_tree:
  branch = key
  for leaf in d_relay_tree[branch]:
    tb_file.write("\n" + indent + "// " + "Relay node " + str(leaf) + "\n")
    write_relay_node(tb_file, str(leaf), "relay_" + str(branch) + "_o", "relay_" + str(leaf) + "_o")

# instantiate and connect configuration nodes
for key in d_inst_pos:
  inst_id = key
  pos = d_inst_pos[key]
  tb_file.write("\n" + indent + "// " + d_inst_name[inst_id] + "\n")
  write_inst_node(tb_file, str(inst_id), str(d_inst_data_bits[inst_id]), d_inst_default[inst_id],\
                           "relay_" + str(pos) + "_o",\
                           "data_" + str(inst_id) + "_o")

# write clock generator
tb_file.write("\n")
tb_file.write(indent + "// clock generator\n")
tb_file.write(indent + "initial begin\n" + \
              indent + indent + clk_cfg + " = 1;\n" + \
              indent + indent + rst_cfg + " = 1;\n" + \
              indent + indent + clk_dst + " = 1;\n" + \
              indent + indent + rst_dst + " = 1;\n" + \
              indent + indent + "#" + str(clk_cfg_period / 2) + " " + rst_cfg + " = 0;\n" + \
              indent + indent + "#" + str(clk_dst_period)     + " " + rst_dst + " = 0;\n" + \
              indent + indent + "#" + str(clk_dst_period)     + " " + rst_dst + " = 1;\n" + \
              indent + indent + "#" + str(clk_dst_period)     + " " + rst_dst + " = 0;\n" + \
              indent + "end\n" + \
              indent + "always #" + str(clk_cfg_period / 2) + " begin\n" + \
              indent + indent + clk_cfg + " = ~" + clk_cfg + ";\n" + \
              indent + "end\n" + \
              indent + "always #" + str(clk_dst_period / 2) + " begin\n" + \
              indent + indent + clk_dst + " = ~" + clk_dst + ";\n" + \
              indent + "end\n")

# module config_setter and config_file_setter are used for the same purpose:
# reading test vectors from some source and serialized each bit to the module's
# output in each clock cycle. config_setter reads from a parameter, and this
# module is synthesizable; config_file_setter is not synthesizable and it reads
# from a formated file "config_file_setter.in". config_setter can be used with
# other components in this design to randomize test patterns for config_node
# network in simulation testbench.

# instantiate config_setter to deliver configuration bits
tb_file.write("\n")
tb_file.write(indent + "// instantiate config_setter to read configuration bits from localparams\n")
tb_file.write(indent + "config_setter #(.setter_vector_p(test_vector_lp),\n" + \
              indent + "                .setter_vector_bits_p(test_vector_bits_lp) )\n" + \
              indent + "  inst_setter  (.clk_i(" + clk_cfg + "),\n" + \
              indent + "                .reset_i(" + rst_cfg + "),\n" + \
              indent + "                .config_o() ); // not connected in simulation testbench\n")

# instantiate config_file_setter to deliver configuration bits
# module config_file_setter is used for reading setter vector bits from file
# and feed them to the configuration network.
tb_file.write("\n")
tb_file.write(indent + "// instantiate config_file_setter to read configuration bits from file\n")
tb_file.write(indent + "config_file_setter\n" + \
              indent + "  inst_file_setter(.clk_i(" + clk_cfg + "),\n" + \
              indent + "                   .reset_i(" + rst_cfg + "),\n" + \
              indent + "                   .config_o(config_root_i) );\n")

# insert snooper node
tb_file.write("\n")
tb_file.write(indent + "// insert snooper node\n")
tb_file.write(indent + "config_snooper\n" + \
              indent + "  inst_config_snooper(.clk(" + clk_dst + "),\n" + \
              indent + "                      .reset(" + rst_dst + "),\n" + \
              indent + "                      .config_i(config_root_i),\n" + \
              indent + "                      .id_o(config_snooped_id),\n" + \
              indent + "                      .data_o(config_snooped_data) );\n")

# create config_node_bind instance
tb_file.write("\n")
tb_file.write(indent + "// configuration node binding verification module\n" + \
              indent + "bind config_node config_node_bind #(.id_p(id_p),\n" + \
              indent + "                                    .data_bits_p(data_bits_p))\n" + \
              indent + "             inst_config_node_bind (clk, data_o);\n\n")

# create config_snooper_bind instance
tb_file.write("\n")
tb_file.write(indent + "// configuration snooper binding verification module\n" + \
              indent + "bind inst_config_snooper config_snooper_bind\n" + \
              indent + "          inst_config_snooper_bind (clk, id_o, data_o);\n\n")

# write simulation ending condition
tb_file.write("\n")
tb_file.write(indent + "// simulation end\n")
tb_file.write(indent + "initial begin\n" + \
              indent + indent + "#" + str(sim_time) + " $finish;\n" + \
              indent + "end\n")

# write "final" block
tb_file.write("\n")
tb_file.write(indent + "// simulation statistics\n")
tb_file.write(indent + "final begin\n" + \
#             indent + indent + "$display(\"\\n  - - - Configuration Network Simulation Statistics - - -\\n\");\n" + \
              indent + "end\n")

tb_file.write("\n//\n")
tb_file.write("endmodule\n\n")

tb_file.close()
