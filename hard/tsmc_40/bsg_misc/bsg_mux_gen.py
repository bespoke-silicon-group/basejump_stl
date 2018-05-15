#!/usr/bin/python
#
# bsg_mux_gen_tsmc_40
#
# This script generates one hot muxes.
#
# data_i:   input data
# data_o:   output data
# sel_one_hot_i  :  one hot signal
#           0 - recycle data
#           1 - take data from previous node
#           2 - take data from data_i
#
#
# there are a few ways to implement the 3-input one hot mux:
#
# AOI222X1:     need an additional inverter. area 8.1 delay .17 to .33
# NAND2, NAND3:      NAND2 delay:  .03 to .05; NAND3 delay: .04 to .11
#
# only real issue with using the NAND's is hold time...
#

import sys;

def emit_module_header (name, input_args, output_args) :
    print "module " + name + "(",
    my_list = []
    for x in input_args :
        my_list.append("input "+x+"\n");
    for x in output_args :
        my_list.append("output "+x+"\n");
    print (" "*(len(name)+8)+",").join(my_list);

    print ");";

def emit_module_footer( ) :
    print "endmodule";

def emit_wire_definition (name) :
    print "wire " + name + "; "

def emit_wire_definition_nocr (name) :
    print "wire " + name + "; ",

def emit_gate_instance (gate_str, arg_list ) :
    print gate_instance(gate_str,arg_list);

def queue_gate_instance (out_dict, gate_str, arg_list, order) :
    the_string = gate_instance(gate_str,arg_list)
    out_dict[the_string] = order

def gate_instance (gate_str, arg_list ) :
    for i in range(0,len(arg_list)) :
        gate_str = gate_str.replace("#"+str(i),arg_list[i]);
    return "// synopsys rp_orient ({N FS} " + arg_list[0] + ")\n" + gate_str;

def access_bit (name, bit) :
    return name + "[" + str(bit) + "]";

def param_bits_all (name, bit) :
    return "[" + str(bit-1) + ":0] " + name;

def ident_name_word_bit (name,word,bit) :
    return name + "_w" + str(word) + "_b" + str(bit);

def ident_name_bit_port (name,bit,port) :
    return name + "_b" + str(bit) + "_p" + str(port);

def ident_name_word_bit_port (name,word,bit,port) :
    return name + "_w" + str(word) + "_b" + str(bit) + "_p" + str(port);

def ident_name_bit (name,bit) :
    return name + "_b" + str(bit);


def emit_rp_group_begin (name) :
    print "// synopsys rp_group (" + name + ")"

def emit_rp_group_end (name) :
    print "// synopsys rp_endgroup (" + name +")"

def emit_rp_fill (params):
    print "// synopsys rp_fill (" + params +")"



# NOTE: for symmetric pins, assume that earlier ones are always faster.
# For example, for AOI22  A's are faster than B's and A0 is faster than A1.
#

fab = "tsmc_40"

#nand2 = "NAND2X2 #0 (.A (#1), .B (#2), .Y (#3)                   );"
#nand3 = "NAND3X2 #0 (.A (#1), .B (#2), .C(#3), .Y (#4)           );"
#nand4 = "NAND4X2 #0 (.A (#1), .B (#2), .C(#3), .D(#4), .Y (#5)   );"
nand2 = "ND2D2BWP #0 (.A1 (#1), .A2 (#2), .ZN(#3)                    );"
nand3 = "ND3D2BWP #0 (.A1 (#1), .A2 (#2), .A3 (#3), .ZN(#4)          );"
nand4 = "ND4D2BWP #0 (.A1 (#1), .A2 (#2), .A3 (#3), .A4 (#4), .ZN(#5));"

# this has bits going vertically and words going horizontally
def generate_mux_shift ( inputs, bits):
    if (inputs == 4) :
        left  = 2;
        right = 2;
        joiner = nand4;
    else:
        if (inputs == 3) :
            left  = 2;
            right = 1;
            joiner = nand3;
        else:
            if (inputs == 2) :
                left  = 1;
                right = 1;
                joiner = nand2;

    module_name = ident_name_word_bit("bsg_rp_"+fab+"_mux",inputs,bits);

    emit_module_header (module_name
                        , [ param_bits_all("data_i",inputs*bits)
                            , param_bits_all("sel_one_hot_i",inputs)
                            ]
                        , [ param_bits_all("data_o",bits)]
                        );
    column = 0

    emit_rp_group_begin("mux_gen")

    for g in range(0,left) :
        emit_rp_fill(str(column) + " 0 UX");
        column=column+1;

        print "wire " +  ",".join([ident_name_word_bit("a2",g,b) for b in range(0,bits)]) + ";";

        for b in range (0,bits) :

            # this mux is optimized for data in to out
            # if we want to optimize for select in to out
            # we would flip the two inputs.
            emit_gate_instance(nand2
                               ,[ ident_name_word_bit("nand2",g,b)
                                  , access_bit("data_i",bits*g+b)
                                  , access_bit("sel_one_hot_i",g)
                                  , ident_name_word_bit("a2",g,b)
                                  ]
                               );
    emit_rp_fill(str(column) + " 0 UX");
    column=column+1;

    for g in range(left,left+right) :
        print "wire " +  ",".join([ident_name_word_bit("a2",g,b) for b in range(0,bits)]) + ";";

    for b in range(0,bits) :
        emit_gate_instance(joiner
                           ,[ ident_name_word_bit("join",g,b)]
                           + [ident_name_word_bit("a2",w,b) for w in range(0,left+right)]
                           + [access_bit("data_o",b)]
                           );

    for g in range(left,left+right) :
        emit_rp_fill(str(column) + " 0 UX");
        column=column+1;

        for b in range (0,bits) :

            # this mux is optimized for data in to out
            # if we want to optimize for select in to out
            # we would flip the two inputs.

            emit_gate_instance(nand2
                               ,[ ident_name_word_bit("nand2",g,b)
                                  , access_bit("data_i",bits*g+b)
                                  , access_bit("sel_one_hot_i",g)
                                  , ident_name_word_bit("a2",g,b)
                                  ]
                               );

    emit_rp_group_end("mux_gen")
    emit_module_footer()



if len(sys.argv) == 3 :
        generate_mux_shift (int(sys.argv[1]), int(sys.argv[2]));
else :
    print "Usage: " + sys.argv[0] + " inputs bits";

