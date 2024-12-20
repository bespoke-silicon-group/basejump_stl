
`include "bsg_defines.sv"

module bsg_nonsynth_test_rom_plusargs
 #(parameter data_width_p="inv"
   , parameter addr_width_p="inv"
   , parameter hex_not_bin_p = 0
   , parameter plusargs_str_p = "inv"
   )
  (
   input [addr_width_p-1:0] addr_i
   , output logic [data_width_p-1:0] data_o
   );

  localparam els_lp = 2**addr_width_p;

  logic [data_width_p-1:0] rom [0:els_lp-1];

  integer ret;
  string test_name, test_tr;
  initial
    begin
      ret = $value$plusargs({plusargs_str_p,"=%s"}, test_name);
      test_tr = $sformatf("%s.tr", test_name);

      if (hex_not_bin_p)
        $readmemh(test_tr, rom);
      else
        $readmemb(test_tr, rom);
    end

  assign data_o = rom[addr_i];

endmodule

