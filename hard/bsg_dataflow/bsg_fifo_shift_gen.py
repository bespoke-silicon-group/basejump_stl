#!/usr/bin/python
#
# bsg_shift_gen_tsmc_250
#
# This script generates shift registers with deterministic naming, and placement directives.
#
# data_i:   input data
# clock_i:  clock
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

fab = "tsmc_250"

dffxl   = "DFFXL #0 (.D(#1), .CK(#2), .Q(#3), .QN()              );"
dffx2   = "DFFX2 #0 (.D(#1), .CK(#2), .Q(#3), .QN()              );"
nand2 = "NAND2XL #0 (.A (#1), .B (#2), .Y (#3)          );"
nand3 = "NAND3XL #0 (.A (#1), .B (#2), .C(#3), .Y (#4)  );"

# this has bits going vertically and words going horizontally
def generate_fifo_shift_array ( words, bits):

    module_name = ident_name_word_bit("bsg_rp_"+fab+"_fifo_shift",words,bits);

    emit_module_header (module_name
                        , [ "clk_i"
                            , param_bits_all("data_i",bits)
                            , param_bits_all("sel_one_hot_i",3*words)
                            ]
                        , [ param_bits_all("data_o",bits)]
                        );
    column = 0

    emit_rp_group_begin("fifo_shift")

    for w in range (0,words+1) :
        print "wire " +  ",".join([ident_name_word_bit("reg",w,b) for b in range(0,bits)]) + ";";

    for b in range(0,bits) :
        print "assign " + access_bit("data_o",b)+ " = ", ident_name_word_bit("reg",0,b) + ";";

    for w in reversed(range (0,words)) :

        for g in [1, 2, 0] :
            if (g != 1 or w < words-1) :
                emit_rp_fill(str(column) + " 0 UX");
                column=column+1;

                print "wire " +  ",".join([ident_name_word_bit_port("a2",w,b,g) for b in range(0,bits)]) + ";";

                for b in range (0,bits) :
                    # we put the selects first on these gates because
                    # that is the faster input. in general, the critical path
                    # is select line, which is updated at the end of the cycle
                    # when we discover if there is an enque or a deque.

                    if (g == 0) :
                        emit_gate_instance(nand2
                                           ,[ ident_name_word_bit_port("nand2",w,b,g)
                                              , access_bit("sel_one_hot_i",w*3+g)
                                              , ident_name_word_bit("reg",w,b)
                                              , ident_name_word_bit_port("a2",w,b,g)]
                                           );
                    else:
                        if (g == 1) :
                            # no value to forward if it's the last item in the chain
                            emit_gate_instance(nand2
                                               ,[ ident_name_word_bit_port("nand2",w,b,g)
                                                  , access_bit("sel_one_hot_i",w*3+g)
                                                  , ident_name_word_bit("reg",w+1,b)
                                                  , ident_name_word_bit_port("a2",w,b,g)]
                                               );
                        else:
                            if (g == 2) :
                                emit_gate_instance(nand2
                                                   ,[ ident_name_word_bit_port("nand2",w,b,g)
                                                      , access_bit("sel_one_hot_i",w*3+g)
                                                      , access_bit("data_i",b)
                                                      , ident_name_word_bit_port("a2",w,b,g)]
                                               );
        emit_rp_fill(str(column) + " 0 UX");
        column=column+1;

        print "wire " +  ",".join([ident_name_word_bit("a3",w,b) for b in range(0,bits)]) + ";";
        for b in range (0,bits) :
            if (w < words - 1) :
                emit_gate_instance(nand3
                                   ,[ ident_name_word_bit("nand3",w,b)
                                      , ident_name_word_bit_port("a2",w,b,2)
                                      , ident_name_word_bit_port("a2",w,b,0)
                                      , ident_name_word_bit_port("a2",w,b,1)
                                      , ident_name_word_bit("a3",w,b)
                                      ]
                                   );
            else :
                emit_gate_instance(nand2
                                   ,[ ident_name_word_bit("nand3",w,b)
                                      , ident_name_word_bit_port("a2",w,b,0)
                                      , ident_name_word_bit_port("a2",w,b,2)
                                      , ident_name_word_bit("a3",w,b)
                                      ]
                                   );

        emit_rp_fill(str(column) + " 0 UX");
        column=column+1;

        for b in range (0,bits) :
            emit_gate_instance(dffx2 if (w==0) else dffxl
                               ,[ ident_name_word_bit("dff",w,b)
                                  , ident_name_word_bit("a3",w,b)
                                  , "clk_i"
                                  , ident_name_word_bit("reg",w,b)
                                  ]
                               );


    emit_rp_group_end("fifo_shift")
    emit_module_footer()



if len(sys.argv) == 3 :
        generate_fifo_shift_array (int(sys.argv[1]), int(sys.argv[2]));
else :
    print "Usage: " + sys.argv[0] + " words bits";

