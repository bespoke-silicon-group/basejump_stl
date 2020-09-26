// MBT 6/8/2016
//
// bsg_1_to_n_tagged
//
// this is intended to take one input and send it to
// one of several channels according to tag.
//
// see bsg_round_robin_n_to_1 for how the tags are assembled
// and for maintaining consistency between the two modules
//
// assumes a valid->yumi interface for input channel
// and valid/ready for output
//
// we do not include the data portion since it is just replicated
//

`include "bsg_defines.v"

module bsg_1_to_n_tagged #(
                           parameter num_out_p    = -1
                           ,parameter tag_width_lp = `BSG_SAFE_CLOG2(num_out_p)
                           )
   (input  clk_i
    , input  reset_i

    , input                   v_i
    , input [tag_width_lp-1:0]  tag_i
    , output                   yumi_o

    , output [num_out_p-1:0]   v_o
    , input  [num_out_p-1:0]   ready_i

    // to downstream
    );

  wire unused0 = clk_i;
  wire unused1 = reset_i;

   if (num_out_p == 1)
     begin : one
        assign v_o = v_i;
        assign yumi_o  = ready_i & v_i;
     end
   else
     begin: many

        genvar                  i;

        bsg_decode_with_v #(.num_out_p(num_out_p)) bdv
          (.i(tag_i)
           ,.v_i(v_i)
           ,.o(v_o)
           );

        assign yumi_o = ready_i[tag_i] & v_i;
     end

endmodule

