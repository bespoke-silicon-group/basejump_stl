/****************************************************************************
 *
 *   FILE: fifo_counter.v:
 *   
 *   Author: Mark Stephenson
 *   Date: Thu Jul 13 10:55:03 2000
 *
 *   Function: Keeps track of the number of elements in the NIB.
 *
 ***************************************************************************/

module fifo_counter (up_count,
		     down_count,
		     num_entries,
		     reset,
		     clk);

   parameter pLogBufSize = 2;
   
   input  up_count;
   input  down_count;
   input  reset;
   input  clk;
   
   output [pLogBufSize-1:0] num_entries;
   wire   [pLogBufSize-1:0] num_entries_internal;
   
   wire [pLogBufSize-1:0]   r_num_entries;
   wire count;
   
   `include "ChipInclude.v"

   assign count = (up_count ^ down_count) | reset;

   rDFF_en_clear #(pLogBufSize) cntreg (r_num_entries, 
					num_entries_internal, 
					count, 
					reset, 
					clk);

   rAddSub #(pLogBufSize) counter (num_entries_internal,
				   {pLogBufSize{1'b1}},
				   up_count,
				   r_num_entries);

   assign num_entries = num_entries_internal;
		 
   //synopsys translate_off
   assert property (@(posedge clk) 
     !( (num_entries == 0)   & down_count    & (~up_count) & (~reset)) )
   else
     $error ("counter underflow");
  
   assert property (@(posedge clk) 
     !( (num_entries+1 == 0) & (~down_count) & (up_count)  & (~reset)) )
   else
     $error ("counter overflow");
   //synopsys translate_on		

endmodule // fifo_counter
