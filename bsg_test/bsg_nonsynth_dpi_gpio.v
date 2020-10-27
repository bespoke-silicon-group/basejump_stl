// Non-Synthesizable DPI General Purpose IO
//
// This module is useful for setting and reading "pins" from C/C++
//
// Parameters:
//   int width_p: bit-width of input and output pins
//   bit [width_p-1:0] init_o_p: Initial value of outputs
//   int debug_p: Turn on debug messages at compile time (as opposed
//     to runtime)
// DPI Functions:
//   void bsg_dpi_init(): Initialize this module. Must be called after
//     the initial block has been evaluated.
//   void bsg_dpi_fini(): Destruct this module. Must be called before
//     the final block has been evaluated.
//   bit bsg_dpi_get(int index): Get the value of the input pin at index
//   bit bsg_dpi_set(int index, bit value): Set the value of the output pin at index
//   void bsg_dpi_debug(bit): Set or unset the debug_o output bit. If
//     a state change occurs (0->1 or 1->0) then module will print DEBUG
//     ENABLED / DEBUG DISABLED. No messages are printed if a state
//     change does not occur.
//   int bsg_dpi_width(): returns the parameter width_p
`include "bsg_defines.v"

module bsg_nonsynth_dpi_gpio
   #(parameter int width_p = -1
     ,parameter bit [width_p-1:0] init_o_p = '0
     ,parameter bit use_input_p = '0
     ,parameter bit use_output_p = '0
     ,parameter bit debug_p = '0
     )
   (output bit [width_p-1:0] gpio_o
    ,input bit [width_p-1:0] gpio_i
    );

   bit             debug_b;

   if(width_p <= 0)
     $fatal(1, "BSG ERROR (%M): width_p must be greater than 0");

   if(~use_input_p & ~use_output_p)
     $fatal(1, "BSG ERROR (%M): GPIO must be configured to use input, output, or both");

   // Print module parameters to the console and set the intial debug
   // value. We use init_b to track whether the module has been
   // initialized.
   bit             init_b;
   initial begin
      debug_b = debug_p;
      init_b = 0;
      gpio_o = init_o_p;
      $display("BSG INFO: bsg_nonsynth_dpi_rom (initial begin)");
      $display("BSG INFO:     Instantiation: %M");
      $display("BSG INFO:     width_p:       %d", width_p);
      $display("BSG INFO:     init_o_p:      %b", init_o_p);
      $display("BSG INFO:     use_input_p:   %b", use_input_p);
      $display("BSG INFO:     use_output_p:  %b", use_output_p);
      $display("BSG INFO:     debug_p:       %d", debug_p);

   end

   // This assert checks that fini was called before $finish
   final begin
      if(init_b)
        $fatal(1, "BSG ERROR (%M): final block executed before fini() was called");
   end

   export "DPI-C" function bsg_dpi_init;
   export "DPI-C" function bsg_dpi_fini;
   export "DPI-C" function bsg_dpi_debug;
   export "DPI-C" function bsg_dpi_width;
   export "DPI-C" function bsg_dpi_gpio_get;
   export "DPI-C" function bsg_dpi_gpio_set;

   // Initialize this Manycore DPI Interface
   function void bsg_dpi_init();
      if(init_b)
        $fatal(1, "BSG ERROR (%M): init() already called");

      init_b = 1;
   endfunction

   // Terminate this Manycore DPI Interface
   function void bsg_dpi_fini();
      if(~init_b)
        $fatal(1, "BSG ERROR (%M): fini() already called");

      init_b = 0;
   endfunction

   // Return the parameter width_p
   function int bsg_dpi_width();
      return width_p;
   endfunction

   // Set or unset the debug_o output bit. If a state change occurs
   // (0->1 or 1->0) then module will print DEBUG ENABLED / DEBUG
   // DISABLED. No messages are printed if a state change does not
   // occur.
   function void bsg_dpi_debug(input bit switch_i);
      if(!debug_b & switch_i)
        $display("BSG DBGINFO (%M@%t): DEBUG ENABLED", $time);
      else if (debug_b & !switch_i)
        $display("BSG DBGINFO (%M@%t): DEBUG DISABLED", $time);

      debug_b = switch_i;
   endfunction

   // Get the value of an input pin at the given index.
   //
   // Fails if an invalid index is accessed
   function bit bsg_dpi_gpio_get(input int index);
      bit retval;
      if(~init_b)
         $fatal(1, "BSG ERROR (%M): get() called before init()");

      if(~use_input_p)
         $fatal(1, "BSG ERROR (%M): get() called but use_input_p is 0");

      if(index >= width_p)
         $fatal(1, "BSG ERROR (%M): Invalid index %d", index);

      retval = gpio_i[index];
      if(debug_b)
        $display("BSG INFO (%M): Read Index %d, got %b", index, retval);

      return retval;
   endfunction

   // Set the value of an output pin at the given index.
   //
   // Fails if an invalid index is accessed
   function bit bsg_dpi_gpio_set(input int index, input bit value);
      if(~init_b)
         $fatal(1, "BSG ERROR (%M): get() called before init()");

      if(~use_output_p)
         $fatal(1, "BSG ERROR (%M): get() called but use_output_p is 0");

      if(index >= width_p)
         $fatal(1, "BSG ERROR (%M): Invalid index %d", index);

      gpio_o[index] = value;
      if(debug_b)
        $display("BSG INFO (%M): Wrote Index %d, set to %b", index, value);

      return gpio_o[index];
   endfunction
endmodule
