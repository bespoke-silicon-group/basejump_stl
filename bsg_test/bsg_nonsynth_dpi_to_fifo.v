// bsg_nonsynth_dpi_to_fifo: A FIFO Interface for transmitting FIFO
// data from C/C++ into simulation via DPI
// 
// Parameters: 
// 
//   width_p: is the bit-width of the FIFO interface. Must be a power
//     of 2 and divisible by 8, i.e. a ctype.
// 
//   debug_p: is the intial value to set on debug_o and to control
//     debug messages. The bsg_dpi_debug() DPI function can be used to
//     control messages at runtime, but this allows it to be set in
//     the initial block, before any runtime functions can be called.
//
// Functions:
//
//   init(): Initialize this FIFO DPI Interface. Init must be called
//     before any other function
//
//   bsg_dpi_debug(input bit): Enable or disable BSG DBGINFO messages
//   from this module and set the debug_o output bit.
//
//   width(): Return the bit-width of data_i
//     
//   fini(): De-Initialize this FIFO DPI Interface. This must be
//     called before $finish is called in the testbench.
//
//   bsg_dpi_fifo_tx(input bit [width_p-1:0] data_i): Write data_i to the FIFO
//     interface and set v_o. If the consumer is ready (ready_i === 1)
//     this function will return 1 to indicate that the consumer
//     accepted the data. Ifthe consumer is not ready (ready_i === 0)
//     this function will return 0 to indicate that the consumer did
//     not accept the data.
//
//     If the data is not accepted by the consumer FIFO, the host
//     C/C++ program MUST call this method again on the next cycle.
//
//     If the data is not accepted by the consumer FIFO, the host
//     C/C++ program MUST call this this method with the same
//     arguments (i.e. data_i should remain constant across calls).
//
//     bsg_dpi_fifo_tx() CAN ONLY be called after the positive edge of clk_i is
//     evaluated.
//
//     bsg_dpi_fifo_tx() CAN ONLY be called only once per clk_i cycle. 
//
//     Violating any of these constraints this will cause $fatal to be
//     called to indicate a protocol violation.
//
//   For safe operation of this interface use the bsg_nonsynth_fifo_to_dpi
//   class provided in bsg_nonsynth_fifo.hpp header.
`include "bsg_defines.v"

module bsg_nonsynth_dpi_to_fifo
  #(
    parameter width_p = "inv"
    ,parameter bit debug_p = 0
    )
   (
    input clk_i
    , input reset_i
      
    , output logic v_o
    , output logic [width_p-1:0] data_o
    , input ready_i
      
    , output bit debug_o);

   // This bit tracks whether initialize has been called. If data is
   // sent and recieved before init() is called, then this module will
   // call $fatal
   bit    init_r = 0;
   // This bit checks whether bsg_dpi_fifo_tx() has been called multiple times in a
   // cycle.
   bit    tx_r = 0;
   
   // Check if width_p is a ctype width. call $fatal, if not.
   if (!(width_p inside {32'd8, 32'd16, 32'd32, 32'd64, 32'd128})) begin
      $fatal(1, "BSG ERROR (%M): width_p of %d is not supported. Must be a power of 2 and divisible by 8", width_p);
   end

   // Print module parameters to the console and set the intial debug
   // value
   initial begin
      debug_o = debug_p;

      $display("BSG INFO: bsg_nonsynth_dpi_to_fifo (initial begin)");
      $display("BSG INFO:     Instantiation: %M");
      $display("BSG INFO:     width_p = %d", width_p);
      $display("BSG INFO:     debug_p = %d", debug_p);
   end

   // This checks that fini was called before $finish
   final begin
      if (init_r === 1)
        $fatal(1, "BSG ERROR (%M): fini() was not called before $finish");
   end
   
   export "DPI-C" function bsg_dpi_init;
   export "DPI-C" function bsg_dpi_fini;
   export "DPI-C" function bsg_dpi_debug;
   export "DPI-C" function bsg_dpi_width;
   export "DPI-C" function bsg_dpi_fifo_tx;
   export "DPI-C" function bsg_dpi_fifo_is_window;
   
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

   // Silly, but useful.
   function int bsg_dpi_width();
      return width_p;
   endfunction

   // Initialize this FIFO DPI Interface
   function void bsg_dpi_init();
      if(debug_o)
        $display("BSG DBGINFO (%M@%t): bsg_dpi_init() called", $time);

      if(init_r)
        $fatal(1, "BSG ERROR (%M): bsg_dpi_init() already called");

      init_r = 1;
   endfunction

   // Terminate this FIFO DPI Interface
   function void bsg_dpi_fini();
      if(debug_o)
        $display("BSG DBGINFO (%M@%t): bsg_dpi_fini() called", $time);

      if(~init_r)
        $fatal(1, "BSG ERROR (%M): bsg_dpi_fini() already called");

      init_r = 0;
   endfunction

   // bsg_dpi_fifo_tx(input logic [width_p-1:0] data_i) -- Provide data_i
   // to the FIFO interface on data_o and set v_o. When the consumer
   // is ready (ready_i == 1) this function will return 1 to indicate
   // that the consumer accepted the data. When the consumer is not
   // ready this function will return 0 to indicate that the consumer
   // did not accept the data.
   //
   // If the data is not consumed, the host C/C++ program MUST call
   // this method again on the next cycle with the same arguments
   // (i.e. data_i should remain constant across calls). Not doing
   // this will cause $fatal to be called to indicate a protocol
   // violation because v_o will return to 0 in the next cycle.
   //
   // bsg_dpi_fifo_tx() MUST be called after the positive edge of clk_i is
   // evaluated. It MUST be called only once per cycle. Failure will
   // cause an error and a call to $fatal.

   // We set v_o_n so that we can signal a read to the producer on the
   // NEXT positive edge. v_o_n flows to v_o on the negative edge of
   // clk_i
   logic v_o_n;
   // Same as above, but with data_o.
   logic [width_p-1:0] data_o_n;
   
   // We track the "last" data_o and last ready_i values to detect
   // protocol violations. These are captured on the positive edge of
   // the clock
   reg [width_p-1:0] data_o_r;
   reg               ready_i_r;

   // We track the polarity of the current edge so that we can call
   // $fatal when $rx is called during the wrong phase of clk_i.
   reg               edgepol;
   always @(posedge clk_i or negedge clk_i) begin
      edgepol <= clk_i;
   end


   // TODO: Check that tx isn't called multiple times in a cycle
   function bit bsg_dpi_fifo_tx(input bit [width_p-1:0] data_bi);

      if(init_r === 0) begin
         $fatal(1, "BSG ERROR (%M): bsg_dpi_fifo_tx() called before init()");
      end

      if(reset_i === 1) begin
         $fatal(1, "BSG ERROR (%M): bsg_dpi_fifo_tx() called while reset_i === 1");
      end      

      if(tx_r !== 0) begin
         $fatal(1, "BSG ERROR (%M): bsg_dpi_fifo_tx() called multiple times in a clk_i cycle");
      end

      if(clk_i === 0) begin
        $fatal(1, "BSG ERROR (%M): bsg_dpi_fifo_tx() must be called when clk_i == 1");
      end

      if(edgepol === 0) begin
        $fatal(1, "BSG ERROR (%M): bsg_dpi_fifo_tx() must be called after the positive edge of clk_i has been evaluated");
      end

      if((ready_i_r === 0 & v_o === 1) & !(data_bi === data_o_r)) begin
         $fatal(1, "BSG ERROR (%M): bsg_dpi_fifo_tx() argument data_bi must be constant across calls/cycles when the consumer is not ready");
      end

      // These will flow to their respective outputs on the next
      // negative clock edge.
      v_o_n = '1;
      data_o_n = data_bi;

      tx_r = 1;
      
      if(debug_o)
        $display("BSG DBGINFO (%M@%t): bsg_dpi_fifo_tx() called -- ready_i: %b, data_o_n: 0x%x", 
                 $time, ready_i, data_bi);

      return (ready_i === 1);
   endfunction

   // The function bsg_dpi_fifo_is_window returns true if the interface is
   // in a valid time-window to call bsg_dpi_fifo_tx()
   function bit bsg_dpi_fifo_is_window();
      return (~tx_r & clk_i & edgepol & ~reset_i);
   endfunction


   // We set v_o and data_o on a negative clock edge so that it is
   // seen on the next positive edge. v_o_n and data_o_n hold the "next"
   // values for v_o and data_o.
   //
   // We proactively clear v_o by setting v_o_n to 0 in case ready_i ==
   // 1 on the positive edge. If ready_i == 1, and we don't set v_o_n
   // here, then the user will have to call tx again to clear v_o even
   // though they aren't sending data. If ready_i === 0 then the user
   // MUST call tx again and v_o will be set to 1 again, otherwise
   // $fatal will be called because dropping v_o without ready_i === 1
   // is a protocol violation. 
   //
   // If the user wants to send NEW data after ready_i === 1, they
   // will call bsg_dpi_fifo_tx() and v_o will be set to 1 again.
   always @(negedge clk_i) begin
      // If the user fails to call bsg_dpi_fifo_tx() AGAIN (v_o_n === 0) after a
      // data beat was not accepted (v_o == 1 && ready_i == 0) that is
      // a protocol error.
      if(v_o_n === 0 & (v_o === 1 & ready_i_r === 0)) begin
         $fatal(1, "BSG ERROR: bsg_dpi_fifo_tx() was not called again on the cycle after the consumer was not ready");
      end

      data_o <= data_o_n;
      v_o <= v_o_n;

      v_o_n = 0;
   end

   // Save the last ready_i and data_o values for protocol checking
   // and reset tx_r to 0 to
   always @(posedge clk_i) begin
      ready_i_r <= ready_i;
      data_o_r <= data_o;

      tx_r = 0;
      if(debug_o)
        $display("BSG DBGINFO (%M@%t): posedge clk_i -- reset_i: %b v_o: %b ready_i: %b data_i: 0x%x",
                 $time, reset_i, v_o, ready_i, data_o);
   end
   
   

endmodule // bsg_nonsynth_dpi_to_fifo
