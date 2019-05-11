`ifndef BSG_TRACE_ROM_V
`define BSG_TRACE_ROM_V

`define bsg_trace_rom_macro(id) \
  if (id_p == ``id``) begin \
    bsg_trace_rom_``id`` #( \
      .width_p(rom_data_width_p) \
      ,.addr_width_p(rom_addr_width_p) \
    ) trace_rom_``id`` ( \
      .addr_i(rom_addr_i) \
      ,.data_o(rom_data_o)  \
    );  \
  end

`endif

module bsg_trace_rom 
  #(parameter rom_addr_width_p="inv"
    , parameter rom_data_width_p="inv"
    , parameter id_p = "inv"
  )
  (
    input [rom_addr_width_p-1:0] rom_addr_i
    , output logic [rom_data_width_p-1:0] rom_data_o
  );


  `bsg_trace_rom_macro(0)
  else `bsg_trace_rom_macro(1)
  else `bsg_trace_rom_macro(2)
  else `bsg_trace_rom_macro(3)


endmodule
