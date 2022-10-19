
`include "bsg_defines.v"

module bsg_fifo_1r1w_rolly
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(lg_size_p)
    , parameter ready_THEN_valid_p = 0
    , parameter harden_p = 0
    )
  (input                  clk_i
   , input                reset_i

   , input                clr_v_i
   , input                deq_v_i
   , input                roll_v_i

   , input [width_p-1:0]  data_i
   , input                v_i
   , output               ready_o

   , output [width_p-1:0] data_o
   , output               v_o
   , input                yumi_i
   );

  if (harden_p == 0)
    begin: unhardened
      bsg_fifo_1r1w_rolly_unhardened #(.width_p(width_p)
                                      ,.lg_size_p(lg_size_p)
                                      ,.ready_THEN_valid_p(ready_THEN_valid_p)
                                      ) fifo
      (.*);
    end
  else
    begin: hardened
      bsg_fifo_1r1w_rolly_hardened #(.width_p(width_p)
                                    ,.lg_size_p(lg_size_p)
                                    ,.ready_THEN_valid_p(ready_THEN_valid_p)
                                    ) fifo
      (.*);
    end


endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_1r1w_rolly)

