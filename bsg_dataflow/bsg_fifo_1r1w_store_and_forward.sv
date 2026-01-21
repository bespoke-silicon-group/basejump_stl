
`include "bsg_defines.v"

module bsg_fifo_1r1w_store_and_forward
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(lg_size_p)
    , parameter ready_THEN_valid_p = 0
    , parameter harden_p = 0
    )
  (input                  clk_i
   , input                reset_i

   , input                commit_v_i
   , input                commit_drop_i

   , input [width_p-1:0]  data_i
   , input                v_i
   , output               ready_o

   , output [width_p-1:0] data_o
   , output               v_o
   , input                yumi_i
   );

  if (harden_p == 0)
    begin: unhardened
      bsg_fifo_1r1w_store_and_forward_unhardened #(.width_p(width_p)
                                      ,.lg_size_p(lg_size_p)
                                      ,.ready_THEN_valid_p(ready_THEN_valid_p)
                                      ) fifo
      (.*);
    end
  else
    begin: hardened
      bsg_fifo_1r1w_store_and_forward_hardened #(.width_p(width_p)
                                    ,.lg_size_p(lg_size_p)
                                    ,.ready_THEN_valid_p(ready_THEN_valid_p)
                                    ) fifo
      (.*);
    end

endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_1r1w_store_and_forward)

