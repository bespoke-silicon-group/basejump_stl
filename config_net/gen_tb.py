#!/usr/bin/python

import optparse
import subprocess
import time
import os
import re
import sys

import os.path


# ========== Global variables ==========
tb_file_name = "py_config_tb.v"
indent = "  " # indentation

spec_file_name = "sc_spec.in"

total_inst_nodes = 3 # scan chain nodes ==> to be determined by input file
l_inst_id = [] # list of unique decimals
d_inst_name = {} # dictionary of strings, indexed by inst id
d_inst_data_bits = {} # dictionary of decimals, indexed by inst id
d_inst_default = {} # dictionary of binary strings, indexed by inst id

# scan chain test sequence ==> to be randomized or from file
#l_test_id = [127, 5, 7]
#l_test_data = ["11111111", "1111111111101101", "100010110001110101000"]
l_test_id = [127, 5, 7, 5, 127]
l_test_data = ["11111111", "1111111111101101", "100010110001110101000", "0000000000000000", "00000000"]
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
l_inst_bit_i = ["bit_i"] # list of inputs bit_i for all nodes; the first one is "bit_i".
l_inst_data_o = [] # list of outputs data_o for all nodes
l_inst_bit_o = [] # list of outputs bit_o for all nodes

# ========== Functions ==========
def check_ptn(pattern, file): # ==> to go
  exist = False
  for line in file:
    if (re.search(pattern, line) != None):
      exist = True
  return exist

def dec2bin(dec, n): # ==> Only works on non-negative number
  if dec == 0: bin = "0"
  else:
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
  file.write(indent + "localparam  " + lhs + " =   " + rhs + ";\n")

def write_logic(file, name):
  file.write(indent + "logic  " + name + ";\n")

def write_logic_vec(file, name, msb, lsb):
  file.write(indent + "logic  [" + msb + " : " + lsb + "]  " + name + ";\n")

def write_inst_node(file, id, data_bits, default, clk_i, bit_i, data_o, bit_o):
  file.write("\
  config_node        #(.id_p(" + id + "),\n\
                       .data_bits_p(" + data_bits + "),\n\
                       .default_p(" + data_bits + "'b" + default + ") )\n\
    node_id_" + \
          id + "_dut(  .clk_i(" + clk_i + "),\n\
                       .bit_i(" + bit_i + "),\n\
                       .data_o(" + data_o + "),\n\
                       .bit_o(" + bit_o + ") );\n ")

# ========== ==========
# read scan chain specification file and parse
spec_file = open(spec_file_name, 'r')
for line in spec_file:
  line = line.rstrip('\n') # remove the newline character
  if line != "": # if not an empty line
    l_words = line.split() # split a line into a list of words on white spaces
    if (line[0] != '#') and (line[0] != ' '): # ignore lines starting with '#' or spaces
      node_id = int(l_words[1])
      l_inst_id.append(node_id)
      d_inst_name[node_id] = l_words[0]
      d_inst_data_bits[node_id] = int(l_words[2])
      d_inst_default[node_id] = l_words[3]
spec_file.close()

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
  print test_packet #==>
  print "test_vector_bits = " + str(test_vector_bits) #==>
  print "==>" #==>

test_idx = 0
# create a dictionary indexed by test id
for test_id in l_test_id:
  test_data = l_test_data[test_idx]
  if d_reference.has_key(test_id):
    d_reference[test_id].append(test_data)
  else:
    d_reference[test_id] = [test_data]
  test_idx += 1
print "dictionary:" # ==>
print d_reference # ==>

# create reset string
reset_string = ""
for bit in range(0, reset_len_lp): # 0, 1, ..., reset_len_lp - 1
  reset_string += '1'

test_vector_bits += reset_len_lp
# the whole test vector begins with reset string
test_vector = reset_string
# the first test packet in l_test_packet is fed into the configuration network first
for packet in l_test_packet:
  test_vector = packet + "__" + test_vector

# calculate the shift register width of the whole scan chain
shift_chain_width = 0
for key in d_inst_data_bits:
  data_bits = d_inst_data_bits[key]
  send_data_bits = data_bits + (data_bits / data_frame_len_lp) + frame_bit_size_lp
  shift_chain_width += send_data_bits + frame_bit_size_lp +\
                       id_width_lp + frame_bit_size_lp +\
                       len_width_lp + frame_bit_size_lp
  print "shift_chain_width = " + str(shift_chain_width) # ==>

# revise simulation time to ensure all test bits walks through the whole scan chain
sim_time += (test_vector_bits + shift_chain_width) * clk_tb_period

print "test_vector      = " + test_vector # ==>
print "test_vector_bits = " + str(test_vector_bits) #==>
print "shift_chain_width = " + str(shift_chain_width) # ==>
print "sim time = " + str(sim_time) # ==>

tb_file = open(tb_file_name, 'w')
tb_file.write("module config_net_tb;\n\n")

# write localparam
write_localparam(tb_file, "len_width_lp     ", str(len_width_lp))
write_localparam(tb_file, "id_width_lp      ", str(id_width_lp))
write_localparam(tb_file, "frame_bit_size_lp", str(frame_bit_size_lp))
write_localparam(tb_file, "data_frame_len_lp", str(data_frame_len_lp))
write_localparam(tb_file, "reset_len_lp     ", str(reset_len_lp))
tb_file.write(indent + "// double underscore __ separates test packet for each node\n")
write_localparam(tb_file, "test_vector_lp   ", str(test_vector_bits) + "'b" + test_vector)

# write reference output sequence as localparam

tb_file.write("\n" + indent + "//\n")
write_logic(tb_file, clk_tb)
write_logic(tb_file, reset_tb)

# declare output bits
for node_id in l_inst_id:
  index = l_inst_id.index(node_id)
  l_inst_bit_i.append("bit_o_" + str(node_id))
  l_inst_bit_o.append("bit_o_" + str(node_id))
  write_logic(tb_file, str(l_inst_bit_i[index]))

# declare output data
for node_id in l_inst_id:
  l_inst_data_o.append("data_o_" + str(node_id))
  write_logic_vec(tb_file, "data_o_" + str(node_id), str(d_inst_data_bits[node_id] - 1), '0')

# declare test vector logic
write_logic_vec(tb_file, "test_vector", str(test_vector_bits - 1), '0')

# instantiate and connect configuration nodes
for node_id in l_inst_id:
  index = l_inst_id.index(node_id)
  tb_file.write("\n" + indent + "// " + d_inst_name[node_id] + "\n")
  write_inst_node(tb_file, str(node_id), str(d_inst_data_bits[node_id]), d_inst_default[node_id],\
                           clk_tb, l_inst_bit_i[index], l_inst_data_o[index], l_inst_bit_o[index])

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

# initialize test vector
tb_file.write("\n")
# shift test vector to the right by 1 position
tb_file.write(indent + "// initialize and right shift test vector\n")
tb_file.write(indent + "always_ff @ (posedge " + clk_tb + ") begin\n" + \
              indent + indent + "if (" + reset_tb + ") begin\n" + \
              indent + indent + indent + "test_vector = test_vector_lp;\n" + \
              indent + indent + indent + "bit_i = test_vector[0];\n" + \
              indent + indent + "end else begin\n" + \
              indent + indent + indent + "test_vector = {1'b0, test_vector[" + str(test_vector_bits) + " - 1 : 1]};\n" + \
              indent + indent + indent + "bit_i = test_vector[0];\n" + \
              indent + indent + "end\n" + \
              indent + "end\n")

# write simulation ending condition
tb_file.write("\n")
tb_file.write(indent + "// simulation end\n")
tb_file.write(indent + "initial begin\n" + \
              indent + indent + "#" + str(sim_time) + " $finish;\n" + \
              indent + "end\n")

tb_file.write("\n//\n")
tb_file.write("endmodule\n\n")

tb_file.close()
