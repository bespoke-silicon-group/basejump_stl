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

fab = "gf_14"

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
    return "// synopsys rp_orient ({N FS} " + arg_list[0] + ")\n" + gate_str;

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

def generate_gate_stack ( gatename, rows,signature, vert) :
    if (vert) :
        module_name = ident_name_bit("bsg_rp_"+fab+"_"+gatename,rows);
    else :
        module_name = ident_name_bit("bsg_rp_"+fab+"_"+gatename+"_horiz",rows);

    num_inputs = signature.count('#') - 2;
    input_params = [param_bits_all("i"+str(x),rows) for x in range(0,num_inputs)]
    emit_module_header (module_name
                        , input_params
                        , [ param_bits_all("o",rows)]
                        );
    column = 0

    emit_rp_group_begin(gatename)

    for pos in range (0,rows) :

        if (vert) :
            emit_rp_fill("0 " + str(pos) + " UX");
        else :
            emit_rp_fill(str(pos) +" 0 UX");

        # NOTE: for symmetric pins, assume that earlier ones are always faster.
        # For example, for AOI22  A's are faster than B's and A0 is faster than A1.

        input_params = [access_bit("i"+str(x),pos) for x in range(0,num_inputs)]
        output_params = [ access_bit("o",pos) ]
        emit_gate_instance(gatename + " " + signature # " #0 (.A (#1), .B (#2), .Y (#3));"
                           , [ident_name_bit("stack", pos)] +
                               input_params +
                               output_params
                             );

    emit_rp_group_end(gatename)
    emit_module_footer()

if len(sys.argv) == 4 :
    if sys.argv[2].isdigit() :
        for x in range(1,int(sys.argv[2])+1) :
            print "\n// ****************************************************** \n"
            generate_gate_stack(sys.argv[1],x,sys.argv[3],1);
    elif (sys.argv[2][0]=="-") :
        for x in range(1,-(int(sys.argv[2]))+1) :
            print "\n// ****************************************************** \n"
            generate_gate_stack(sys.argv[1],x,sys.argv[3],0);

elif len(sys.argv) == 5 :
    signature=sys.argv[3]
    num_inputs = signature.count('#') - 2;
    input_params = ["input [width_p-1:0] i"+str(x) for x in range(0,num_inputs)]
    print '''

module bsg_'''+sys.argv[4],'''#(width_p="inv",harden_p=1)
   ('''+"\n    ,".join(input_params)+'''
    , output [width_p-1:0] o
    );
'''

    for x in range(1,int(sys.argv[2])+1) :
        print ''' if (harden_p && (width_p=='''+str(x)+'''))
    begin:macro
      bsg_rp_tsmc_40_'''+sys.argv[1]+'''_b'''+str(x)+''' gate(.*);
    end
 else ''';
    print '''
   begin: notmacro
       initial assert(0!=1) else $error("%m unsupported gatestack size",width_p);
   end

endmodule
'''
else :
    print "Usage: bsg_gate_stack_gen.py AND2X1 32 > bsg_and_stacks.v # generate each individual netlist of each size"
    print "       bsg_gate_stack_gen.py AND2X1 32 and > bsg_and.v    # generate the verilog function that thunks to the right netlist"
