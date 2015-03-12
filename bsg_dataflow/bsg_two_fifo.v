// MBT 9-7-2014
//
// two element fifo
//
// permissive interface
//
// input : ready/valid   flow control
// output: valid->yumi    flow control
//
// INPUTS: although this module's inputs adheres to
// ready/valid protocol where both sender and receiver
// AND the two signals together to determine
// if transaction happened; in some cases, we
// know that the sender takes into account the
// ready signal before sending out valid, and the
// check is unnecessary. We use ready_THEN_valid_p
// to remove the check if it is unnecessary.
//
//
// note: ~v_o == fifo is empty.
//

module bsg_two_fifo #(parameter width_p="inv"
                      , parameter ready_THEN_valid_p=0
		      , parameter verbose_p=0)
   (input clk_i
    , input reset_i

    // input side
    , output              ready_o // early
    , input [width_p-1:0] data_i  // late
    , input               v_i     // late

    // output side
    , output              v_o     // early
    , output[width_p-1:0] data_o  // early
    , input               yumi_i  // late
    );

   wire deq_i = yumi_i;
   wire enq_i;

   logic [1:0][width_p-1:0] data_r;

   logic                  head_r,  tail_r;
   logic                  empty_r, full_r;

   assign data_o    = data_r[head_r];
   assign v_o       = ~empty_r;
   assign ready_o   = ~full_r;

   if (ready_THEN_valid_p)
     assign enq_i = v_i;
   else
     assign enq_i = v_i & ~full_r;

   always_ff @(posedge clk_i)
     begin
        if (reset_i)
          begin
             tail_r  <= 1'b0;
             head_r  <= 1'b0;
             empty_r <= 1'b1;
             full_r  <= 1'b0;
          end
        else
          begin
             if (enq_i)
               begin
                  data_r[tail_r] <= data_i;
                  tail_r         <= ~tail_r;
               end

             if (deq_i)
               head_r         <= ~head_r;

             // logic simplifies nicely for 2 element case
             empty_r             <= (   empty_r & ~enq_i)
                                    | (~full_r  &  deq_i & ~enq_i);

             full_r              <= (  ~empty_r &  enq_i & ~deq_i)
                                    | ( full_r  & ~deq_i);
          end // else: !if(reset_i)
     end // always_ff @

   // synopsys translate_off
   always_ff @(posedge clk_i)
     begin
        if (~reset_i)
          begin
             assert ({empty_r, deq_i} !== 2'b11)
               else $error("invalid deque on empty fifo ", empty_r, deq_i);

             assert ({full_r,enq_i}   !== 2'b11)
               else $error("invalid enque on full fifo ", full_r, enq_i);

             assert ({full_r,empty_r} !== 2'b11)
               else $error ("fifo full and empty at same time ", full_r, empty_r);
          end // if (~reset_i)
     end // always_ff @
   
   always_ff @(posedge clk_i)
     if (verbose_p)
       begin
          if (v_i)
	    $display("### %m enq %x onto fifo",data_i);
	  
	  if (deq_i)
	    $display("### %m deq %x from fifo",data_o);
       end
   
   // for debugging
   wire [31:0] num_elements_debug = full_r + (empty_r==0);
   
   // synopsys translate_on

endmodule
