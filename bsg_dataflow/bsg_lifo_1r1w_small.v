
//
// This module implements a LIFO (hardware stack)
// Simultaneous push / pop will return the pushed data without putting on the stack
//
// By default, this module will not allow users to enqueue onto a full stack
// Setting allow_rollover_p will allow this behavior, such that ready_o is
//   always asserted.
module bsg_lifo_1r1w_small #( parameter width_p          = -1
                            , parameter els_p            = -1

                            , parameter allow_rollover_p =  0
                            )
    ( input                clk_i
    , input                reset_i

    // ready-then-valid
    , input [width_p-1:0]  data_i
    , input                v_i
    , output               ready_o

    // valid-then-yumi
    , output [width_p-1:0] data_o
    , output               v_o
    , input                yumi_i
    );

   logic empty, full;

   wire push = ready_o & v_i;
   wire pop  = v_o & yumi_i;

   localparam ptr_width_lp = `BSG_SAFE_CLOG2(els_p);
   logic [ptr_width_lp-1:0] rptr_n, wptr_n;
   logic [ptr_width_lp-1:0] rptr_r, wptr_r;

   logic [width_p-1:0] data_lo;
   bsg_mem_1r1w #(.width_p (width_p)
                  ,.els_p  (els_p  )
   // MBT: this should be zero
                  ,.read_write_same_addr_p(0)
                  ) mem_1r1w
     (.w_clk_i   (clk_i  )
      ,.w_reset_i(reset_i)
      ,.w_v_i    (push & ~pop )
      ,.w_addr_i (wptr_r )
      ,.w_data_i (data_i )
      ,.r_v_i    (pop & ~push )
      ,.r_addr_i (rptr_r )
      ,.r_data_o (data_lo)
      );
   assign data_o = (push & pop) ? data_i : data_lo;

   logic push_r;
   bsg_dff_reset_en #(.width_p(1)
                      ) push_reg
      (.clk_i(clk_i)
       ,.reset_i(reset_i)
       ,.en_i(push | pop)
       ,.data_i(push)
       ,.data_o(push_r)
       );

   // Write pointer updates on push and pop
   // Read pointer always lags behind write pointer by 1
   assign wptr_n = wptr_r + push - pop;
   assign rptr_n = wptr_n - 1'b1;
   bsg_dff_reset_en #(.width_p(2*ptr_width_lp)
                      ) rwptr_reg
      (.clk_i(clk_i)
       ,.reset_i(reset_i)
       ,.en_i(push | pop)
       ,.data_i({rptr_n, wptr_n})
       ,.data_o({rptr_r, wptr_r})
       );

   // In order to compute emptiness in the case of rollover, we track
   //   a base pointer, which points to the current base of the lifo.
   //   We increment this pointer whenever we rollover (enqueue during full).
   if (allow_rollover_p)
     begin : fi1
       logic [ptr_width_lp-1:0] bptr_n, bptr_r;
       assign bptr_n = bptr_r + (full & push);
       bsg_dff_reset #(.width_p(ptr_width_lp)
                       ) bptr_reg
         (.clk_i(clk_i)
          ,.reset_i(reset_i)
          ,.data_i(bptr_n)
          ,.data_o(bptr_r)
          );

       assign empty = (wptr_r == bptr_r) & ~push_r;
       assign full  = (wptr_r == bptr_r) &  push_r;

       assign ready_o = 1'b1;
       assign v_o     = ~empty;
     end
   else
     begin : fi1
       // If we don't allow rollover, we simply check whether the 
       //   write pointer is zero.
       assign empty = (wptr_r == '0) & ~push_r;
       assign full  = (wptr_r == '0) &  push_r;

       assign ready_o = ~full;
       assign v_o     = ~empty;
     end

endmodule
