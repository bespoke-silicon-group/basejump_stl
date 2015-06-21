#!/usr/bin/python
#
# bsg_comp42_gen < number of rows of 4:2 compressors >
#
#
#
# This script generates sections of 42: compressors for
# multipliers. (See Computer Arthmetic Google Doc.)
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

aoi22 = "AOI22X1 #0 (.A0(#1), .A1(#2), .B0(#3), .B1(#4), .Y(#5)  );"
xnor2 = "XNOR2X1 #0 (.A (#1), .B (#2), .Y (#3)                   );"
addf  = "ADDFHX1 #0 (.A (#1), .B (#2), .CI (#3), .S(#4), .CO(#5) );"


#
#     CSA
#     CSA
#

def generate_c42_block ( rows ) :
    module_name = ident_name_bit("bsg_rp_"+fab+"_comp42_block",rows);

    emit_module_header (module_name
                        , [  param_bits_all("i",4*rows) + " /*" + param_bits_2D_all("i",4,rows)+ "*/"
                            , "cr_i"
                            ]
                        , [ "cl_o", param_bits_all("c_o",rows), param_bits_all("s_o",rows)]
                        );
    column = 0

    emit_rp_group_begin("c42")

    for pos in range (0,rows) :
        print ""
        print "wire " + ident_name_bit("s_int",pos) +";";
        print "wire " + ident_name_bit("cl_int",pos)+";";

        emit_rp_fill("0 " + str(pos*2) + " UX");

        emit_gate_instance(addf
                           , [ ident_name_word_bit("add42", pos, 0)
                               , access_2D_bit("i", 3, pos, rows)
                               , access_2D_bit("i", 2, pos, rows)
                               , access_2D_bit("i", 1, pos, rows)
                               , ident_name_bit("s_int", pos)
                               , "cl_o" if (pos == rows-1) else ident_name_bit("cl_int",pos)
                               ]);

        # insert ADDF here
        emit_gate_instance(addf
                           , [ ident_name_word_bit("add42", pos, 1)
                               , access_2D_bit("i", 0, pos, rows)
                               , ident_name_bit("s_int", pos)
                               , ident_name_bit("cl_int" ,pos-1) if (pos > 0) else "cr_i"
                               , access_bit("s_o", pos)
                               , access_bit("c_o", pos)
                               ]);

    emit_rp_group_end("c42")
    emit_module_footer()

if len(sys.argv) == 2 :
        generate_c42_block (int(sys.argv[1]));
else :
    print "Usage: " + sys.argv[0] + " rows";

