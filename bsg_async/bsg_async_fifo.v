// MBT 7/24/2014
// async fifo
// uses synchronous reset for both sides
//
// note: special attention should be paid to
// how reset is done. you cannot just tie
// the two resets together. talk to MBT.
//
// talk to MBT if you intend to change this
// it has been specially designed to cross
// clock domains.
//

`include "bsg_defines.v"

module bsg_async_fifo #(parameter   lg_size_p = "inv"
                        , parameter   width_p = "inv"
                        // we allow the control bits to be separated from
                        // the data bits to allow for better control optimization.
                        // control_width_p is how many of the width_p bits are control bits;
                        // these bits should be at the top of the array
                        , parameter   control_width_p = 0)
   (
    input    w_clk_i
    , input  w_reset_i
    // not legal to w_enq_i if w_full_o is not low.
    , input  w_enq_i
    , input  [width_p-1:0] w_data_i
    , output w_full_o

    // not legal to r_deq_i if r_valid_o is not high.
    , input  r_clk_i
    , input  r_reset_i
    , input  r_deq_i
    , output [width_p-1:0] r_data_o
    , output r_valid_o
    );

   localparam size_lp = 1 << lg_size_p;

   // we use an extra bit for the pointers to detect wraparound
   logic [lg_size_p:0] r_ptr_gray_r;

   logic [lg_size_p:0] w_ptr_gray_r;
   logic [lg_size_p:0] w_ptr_gray_r_rsync, r_ptr_gray_r_wsync, r_ptr_binary_r, w_ptr_binary_r;

   wire               r_valid_o_tmp; // remove inout warning from Lint
   assign r_valid_o = r_valid_o_tmp;

   bsg_mem_1r1w #(.width_p(width_p-control_width_p)
                  ,.els_p(size_lp)
		  ,.read_write_same_addr_p(0)
                  ) MSYNC_1r1w
     (.w_clk_i    (w_clk_i  )
      ,.w_reset_i (w_reset_i)

      ,.w_v_i   (w_enq_i                                  )
      ,.w_addr_i(w_ptr_binary_r[0+:lg_size_p]             )
      ,.w_data_i(w_data_i[0+:(width_p - control_width_p)] )

      ,.r_v_i   (r_valid_o_tmp                            )
      ,.r_addr_i(r_ptr_binary_r[0+:lg_size_p]             )
      ,.r_data_o(r_data_o[0+:(width_p - control_width_p)] )
      );

   if (control_width_p > 0)
     begin : ctrl
        bsg_mem_1r1w #(.width_p(control_width_p)
                       ,.els_p(size_lp)
		       ,.read_write_same_addr_p(0)
                       ) MSYNC_1r1w
          (.w_clk_i   (w_clk_i  )
           ,.w_reset_i(w_reset_i)

           ,.w_v_i    (w_enq_i                           )
           ,.w_addr_i (w_ptr_binary_r[0+:lg_size_p]      )
           ,.w_data_i (w_data_i[(width_p-1)-:control_width_p])

           ,.r_v_i    (r_valid_o_tmp                     )
           ,.r_addr_i (r_ptr_binary_r[0+:lg_size_p]      )
           ,.r_data_o (r_data_o[(width_p-1)-:control_width_p])
           );
     end

   // pointer from writer to reader (input to output of FIFO)
   bsg_async_ptr_gray #(.lg_size_p(lg_size_p+1)) bapg_wr
   (.w_clk_i(w_clk_i)
    ,.w_reset_i(w_reset_i)
    ,.w_inc_i(w_enq_i)
    ,.r_clk_i(r_clk_i)
    ,.w_ptr_binary_r_o(w_ptr_binary_r)
    ,.w_ptr_gray_r_o(w_ptr_gray_r)
    ,.w_ptr_gray_r_rsync_o(w_ptr_gray_r_rsync)
    );

   // pointer from reader to writer (output to input of FIFO)
   // note this pointer travels backwards so the order is reverse

   bsg_async_ptr_gray #(.lg_size_p(lg_size_p+1)) bapg_rd
   (.w_clk_i(r_clk_i)
    ,.w_reset_i(r_reset_i)
    ,.w_inc_i(r_deq_i)
    ,.r_clk_i(w_clk_i)
    ,.w_ptr_binary_r_o(r_ptr_binary_r)
    ,.w_ptr_gray_r_o(r_ptr_gray_r)  // after launch flop
    ,.w_ptr_gray_r_rsync_o(r_ptr_gray_r_wsync) // after sync flops
    );

   // data is available if the two pointers are not equal
   assign r_valid_o_tmp = (r_ptr_gray_r != w_ptr_gray_r_rsync);

   // compare two gray code values whose binaries values differ
   // by top bit; this corresponds to the full conditions

   assign w_full_o  = (w_ptr_gray_r == { ~r_ptr_gray_r_wsync[lg_size_p-:2]
                                         , r_ptr_gray_r_wsync[0+:lg_size_p-1] });


   // synopsys translate_off
   always @(negedge w_clk_i)
     assert(!(w_full_o===1 && w_enq_i===1))   else $error("enqueing data on bsg_async_fifo when full");

   always @(negedge r_clk_i)
     assert(!(r_valid_o_tmp===0 && r_deq_i===1)) else $error("dequeing data on bsg_async_fifo when empty");

   // synopsys translate_on

endmodule // bsg_async_fifo
