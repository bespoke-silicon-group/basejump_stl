// bsg_nonsynth_fifo_to_dpi: A FIFO Interface for receiving FIFO data
// in C/C++ via DPI
// 
// Parameters: 
// 
// name_p is the name to print in this modules BSG DBGINFO messages
// 
// width_p is the bit-width of the FIFO interface. Must be a power of
//   2 and divisible by 8, i.e. a ctype.
// 
// debug_p is the intial value to set on debug_o and to control debug
//   messages. The debug() DPI function can be used to control
//   messages at runtime, but this allows it to be set in the initial
//   block, before any runtime functions can be called.
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
    , output yumi_o
      
    , output bit debug_o);

   // This bit tracks whether initialize has been called. If data is
   // sent and recieved before init() is called, then this module will
   // throw an assertion. TODO
   bit    init_b = 0;
   
   // Print module parameters to the console and set the intial debug
   // value.
   //
   // Also, Check if width_p is a ctype width. call $fatal, if not.
   initial begin
      if (!(width_p inside {8, 16, 32, 64})) begin
         $display("BSG ERROR: bsg_nonsynth_fifo_to_dpi (%s) -- width_p of %d is not supported. Must be a power of 2 and divisible by 8", name_p, width_p);
         $fatal();
      end

      debug_o = debug_p;

      $display("BSG INFO: bsg_nonsynth_dpi_to_fifo (initial begin)");
      $display("BSG INFO:     name_p  = %s", name_p);
      $display("BSG INFO:     width_p = %d", width_p);
      $display("BSG INFO:     debug_p = %d", debug_p);
      $display("BSG INFO:     debug_o = %d", debug_o);
   end

   // This assert checks that fini was called before $finish
   final begin
      assert(!init_b);
   end

`ifdef __BSG_PERMODULE_EXPORT
   // These should be exported from the top-level of the design, but
   // if you do want to export them here, you can do so by setting
   // __BSG_PERMODULE_EXPORT
   export "DPI-C" function init;
   export "DPI-C" function fini;
   export "DPI-C" function debug;
   export "DPI-C" function width;
   export "DPI-C" function rx;
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
      init_b = 1;
   endfunction

   // Terminate this FIFO DPI Interface
   function void fini();
      if(debug_o)
        $display("BSG DBGINFO (%s@%t): fini() called", name_p, $time);
      init_b = 0;
   endfunction

   // rx(output logic [width_p-1:0] data_o) -- Set ready_i and read
   // data_i from the FIFO interface. When valid data is available
   // (v_i === 1) this function will return 1. When there is no valid
   // data available, this function will return 0.
   //
   // If valid data is not available (v_i === 0) the host C/C++
   // program MUST call this method again on the next cycle. Not doing
   // this will cause $fatal to be called to indicate a protocol
   // violation because ready_i will return to 0 on the next cycle.
   //
   // rx() MUST be called after the positive edge of clk_i is
   // evaluated.

   // We set _yumi_o so that we can signal a read to the producer on
   // the NEXT positive edge without reading multiple times
   reg    _yumi_o;

   // We track the "last" v_i and last yumi_o values to detect
   // protocol violations. These are captured on the positive edge of
   // the clock
   reg    last_v_i;
   reg    last_yumi_o;
   
   // We track the polarity of the current edge so that we can notify
   // the user of incorrect behavior.
   reg    edgepol;
   always @(posedge clk_i or negedge clk_i) begin
      edgepol <= clk_i;
   end

   function bit rx(output logic [width_p-1:0] data_o);

      if(~init_b) begin
         $display("BSG ERROR (%s): rx() called before init()", name_p);
         $fatal();
      end

      if(reset_i) begin
         $display("BSG ERROR (%s): rx() called while reset_i == 1", name_p);
         $fatal();
      end      

      if(~clk_i) begin
         $display("BSG ERROR (%s): rx() must be called when clk_i == 1", name_p);
         $fatal();
      end

      if(!edgepol) begin
        $display("BSG ERROR (%s): rx() must be called after the positive edge of clk_i has been evaluated", name_p);
        $fatal();
      end

      if(debug_o)
        $display("BSG DBGINFO (%s@%t): rx() called -- v_i: %b data_i: 0x%x",
                 name_p, $time, v_i, data_i);

      // This will flow to its output on the next negative clock edge.
      _yumi_o = '1;
      data_o = data_i;

      return (v_i === 1);
   endfunction

   // To ensure that the correct yumi_o value is read on a positive
   // clock edge, we set _yumi_o ("next yumi") in rx() and propogate
   // it to yumi_o on the negative clock edge. The producer will see
   // the correct value of yumi_o on the next positive edge.
   //
   // Because we're pulling data out of a FIFO interface (in
   // simulation, i.e. non synthesizable) we need to reset yumi_o to 0
   // on the positive clock edge to ensure that we don't
   // unintentionally read multiple cycles in a row. Therefore, we
   // pre-emptively set _yumi_o 0 in case rx() is not called again on
   // the next cycle.
   //
   // We also do some basic protocol checking. Users should never
   // de-assert ready unless they consume valid data from the
   // producer.
   always @(negedge clk_i) begin
      // If the user fails to call rx() AGAIN after a data beat was
      // not consumed (last_v_i == 0 && last_yumi_o == 1) that is a
      // protocol error.
      if(_yumi_o === 0 & (last_v_i === 0 & last_yumi_o === 1)) begin
         $display("BSG ERROR (%s): rx() was not called again the cycle after the producer did not provide valid data", name_p);
         $fatal();
      end

      yumi_o <= _yumi_o;

      _yumi_o = '0;
   end

   // Save the last v_i and yumi_o values for protocol checking
   always @(posedge clk_i) begin
      last_v_i = v_i;
      last_yumi_o = yumi_o;
      
      if(debug_o)
        $display("BSG DBGINFO (%s@%t): posedge clk_i -- reset_i: %b v_i: %b yumi_o: %b data_i: 0x%x",
                 name_p, $time, reset_i, v_i, yumi_o, data_i);
   end

endmodule // bsg_nonsynth_fifo_to_dpi
