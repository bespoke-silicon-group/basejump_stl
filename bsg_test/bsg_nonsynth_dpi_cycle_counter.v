// This modules defines a DPI interface for a counter that can be read
// periodically using DPI
`include "bsg_defines.v"

module bsg_nonsynth_dpi_cycle_counter
  #(
    parameter int width_p = "inv"
    ,parameter bit debug_p = 0
    )
   (
    input clk_i
    ,input reset_i

    ,output logic [width_p-1:0] ctr_r_o
    ,output logic debug_o
    );

   export "DPI-C" function bsg_dpi_init;
   export "DPI-C" function bsg_dpi_fini;
   export "DPI-C" function bsg_dpi_debug;
   export "DPI-C" function bsg_dpi_width;
   export "DPI-C" function bsg_dpi_cycle_counter_read;
   export "DPI-C" function bsg_dpi_cycle_counter_is_window;

   // Tracks whether init has been called
   logic  init_l;

   // Print module parameters to the console and set the intial debug
   // value.   
   initial begin
      $display("BSG INFO: bsg_nonsynth_dpi_cycle_counter (initial begin)");
      $display("BSG INFO:     Instantiation: %M");
      $display("BSG INFO:     width_p = %d", width_p);
      $display("BSG INFO:     debug_p = %d", debug_p);
   end

   bsg_cycle_counter
     #(.width_p(width_p)
       ,.init_val_p('0))
   counter_inst
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.ctr_r_o(ctr_r_o));

   // We track the polarity of the current edge so that we can notify
   // the user of incorrect behavior.
   logic    edgepol;
   always_ff @(posedge clk_i or negedge clk_i) begin
      edgepol <= clk_i;
   end

   // Initialize this Module
   function void bsg_dpi_init();
      if(init_l)
        $fatal(1, "BSG ERROR (%M): init() already called");

      init_l = 1;
   endfunction

   // Terminate this Module
   function void bsg_dpi_fini();
      if(~init_l)
        $fatal(1, "BSG ERROR (%M): fini() already called");

      init_l = 0;
   endfunction

   // Set or unset the debug_o output bit. If a state change occurs
   // (0->1 or 1->0) then module will print DEBUG ENABLED / DEBUG
   // DISABLED. No messages are printed if a state change does not
   // occur.
   function void bsg_dpi_debug(input bit switch_i);
      if(!debug_o & switch_i)
        $display("BSG DBGINFO (%M@%t): DEBUG ENABLED", $time);
      else if (debug_o & !switch_i) 
        $display("BSG DBGINFO (%M@%t): DEBUG DISABLED", $time);

      debug_o = switch_i;
   endfunction

   // Returns width_p
   function int bsg_dpi_width();
      return width_p;
   endfunction

   // The function bsg_dpi returns true if the interface is in a
   // valid time-window to call bsg_dpi_fifo_rx()
   function bit bsg_dpi_cycle_counter_is_window();
      return (clk_i & edgepol & ~reset_i);
   endfunction

   // Read and return the current counter value.
   function void bsg_dpi_cycle_counter_read(output bit [width_p-1:0] data_bo);
      if(init_l === 0) begin
         $fatal(1,"BSG ERROR (%M): read() called before init()");
      end

      if(reset_i === 1) begin
         $fatal(1, "BSG ERROR (%M): read() called while reset_i === 1");
      end      

      if(clk_i === 0) begin
         $fatal(1, "BSG ERROR (%M): read() must be called when clk_i == 1");
      end

      if(edgepol === 0) begin
        $fatal(1, "BSG ERROR (%M): read() must be called after the positive edge of clk_i has been evaluated");
      end

      data_bo = ctr_r_o;
   endfunction

endmodule
