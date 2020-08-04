
module bsg_mem_1rw_sync_mask_write_byte #( parameter els_p = -1
                                         , parameter data_width_p = -1
                                         , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                                         , parameter write_mask_width_lp = data_width_p>>3
                                         , parameter harden_p = 1
                                         , parameter latch_last_read_p = 1
                                         )

  ( input                           clk_i
  , input                           reset_i
  , input                           v_i
  , input                           w_i
  , input [addr_width_lp-1:0]       addr_i
  , input [data_width_p-1:0]        data_i
  , input [write_mask_width_lp-1:0] write_mask_i
  , output logic [data_width_p-1:0] data_o
  );

  wire unused =
      &{clk_i
        ,reset_i
        ,v_i
        ,w_i
        ,addr_i
        ,data_i
        ,write_mask_i
        };

endmodule

