/**
 *  bsg_nonsynth_test_rom.v
 *
 *  async read test_rom that uses readmemb to read its contents.
 *
 */


module bsg_nonsynth_test_rom
  #(parameter filename_p="inv"
    , parameter data_width_p="inv"
    , parameter addr_width_p="inv"
  )
  (
    input [addr_width_p-1:0] addr_i
    , output logic [data_width_p-1:0] data_o
  );

  localparam els_lp = 2**addr_width_p;

  logic [data_width_p-1:0] rom [els_lp-1:0];

  initial
    $readmemb(filename_p, rom);

  assign data_o = rom[addr_i];


endmodule
