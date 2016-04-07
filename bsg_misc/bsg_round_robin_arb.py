#!/usr/bin/python

"""
Round robin arbitration unit generator

Bandhav Veluri 01/29/2016
"""

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

max_reqs = 0 # no. of inputs
try:
    assert len(sys.argv) == 2
    max_reqs = int(sys.argv[1])
except:
    print "UsageError: bsg_round_robin_arb.py <max no. of channels>"
    sys.exit()

print """// Round robin arbitration unit

// Automatically generated using bsg_round_robin_arb.py
// DO NOT MODIFY
"""

print "module bsg_round_robin_arb #(parameter inputs_p = %s)" % '''"not assigned"'''

print """    (input clk_i
    , input reset_i
    , input ready_i
    , input [inputs_p-1:0] reqs_i
    , output [inputs_p-1:0] grants_o
    );

logic [inputs_p-1:0] grants;
logic [`BSG_SAFE_CLOG2(inputs_p)-1:0] last, last_n, last_r;

assign grants_o = grants;"""

for reqs_w in range(1, max_reqs+1):
    print """
if(inputs_p == %d)
begin: inputs_%d
always_comb
begin
  unique casez({ready_i, last_r, reqs_i})""" % (reqs_w, reqs_w)

    last_w = int(math.ceil(math.log(reqs_w)/math.log(2))) if (reqs_w!=1) else 1
    print "    %d'b"%(1+last_w+reqs_w) + "0" + "_" + "?"*last_w + "_" + "?"*reqs_w + ":"\
            , "grants ="\
            , "%d'b"%reqs_w + "0"*reqs_w + ";"
    print "    %d'b"%(1+last_w+reqs_w) + "1" + "_" + "?"*last_w + "_" + "0"*reqs_w + ":"\
            , "grants ="\
            , "%d'b"%reqs_w + "0"*reqs_w + ";"
    
    grants = {}
    for i in range(reqs_w):
        grants[i] = calculate_grants(i, reqs_w)

    for key in grants:
        for req in grants[key]:
            print "    %d'b"%(1+last_w+reqs_w) + "1" + "_" + bin(key)[2:].zfill(last_w)\
                    + "_" + req[0] + ":"\
                    , "grants ="\
                    , "%d'b"%reqs_w + req[1] + ";"

    print """    default: grants = {%d{1'bx}};
  endcase
end
end: inputs_%d""" % (reqs_w, reqs_w) 

print """
if(inputs_p == 1)
  assign last_r = 1'b0;
else
  begin
    bsg_encode_one_hot #(.width_p(inputs_p)
                        ) encoder( .i     (grants)
                                  ,.addr_o(last)
                                  ,.v_o   ()
                                 );

    always_comb
      last_n = (ready_i & (|reqs_i))? last:last_r;
    
    always_ff @(posedge clk_i)
      last_r <= (reset_i)? `BSG_SAFE_CLOG2(inputs_p)'(0):last_n;
  end

endmodule"""
