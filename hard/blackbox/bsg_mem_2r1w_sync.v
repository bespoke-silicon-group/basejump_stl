
module bsg_mem_2r1w_sync #( parameter width_p = -1
                          , parameter els_p = -1
                          , parameter read_write_same_addr_p = 0
                          , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                          , parameter harden_p = 1
                          , parameter substitute_2r1w_p = 0
                          , parameter latch_last_read_p = 1
                          )
  ( input clk_i
  , input reset_i

  , input                     w_v_i
  , input [addr_width_lp-1:0] w_addr_i
  , input [width_p-1:0]       w_data_i

  , input                      r0_v_i
  , input [addr_width_lp-1:0]  r0_addr_i
  , output logic [width_p-1:0] r0_data_o

  , input                      r1_v_i
  , input [addr_width_lp-1:0]  r1_addr_i
  , output logic [width_p-1:0] r1_data_o
  );

  wire unused =
    &{clk_i
      ,reset_i
      ,w_v_i
      ,w_addr_i
      ,w_data_i
      ,r0_v_i
      ,r0_addr_i
      ,r1_v_i
      ,r1_addr_i
      };

endmodule

