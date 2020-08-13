
import sys
import argparse
import math
import os
import subprocess

# Parse arguments
parser = argparse.ArgumentParser()
parser.add_argument("--file_name", dest='file_name', help="log file name")
args = parser.parse_args()

# Open log file
f = open(args.file_name, "r")
lines = f.readlines()

count_dict = {}
delay_dict = {}
final_dict = {}

for line in lines:
    stripped = line.strip()
    if stripped:
        array = stripped.split(":")
        param_string = array[0]
        param_name = param_string.split("/")[0]
        delay_value = float(array[2])
        
        if param_name in count_dict:
            count_dict[param_name] = count_dict[param_name] + 1.0
            delay_dict[param_name] = delay_dict[param_name] + delay_value
        else:
            count_dict[param_name] = 1.0
            delay_dict[param_name] = delay_value

for key in count_dict:
    final_dict[key] = delay_dict[key]/count_dict[key]

final_sorted = sorted(final_dict.items())

for item in final_sorted:
    print(item[0] + "," + str(item[1]))
