#!/usr/bin/python
#
# bsg_dff_gen
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

def rp_fill_string (params) :
    return "// synopsys rp_fill (" + params + ")"

def emit_rp_fill (params):
    print "// synopsys rp_fill (" + params +")"



# NOTE: for symmetric pins, assume that earlier ones are always faster.
# For example, for AOI22  A's are faster than B's and A0 is faster than A1.
#

fab = "gf_14"

#dffr1 = "DFKCND1BWP #0 (.D(#1), .CP(#3), .Q(#4),.QN(), .CN(#5));"
# note: reset has priority over enable for these E-cells
#dffre1 = "EDFKCND1BWP #0 (.D(#1), .E(#2), .CP(#3), .Q(#4),.QN(), .CN(#5));"
#dffre2 = "EDFKCND2BWP #0 (.D(#1), .E(#2), .CP(#3), .Q(#4),.QN(), .CN(#5));"
#dff1 = "DFD1BWP #0 (.D(#1), .CP(#3), .Q(#4), .QN());"
#dff2 = "DFD2BWP #0 (.D(#1), .CP(#3), .Q(#4), .QN());"
#dff4 = "DFD4BWP #0 (.D(#1), .CP(#3), .Q(#4), .QN());"
#dff8 = "wire tmp_bsg_dff8_#0;\n DFD1BWP #0 (.D(#1), .CP(#3), .Q(tmp_bsg_dff8_#0), .QN()); BUFFD8BWP #0_bsg_buf (.I(tmp_bsg_dff8_#0), .Z(#4));"
#dffe1 = "EDFD1BWP #0 (.D(#1), .E(#2), .CP(#3), .Q(#4),.QN());"
# FIXME (dffr1, dffre1, dffre2): This should be a synchronous reset_lo flop, but was specified here as asynchronous.
# FIXME: Maybe have to use AND gate with reset signal on input
dffr1 = "SC7P5T_DFFRQX1_SSC14L #0 (.D(#1), .CLK(#3), .Q(#4), .RESET(#5));"
dffre1 = "wire tmp_bsg_dffre1_#0;\n SC7P5T_MUX2X1_SSC14SL #0_bsg_mux (.S(#2), .D0(#4), .D1(#1), .Z(tmp_bsg_dffre1_#0)); SC7P5T_DFFRQX1_SSC14L #0 (.D(tmp_bsg_dffre1_#0), .CLK(#3), .Q(#4), .RESET(#5));"
dffre2 = "wire tmp_bsg_dffre2_#0;\n SC7P5T_MUX2X2_SSC14SL #0_bsg_mux (.S(#2), .D0(#4), .D1(#1), .Z(tmp_bsg_dffre1_#0)); SC7P5T_DFFRQX2_SSC14L #0 (.D(tmp_bsg_dffre1_#0), .CLK(#3), .Q(#4), .RESET(#5));"
dff1 = "SC7P5T_DFFQX1_SSC14SL #0 (.D(#1), .CLK(#3) .Q(#4));"
dff2 = "SC7P5T_DFFQX2_SSC14SL #0 (.D(#1), .CLK(#3) .Q(#4));"
dff4 = "SC7P5T_DFFQX4_SSC14SL #0 (.D(#1), .CLK(#3) .Q(#4));"
#FIXME: use DFF1 and BUF8 rather than DFF8 and BUF8, like in 40
#FIXME: two missing commas, wire is misnamed when used.
dff8 = "wire tmp_bsg_dff8_#0;\n SC7P5T_BUFX8_SSC14SL #0_bsg_buf (.A(tmp_bsg_dff8_#0), .Z(#4)); SC7P5T_DFFQX8_SSC14SL #0 (.D(#1), .CLK(#3) .Q(tmp_bsg_dff8_#0));"
dffe1 = "wire tmp_bsg_dffe1_#0;\n SC7P5T_MUX2X1_SSC14SL #0_bsg_mux (.S(#2), .D0(#4), .D1(#1), .Z(tmp_bsg_dffre1_#0)); SC7P5T_DFFQX1_SSC14SL #0 (.D(tmp_bsg_dffre1_#0), .CLK(#3) .Q(#4));"

string_to_cell = {};
string_to_cell["dffre1"] = dffre1;
string_to_cell["dffre2"] = dffre2;
string_to_cell["dffr1"] = dffr1;
string_to_cell["dff1"] = dff1;
string_to_cell["dff2"] = dff2;
string_to_cell["dff4"] = dff4;
string_to_cell["dff8"] = dff8;
string_to_cell["dffe1"] = dffe1;

string_to_suffix = {};
string_to_suffix["dffre1"] = "dff_nreset_en_s1";
string_to_suffix["dffre2"] = "dff_nreset_en_s2";
string_to_suffix["dffr1"] = "dff_nreset_s1";
string_to_suffix["dffe1"]  = "dff_en_s1";
string_to_suffix["dff1"] = "dff_s1";
string_to_suffix["dff2"] = "dff_s2";
string_to_suffix["dff4"] = "dff_s4";
string_to_suffix["dff8"] = "dff_s8";

string_to_param_list = {};
string_to_param_list["dffre2"] = ["nreset_i","en_i"];
string_to_param_list["dffre1"] = ["nreset_i","en_i"];
string_to_param_list["dffe1"]  = ["en_i"];
string_to_param_list["dffr1"]  = ["nreset_i"];
string_to_param_list["dff1"] = [];
string_to_param_list["dff2"] = [];
string_to_param_list["dff4"] = [];
string_to_param_list["dff8"] = [];

def generate_dff_nreset_en ( basecell, bits, strength ) :
    basecell = basecell+str(strength);
    module_name = ident_name_bit("bsg_rp_"+fab+"_"+string_to_suffix[basecell],bits);

    emit_module_header (module_name
                        , [ "clk_i"
                            , param_bits_all("data_i",bits)
                            ] + string_to_param_list[basecell]
        , [ param_bits_all("data_o",bits)]
    );
    column = 0

    emit_rp_group_begin("dff")

    for b in range (0,bits) :
        emit_rp_fill(" 0 " + str(column) + " RX");
        column=column+1;
        emit_gate_instance(string_to_cell[basecell]
                           ,[ ident_name_bit("reg",b)
                              , access_bit("data_i",b)
                              , "en_i"
                              , "clk_i"
                              , access_bit("data_o",b)
                              , "nreset_i"]
                           );

    emit_rp_group_end("dff")
    emit_module_footer()


if len(sys.argv) == 4 :
    # suffix, basecell;  e.g. dff, dff
    generate_dff_nreset_en( sys.argv[1], int(sys.argv[2]), int(sys.argv[3]) );
else :
    if ((len(sys.argv) == 5) and (sys.argv[4]=="SWEEP")) :
        for b in range (1,int(sys.argv[2])+1) :
            generate_dff_nreset_en( sys.argv[1], b, sys.argv[3] );
    else:
        print "Usage: " + sys.argv[0] + " type " + " bits " + " strength";
        print "Usage: " + sys.argv[0] + " type " + " bits " + " strength " + "SWEEP (to go from 1..bits)";

