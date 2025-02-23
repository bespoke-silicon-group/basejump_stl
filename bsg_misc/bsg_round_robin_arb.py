#!/usr/bin/python

"""
Round robin arbitration unit generator

Bandhav Veluri 01/29/2016

Added the Hold logic by Shaolin Xie(shawnless.xie@gmail.com), 12/09/2016
==> When there is only 1 request and the request is with the highest priority,
    don't update the grant register, so the master with most request would get
    more priorities.
"""

from __future__ import print_function

import sys, math

def calculate_grants(last, reqs_w):
    """
    Returns the list of all possible request-grant pairs
    for a given last-read channel
    """
    result = []
    inp = ["?"] * reqs_w
    grant = ["0"] * reqs_w
    curr = (last+1) % reqs_w
    for i in range(reqs_w):
        inp[-curr-1] = "1"
        grant[-curr-1] = "1"
        result.append(("".join(inp), "".join(grant)))
        inp[-curr-1] = "0"
        grant[-curr-1] = "0"
        curr = (curr+1) % reqs_w
    return result


def get_single_request_str(last_r, reqs_w):
    """ 
    Returns the string that represens the request which would trigger the hold 
    on condition
    """
    req_string = ["0"]*reqs_w
    req_string[ (last_r + 1) % reqs_w ] = "1"
    
    return "".join(req_string)

def print_hold_on_logic(last_w, reqs_w):
    """
    Print the logic of the hold on logic 
    """
    print ("""
if ( hold_on_sr_p ) begin """)
    print ("""   
    always_comb begin
        unique casez( last_r )""")           
    for last_r in range(reqs_w ):
        last_r_str = bin(last_r)[2:].zfill(last_w);
        req_str    = get_single_request_str(last_r, reqs_w)
        #Full cases
        if( (last_r == ( (1<< last_w) -1 ) ) & (last_r == (reqs_w-1) ) ):
            print ("""           default: hold_on_sr = ( reqs_i == %d'b%s );"""%( reqs_w, req_str))
        #Not Full cases
        else : 
            print ("""           %d'b%s : hold_on_sr = ( reqs_i == %d'b%s );"""%( last_w, last_r_str, reqs_w, req_str))

    #Not full cases
    if( (1<< last_w ) != reqs_w ):
        print ("""           default : hold_on_sr = 1'b0;""")

    print ("""       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p """)

################################################################################
#    Logic for priority reset logic
################################################################################

def print_reset_on_logic(reqs_w):
    """
    Print the logic of the logic of reset on signle request 
    """

    req_str= get_single_request_str(0, reqs_w)

    print ("""
if ( reset_on_sr_p ) begin:reset_on_%d 
    assign reset_on_sr = ( reqs_i == %d'b%s ) """%( reqs_w,reqs_w, req_str))

    for curr_r in range(1, reqs_w):
        req_str= get_single_request_str(curr_r, reqs_w)
        print ("""                       | ( reqs_i == %d'b%s ) """ %(reqs_w, req_str ))
    
    print ("                       ;")
    print ("""
end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p """)
max_reqs = 0 # no. of inputs
try:
    assert len(sys.argv) == 2
    max_reqs = int(sys.argv[1])
except:
    print ("UsageError: bsg_round_robin_arb.py <max no. of channels>")
    sys.exit()

print ("""// Round robin arbitration unit
// NOTE: generally prefer https://github.com/bespoke-silicon-group/basejump_stl/blob/master/bsg_misc/bsg_arb_round_robin.sv to this module.
// Automatically generated using bsg_round_robin_arb.py
// DO NOT MODIFY

// this arbiter has a few usage scenarios which explains the somewhat complicated interface.
// Informal description of the interface:
// grants_en_i  - Whether to suppress grant_o signals and tag_o, which are computed based on reqs_i
// sel_one_hot_o- The selection signal after the arbitration.
// grant_o      - The grant signals that taking grant_en_i into consideration.
// v_o          - Whether any reqs_i signals were valid. computed without grants_en_i. 
// yumi_i       - Whether to advance "least priority" pointer to the selected item
//                in some typical use cases, grants_en_i comes from a downstream consumer to indicate readiness;
//                this can be used with v_o to implement ready/valid protocol at both producer (fed into yumi_i) and consumer

`include "bsg_defines.sv"

""")

print ("""module bsg_round_robin_arb #(parameter `BSG_INV_PARAM(inputs_p)
                                     ,lg_inputs_p   =`BSG_SAFE_CLOG2(inputs_p)
                                     ,reset_on_sr_p = 1'b0
                                     ,hold_on_sr_p  = 1'b0
                                     // Hold on valid sets the arbitration policy such that once
                                     // a output tag is selected, it remains selected until it is
                                     // acked. This is consistent with BaseJump STL handshake
                                     // assumptions. Notably, this parameter is required to work
                                     // with bsg_parallel_in_serial_out_passthrough. This policy
                                     // has a slight throughput degradation but effectively
                                     // arbitrates based on age, so minimizes worst case latency.
                                     ,hold_on_valid_p = 1'b0)""")

print ("""    (input clk_i
    , input reset_i
    , input grants_en_i // whether to suppress grants_o

    // these are "third-party" inputs/outputs
    // that are part of the "data plane"

    , input  [inputs_p-1:0] reqs_i
    , output logic [inputs_p-1:0] grants_o
    , output logic [inputs_p-1:0] sel_one_hot_o

    // end third-party inputs/outputs

    , output v_o                           // if grants_en_i (i.e. ready_i) were set, would a grant signal be asserted? 
    , output logic [lg_inputs_p-1:0] tag_o // to which input the grant was given
    , input yumi_i                         // yes, go ahead with whatever grants_o proposed
    );

logic [lg_inputs_p-1:0] last, last_n, last_r;
logic hold_on_sr, reset_on_sr;

""")

print ("""
// synopsys translate_off
initial begin
assert (inputs_p <= """,max_reqs,""")
  else begin
    $error("[%m] Can not support inputs_p greater than """,max_reqs,""". You can regenerate bsg_round_robin_arb.sv with a greater input range.\");
    $finish();
  end
end
// synopsys translate_on
""") 

for reqs_w in range(1, max_reqs+1):
    print ("""
if(inputs_p == %d)
begin: inputs_%d

logic [%d-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})""" % (reqs_w, reqs_w, reqs_w))

    last_w = int(math.ceil(math.log(reqs_w)/math.log(2))) if (reqs_w!=1) else 1
#    print "    %d'b"%(1+last_w+reqs_w) + "0" + "_" + "?"*last_w + "_" + "?"*reqs_w + ":"\
#            , "begin sel_one_hot_n="\
#            , "%d'b"%reqs_w + "0"*reqs_w + "; tag_o = (lg_inputs_p) ' (0); end // X"
    print ("    %d'b"%(last_w+reqs_w) + "?"*last_w + "_" + "0"*reqs_w + ":"\
            , "begin sel_one_hot_n ="\
            , "%d'b"%reqs_w + "0"*reqs_w + "; tag_o = (lg_inputs_p) ' (0); end // X")
    
    grants = {}
    for i in range(reqs_w):
        grants[i] = calculate_grants(i, reqs_w)

    for key in grants:
        for req in grants[key]:
            print ("    %d'b"%(last_w+reqs_w) + bin(key)[2:].zfill(last_w)\
                    + "_" + req[0] + ":"\
                    , "begin sel_one_hot_n="\
                    , "%d'b"%reqs_w + req[1] + "; tag_o = (lg_inputs_p) ' ("+str(req[1][::-1].index('1'))+"); end")

    print ("""    default: begin sel_one_hot_n= {%d{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end """% (reqs_w)) 
    
    print ("""
assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {%d{grants_en_i}} ;   
    """% (reqs_w))

    print_hold_on_logic(last_w, reqs_w)

    print_reset_on_logic(reqs_w)


    print ("""
end: inputs_%d""" % (reqs_w))

print ("// if (inputs_p > ",max_reqs,") initial begin $error(\"unhandled number of inputs\"); end");
print ("""

assign v_o = | reqs_i ;

if(inputs_p == 1)
  assign last_r = 1'b0;
else
  begin
    always_comb
      if( hold_on_sr_p ) begin: last_n_gen
        last_n = hold_on_sr ? last_r :
               ( yumi_i     ? tag_o  : last_r );  
      end else if( reset_on_sr_p ) begin: reset_on_last_n_gen
        last_n = reset_on_sr? (inputs_p-2'd2) :
               ( yumi_i     ?tag_o : last_r );  
      end else if( hold_on_valid_p ) begin: hold_on_last_n_gen
        // Need to manually handle wrap around on non-power of two case, else reuse subtraction
        last_n = yumi_i ? tag_o
               : v_o ? ((~`BSG_IS_POW2(inputs_p) && tag_o == '0) ? (lg_inputs_p)'(inputs_p-1) : (tag_o-1'b1))
                     : last_r;
      end else
        last_n = (yumi_i ? tag_o:last_r);

    always_ff @(posedge clk_i)
      last_r <= (reset_i) ? (lg_inputs_p)'(0):last_n;
  end

endmodule

`BSG_ABSTRACT_MODULE(bsg_round_robin_arb)""")

