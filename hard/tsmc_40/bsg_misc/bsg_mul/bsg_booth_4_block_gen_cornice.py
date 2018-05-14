#!/usr/bin/python
#
# bsg_booth_4_block_gen < number of continuous rows of 4 partial products >
#
#
#
# This script generates sections of partial product arrays for use in
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

def access_2D_bit (name, word,bit) :
    if (name == "SDN_i") :
        return name + "[" + str(word * 3 + bit) + "]" + "/*" + name + "[" + str(word) + "][" + str(bit) + "]" + "*/";
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
# fixme: the code currently assumes that the A input of ADDFHX's are the slowest
# input, which is true in TSMC. We should fix the code so that we swizzle
# the order in the below string, rather than in the code base, which is
# just confusing.

fab = "tsmc_40"

aoi22 = "AOI22X1 #0 (.A0(#1), .A1(#2), .B0(#3), .B1(#4), .Y(#5)  );"
xnor2 = "XNOR2X1 #0 (.A (#1), .B (#2), .Y (#3)                   );"
addf  = "ADDFHX1 #0 (.A (#1), .B (#2), .CI (#3), .S(#4), .CO(#5) );"


#
#   AOI22 (3)  XNOR2 (2) CSA   AOI22 (1)   XNOR2 (0)
#   XNOR2 (3)  AOI22 (2) CSA   XNOR2 (1)   AOI22 (0)
#

def generate_booth_4_block ( rows ) :
    module_name = ident_name_bit("bsg_rp_"+fab+"_booth_4_block_cornice",rows);

    emit_module_header (module_name
                        , [  param_bits_all("SDN_i",5*3) + " /*" + param_bits_2D_all("SDN_i",5,3)+ "*/"
                            , param_bits_all("y_vec_i",rows*4*2) + " /*" + param_bits_3D_all("y_vec_i",rows,4,2) + "*/"
                            ]
                        , [ "cl_o", param_bits_all("c_o",rows), param_bits_all("s_o",rows)]
                        );
    column = 0

    # handles the very first cornice, which is a omits the first two rows.
    if (rows == 8) :
        start_row = 0;
    else :
        if (rows == 6) :
            start_row = 2;

    emit_rp_group_begin("b4b")

    for pos in range (0,rows) :
        adj_pos = start_row + pos;

        print ""
        print "wire " + ",".join([ident_name_word_bit("pp",pos,b) for b in range(0,4)])+";"
        print "wire " + ",".join([ident_name_word_bit("aoi",pos,b) for b in range(0,4)])+";"
        print "wire " + ",".join([ident_name_word_bit("cl",pos,b) for b in range(0,1)])+";"
        print "wire " + ",".join([ident_name_word_bit("s0",pos,b) for b in range(0,1)])+";"


        # irritatingly, we need to place at least one cell at X position 0 for it to shift everything over.
        if (pos == rows-1) :
            emit_rp_fill("1 " + str(pos*2) + " RX");
        else :
            emit_rp_fill("0 " + str(pos*2) + " RX");
        #2
        if (adj_pos == 6 or adj_pos == 7) :
            emit_gate_instance(aoi22
                               , [ ident_name_word_bit ("aoi2"     ,pos,2)
                                   , access_2D_bit      ("SDN_i"       ,2+1,1)
                                   , access_3D_bit      ("y_vec_i" ,pos,2,0)
                                   , access_2D_bit      ("SDN_i"       ,2+1,2)
                                   , access_3D_bit      ("y_vec_i" ,pos,2,1)
                                   , ident_name_word_bit("aoi"     ,pos,2)
                                   ]);

   
        if (adj_pos != 0 and adj_pos != 1 and adj_pos != 3) :
            emit_gate_instance(addf
                               , [ ident_name_word_bit("add42", pos, 0)
                                   , "1'b0" if (adj_pos == 7 or adj_pos == 5 or adj_pos == 3 or adj_pos == 1) else access_2D_bit("SDN_i",(adj_pos>>1),0) # note "S" on diagram means N for SDN!!!
                                   , ident_name_word_bit("pp", pos, 1) if (adj_pos >= 4) else "1'b0"
                                   , ident_name_word_bit("pp", pos, 0)
                                   , ident_name_word_bit("s0", pos, 0) if (adj_pos == 7 or adj_pos == 6) else access_bit("s_o",pos)
                                   , (ident_name_word_bit("cl", pos, 0) if (adj_pos < 7) else "cl_o")
                                   if (adj_pos == 7 or adj_pos == 6) else access_bit("c_o",pos)
                                   ]);

        #1
        if (adj_pos >= 4) :
            emit_gate_instance(xnor2
                               , [ ident_name_word_bit ("xnor2",pos,1)
                                   , ident_name_word_bit("aoi"  ,pos,1)
                                   , access_2D_bit      ("SDN_i",    1+1,0)
                                   , ident_name_word_bit("pp"   ,pos,1)
                                   ]);


        #0
        if (adj_pos >= 2) :
            emit_gate_instance(aoi22
                               , [ ident_name_word_bit ("aoi2"    ,pos ,0)
                                   , access_2D_bit      ("SDN_i"        ,0+1 ,1)
                                   , access_3D_bit      ("y_vec_i" ,pos ,0,0)
                                   , access_2D_bit      ("SDN_i"        ,0+1 ,2)
                                   , access_3D_bit      ("y_vec_i" ,pos ,0,1)
                                   , ident_name_word_bit("aoi"     ,pos ,0)
                                   ]);

        # NEXT ROW

        emit_rp_fill("0 " + str(pos*2+1) + " RX");
        #2
        if (adj_pos == 6 or adj_pos == 7) :
            emit_gate_instance(xnor2
                               , [ ident_name_word_bit ("xnor2" ,pos ,2)
                                   , ident_name_word_bit("aoi"   ,pos ,2)
                                   , access_2D_bit      ("SDN_i"      ,2+1,0)
                                   , ident_name_word_bit("pp"    ,pos ,2)
                                   ]);

  
        # insert ADDF here
        if (adj_pos == 6 or adj_pos == 7) :
            emit_gate_instance(addf
                               , [ ident_name_word_bit("add42", pos, 1)
                                   , ident_name_word_bit("pp" , pos, 2)
                                   , ident_name_word_bit("s0" , pos, 0)
                                   , ident_name_word_bit("cl" , pos-1,0) if (adj_pos > 6) else "1'b0"
                                   , access_bit("s_o", pos)
                                   , access_bit("c_o", pos)
                                   ]);

  
        #1
        if (adj_pos >= 4) :
            emit_gate_instance(aoi22
                               , [ ident_name_word_bit ("aoi2"    ,pos,1)
                                   , access_2D_bit      ("SDN_i"       ,1+1,1)
                                   , access_3D_bit      ("y_vec_i" ,pos,1  ,0)
                                   , access_2D_bit      ("SDN_i"       ,1+1,2)
                                   , access_3D_bit      ("y_vec_i" ,pos,1  ,1)
                                   , ident_name_word_bit("aoi" ,pos,1)
                                   ]);

  
        #0
        if (adj_pos >= 2) :
            emit_gate_instance(xnor2
                               , [ ident_name_word_bit ("xnor2",pos,0)
                                   , ident_name_word_bit("aoi"  ,pos,0)
                                   , access_2D_bit      ("SDN_i",    0+1,0)
                                   , ident_name_word_bit("pp"   ,pos,0)
                                   ]);


        if (adj_pos == 0) :
            print "assign s_o[0] = SDN_i[0]; /* SDN_i[0][0] */ assign c_o[0] = 1'b0;"

        if (adj_pos == 1) :
            print "assign s_o[1] = 1'b0; assign c_o[1] = 1'b0;"

        if (adj_pos == 3) :
            print "assign s_o[" + str(pos) + "] = pp_w" + str(pos) + "_b0; assign c_o[" + str(pos) + "] = 1'b0;"


    emit_rp_group_end("b4b")
    emit_module_footer()

if len(sys.argv) == 2 :
        generate_booth_4_block (int(sys.argv[1]));
else :
    print "Usage: " + sys.argv[0]

