// bsg_nonsynth_fifo_to_dpi: A FIFO Interface for receiving FIFO data
// in C/C++ via DPI.
//
// The functions in this module can be exported via DPI by setting
// __BSG_PERMODULE_EXPORT. However, the recommended practice is to
// export them from the top-level of the design.
// 
// Parameters: 
// 
//   name_p: is the name to print in this modules BSG DBGINFO messages
// 
//   width_p: is the bit-width of the FIFO interface. Must be a power
//     of 2 and divisible by 8, i.e. a ctype.
// 
//   debug_p: is the intial value to set on debug_o and to control
//     debug messages. The debug() DPI function can be used to control
//     messages at runtime, but this allows it to be set in the
//     initial block, before any runtime functions can be called.
//
// Functions:
//
//   init(): Initialize this FIFO DPI Interface. Init must be called
//     before any other function
//
//   debug(input bit): Enable or disable BSG DBGINFO messages from this
//     module and set the debug_o output bit.
//
//   width(): Return the bit-width of data_i
//     
//   fini(): De-Initialize this FIFO DPI Interface. This must be
//     called before $finish is called in the testbench.
//     
//   rx(output logic [width_p-1:0] data_o): Receive width_p bits from
//     the FIFO interface through the data_o argument. If data is
//     available, yumi_o will be set to 1 before the next positive
//     edge of clk_i and this method will return 1. If data is not
//     available, this method will return 0 and yumi_o will be set to
//     0 before the next negative edge. 
//
//     rx() CAN ONLY be called after the positive edge of clk_i is
//     evaluated.
//
//     rx() CAN ONLY be called only once per cycle.
//
//     Violating any of these constraints this will cause $fatal to be
//     called to indicate a protocol violation.
//
//   For safe operation of this interface use the bsg_nonsynth_fifo_to_dpi
//   class provided in bsg_nonsynth_fifo.hpp header.
module bsg_nonsynth_fifo_to_dpi
  #(
    parameter string name_p = "bsg_nonsynth_fifo_to_dpi"
    ,parameter width_p = "inv"
    ,parameter bit debug_p = 0
    ) 
   (
    input clk_i
    , input reset_i
      
    , input v_i
    , input [width_p-1:0] data_i
    , output logic yumi_o
      
    , output bit debug_o);

   // This bit tracks whether initialize has been called. If data is
   // sent and recieved before init() is called, then this module will
   // call $fatal
   bit    init_r = 0;
   // This bit checks whether rx() has been called multiple times in a
   // cycle.
   bit    rx_r = 0;
   
   // Check if width_p is a ctype width. call $fatal, if not.
   if (!(width_p inside {32'd8, 32'd16, 32'd32, 32'd64})) begin
      $fatal(1, "BSG ERROR: bsg_nonsynth_dpi_to_fifo (%s) -- width_p of %d is not supported. Must be a power of 2 and divisible by 8", name_p, width_p);
   end

   // Print module parameters to the console and set the intial debug
   // value.
   initial begin
      debug_o = debug_p;

      $display("BSG INFO: bsg_nonsynth_dpi_to_fifo (initial begin)");
      $display("BSG INFO:     name_p  = %s", name_p);
      $display("BSG INFO:     width_p = %d", width_p);
      $display("BSG INFO:     debug_p = %d", debug_p);
      $display("BSG INFO:     debug_o = %d", debug_o);
   end

   // This checks that fini was called before $finish
   final begin
      if (init_r === 1)
        $fatal(1, "BSG ERROR: bsg_nonsynth_dpi_to_fifo (%s) -- fini() was not called before $finish", name_p);
   end

   // The DPI Functions should be exported from the top-level of the
   // design, but if you do want to export them here, you can do so by
   // setting __BSG_PERMODULE_EXPORT
`ifdef __BSG_PERMODULE_EXPORT
   export "DPI-C" function init;
   export "DPI-C" function fini;
   export "DPI-C" function debug;
   export "DPI-C" function width;
   export "DPI-C" function rx;
   export "DPI-C" function is_window;
`endif // __BSG_PERMODULE_EXPORT

   // Set or unset the debug_o output bit. If a state change occurs
   // (0->1 or 1->0) then module will print DEBUG ENABLED / DEBUG
   // DISABLED. No messages are printed if a state change does not
   // occur.
   function void debug(input bit switch_i);
      if(!debug_o & switch_i)
        $display("BSG DBGINFO (%s@%t): DEBUG ENABLED", name_p, $time);
      else if (debug_o & !switch_i) 
        $display("BSG DBGINFO (%s@%t): DEBUG DISABLED", name_p, $time);

      debug_o = switch_i;
   endfunction

   // Silly, but useful.
   function int width();
      return width_p;
   endfunction

   // Initialize this FIFO DPI Interface
   function void init();
      if(debug_o)
        $display("BSG DBGINFO (%s@%t): init() called", name_p, $time);

      if(init_r)
        $fatal(1, "BSG ERROR (%s): init() already called", name_p);

      init_r = 1;
   endfunction

   // Terminate this FIFO DPI Interface
   function void fini();
      if(debug_o)
        $display("BSG DBGINFO (%s@%t): fini() called", name_p, $time);

      if(~init_r)
        $fatal(1, "BSG ERROR (%s): fini() already called", name_p);

      init_r = 0;
   endfunction

   // rx(output logic [width_p-1:0] data_o) -- Set ready_i and read
   // data_i from the FIFO interface. When valid data is available
   // (v_i === 1) this function will return 1. When there is no valid
   // data available, this function will return 0.
   //
   // rx() MUST be called after the positive edge of clk_i is
   // evaluated. It MUST be called only once per cycle. Failure will
   // cause an error and a call to $fatal.
   // 
   // We set yumi_o_n so that we can signal a read to the producer on
   // the NEXT positive edge without reading multiple times
   logic    yumi_o_n;

   // We track the "last" v_i and last yumi_o values to detect
   // protocol violations. These are captured on the positive edge of
   // the clock
   reg    v_i_r;
   reg    yumi_o_r;
   
   // We track the polarity of the current edge so that we can notify
   // the user of incorrect behavior.
   reg    edgepol;
   always @(posedge clk_i or negedge clk_i) begin
      edgepol <= clk_i;
   end

   function bit rx(output logic [width_p-1:0] data_o);

      if(init_r === 0) begin
         $fatal(1,"BSG ERROR (%s): rx() called before init()", name_p);
      end

      if(reset_i === 1) begin
         $fatal(1, "BSG ERROR (%s): rx() called while reset_i === 1", name_p);
      end      

      if(clk_i === 0) begin
         $fatal(1, "BSG ERROR (%s): rx() must be called when clk_i == 1", name_p);
      end

      if(rx_r !== 0) begin
         $fatal(1, "BSG ERROR (%s): rx() called multiple times in a clk_i cycle", name_p);
      end

      if(edgepol === 0) begin
        $fatal(1, "BSG ERROR (%s): rx() must be called after the positive edge of clk_i has been evaluated", name_p);
      end

      // This will flow to its output on the next negative clock edge.
      yumi_o_n = v_i;
      data_o = data_i;

      rx_r = 1;

      if(debug_o)
        $display("BSG DBGINFO (%s@%t): rx() called -- v_i: %b data_i: 0x%x",
                 name_p, $time, v_i, data_i);

      return (v_i === 1);
   endfunction

   // The function isWindow returns true if the interface is in a
   // valid time-window to call rx()
   function bit is_window();
      return (~rx_r & clk_i & edgepol);
   endfunction

   // We set yumi_o to 0 on the positive edge of clk_i (after it has
   // been seen by the producer) so that we don't trigger negedge
   // protocol assertions in the BSG FIFOs. We also need to reset
   // yumi_o to 0 after data has been read to ensure that we don't
   // "latch" yumi_o ===1 and unintentionally read multiple cycles in
   // a row.
   // 
   // To ensure that the correct yumi_o value is read on a positive
   // clock edge, we set yumi_o_n ("next yumi") in rx() and propogate
   // it to yumi_o on the negative clock edge. The producer will see
   // the correct value of yumi_o on the next positive edge.
   //
   // We also set yumi_o on the negative edge to ensure that it
   // changes after the BSG FIFO protocol assertions have
   // passed. After yumi_o_n has been read, we pre-emptively set it
   // back to 0. If rx() is called again on the next cycle, it will
   // set yumi_o_n === 1 to read.
   always @ (posedge clk_i or negedge clk_i) begin
      if(clk_i)
        yumi_o <= 0;
      else
        yumi_o <= yumi_o_n;
      yumi_o_n = '0;
   end

   // Save the last v_i and yumi_o values for protocol checking
   always @(posedge clk_i) begin
      v_i_r <= v_i;
      yumi_o_r <= yumi_o;
      
      rx_r = 0;
      if(debug_o)
        $display("BSG DBGINFO (%s@%t): posedge clk_i -- reset_i: %b v_i: %b yumi_o: %b data_i: 0x%x",
                 name_p, $time, reset_i, v_i, yumi_o, data_i);
   end

endmodule // bsg_nonsynth_fifo_to_dpi
