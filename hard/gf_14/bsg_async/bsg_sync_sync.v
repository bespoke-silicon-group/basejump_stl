
// MBT 7/24/2014
//
// bsg_sync_sync
//
// This is just two synchronization flops.
//
// We use the rp placement flop from synopsys.
// Fixme: move this into asic-specific components.
//

`ifndef rp_group
 `define rp_group(x)
 `define rp_place(x)
 `define rp_endgroup(x)
 `define rp_fill(x)
 `define rp_array_dir(up)
`endif

`define bsg_sync_sync_unit(width_p)                             \
                                                                \
module bsg_sync_sync_``width_p``_unit                           \
  (                                                             \
   input oclk_i                                                 \
   , input  [width_p-1:0] iclk_data_i                           \
   , output [width_p-1:0] oclk_data_o // after sync flops       \
   );                                                           \
                                                                \
   `rp_group (bss_bank)                                         \
   `rp_place (hier bss_1 0 0)                                   \
   `rp_endgroup (bss_bank)                                      \
                                                                \
  genvar i;                                                     \
                                                                \
   logic [width_p-1:0] bsg_SYNC_2_r;                            \
                                                                \
   assign oclk_data_o = bsg_SYNC_2_r;                           \
                                                                \
   for (i = 0; i < width_p; i = i + 1)                          \
     begin : bss_unit                                           \
       `rp_group(bss_1)                                         \
       `rp_fill(0 0 UX)                                         \
       `rp_array_dir(up)                                        \
       `rp_endgroup(bss_1)                                      \
       SC7P5T_SYNC2SDFFQX2_SSC14SL hard_sync_int                \
         (.D   (iclk_data_i[i])                                 \
         ,.CLK (oclk_i)                                         \
         ,.SI  (1'b0)                                           \
         ,.SE  (1'b0)                                           \
         ,.Q   (bsg_SYNC_2_r[i])                                \
         );                                                     \
     end                                                        \
                                                                \
endmodule

`bsg_sync_sync_unit(1)
`bsg_sync_sync_unit(2)
`bsg_sync_sync_unit(3)
`bsg_sync_sync_unit(4)
`bsg_sync_sync_unit(5)
`bsg_sync_sync_unit(6)
`bsg_sync_sync_unit(7)
`bsg_sync_sync_unit(8)

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

   // synopsys translate_off
 /*
   initial
     begin
        $display("%m: instantiating bss of size %d",width_p);
     end
  */
   // synopsys translate_on

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
