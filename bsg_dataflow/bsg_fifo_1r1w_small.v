// bsg_fifo with 1 read and 1 write, using register file
// dedicated for smaller fifos
// input handshake protocol is valid-and-ready or 
// ready-then-valid (based on ready_THEN_valid_p parameter)
// and output protocol is valid-yumi 
module bsg_fifo_1r1w_small #( parameter width_p      = -1
                            , parameter els_p        = -1

                            , parameter ready_THEN_valid_p = 0
                            )                           
                            
    ( input                clk_i
    , input                reset_i

    , input [width_p-1:0]  data_i
    , input                v_i
    , output               ready_o

    , output               v_o
    , output [width_p-1:0] data_o
    , input                yumi_i

    );

   localparam ptr_width_lp = `BSG_SAFE_CLOG2(els_p);

   // one read pointer, one write pointer;
   logic [ptr_width_lp-1:0] rptr_r, wptr_r;

   // Used to latch last operation, to determine fifo full or empty
   logic 		    enque_r, deque_r;

   // internal signals
   logic 		    empty, full, equal_ptrs, enque;

   bsg_mem_1r1w #(.width_p (width_p)
		  ,.els_p  (els_p  )
		  ,.read_write_same_addr_p(1)
		  ) mem_1r1w
     (.w_clk_i   (clk_i  )
      ,.w_reset_i(reset_i)
      ,.w_v_i    (enque  )
      ,.w_addr_i (wptr_r )
      ,.w_data_i (data_i )
      ,.r_v_i    (1'b1   )
      ,.r_addr_i (rptr_r )
      ,.r_data_o (data_o )
      );
   
   // If FIFO is full it cannot accept new data correctly
   // (In valid-ready protocol both ends assert their signal at the 
   // beginning of the cycle, and if the sender end finds that receiver
   // was not ready it would send it again. So in the receiver side
   // valid means enque if it could accept it)
   if (ready_THEN_valid_p) 
     begin: rtv
	assign enque = v_i;
     end 
   else 
     begin: rav
	assign enque = v_i & ready_o;
     end

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

   // Registering last operation
   // for reset last operation considered to be deque, so
   // same pointers mean empty FIFO
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
       if (enque | yumi_i) 
       begin
	  enque_r <= enque;
	  deque_r <= yumi_i;
       end
    end

   // if read and write pointers are equal
   // empty or fullness is determined by whether
   // the last request was a deque or enque.

   // There is no need to check both enque and deque for each of the 
   // empty and full signals, since during full or empty state one 
   // of the enque or deque cannot be asserted (no enque when it is
   // not ready and no yumi when no data is valid to be sent out)
   // Moreover, other than full or empty state only one of deque or 
   // enque signals would not make the counters equal
   assign equal_ptrs = (rptr_r == wptr_r);
   assign empty      = equal_ptrs & deque_r;
   assign full       = equal_ptrs & enque_r;

   // During reset, empty becomes 1 which makes valid_o be zero
   // during reset ready must not be asserted by due to full 
   // signal becoming zero it needs to be anded by ~reset
   assign ready_o = ~full & ~reset_i;
   assign v_o     = ~empty;
       
   // Check overflow or underflow.

   //synopsys translate_off		
   always_ff @ (posedge clk_i)    
     begin  
	if (ready_THEN_valid_p & full  & v_i    & ~reset_i)
	  $display("%m error: enque full fifo at time %t", $time);
	if (empty & yumi_i & ~reset_i)
	  $display("%m error: deque empty fifo at time %t", $time);			
     end
   //synopsys translate_on								

endmodule
