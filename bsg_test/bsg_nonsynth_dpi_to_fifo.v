// bsg_nonsynth_dpi_to_fifo: A FIFO Interface for transmitting FIFO
// data from C/C++ into simulation via DPI
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
module bsg_nonsynth_dpi_to_fifo
  #(
    parameter string name_p = "bsg_nonsynth_dpi_to_fifo"
    ,parameter width_p = "inv"
    ,parameter bit debug_p = 0
    )
   (
    input clk_i
    , input reset_i
      
    , output v_o
    , output [width_p-1:0] data_o
    , input ready_i
      
    , output bit debug_o);

   // This bit tracks whether initialize has been called. If data is
   // sent and recieved before init() is called, then this module will
   // throw an assertion.
   bit    init_b = 0;
   
   // Print module parameters to the console and set the intial debug
   // value
   initial begin
      if (!(width_p inside {8, 16, 32, 64})) begin
         $display("BSG ERROR: bsg_nonsynth_dpi_to_fifo (%s) -- width_p of %d is not supported. Must be a power of 2 and divisible by 8", name_p, width_p);
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
   export "DPI-C" function tx;
`endif // __BSG_PERMODULE_EXPORT
   
   // Set or unset the debug_o output bit. If a state change occurs
   // (0->1 or 1->0) then module will print DEBUG ENABLED / DEBUG
   // DISABLED. No messages are printed if a state change does not
   // occur.
   function void debug(input bit switch_i);
      if(!debug_o & switch_i)
        $display("BSG DBGINFO (%s@%t): DEBUG ENABLED", 
                 name_p, $time);
      else if (debug_o & !switch_i) 
        $display("BSG DBGINFO (%s@%t): DEBUG DISABLED", 
                 name_p, $time);

      debug_o = switch_i;
   endfunction

   // Silly, but useful.
   function int width();
      return width_p;
   endfunction

   // Initialize this FIFO DPI Interface
   function void init();
      if(debug_o)
        $display("BSG DBGINFO (%s@%t): init() called", 
                 name_p, $time);
      init_b = 1;
   endfunction

   // Terminate this FIFO DPI Interface
   function void fini();
      if(debug_o)
        $display("BSG DBGINFO (%s@%t): fini() called", 
                 name_p, $time);
      init_b = 0;
   endfunction

   // tx(input logic [width_p-1:0] data_i) -- Provide data_i to the
   // FIFO interface on data_o and set v_o. When the consumer is ready
   // (ready_i == 1) this function will return 1 to indicate that the
   // consumer accepted the data. When the consumer is not ready this
   // function will return 0 to indicate that the consumer did not
   // accept the data.
   //
   // If the data is not consumed, the host C/C++ program MUST call
   // this method again on the next cycle with the same arguments
   // (i.e. data_i should remain constant across calls). Not doing
   // this will cause $fatal to be called to indicate a protocol
   // violation because v_o will return to 0 in the next cycle.
   //
   // tx() MUST be called after the positive edge of clk_i is
   // evaluated.

   // We set _v_o so that we can signal a read to the producer on the
   // NEXT positive edge. _v_o flows to v_o on the negative edge of
   // clk_i
   logic _v_o;
   // Same as above, but with data_o.
   logic [width_p-1:0] _data_o;
   
   // We track the "last" data_o and last ready_i values to detect
   // protocol violations. These are captured on the positive edge of
   // the clock
   reg [width_p-1:0] last_data_o;
   reg               last_ready_i;

   // We track the polarity of the current edge so that we can call
   // $fatal when $rx is called during the wrong phase of clk_i.
   reg               edgepol;
   always @(posedge clk_i or negedge clk_i) begin
      edgepol <= clk_i;
   end

   function bit tx(input logic [width_p-1:0] data_i);

      if(~init_b) begin
         $display("BSG ERROR (%s): tx() called before init()", name_p);
         $fatal();
      end

      if(reset_i) begin
         $display("BSG ERROR (%s): tx() called while reset_i == 1", name_p);
         $fatal();
      end      

      if(~clk_i) begin
        $display("BSG ERROR (%s): tx() must be called when clk_i == 1", name_p);
        $fatal();
      end

      if(!edgepol) begin
        $display("BSG ERROR (%s): tx() must be called after the positive edge of clk_i has been evaluated", name_p);
        $fatal();
      end

      if((last_ready_i === 0 & v_o === 1) & !(data_i === last_data_o)) begin
         $display("BSG ERROR (%s): tx() argument data_i must be constant across calls/cycles when the consumer is not ready", name_p);
         $fatal();
      end

      // These will flow to their respective outputs on the next
      // negative clock edge.
      _v_o = '1;
      _data_o = data_i;

      if(debug_o)
        $display("BSG DBGINFO (%s@%t): tx() called -- ready_i: %b, data_i: 0x%x", 
                 name_p, $time, ready_i, data_i);

      return (ready_i === 1);
   endfunction

   // We set v_o and data_o on a negative clock edge so that it is
   // seen on the next positive edge. _v_o and _data_o hold the "next"
   // values for v_o and data_o.
   //
   // We proactively clear v_o by setting _v_o to 0 in case ready_i ==
   // 1 on the positive edge. If ready_i == 1, and we don't set _v_o
   // here, then the user will have to call tx again to clear v_o even
   // though they aren't sending data. If ready_i === 0 then the user
   // MUST call tx again and v_o will be set to 1 again, otherwise
   // $fatal will be called because dropping v_o without ready_i === 1
   // is a protocol violation. 
   //
   // If the user wants to send NEW data after ready_i === 1, they
   // will call tx() and v_o will be set to 1 again.
   always @(negedge clk_i) begin
      // If the user fails to call tx() AGAIN (_v_o === 0) after a
      // data beat was not accepted (v_o == 1 && ready_i == 0) that is
      // a protocol error.
      if(_v_o === 0 & (v_o === 1 & last_ready_i === 0)) begin
         $display("BSG ERROR: tx() was not called again on the cycle after the consumer was not ready");
         $fatal;
      end

      data_o <= _data_o;
      v_o <= _v_o;

      _v_o = 0;
   end

   // Save the last ready_i and data_o values for protocol checking
   always @(posedge clk_i) begin
      last_ready_i <= ready_i;
      last_data_o <= data_o;

      if(debug_o)
        $display("BSG DBGINFO (%s@%t): posedge clk_i -- reset_i: %b v_o: %b ready_i: %b data_i: 0x%x",
                 name_p, $time, reset_i, v_o, ready_i, data_o);
   end

endmodule // bsg_nonsynth_dpi_to_fifo
