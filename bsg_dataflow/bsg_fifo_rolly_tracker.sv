
`include "bsg_defines.v"

  /* Operation Table */

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //          //          //          //          //          //          //          //          //          //
  // from\to  //  wptr    //  wptr+1  //  rptr    //  rptr+1  //  wcptr   //  wcptr+1 //  rcptr   //  rcptr+1 //
  //          //          //          //          //          //          //          //          //          //
  //          //          //          //          //          //          //          //          //          //
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //          //          //          //          //          //          //          //          //          //
  //  wptr    //    -     //  w_enq   //  w_clear //  w_clear // w_rewind // w_rewind //    -     //    -     //
  //          //          //          // (~r_deq) //  (r_deq) // (~w_incr)// (w_incr) //          //          //
  //          //          //          //          //          //          //          //          //          //
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //          //          //          //          //          //          //          //          //          //
  //  rptr    //    -     //    -     //    -     //  r_deq   //  r_clear //  r_clear // r_rewind // r_rewind //
  //          //          //          //          //          // (~w_incr)// (w_incr) // (~r_incr)// (r_incr) //
  //          //          //          //          //          //          //          //          //          //
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //          //          //          //          //          //          //          //          //          //
  //  wcptr   // w_forward// w_forward//  w_clear //  w_clear //    -     //  w_incr  //    -     //    -     //
  //          // (~w_enq) //  (w_enq) // (~r_deq) //  (r_deq) //          //          //          //          //
  //          //          //          //          //          //          //          //          //          //
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //          //          //          //          //          //          //          //          //          //
  //  rcptr   //    -     //    -     // r_forward// r_forward//  r_clear //  r_clear //    -     //  r_incr  //
  //          //          //          // (~r_deq) //  (r_deq) // (~w_incr)// (w_incr) //          //          //
  //          //          //          //          //          //          //          //          //          //
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Priority: clear > rewind > enq/deq

module bsg_fifo_rolly_tracker
  #(parameter `BSG_INV_PARAM(lg_size_p)
  , localparam els_lp = (1 << lg_size_p)
  )
  (input  clk_i
  , input reset_i

  // read side
  , input                r_deq_i
  , input                r_incr_i
  , input                r_rewind_i
  , input                r_forward_i
  , input                r_clear_i

  // write side
  , input                w_enq_i
  , input                w_incr_i
  , input                w_rewind_i
  , input                w_forward_i
  , input                w_clear_i

  , output [lg_size_p-1:0] wptr_r_o
  , output [lg_size_p-1:0] rptr_r_o
  , output [lg_size_p-1:0] wcptr_r_o
  , output [lg_size_p-1:0] rcptr_r_o

  , output [lg_size_p-1:0] wptr_n_o
  , output [lg_size_p-1:0] rptr_n_o
  , output [lg_size_p-1:0] wcptr_n_o
  , output [lg_size_p-1:0] rcptr_n_o

  , output full_o
  , output empty_o
  );

  // One read pointer, one write pointer, two checkpoint pointers
  // lg_size_p + 1 for wrap bit
  logic [lg_size_p:0] rptr_r, rcptr_r;
  logic [lg_size_p:0] wptr_r, wcptr_r;
  logic [lg_size_p:0] rptr_n, rcptr_n;
  logic [lg_size_p:0] wptr_n, wcptr_n;

  // Used to catch up on various read/write operations
  logic [lg_size_p:0] rptr_jmp, rcptr_jmp, wptr_jmp, wcptr_jmp;

  assign rptr_jmp  = r_clear_i
                     ? (wcptr_r - rptr_r + (lg_size_p+1)'(w_incr_i))
                     : r_rewind_i
                       ? (rcptr_r - rptr_r + (lg_size_p+1)'(r_incr_i))
                       : ((lg_size_p+1)'(r_deq_i));

  assign wptr_jmp  = w_clear_i
                     ? (rptr_r - wptr_r + (lg_size_p+1)'(r_deq_i))
                     : w_rewind_i
                       ? (wcptr_r - wptr_r + (lg_size_p+1)'(w_incr_i))
                       : ((lg_size_p+1)'(w_enq_i));

  assign rcptr_jmp = r_clear_i
                     ? (wcptr_r - rcptr_r + (lg_size_p+1)'(w_incr_i))
                     : r_forward_i
                       ? (rptr_r - rcptr_r + (lg_size_p+1)'(r_deq_i))
                       : ((lg_size_p+1)'(r_incr_i));

  assign wcptr_jmp = w_clear_i
                     ? (rptr_r - wcptr_r + (lg_size_p+1)'(r_deq_i))
                     : w_forward_i
                       ? (wptr_r - wcptr_r) + (lg_size_p+1)'(w_enq_i)
                       : ((lg_size_p+1)'(w_incr_i));

  bsg_circular_ptr
   #(.slots_p(2*els_lp), .max_add_p(2*els_lp-1))
   wcptr
    (.clk(clk_i)
     ,.reset_i(reset_i)
     ,.add_i(wcptr_jmp)
     ,.o(wcptr_r)
     ,.n_o(wcptr_n)
     );

  bsg_circular_ptr
   #(.slots_p(2*els_lp), .max_add_p(2*els_lp-1))
   rcptr
    (.clk(clk_i)
     ,.reset_i(reset_i)
     ,.add_i(rcptr_jmp)
     ,.o(rcptr_r)
     ,.n_o(rcptr_n)
     );

  bsg_circular_ptr
   #(.slots_p(2*els_lp),.max_add_p(2*els_lp-1))
   wptr
    (.clk(clk_i)
     ,.reset_i(reset_i)
     ,.add_i(wptr_jmp)
     ,.o(wptr_r)
     ,.n_o(wptr_n)
     );

  bsg_circular_ptr
  #(.slots_p(2*els_lp), .max_add_p(2*els_lp-1))
  rptr
   (.clk(clk_i)
    ,.reset_i(reset_i)
    ,.add_i(rptr_jmp)
    ,.o(rptr_r)
    ,.n_o(rptr_n)
    );

  assign full_o = (rcptr_r[0+:lg_size_p] == wptr_r[0+:lg_size_p])
              & (rcptr_r[lg_size_p] != wptr_r[lg_size_p]);

  assign empty_o = (rptr_r[0+:lg_size_p] == wcptr_r[0+:lg_size_p])
               & (rptr_r[lg_size_p] == wcptr_r[lg_size_p]);

  assign wptr_r_o = wptr_r[0+:lg_size_p];
  assign rptr_r_o = rptr_r[0+:lg_size_p];
  assign wcptr_r_o = wcptr_r[0+:lg_size_p];
  assign rcptr_r_o = rcptr_r[0+:lg_size_p];

  assign wptr_n_o  = wptr_n[0+:lg_size_p];
  assign rptr_n_o  = rptr_n[0+:lg_size_p];
  assign wcptr_n_o = wcptr_n[0+:lg_size_p];
  assign rcptr_n_o = rcptr_n[0+:lg_size_p];

  // synopsys translate_off

  //   This avoids rcptr going past rptr which happens when
  // rptr == rcptr, r_deq is 0 and r_incr is 1
  assert property (@(posedge clk_i) (reset_i == 1'b1 || !(r_incr_i && (rptr_r == rcptr_r) &&
        r_deq_i == 1'b0)))
    else begin $error("%m error: rcptr goes pass rptr at time %t", $time); $finish; end
  //   This avoids wcptr going past wptr which happens when
  // wptr == wcptr, w_enq is 0 and w_incr is 1
  assert property (@(posedge clk_i) (reset_i == 1'b1 || !(w_incr_i && (wptr_r == wcptr_r) &&
        w_enq_i == 1'b0)))
    else begin $error("%m error: wcptr goes pass wptr at time %t", $time); $finish; end

  assert property (@(posedge clk_i) (reset_i == 1'b1 ||
      $countones({r_incr_i, r_forward_i}) <= 1))
    else begin $error("%m error: multiple operations for rcptr happen at time %t",
      $time); $finish; end

  assert property (@(posedge clk_i) (reset_i == 1'b1 ||
      $countones({w_incr_i, w_forward_i}) <= 1))
    else begin $error("%m error: multiple operations for wcptr happen at time %t",
      $time); $finish; end

  // rewind and forward are two conflicting operations and therefore cannot go together
  assert property (@(posedge clk_i) (reset_i == 1'b1 || !(r_rewind_i && r_forward_i)))
    else begin $error("%m error: conflicting operations r_rewind and r_forward happen at time %t",
      $time); $finish; end

  assert property (@(posedge clk_i) (reset_i == 1'b1 || !(w_rewind_i && w_forward_i)))
    else begin $error("%m error: conflicting operations w_rewind and w_forward happen at time %t",
      $time); $finish; end
  // r_clear_i and w_clear_i are two conflicting operations and therefore cannot go together
  assert property (@(posedge clk_i) (reset_i == 1'b1 || !(r_clear_i && w_clear_i)))
    else begin $error("%m error: conflicting operations r_clear and w_clear happen at time %t",
      $time); $finish; end

  // synopsys translate_on

endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_rolly_tracker)
