#!/usr/bin/python

#
# input format:
#  lines of verilog binary strings, e.g.
#    1001_10101_10011_1101
#  comments beginning with # sign
#  lines with just whitespace
#
# output format:
#  a module that implements a rom
#
# usage: bsg_ascii_to_rom.py <filename> <modulename>
#
# to compress out zero entries with a default 0 setting:
#
# usage: bsg_ascii_to_rom.py <filename> <modulename> zero  
# 
 
import sys;
import os;
import binascii;

zero = 0;

if ((len(sys.argv)==4) and sys.argv[3]=="zero") :
    zero = 1;

if ((len(sys.argv)!=3) and (len(sys.argv)!=4)) :
    print "Usage ascii_to_rom.py <filename> <modulename>";
    exit -1

myFile = open(sys.argv[1],"r");

i = 0;
print "// auto-generated by bsg_ascii_to_rom.py from " + os.path.abspath(sys.argv[1]) + "; do not modify";
print "`include \"bsg_defines.sv\""
print "module " + sys.argv[2] + " #(`BSG_INV_PARAM(width_p), `BSG_INV_PARAM(addr_width_p))";
print "(input  [addr_width_p-1:0] addr_i";
print ",output logic [width_p-1:0]      data_o";
print ");";
print "always_comb case(addr_i)"
all_zero = set("0_");
for line in myFile.readlines() :
    line = line.strip();
    if (len(line)!=0):
        if (line[0] != "#") :
            if (not zero or not (set(line) <= all_zero)) :
                digits_only = filter(lambda m:m.isdigit(), str(line));

                # http://stackoverflow.com/questions/2072351/python-conversion-from-binary-string-to-hexadecimal
                hstr = '%0*X' % ((len(digits_only) + 3) // 4, int(digits_only, 2))

                print str(i).rjust(10)+": data_o = width_p ' (" + str(len(digits_only))+ "'b"+line+");"+" // 0x"+hstr;
            i = i + 1;
        else :
            print "                                 // " + line;
if (zero) : 
    print "default".rjust(10) + ": data_o = { width_p { 1'b0 } };"
else :
    print "default".rjust(10) + ": data_o = 'X;"
print "endcase"
print "endmodule"
print "`BSG_ABSTRACT_MODULE(" + sys.argv[2] + ")"
