// MBT 7/24/2014
//
// This is a launch/synchronization complex.
// The launch flop prevents combinational glitching.
// The two sync flops reduce probability of metastability.
// See MBT's note on async design and CDC.
//
// The three flops should be don't touched in synopsys
// and abutted in physical design to reduce chances of metastability.
//
// Use of reset is optional; it can be used to hold a known value during reset
// if for instance, the value is coming off chip.
//

// the code is structured this way because synopsys's
// support for hierarchical placement groups appears
// not to work for parameterized modules.
// so we must have a non-parameterized module
// in order to abut the three registers, which
// have two different clocks.
//

`define bsg_launch_sync_sync_unit_hard(EDGE,bits)                       \
                                                                        \
module bsg_launch_sync_sync_``EDGE``_``bits``_unit                      \
  (input             iclk_i                                             \
  ,input             iclk_reset_i                                       \
  ,input             oclk_i                                             \
  ,input  [bits-1:0] iclk_data_i                                        \
  ,output [bits-1:0] iclk_data_o                                        \
  ,output [bits-1:0] oclk_data_o                                        \
  );                                                                    \
                                                                        \
  genvar i;                                                             \
                                                                        \
  logic [bits-1:0] bsg_SYNC_LNCH_r;                                     \
  logic [bits-1:0] bsg_SYNC_2_r;                                        \
                                                                        \
  assign iclk_data_o = bsg_SYNC_LNCH_r;                                 \
  assign oclk_data_o = bsg_SYNC_2_r;                                    \
                                                                        \
  always_ff @(EDGE iclk_i)                                              \
    begin                                                               \
      if (iclk_reset_i)                                                 \
        bsg_SYNC_LNCH_r <= {bits{1'b0}};                                \
      else                                                              \
        bsg_SYNC_LNCH_r <= iclk_data_i;                                 \
    end                                                                 \
                                                                        \
  for (i = 0; i < bits; i = i + 1)                                      \
    begin : blss_unit                                                   \
      SDFFYQ2D_X2N_A7P5PP96PTS_C16 hard_sync_int                        \
        (.D  (bsg_SYNC_LNCH_r[i])                                       \
        ,.CK (oclk_i)                                                   \
        ,.SI (1'b0)                                                     \
        ,.SE (1'b0)                                                     \
        ,.Q  (bsg_SYNC_2_r[i])                                          \
        );                                                              \
    end                                                                 \
                                                                        \
endmodule


// bsg_launch_sync_sync_posedge_1_unit
`bsg_launch_sync_sync_unit_hard(posedge,1)
`bsg_launch_sync_sync_unit_hard(posedge,2)
`bsg_launch_sync_sync_unit_hard(posedge,3)
`bsg_launch_sync_sync_unit_hard(posedge,4)
`bsg_launch_sync_sync_unit_hard(posedge,5)
`bsg_launch_sync_sync_unit_hard(posedge,6)
`bsg_launch_sync_sync_unit_hard(posedge,7)
`bsg_launch_sync_sync_unit_hard(posedge,8)

// bsg_launch_sync_sync_negedge_1_unit
`bsg_launch_sync_sync_unit_hard(negedge,1)
`bsg_launch_sync_sync_unit_hard(negedge,2)
`bsg_launch_sync_sync_unit_hard(negedge,3)
`bsg_launch_sync_sync_unit_hard(negedge,4)
`bsg_launch_sync_sync_unit_hard(negedge,5)
`bsg_launch_sync_sync_unit_hard(negedge,6)
`bsg_launch_sync_sync_unit_hard(negedge,7)
`bsg_launch_sync_sync_unit_hard(negedge,8)

// warning: if you make this != 8, you need
// to modify other parts of this code

`define blss_max_block 8

// handle trailer bits
`define blss_if_clause(EDGE,num) if ((width_p % `blss_max_block) == num) begin: z            \
                                     bsg_launch_sync_sync_``EDGE``_``num``_unit blss \
                                        (.iclk_i                                     \
                                         ,.iclk_reset_i                              \
                                         ,.oclk_i                                    \
                                         ,.iclk_data_i(iclk_data_i[width_p-1-:num])  \
                                         ,.iclk_data_o(iclk_data_o[width_p-1-:num])  \
                                         ,.oclk_data_o(oclk_data_o[width_p-1-:num])  \
                                         ); end

module bsg_launch_sync_sync #(parameter width_p="inv"
                              , parameter use_negedge_for_launch_p = 0)
   (input iclk_i
    , input iclk_reset_i
    , input oclk_i
    , input  [width_p-1:0] iclk_data_i
    , output [width_p-1:0] iclk_data_o // after launch flop
    , output [width_p-1:0] oclk_data_o // after sync flops
    );

   genvar i;

   // synopsys translate_off
   initial assert (iclk_reset_i !== 'z)
     else
       begin
          $error("%m iclk_reset should be connected");
          $finish();
       end
   // synopsys translate_on

   if (use_negedge_for_launch_p)
     begin: n
        for (i = 0; i < (width_p/`blss_max_block); i = i + 1)
          begin : maxb
             bsg_launch_sync_sync_negedge_8_unit blss
                 (.iclk_i
                  ,.iclk_reset_i
                  ,.oclk_i
                  ,.iclk_data_i(iclk_data_i[i*`blss_max_block+:`blss_max_block])
                  ,.iclk_data_o(iclk_data_o[i*`blss_max_block+:`blss_max_block])
                  ,.oclk_data_o(oclk_data_o[i*`blss_max_block+:`blss_max_block])
                  );
          end

        `blss_if_clause(negedge,1) else
          `blss_if_clause(negedge,2) else
            `blss_if_clause(negedge,3) else
              `blss_if_clause(negedge,4) else
                `blss_if_clause(negedge,5) else
                  `blss_if_clause(negedge,6) else
                    `blss_if_clause(negedge,7)
     end
   else
     begin: p
        for (i = 0; i < (width_p/`blss_max_block); i = i + 1)
          begin : maxb
             bsg_launch_sync_sync_posedge_8_unit blss
                 (.iclk_i
                  ,.iclk_reset_i
                  ,.oclk_i
                  ,.iclk_data_i(iclk_data_i[i*`blss_max_block+:`blss_max_block])
                  ,.iclk_data_o(iclk_data_o[i*`blss_max_block+:`blss_max_block])
                  ,.oclk_data_o(oclk_data_o[i*`blss_max_block+:`blss_max_block])
                  );
          end

        `blss_if_clause(posedge,1) else
          `blss_if_clause(posedge,2) else
            `blss_if_clause(posedge,3) else
              `blss_if_clause(posedge,4) else
                `blss_if_clause(posedge,5) else
                  `blss_if_clause(posedge,6) else
                    `blss_if_clause(posedge,7)
     end

endmodule
