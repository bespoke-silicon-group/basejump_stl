// MBT 7/24/2014
//
// bsg_sync_sync
//
// This is just two synchronization flops.
//
// We use the rp placement flop from synopsys.
// Fixme: move this into asic-specific components.
//

`define bsg_sync_sync_unit_hard(width_p)                                \
                                                                        \
module bsg_sync_sync_``width_p``_unit                                   \
  (input                oclk_i                                          \
  ,input  [width_p-1:0] iclk_data_i                                     \
  ,output [width_p-1:0] oclk_data_o // after sync flops                 \
  );                                                                    \
                                                                        \
  genvar i;                                                             \
                                                                        \
  logic [width_p-1:0] bsg_SYNC_2_r;                                     \
                                                                        \
  assign oclk_data_o = bsg_SYNC_2_r;                                    \
                                                                        \
  for (i = 0; i < width_p; i = i + 1)                                   \
    begin : bss_unit                                                    \
      SDFFYQ2D_X2N_A7P5PP96PTS_C16 hard_sync_int                        \
        (.D  (iclk_data_i[i])                                           \
        ,.CK (oclk_i)                                                   \
        ,.SI (1'b0)                                                     \
        ,.SE (1'b0)                                                     \
        ,.Q  (bsg_SYNC_2_r[i])                                          \
        );                                                              \
    end                                                                 \
                                                                        \
endmodule

`bsg_sync_sync_unit_hard(1)
`bsg_sync_sync_unit_hard(2)
`bsg_sync_sync_unit_hard(3)
`bsg_sync_sync_unit_hard(4)
`bsg_sync_sync_unit_hard(5)
`bsg_sync_sync_unit_hard(6)
`bsg_sync_sync_unit_hard(7)
`bsg_sync_sync_unit_hard(8)

// warning: if you make this != 8, you need to modify other
// parts of this code.

`define bss_max_block 8

`define bss_if_clause(num) if ((width_p % `bss_max_block) == num) begin: z\
                            bsg_sync_sync_``num``_unit bss                \
                              (.oclk_i                                    \
                               ,.iclk_data_i(iclk_data_i[width_p-1-:num]) \
                               ,.oclk_data_o(oclk_data_o[width_p-1-:num]) \
                               ); end


module bsg_sync_sync #(parameter width_p = "inv")
   (
      input oclk_i
    , input  [width_p-1:0] iclk_data_i
    , output [width_p-1:0] oclk_data_o // after sync flops
    );

   genvar   i;

   for (i = 0; i < (width_p/`bss_max_block); i = i + 1)
     begin : maxb
        bsg_sync_sync_8_unit bss8
            (.oclk_i
             ,.iclk_data_i(iclk_data_i[i*`bss_max_block+:`bss_max_block])
             ,.oclk_data_o(oclk_data_o[i*`bss_max_block+:`bss_max_block])
             );
     end

   `bss_if_clause(1) else
     `bss_if_clause(2) else
       `bss_if_clause(3) else
         `bss_if_clause(4) else
           `bss_if_clause(5) else
             `bss_if_clause(6) else
               `bss_if_clause(7)

endmodule
