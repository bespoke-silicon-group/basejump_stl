
module bsg_mem_1rw_sync #( parameter width_p = -1
                         , parameter els_p = -1
                         , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                         // whether to substitute a 1r1w
                         , parameter substitute_1r1w_p = 1
                         , parameter harden_p = 1
                         , parameter latch_last_read_p = 1
                         )
  ( input                     clk_i
  , input                     reset_i

  , input [width_p-1:0]       data_i
  , input [addr_width_lp-1:0] addr_i
  , input                     v_i
  , input                     w_i

  , output logic [width_p-1:0]  data_o
  );

  wire unused =
    &{clk_i
      ,reset_i
      ,data_i
      ,addr_i
      ,v_i
      ,w_i
      };

endmodule

