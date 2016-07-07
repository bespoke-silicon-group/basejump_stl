// bsg_fifo_tracker
//
// MBT 7/7/16
//

module bsg_fifo_tracker #(parameter els_p           = -1
                          , ptr_width_lp = `BSG_SAFE_CLOG2(els_p)
                          )
   (input   clk_i
    , input reset_i

    , input enq_i
    , input deq_i

    , output [ptr_width_lp-1:0] wptr_r_o
    , output [ptr_width_lp-1:0] rptr_r_o

    , output full_o
    , output empty_o
    );

   // one read pointer, one write pointer;
   logic [ptr_width_lp-1:0] rptr_r, wptr_r;

   assign wptr_r_o = wptr_r;
   assign rptr_r_o = rptr_r;

   // Used to latch last operation, to determine fifo full or empty
   logic                    enque_r, deque_r;

   // internal signals
   logic                    empty, full, equal_ptrs, enque;

   bsg_circular_ptr #(.slots_p   (els_p)
                      ,.max_add_p(1    )
                      ) rptr
     ( .clk      (clk_i  )
       , .reset_i(reset_i)
       , .add_i  (yumi_i )
       , .o      (rptr_r )
       );

   bsg_circular_ptr #(.slots_p   (els_p)
                      ,.max_add_p(1    )
                      ) wptr
     ( .clk      (clk_i  )
       , .reset_i(reset_i)
       , .add_i  (enque  )
       , .o      (wptr_r )
       );

   // registering last operation
   // for reset, last op is deque, so
   // equal w and r pointers signal empty FIFO

   always_ff @(posedge clk_i)
     if (reset_i)
       begin
          enque_r <= 1'b0;
          deque_r <= 1'b1;
       end
     else
       begin
          // update "last operation" when
          // either enque or dequing
          if (enq_i | deq_i)
            begin
               enque_r <= enq_i;
               deque_r <= deq_i;
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
   assign empty_o    = equal_ptrs & deque_r;
   assign full_o     = equal_ptrs & enque_r;

endmodule // bsg_fifo_tracker
