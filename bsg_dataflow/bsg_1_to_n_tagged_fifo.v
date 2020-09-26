// MBT 7/7/2016
//
// This module implements a FIFO that takes in a multiplexed stream
// on one end, and provides demultiplexed access on the other.
//
// Each stream is guaranteed to have els_p worth of storage.
//
// The parameter unbuffered_mask_p allows you to select some channels
// to come out without a FIFO. This is useful, for example, for credit
// channels that do not need buffering. The yumi_i signal is ignored
// for these channels; they are assumed to always be ready.
//

`include "bsg_defines.v"

module bsg_1_to_n_tagged_fifo   #(parameter width_p                   = "inv"
                                  ,parameter num_out_p                = -1
                                  ,parameter els_p                    = "inv" // these are elements per channel
                                  ,parameter unbuffered_mask_p        = 0
                                  ,parameter use_pseudo_large_fifo_p  = 0
                                  ,parameter tag_width_lp        = `BSG_SAFE_CLOG2(num_out_p)
                                  )
   (input  clk_i
    , input  reset_i

    , input                    v_i
    , input [tag_width_lp-1:0] tag_i
    , input [     width_p-1:0] data_i
    , output                   yumi_o

    , output [num_out_p-1:0]              v_o
    , input  [num_out_p-1:0]               yumi_i
    , output [num_out_p-1:0] [width_p-1:0] data_o

    );

   wire [num_out_p-1:0]               valid_lo;
   wire [num_out_p-1:0]               ready_li;

   bsg_1_to_n_tagged #(.num_out_p   (num_out_p   )
                       ) _1_to_n
     (.clk_i
      ,.reset_i

      ,.v_i
      ,.tag_i
      ,.yumi_o

      ,.v_o(valid_lo)
      ,.ready_i(ready_li)
      );

   genvar i;

   for (i = 0; i < num_out_p; i=i+1)
     begin: rof
        if (unbuffered_mask_p[i])
          begin: unbuf
             assign v_o     [i] = valid_lo[i];
             assign data_o  [i] = data_i;
             assign ready_li[i] = 1'b1;
          end
        else if (use_pseudo_large_fifo_p)
          begin : psdlrg
             bsg_fifo_1r1w_pseudo_large #(.width_p(width_p)
                                          ,.els_p(els_p)
                                          ) fifo
               (.clk_i
                ,.reset_i

                ,.v_i    (valid_lo[i])
                ,.data_i
                ,.ready_o(ready_li[i])

                ,.v_o   (v_o   [i])
                ,.data_o(data_o[i])
                ,.yumi_i(yumi_i[i])
                );
          end
        else
          begin: buff
             bsg_fifo_1r1w_small #(.width_p(width_p)
                                   ,.els_p (els_p  )
                                   ) fifo
               (.clk_i
                ,.reset_i

                ,.v_i      (valid_lo[i])
                ,.data_i   (data_i     )
                ,.ready_o  (ready_li[i])

                ,.v_o      (v_o   [i])
                ,.data_o   (data_o[i])
                ,.yumi_i   (yumi_i[i])
                );
          end // block: fi
     end

endmodule
