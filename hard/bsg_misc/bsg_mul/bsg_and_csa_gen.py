#!/usr/bin/python
#
# bsg_and_csa_gen < number of rows of 4:2 compressors >
#
#
#
# This script generates sections of AND, 3:2 compressors for
# multipliers. (See Computer Arthmetic Google Doc, "green block")
#
#
#
#

import sys;

def emit_module_header (name, input_args, output_args) :
    print "module " + name + " (",
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
    return gate_str;

def access_bit (name, bit) :
    return name + "[" + str(bit) + "]";

def access_2D_bit (name, word,bit,rows) :
    if (name == "i") :
        return name + "[" + str(word * rows + bit) + "]" + "/*" + name + "[" + str(word) + "][" + str(bit) + "]" + "*/";
    else :
        return "error";

def access_3D_bit (name, dof, word,bit) :
    
    if (name == "y_vec_i") :
        maxword = 4;
        maxbit = 2;
        return name + "[" + str(maxbit*(dof*maxword+word)+bit)+ "] /*" + name + "[" + str(dof) + "][" + str(word) + "][" + str(bit) + "]" + "*/";
    else :
        return "error";

def param_bits_all (name, bit) :
    return "[" + str(bit-1) + ":0] " + name;

def param_bits_2D_all (name, words,bit) :
    return "["+str(words-1) + ":0][" + str(bit-1) + ":0] " + name;

def param_bits_3D_all (name, words,bit,zop) :
    return "["+str(words-1) + ":0][" + str(bit-1) + ":0]["+str(zop-1)+":0] " + name;

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

fab = "tsmc_250"

and2 = "AND2X1 #0 (.A (#1), .B (#2), .Y (#3));"
addf  = "ADDFHX1 #0 (.A (#1), .B (#2), .CI (#3), .S(#4), .CO(#5) );"


#
#     CSA
#     CSA
#

def generate_and_csa_block ( rows ) :
    module_name = ident_name_bit("bsg_rp_"+fab+"_and_csa_block",rows);

    emit_module_header (module_name
                        , [  param_bits_all("x_i",rows)
                             , param_bits_all("y_i",rows)
                             , param_bits_all("z_and1_i",rows)
                             , param_bits_all("z_and2_i",rows)
                            ]
                        , [ param_bits_all("c_o",rows), param_bits_all("s_o",rows)]
                        );
    column = 0

    emit_rp_group_begin("and_csa")

    for pos in range (0,rows) :

        emit_rp_fill("0 " + str(pos*2) + " UX");
        print "wire " + ident_name_bit("and_int",pos) + ";";

        emit_gate_instance(addf
                           , [ ident_name_word_bit("csa", pos, 0)
                               # fastest input first
                               , ident_name_bit("and_int",pos)
                               , access_bit("x_i", pos)
                               , access_bit("y_i", pos)
                               , access_bit("s_o", pos)
                               , access_bit("c_o", pos)
                               ]);

        # insert ADDF here
        emit_gate_instance(and2
                           , [ ident_name_word_bit("and", pos, 0)
                               , access_bit("z_and1_i", pos)
                               , access_bit("z_and2_i", pos)
                               , ident_name_bit("and_int", pos)
                               ]);

    emit_rp_group_end("and_csa")
    emit_module_footer()

if len(sys.argv) == 2 :
        generate_and_csa_block(int(sys.argv[1]));
else :
    print "Usage: " + sys.argv[0] + " rows";

