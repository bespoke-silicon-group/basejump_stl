/****************************************************************************
 *
 *   FILE: network_input_blk_4elmt.v:
 *   
 *   Author: Mark Stephenson
 *   Date: Thu Jul 13 12:29:13 2000
 *
 *   Function: The network input block buffers data between communicating
 *             switches. It communicates with:
 * 
 *              a. the remote switch (from whom it is receiving data)
 *              b. the local switch  (to whom it is sending data)
 *
 *             It is assumed that the remote switch is far enough away that 
 *             it takes most of a cycle for data values to propagate between 
 *             the input block and the remote switch. In particular, these
 *             NIBs will be used to buffer data on the receiving side of an 
 *             interchip communication.
 *
 *             The remote switch will only send a data value if it knows 
 *             that the input block has enough space to hold it.  The 
 *             elements are buffered using a forward propagating FIFO.
 *
 ***************************************************************************/

module network_input_blk_4elmt (clk,
			 	reset,
			 	dataIn,
                         	validIn,
                         	yummyOut, 
                         	thanksIn,
                         	dataVal,
                         	dataAvail,
                         	dataCount,
				full);  

   input	 clk;
   input	 reset;
   input [31:0]	 dataIn;
   input	 validIn;
   input	 thanksIn;
   
   output	 yummyOut;
   output	 dataAvail;
   output [31:0] dataVal;
   output [2:0]	 dataCount;
   output	 full;

   wire [31:0]	 elmt3_value;
   wire [31:0]	 elmt2_value;
   wire [31:0]	 elmt1_value;
   wire [31:0]	 elmt0_value;
   wire [31:0]	 dataIn_r;

   wire		 elmt3_full;
   wire		 elmt2_full;
   wire		 elmt1_full;
   wire		 elmt0_full, elmt0_full_buf;
   wire		 enqueue;
   wire		 validIn_r, validIn_r_buf;
   wire          dataAvail_l;
   
   
   wire		 yummyOut_internal;

   `include "ChipInclude.v"

   // Keeps count of how many elements are in the FIFO.
   fifo_counter #(3) cnt (.up_count(validIn_r_buf),   // validIn
			  .down_count(yummyOut_internal),  // thanksIn
			  .num_entries(dataCount),
			  .reset(reset),
			  .clk(clk));

   // Give the acknowledgement of receipt.
   rDFF_clear #(1) yumreg (thanksIn, yummyOut_internal, reset, clk);
   assign yummyOut = yummyOut_internal;
   
   // Register the inputs.
   rDFF #(32) datareg (dataIn, dataIn_r, clk);
   rDFF_clear #(1) valreg (validIn, validIn_r, reset, clk);
 
   // we use this buffer to separate the critical path (dataAvail)
   // from the non-critical paths
   
   rBuffer #(1,`OPWR) valreg_buf (validIn_r, validIn_r_buf);


   // The FIFO is made by composing several small fifo_elmts.
   fifo_elmt elmt3 (.enqueue(validIn_r_buf),
		    .dequeue(thanksIn),
		    .new_value(dataIn_r),
		    .prop_value(32'd0),
		    .prev_full(1'b0),
		    .next_full(elmt2_full),
		    .clk(clk),
		    .reset(reset),
		    .full(elmt3_full),
		    .value(elmt3_value));
   
   fifo_elmt elmt2 (.enqueue(validIn_r_buf),
		    .dequeue(thanksIn),
		    .new_value(dataIn_r),
		    .prop_value(elmt3_value),
		    .prev_full(elmt3_full),
		    .next_full(elmt1_full),
		    .clk(clk),
		    .reset(reset),
		    .full(elmt2_full),
		    .value(elmt2_value));
   
   fifo_elmt elmt1 (.enqueue(validIn_r_buf),
		    .dequeue(thanksIn),
		    .new_value(dataIn_r),
		    .prop_value(elmt2_value),
		    .prev_full(elmt2_full),
		    .next_full(elmt0_full_buf),
		    .clk(clk),
		    .reset(reset),
		    .full(elmt1_full),
		    .value(elmt1_value));
   
   fifo_elmt elmt0 (.enqueue(validIn_r_buf),
		    .dequeue(thanksIn),
		    .new_value(dataIn_r),
		    .prop_value(elmt1_value),
		    .prev_full(elmt1_full),
		    .next_full(enqueue),
		    .clk(clk),
		    .reset(reset),
		    .full(elmt0_full),
		    .value(elmt0_value));

   // take the load off of this signal
   rBuffer #(1,`OPWR) full_buf (elmt0_full, elmt0_full_buf);
   
   // This is the bypass logic which will select the registered
   // value if the FIFO is empty.  In addition, if the FIFO is
   // empty and the "thanks" signal is asserted, data is not
   // latched into elmt0.
   assign enqueue = !(!elmt0_full_buf & thanksIn);
   
   rMux2 #(32) bypassmux (dataIn_r, elmt0_value, elmt0_full, dataVal);

   // Report whether or not data is available.
   rNOR2 #(1,`JPWR)    dataAvail_nor(validIn_r, elmt0_full, dataAvail_l);

   // high drive strength for long wires and multiple fanout
   rInvert #(1,`OPWR) dataAvail_not(dataAvail_l, dataAvail);
   
   assign full = elmt0_full;
   
endmodule // network_input_blk_4elmt

	       
   
