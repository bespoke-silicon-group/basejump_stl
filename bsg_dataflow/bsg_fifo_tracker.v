// bsg_fifo_tracker
//
// MBT 7/7/16
//

`include "bsg_defines.v"

module bsg_fifo_tracker #(parameter els_p           = -1
                          , ptr_width_lp = `BSG_SAFE_CLOG2(els_p)
                          )
   (input   clk_i
    , input reset_i

    , input enq_i
    , input deq_i

    , output [ptr_width_lp-1:0] wptr_r_o
    , output [ptr_width_lp-1:0] rptr_r_o
    , output [ptr_width_lp-1:0] rptr_n_o

    , output full_o
    , output empty_o
    );

   // one read pointer, one write pointer;
   logic [ptr_width_lp-1:0] rptr_r, rptr_n, wptr_r;

   assign wptr_r_o = wptr_r;
   assign rptr_r_o = rptr_r;
   assign rptr_n_o = rptr_n;

   // Used to latch last operation, to determine fifo full or empty
   logic                    enq_r, deq_r;

   // internal signals
   logic                    empty, full, equal_ptrs;

   bsg_circular_ptr #(.slots_p   (els_p)
                      ,.max_add_p(1    )
                      ) rptr
     ( .clk      (clk_i  )
       , .reset_i(reset_i)
       , .add_i  (deq_i )
       , .o      (rptr_r )
       , .n_o    (rptr_n)
       );

   bsg_circular_ptr #(.slots_p   (els_p)
                      ,.max_add_p(1    )
                      ) wptr
     ( .clk      (clk_i  )
       , .reset_i(reset_i)
       , .add_i  (enq_i  )
       , .o      (wptr_r )
       , .n_o    ()
       );

   // registering last operation
   // for reset, last op is deque, so
   // equal w and r pointers signal empty FIFO

   always_ff @(posedge clk_i)
     if (reset_i)
       begin
          enq_r <= 1'b0;
          deq_r <= 1'b1;
       end
     else
       begin
          // update "last operation" when
          // either enque or dequing
          if (enq_i | deq_i)
            begin
               enq_r <= enq_i;
               deq_r <= deq_i;
            end
       end // else: !if(reset_i)

   // if read and write pointers are equal
   // empty or fullness is determined by whether
   // the last request was a deque or enque.

   // no need to check both enque and deque for each of the
   // empty and full signals, since during full or empty state one
   // of the enque or deque cannot be asserted (no enque when it is
   // not ready and no yumi when no data is valid to be sent out)
   // Moreover, other than full or empty state only one of deque or
   // enque signals would not make the counters equal

   assign equal_ptrs = (rptr_r == wptr_r);
   assign empty      = equal_ptrs & deq_r;
   assign full       = equal_ptrs & enq_r;
   
   assign full_o = full;
   assign empty_o = empty;

endmodule // bsg_fifo_tracker
