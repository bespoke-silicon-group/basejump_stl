module data_rom #( parameter word_width_p="inv"
                  ,parameter word_count_p="inv"
                  ,parameter filename_p="inv")
(
  input [`BSG_SAFE_CLOG2(word_count_p)-1:0] addr_i
  ,output logic [word_width_p-1:0] data_o
);
  
  logic [word_width_p-1:0] rom_data [word_count_p-1:0];
  
  initial begin
    $readmemb(filename_p, rom_data);
  end

  assign data_o = rom_data[addr_i];

endmodule
