
module bsg_mem_1r1w_sync
  #(parameter width_p=-1
    , parameter els_p=-1
    , parameter read_write_same_addr_p=0
    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    , parameter harden_p=1
    , parameter disable_collision_warning_p=0
    , parameter enable_clock_gating_p=0
  )
  (
    input clk_i
    , input reset_i

    , input w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0] w_data_i

    , input r_v_i
    , input [addr_width_lp-1:0] r_addr_i

    , output logic [width_p-1:0] r_data_o
  );

  wire unused =
      &{clk_i
        ,reset_i
        ,w_v_i
        ,w_addr_i
        ,w_data_i
        ,r_v_i
        ,r_addr_i
        };

endmodule

