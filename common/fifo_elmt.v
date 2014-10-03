/****************************************************************************
 *
 *   FILE: fifo_elmt.v:
 *   
 *   Author: Mark Stephenson
 *   Date: Mon Jul 10 16:32:58 2000
 *
 *   Function: This file describes one element of a fifo queue.
 *
 *   Modified: Nathan Goulding
 *   Date:     2010-12-01
 *   Comment:  Parameterized width, default 32 bits
 *
 ***************************************************************************/
`include "ComponentsInclude.v"
module fifo_elmt #(parameter width_p = 32) (
		  enqueue,	// add an element to the fifo.
		  dequeue,	// remove an element from the fifo.
		  new_value,	// the globally new element.
		  prop_value,	// the previous stage's element.
		  prev_full,	// the full value of the last stage.
		  next_full,	// the full value of the next stage.
		  clk,
		  reset,
		  
		  full,		// this stage's full value.
		  value);	// the output of this stage.
   
   input 	enqueue;
   input 	dequeue;
   input [width_p-1:0] new_value;
   input [width_p-1:0] prop_value;
   input 	prev_full;
   input 	next_full;
   input 	clk;
   input 	reset;

   output 	 full;
   output [width_p-1:0] value;

   wire [1:0]   full_sel;
   wire 	full_preg;
   wire [1:0] 	val_sel;
   wire [width_p-1:0] 	value_preg;

   wire full_internal, full_internal_buf;
   wire [width_p-1:0] value_internal;

   // This data-path for the fifo element is simple: we just need
   // two 3-input muxes and two registers.

      `include "ChipInclude.v"

   rMux3 #(1) fullmux (full_internal_buf, prev_full, 1'b1, full_sel, full_preg);
   rDFF_clear #(1) fullreg (full_preg, full_internal, reset, clk);

   rMux3 #(width_p) valmux (value_internal, prop_value, new_value, val_sel, value_preg);
   rDFF  #(width_p) valuereg (value_preg, value_internal, clk);

   // the goal of this buffer is to take all of the load of off this signal
   // so that the output is very fast
   rBuffer #(1,`OPWR) full_buf (full_internal, full_internal_buf);
   
   // Here's the control for the fifo element.

   wire enqueue_b = !enqueue;
   wire dequeue_b = !dequeue;
   wire full_b = !full_internal_buf;
   
   assign full_sel[1] = enqueue & dequeue_b & next_full & full_b;
   assign full_sel[0] = enqueue_b & dequeue;

   // val_sel[1:0]: 2=dataIn_r, 1=previous fifo_elmt value 0=itself
   // only select dataIn_r when (1) we're both enqueuing and dequeing 
   // at the same time and I'm the last elmt on the queue, OR (2) we're only 
   // enqueing and I'm the next available free fifo_elmt
   assign val_sel[1] = enqueue & dequeue & !prev_full & full_internal_buf | full_sel[1];
   // only select previous fifo_elmt when it has a value to feed during dequeing,
   // otherwise select itself to minimize unncessary switching
   assign val_sel[0] =   (dequeue & full_internal_buf & prev_full);

   assign full = full_internal;
   assign value = value_internal;
   

endmodule // fifo_elmt

