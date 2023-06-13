/**
 *  bsg_nonsynth_test_rom.sv
 *
 *  async read test_rom that uses readmemb to read its contents.
 *
 */


`include "bsg_defines.sv"

module bsg_nonsynth_test_rom
  #(parameter `BSG_INV_PARAM(filename_p)
    , parameter `BSG_INV_PARAM(data_width_p)
    , parameter `BSG_INV_PARAM(addr_width_p)
    , parameter hex_not_bin_p = 0
  )
  (
    input [addr_width_p-1:0] addr_i
    , output logic [data_width_p-1:0] data_o
  );

  localparam els_lp = 2**addr_width_p;

  logic [data_width_p-1:0] rom [els_lp-1:0];

  initial
    if (hex_not_bin_p)
      $readmemh(filename_p, rom);
    else
      $readmemb(filename_p, rom);

  assign data_o = rom[addr_i];


endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_test_rom)
