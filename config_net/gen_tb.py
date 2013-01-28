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

total_inst_nodes = 3 # scan chain nodes ==> to be determined by input file
l_inst_name = ["Node1", "Node2", "Node3"]
l_inst_id = [5, 12, 39]
l_inst_data_bits = [16, 8, 10]
l_inst_default = [10, 0, 15]

# scan chain test sequence ==> to be randomized or from file
l_test_id = [5, 39, 5, 12]
l_test_data = ["1111111011110000", "1110111000", "0000111100001111", "11111111"]
l_test_packet = []

# scan chain communication protocol parameters, applying to all nodes
valid_bit = '0' #
frame_bit = '0' #
len_width_lp = 8 # lenth field width in the scan chain
id_width_lp = 8 # id field width in the scan chain
frame_bit_size_lp = 1 # scan chain protocol frame bits size
data_frame_len_lp = 8 # scan chain protocol data frame length in bits
reset_len_lp = 10 # scan chain reset signal length in bits

#
global_clk = "clk_i"
global_clk_period = 10 # time units
sim_time = 3500 # time units

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
  data = data[::-1] # reverse the string; in python data[0] is the msb
  for idx in range(1, len(data) + 1): # 1, 2, 3 ... len(data)
    if idx % data_frame_len_lp == 0:
      framed_data = frame_bit + "_" + data[idx - 1] + framed_data
      if idx != len(data):
        framed_data = "_" + framed_data
    else:
      framed_data = data[idx - 1] + framed_data
  framed_data = frame_bit + "_" + framed_data
  return framed_data

def write_localparam(file, name, value):
  file.write(indent + "localparam  " + name + " =   " + value + ";\n")

def write_logic(file, name):
  file.write(indent + "logic  " + name + ";\n")

def write_logic_vec(file, name, msb, lsb):
  file.write(indent + "logic  [" + msb + " - 1 : " + lsb + "]  " + name + ";\n")

def write_inst_bit_i(file, name, index):
  write_logic(file, "bit_i" + l_inst_id[index])

def write_cnode(file, id, data_bits, default, clk_i, bit_i, data_o, bit_o):
  file.write("\
    config_node          #(.id_p(" + id + "),\n\
                           .data_bits_p(" + data_bits + "),\n\
                           .default_p(" + default + ") )\n\
      config_inst_" + \
              id + "_dut(  .clk_i(" + clk_i + "),\n\
                           .bit_i(" + bit_i + "),\n\
                           .data_o(" + data_o + "),\n\
                           .bit_o(" + bit_o + ") );\n ")

# ========== ==========
tb_file = open(tb_file_name, 'w')
tb_file.write("module config_net_tb;\n\n")

write_localparam(tb_file, "len_width_lp     ", str(len_width_lp))
write_localparam(tb_file, "id_width_lp      ", str(id_width_lp))
write_localparam(tb_file, "frame_bit_size_lp", str(frame_bit_size_lp))
write_localparam(tb_file, "data_frame_len_lp", str(data_frame_len_lp))
write_localparam(tb_file, "reset_len_lp     ", str(reset_len_lp))

tb_file.write("\n//\n")
write_logic(tb_file, global_clk);

test_idx = 0
for test_id in l_test_id:
  inst_idx = l_inst_id.index(test_id)
  send_data = insert_frame_bits(l_test_data[test_idx])
  data_bits = l_inst_data_bits[inst_idx]
  send_data_bits = data_bits + (data_bits / data_frame_len_lp) + frame_bit_size_lp
  packet_len = send_data_bits + frame_bit_size_lp + id_width_lp + frame_bit_size_lp + len_width_lp + frame_bit_size_lp
  #test_packet = send_data + frame_bit + dec2bin(id) + frame_bit + dec2bin(packet_len) + valid_bit # valid bit
  test_packet = send_data +\
                "_" + frame_bit +\
                "_" + dec2bin(test_id, id_width_lp) +\
                "_" + frame_bit +\
                "_" + dec2bin(packet_len, len_width_lp) +\
                "_" + valid_bit
  l_test_packet.append(test_packet)
  test_idx += 1;
  print test_packet
  print "==>"

print dec2bin(0, 1)
print dec2bin(1, 2)
print dec2bin(10, 3)
print dec2bin(15, 3)
print dec2bin(255, 10)
print dec2bin(256, 11)
print "== == framed data == =="
print insert_frame_bits("10")
print insert_frame_bits("1010")
print insert_frame_bits("0101010")
print insert_frame_bits("10101010")
print insert_frame_bits("11111110000000")
print insert_frame_bits("1111111100000000")
print insert_frame_bits("1110001111111100000000")
print insert_frame_bits("011110001111111100000000")

for node_id in l_inst_id:
  index = l_inst_id.index(node_id)
  l_inst_bit_i.append("bit_o_" + str(node_id))
  l_inst_bit_o.append("bit_o_" + str(node_id))
  write_logic(tb_file, str(l_inst_bit_i[index]))

for node_id in l_inst_id:
  index = l_inst_id.index(node_id)
  l_inst_data_o.append("data_o_" + str(node_id))
  write_logic_vec(tb_file, "data_o_" + str(node_id), str(l_inst_data_bits[index]), str(l_inst_default[index]));

for node_id in l_inst_id:
  index = l_inst_id.index(node_id)
  tb_file.write("\n" + indent + indent + "// " + l_inst_name[index] + "\n")
  write_cnode(tb_file, str(node_id), str(l_inst_data_bits[index]), str(l_inst_default[index]),\
                       "clk_i", l_inst_bit_i[index], l_inst_data_o[index], l_inst_bit_o[index])

# write clock generator
tb_file.write("\n")
tb_file.write(indent + "// clock generator\n")
tb_file.write(indent + "initial begin\n" + \
              indent + indent + global_clk + " = 1;\n" + \
              indent + "end\n" + \
              indent + "always #" + str(global_clk_period / 2) + " begin\n" + \
              indent + indent + global_clk + " = ~" + global_clk + ";\n" + \
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
