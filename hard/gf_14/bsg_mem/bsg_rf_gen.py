#!/usr/bin/python
#
# bsg_rf_gen_gf_14
#
# This script generates register files with deterministic naming, and placement directives.
#
# MBT 4/1/2015
# STD 5/4/2019 -- modified tsmc 40 version
#
#
# data_i:   input data
# write_sel_one_hot_i: write select
# clock_i:  clock
# data_o:   output data
# read_sel_one_hot_i:  read select
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

fab = "gf_14"

#dffe  = "EDFFX1  #0 (.D (#1), .E (#2), .CK(#3), .Q (#4), .QN()         );"
#aoi22 = "AOI22X1 #0 (.A0(#1), .A1(#2), .B0(#3), .B1(#4), .Y(#5) );"
#nand4 = "NAND4X1 #0 (.A (#1), .B (#2), .C (#3), .D (#4), .Y(#5) );"
#nor2  = "NOR2X2  #0 (.A (#1), .B (#2), .Y (#3)                  );"
#nand2 = "NAND2X2 #0 (.A (#1), .B (#2), .Y (#3)                  );"
#inv   = "INVX8   #0 (.A (#1), .Y(#2)                            );"
#invx3 = "INVX3   #0 (.A (#1), .Y(#2)                            );"
dffe = "wire tmp_bsg_dffe1_#0;\n SC7P5T_MUX2X1_SSC14SL #0_bsg_mux (.S(#2), .D0(#4), .D1(#1), .Z(tmp_bsg_dffre1_#0)); SC7P5T_DFFQX1_SSC14SL #0 (.D(tmp_bsg_dffre1_#0), .CLK(#3) .Q(#4));"
aoi22 = "SC7P5T_AOI22X1_SSC14SL #0 (.A1(#1), .A2(#2), .B1(#3), .B2(#4), .Z(#5));"
nand4 = "SC7P5T_ND4X2_SSC14SL #0 (.A(#1), .B(#2), .C(#3), .D(#4), .Z(#5));"
nor2 = "SC7P5T_NR2X2_SSC14SL #0 (.A(#1), .B(#2), .Z(#3));"
nand2 = "SC7P5T_ND2X2_SSC14SL #0 (.A(#1), .B(#2), .Z(#3));"
inv   = "SC7P5T_INVX8_SSC14SL #0 (.A (#1), .Z(#2));"
invx3 = "SC7P5T_INVX3_SSC14SL #0 (.A (#1), .Z(#2));"

# STD: Unused?
#cell_height=0.480
#width = { 'dffe'   : 
#         , 'aoi22' : 
#         , 'nand4' : 
#         , 'nor2'  : 
#         , 'nand2' : 
#         , 'inv8'  : 
#         , 'invx3' : 
#         , 'invx4' : 
#         }

# this has bits going vertically and words going horizontally
def generate_2_word_1r1w_array ( words, bits, readports):
    assert ( (words == 2) and readports == 1), "only words == 2 supported";

    module_name = ident_name_word_bit("bsg_rp_"+fab+"_rf",words,bits) + "_" + str(readports) + "r1w";

    emit_module_header (module_name
                        , [ "clock_i"
                            , param_bits_all("data_i",bits)
                            , param_bits_all("write_sel_one_hot_i",words)
                            , param_bits_all("read_sel_one_hot_i",words*readports)
                            ]
                        , [ param_bits_all("data_o",bits*readports)]
                        );
    column = 0

    emit_rp_group_begin("rf")

    for w in range (0,words) :
        emit_rp_fill(str(column) + " 0 UX");
        column=column+1;

        print "wire " +  ",".join([ident_name_word_bit("q",w,b) for b in range(0,bits)]) + ";";
        for b in range (0,bits) :

            emit_gate_instance(dffe
                                ,[ ident_name_word_bit("reg",w,b)
                                   , access_bit("data_i",b)
                                   , access_bit("write_sel_one_hot_i",w)
                                   , "clock_i"
                                   , ident_name_word_bit("q",w,b)]
                                );

    emit_rp_fill(str(column) + " 0 UX");
    column=column+1;

    print "wire " +  ",".join([ident_name_bit_port("qaoi",b,0) for b in range(0,bits)]) + ";";

    for b in range(0,bits) :
        emit_gate_instance(aoi22,
                            [ ident_name_bit_port("bsg_aoi22",b,0)
                              ,access_bit("read_sel_one_hot_i",0)
                              ,ident_name_word_bit("q",0,b)
                              ,access_bit("read_sel_one_hot_i",1)
                              ,ident_name_word_bit("q",1,b)
                              ,ident_name_bit_port("qaoi",b,0)
                              ]);

    emit_rp_fill(str(column) + " 0 UX");
    column=column+1;

    for b in range(0,bits) :
        emit_gate_instance(invx3,
                            [ ident_name_bit("bsg_inv",b)
                              , ident_name_bit_port("qaoi",b,0)
                              , access_bit("data_o",b)
                              ]);

    emit_rp_group_end("rf")
    emit_module_footer()


# this has bits going vertically and words going horizontally
def generate_4_word_1r1w_array ( words, bits, readports):
    assert ( (words == 4) and readports == 1), "only words == 4 supported";

    module_name = ident_name_word_bit("bsg_rp_"+fab+"_rf",words,bits) + "_" + str(readports) + "r1w";

    emit_module_header (module_name
                        , [ "clock_i"
                            , param_bits_all("data_i",bits)
                            , param_bits_all("write_sel_one_hot_i",words)
                            , param_bits_all("read_sel_one_hot_i",words*readports)
                            ]
                        , [ param_bits_all("data_o",bits*readports)]
                        );
    column = 0

    emit_rp_group_begin("rf")

    for bank in range(0,2) :
        for w in range (2*bank,2*bank+2) :
            emit_rp_fill(str(column) + " 0 UX");
            column=column+1;

            print "wire " +  ",".join([ident_name_word_bit("q",w,b) for b in range(0,bits)]) + ";";
            for b in range (0,bits) :

                emit_gate_instance(dffe
                                   ,[ ident_name_word_bit("reg",w,b)
                                      , access_bit("data_i",b)
                                      , access_bit("write_sel_one_hot_i",w)
                                      , "clock_i"
                                      , ident_name_word_bit("q",w,b)]
                                   );

        emit_rp_fill(str(column) + " 0 UX");
        column=column+1;

        print "wire " +  ",".join([ident_name_word_bit("qaoi",bank,b) for b in range(0,bits)]) + ";";

        for b in range(0,bits) :
            emit_gate_instance(aoi22,
                               [ ident_name_word_bit("bsg_aoi22",bank,b)
                                 ,access_bit("read_sel_one_hot_i",bank*2)
                                 ,ident_name_word_bit("q",bank*2,b)
                                 ,access_bit("read_sel_one_hot_i",bank*2+1)
                                 ,ident_name_word_bit("q",bank*2+1,b)
                                 ,ident_name_word_bit("qaoi",bank,b)
                                 ]);

    emit_rp_fill(str(column) + " 0 UX");
    column=column+1;

    # fixme: which nand2 is appropriate?
    for b in range(0,bits) :
        emit_gate_instance(nand2,
                            [ ident_name_bit("bsg_nand",b)
                              , ident_name_word_bit("qaoi",0,b)
                              , ident_name_word_bit("qaoi",1,b)
                              , access_bit("data_o",b)
                              ]);

    emit_rp_group_end("rf")
    emit_module_footer()

def generate_Nr1w_array ( words, bits, readports) :

    if (words == 2) :
        return generate_2_word_1r1w_array (words,bits,readports);

    if (words == 4) :
        return generate_4_word_1r1w_array (words,bits,readports);

    # this one has words going vertically and bits horizontally

    assert (words == 32 or words == 16 or words == 8), "only words == 32,16, and 8 is currently handled";

    # get the maximum width of a cell that is not the dffe
    # mux_width = max([v for k,v in width.iteritems() if k not in ('dffe')])

    module_name = ident_name_word_bit("bsg_rp_"+fab+"_rf",words,bits) + "_" + str(readports) + "r1w";

    emit_module_header (module_name
                        , [ "clock_i"
                            , param_bits_all("data_i",bits)
                            , param_bits_all("write_sel_one_hot_i",words)
                            , param_bits_all("read_sel_one_hot_i",words*readports)
                            ]
                        , [ param_bits_all("data_o",bits*readports)]
                        );
    column = 0

    emit_rp_group_begin("rf")

    for b in range (0,bits) :
        emit_wire_definition(ident_name_bit("data_i_inv",b));
        emit_rp_fill(str(column) +" 0 UX")
        # we generate the state first
        print "wire " +  ",".join([ident_name_word_bit("q",w,b) for w in range(words)]) + ";";
        for w in range (0,words) :
            emit_gate_instance(dffe
                               ,[ ident_name_word_bit("reg",w,b)
                                  , ident_name_bit("data_i_inv",b)
                                  , access_bit("write_sel_one_hot_i",w)
                                  , "clock_i"
                                  , ident_name_word_bit("q",w,b)]
                               );
        column=column+1


        # then muxes, one for each port
        for p in range(0,readports) :
            gate_dict = {};


            # only add input inverter on first port
            if (p == 0) :
                queue_gate_instance(gate_dict, inv
                                    , [ ident_name_bit("bsg_inv_in",b)
                                        ,  access_bit("data_i",b)
                                        , ident_name_bit("data_i_inv",b)
                                        ]
                                    , 1
                                    );

            # AOI22 every pair of words

            # we generate the state first
            print "wire " +  ",".join([ident_name_word_bit_port("qaoi",w,b,p) for w in range(0,words,2)]) + ";";

            for w in range (0,words,2) :
                queue_gate_instance(gate_dict, aoi22
                                    ,[ ident_name_word_bit_port("bsg_aoi22",w,b,p)
                                       ,access_bit("read_sel_one_hot_i",words*p+w)    # crit
                                       ,ident_name_word_bit("q",      w,b)
                                       ,access_bit("read_sel_one_hot_i",words*p+w+1)  # crit
                                       ,ident_name_word_bit("q",      w+1,b)
                                       ,ident_name_word_bit_port("qaoi",w,b,p)
                                       ]
                                    ,w
                                    );

            # NAND4 each pair
            for w in range (0,words,8) :
                emit_wire_definition_nocr(ident_name_word_bit_port("nand",w,b,p));
                queue_gate_instance(gate_dict, nand4
                                    , [ident_name_word_bit_port("bsg_nand4",w,b,p)
                                       , ident_name_word_bit_port("qaoi",w+0,b,p)
                                       , ident_name_word_bit_port("qaoi",w+2,b,p)
                                       , ident_name_word_bit_port("qaoi",w+4,b,p)
                                       , ident_name_word_bit_port("qaoi",w+6,b,p)
                                       , ident_name_word_bit_port("nand",w,b,p)]
                                    ,w+3
                                    );

            if (words >= 16) :
                # NOR2 each group of 8
                for w in range (0,words,16) :
                    emit_wire_definition_nocr(ident_name_word_bit_port("nor2",w,b,p));
                    queue_gate_instance(gate_dict, nor2
                                        , [ ident_name_word_bit_port("bsg_nor2",w,b,p)
                                            , ident_name_word_bit_port("nand",w,b,p)
                                            , ident_name_word_bit_port("nand",w+8,b,p)
                                            , ident_name_word_bit_port("nor2",w,b,p)
                                            ]
                                        ,w+7
                                        );

                 # NAND2 each group of 16
                for w in range (0,words,32) :
                    emit_wire_definition_nocr(ident_name_word_bit_port("nand2",w,b,p));
                    queue_gate_instance(gate_dict, nand2
                                        , [ ident_name_word_bit_port("bsg_nand2",w,b,p)
                                            , ident_name_word_bit_port("nor2",w,b,p)
# the 16 if (words > 16) else 0 hack allows 16 word RF's to be generated
# (fixme; it would be more efficient to run through an inverter rather than a nand2 gate for 16 word RF's!)
#
                                            , ident_name_word_bit_port("nor2",w+(16 if (words>16) else 0),b,p)
                                            , ident_name_word_bit_port("nand2",w,b,p)
                                            ]
# tweak placement to position 13 for words == 16
                                        , w+(15 if (words > 16) else 13)
                                        );

                print "\n";
                # add inverters to data in, and data out.
                # these are on opposite sides of the array
                # we may potentially pay in delay, but we get
                # a lot in isolation and usability, with no area cost.

            if (words >= 16) :
                my_nand = "nand2";
            else :
                my_nand = "nand";

            queue_gate_instance(gate_dict, inv
                                , [ ident_name_word_bit_port("bsg_inv_out",w,b,p)
                                    , ident_name_word_bit_port(my_nand,0,b,p)
                                    , access_bit("data_o",p*bits+b)
                                    ]
                                , words-1  # put this gate right at the end
                                );

            # we output the bits roughly in order
            # this should not technically be necessary
            # since we are using rp_fill commands
            # but it makes things more readable

            for x in sorted(gate_dict.items(), key=lambda x: x[1]) :
                emit_rp_fill( str(column) +" "+str(x[1])+" UX")
                print x[0], "// ",x[1];
            column=column+1


    emit_rp_group_end("rf")
    emit_module_footer()

if len(sys.argv) == 4 :
    generate_Nr1w_array (int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]));
else :
    print "Usage: " + sys.argv[0] + " words bits readports";

