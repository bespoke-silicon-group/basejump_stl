// Non-Synthesizable DPI ROM
//
// This module is useful for putting compile-time parameters in a
// verilog design to be accessed by a C/C++ runtime.
//
// Parameters:
//   int els_p: Number of ROM elements
//   int width_p: bit-width of ROM elements
//   bit [width_p-1:0] arr_p [els_p-1:0]: The array of values to load
//     into the ROM.
//   int debug_p: Turn on debug messages at compile time (as opposed
//     to runtime)
// DPI Functions:
//   void bsg_dpi_init(): Initialize this module. Must be called after
//     the initial block has been evaluated.
//   void bsg_dpi_fini(): Destruct this module. Must be called before
//     the final block has been evaluated.
//   void bsg_dpi_debug(bit): Set or unset the debug_o output bit. If a state change occurs
//     (0->1 or 1->0) then module will print DEBUG ENABLED / DEBUG
//     DISABLED. No messages are printed if a state change does not
//     occur.
//   int bsg_dpi_nels(): returns the parameter els_p
//   int bsg_dpi_width(): returns the parameter width_p
//   bit [width_p-1:0] bsg_dpi_rom_get(int): Read and return the value
//     at index idx in arr_p
`include "bsg_defines.v"

module bsg_nonsynth_dpi_rom
   #(parameter int els_p = -1
     ,parameter int width_p = -1
     ,parameter bit [width_p-1:0] arr_p [els_p-1:0] = '{default:0}
     ,parameter bit debug_p = 0
     )
   ();

   bit             debug_b;

   bit [width_p-1:0] rom_l [0:els_p-1];

   if(els_p <= 0)
     $fatal(1, "BSG ERROR (%M): els_p must be greater than 0");

   if(width_p <= 0)
     $fatal(1, "BSG ERROR (%M): width_p must be greater than 0");

   // Print module parameters to the console and set the intial debug
   // value. We use init_b to track whether the module has been
   // initialized.
   bit             init_b;
   initial begin
      debug_b = debug_p;
      init_b = 0;

      $display("BSG INFO: bsg_nonsynth_dpi_rom (initial begin)");
      $display("BSG INFO:     Instantiation: %M");
      $display("BSG INFO:     width_p:       %d", width_p);
      $display("BSG INFO:     els_p:         %d", els_p);
      $display("BSG INFO:     debug_p:       %d", debug_p);
      for(int i = 0; i < els_p; i++)
        $display("BSG INFO:     arr_p[%d]:     0x%x", i, arr_p[i]);
   end

   // This assert checks that fini was called before $finish
   final begin
      if(init_b)
        $fatal(1, "BSG ERROR (%M): final block executed before fini() was called");
   end

   export "DPI-C" function bsg_dpi_init;
   export "DPI-C" function bsg_dpi_fini;
   export "DPI-C" function bsg_dpi_debug;
   export "DPI-C" function bsg_dpi_rom_get;
   export "DPI-C" function bsg_dpi_nels;
   export "DPI-C" function bsg_dpi_width;

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

   // Return the parameter els_p
   function int bsg_dpi_nels();
      return els_p;
   endfunction

   // Return the parameter width_p
   function int bsg_dpi_width();
      return width_p;
   endfunction

   // Initialize every index in the rom array variable with data from
   // arr_p
   generate
      for(genvar i = 0; i < els_p; i++) begin
         initial
           rom_l[i] = arr_p[i];
      end
   endgenerate

   // Get the value at an index in the rom. This fails if an invalid
   // index is accessed.
   function bit [width_p-1:0] bsg_dpi_rom_get(input int idx);
      if(~init_b)
         $fatal(1, "BSG ERROR (%M): get() called before init()");

      if(idx >= els_p | idx < 0)
         $fatal(1, "BSG ERROR (%M): Invalid index %d", idx);

      if(debug_b)
        $display("BSG INFO (%M): Read Index %d: %x", idx, rom_l[idx]);

      return rom_l[idx];
   endfunction
endmodule
