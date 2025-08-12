// bsg_fifo_1r1w_small_unhardened
// *** Renamed from bsg_fifo_1r1w_small ***
//
// bsg_fifo with 1 read and 1 write, using
// 1-write 1-async-read register file implementation.
//
// used for smaller fifos.
//
// input handshake protocol (based on ready_THEN_valid_p parameter):
//     valid-and-ready or
//     ready-then-valid
//
// output protocol is valid-yumi (like typical fifo)
//                    aka valid-then-ready
//
//

`include "bsg_defines.sv"

module bsg_fifo_1r1w_small_unhardened #( parameter `BSG_INV_PARAM(width_p      )
                            , parameter `BSG_INV_PARAM(els_p        )
                            , parameter ready_THEN_valid_p = 0
                            )
    ( input                clk_i
    , input                reset_i

    , input                v_i
    , output               ready_param_o
    , input [width_p-1:0]  data_i

    , output               v_o
    , output [width_p-1:0] data_o
    , input                yumi_i
    );

   wire deque = yumi_i;
   wire v_o_tmp;

   assign v_o = v_o_tmp;

   // vivado bug prohibits declaring wire inside of generate block
   wire enque;
   logic ready_param_lo;

   if (ready_THEN_valid_p)
     begin: rtv
        assign enque = v_i;
     end
   else
     begin: rav
        assign enque = v_i & ready_param_lo;
     end

   localparam ptr_width_lp = `BSG_SAFE_CLOG2(els_p);

   // one read pointer, one write pointer;
   logic [ptr_width_lp-1:0] rptr_r, wptr_r;
   logic                    full, empty;

   bsg_fifo_tracker #(.els_p(els_p)
                      ) ft
     (.clk_i
      ,.reset_i
      ,.enq_i   (enque)
      ,.deq_i   (deque)
      ,.wptr_r_o(wptr_r)
      ,.rptr_r_o(rptr_r)
      ,.rptr_n_o()
      ,.full_o  (full)
      ,.empty_o (empty)
      );

   // async read
   bsg_mem_1r1w #(.width_p (width_p)
                  ,.els_p  (els_p  )
		  // MBT: this should be zero
                  ,.read_write_same_addr_p(0)
                  ) mem_1r1w
     (.w_clk_i   (clk_i  )
      ,.w_reset_i(reset_i)
      ,.w_v_i    (enque  )
      ,.w_addr_i (wptr_r )
      ,.w_data_i (data_i )
      ,.r_v_i    (v_o_tmp)
      ,.r_addr_i (rptr_r )
      ,.r_data_o (data_o )
      );

   // during reset, we keep ready low
   // even though fifo is empty

   //assign ready_param_lo = ~full & ~reset_i;
   assign ready_param_lo = ~full;
   assign ready_param_o = ready_param_lo;
   assign v_o_tmp = ~empty;

`ifndef BSG_HIDE_FROM_SYNTHESIS
	always_ff @ (posedge clk_i)
     begin
        if (ready_THEN_valid_p & full  & v_i    & ~reset_i)
          $display("%m error: enque full fifo at time %t", $time);
        if (empty & yumi_i & ~reset_i)
          $display("%m error: deque empty fifo at time %t", $time);
     end
`endif

/*
   always_ff @(negedge clk_i)
     begin
        $display("%m v_i=%x yumi_i=%x wptr=%b rptr=%b enque=%b full=%d empty=%d ready_param_o=%d",v_i,yumi_i,wptr_r, rptr_r, enque, full,empty,ready_param_o);
     end
 */
endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_1r1w_small_unhardened)
