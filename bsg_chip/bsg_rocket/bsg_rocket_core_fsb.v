// mbt 2-16-16

`include "bsg_defines.v"

module bsg_rocket_core_fsb
  import bsg_fsb_packet::RingPacketType;
   #(parameter nasti_destid_p="invalid"
     , parameter htif_destid_p ="invalid"
     , parameter htif_width_p = 16
     , parameter ring_width_lp=$size(RingPacketType))

   (input clk_i
    , input reset_i
    , input enable_i

    // 0 = nasti, 1 = htif
    , input  [1:0]                    v_i
    , input  [1:0][ring_width_lp-1:0] data_i
    , output [1:0]                    ready_o

    , output [1:0]                     v_o
    , output [1:0] [ring_width_lp-1:0] data_o
    , input  [1:0]                     yumi_i
    );

   wire w_ready, aw_ready, ar_ready, rd_ready, wr_ready;

   bsg_nasti_write_data_channel_s     w;
   bsg_nasti_addr_channel_s           ar;
   bsg_nasti_addr_channel_s           aw;
   bsg_nasti_read_data_channel_s      rd;
   bsg_nasti_write_response_channel_s wr;

   bsg_fsb_to_nasti_master_connector #(.destid_p(nasti_destid_p)) bsg_fsb_nasti_master
     (.clk_i                        (clk_i   )
      ,.reset_i                     (reset_i )
      ,.nasti_read_addr_ch_i        (ar      )
      ,.nasti_read_addr_ch_ready_o  (ar_ready)
      ,.nasti_write_addr_ch_i       (aw      )
      ,.nasti_write_addr_ch_ready_o (aw_ready)
      ,.nasti_write_data_ch_i       (w       )
      ,.nasti_write_data_ch_ready_o (w_ready )
      ,.nasti_read_data_ch_o        (rd      )
      ,.nasti_read_data_ch_ready_i  (rd_ready)
      ,.nasti_write_resp_ch_o       (wr      )
      ,.nasti_write_resp_ch_ready_i (rd_ready)

      ,.fsb_v_i    (v_i    [0])
      ,.fsb_data_i (data_i [0]) // --> from FSB
      ,.fsb_ready_o(ready_o[0])

      ,.fsb_v_o    (v_o    [0]   )
      ,.fsb_data_o (data_o [0]) // --> to FSB
      ,.fsb_yumi_i (yumi_i [0])
      );

   wire htif_in_valid, htif_out_valid;
   wire htif_in_ready, htif_out_ready;
   wire [htif_width_p-1:0] htif_in_data;
   wire [htif_width_p-1:0] htif_out_data;

   bsg_fsb_to_htif_connector #(.destid_p(htif_destid_p)
                               ,.htif_width_p(htif_width_p)
                               )
   (.clk_i   ( clk_i     )
    ,.reset_i( reset_i   )

    // FSB interface
    ,.fsb_v_i    ( v_i    [1] )
    ,.fsb_data_i ( data_i [1] )
    ,.fsb_ready_o( ready_o[1] )

    ,.fsb_v_o    ( v_o    [1] )
    ,.fsb_data_o ( data_o [1] )
    ,.fsb_yumi_i ( yumi_i [1] )

    // htif interface
    ,.htif_v_i     ( htif_in_valid )
    ,.htif_data_i  ( htif_in_data  )
    ,.htif_ready_o ( htif_in_ready )

    ,.htif_v_o     ( htif_out_valid )
    ,.htif_data_o  ( htif_out_data  )
    ,.htif_ready_o ( htif_out_ready )
    );

   top rocket
     (.clk(clk_i)
      ,.reset(reset_i)
      ,.io_mem_0_ar_valid       ( ar.v     )
      ,.io_mem_0_ar_ready       ( ar_ready )
      ,.io_mem_0_ar_bits_addr   ( ar.addr  )
      ,.io_mem_0_ar_bits_id     ( ar.id    )
      ,.io_mem_0_ar_bits_size   ( ar.size  )
      ,.io_mem_0_ar_bits_len    ( ar.len   )
      ,.io_mem_0_ar_bits_burst  ()
      ,.io_mem_0_ar_bits_lock   ()
      ,.io_mem_0_ar_bits_cache  ()
      ,.io_mem_0_ar_bits_prot   ()
      ,.io_mem_0_ar_bits_qos    ()
      ,.io_mem_0_ar_bits_region ()
      ,.io_mem_0_ar_bits_user   ()

      ,.io_mem_0_aw_valid      ( aw.v     )
      ,.io_mem_0_aw_ready      ( aw_ready )
      ,.io_mem_0_aw_bits_addr  ( aw.addr  )
      ,.io_mem_0_aw_bits_id    ( aw.id    )
      ,.io_mem_0_aw_bits_size  ( aw.size  )
      ,.io_mem_0_aw_bits_len   ( aw.len   )
      ,.io_mem_0_aw_bits_burst ()
      ,.io_mem_0_aw_bits_lock  ()
      ,.io_mem_0_aw_bits_cache ()
      ,.io_mem_0_aw_bits_prot  ()
      ,.io_mem_0_aw_bits_qos   ()
      ,.io_mem_0_aw_bits_region()
      ,.io_mem_0_aw_bits_user  ()

      ,.io_mem_0_w_valid     ( w.v     )
      ,.io_mem_0_w_ready     ( w_ready )
      ,.io_mem_0_w_bits_strb ( w.strb  )
      ,.io_mem_0_w_bits_data ( w.data  )
      ,.io_mem_0_w_bits_last ( w.last  )
      ,.io_mem_0_w_bits_user ()

      ,.io_mem_0_r_valid     ( r.v     )
      ,.io_mem_0_r_ready     ( r_ready )
      ,.io_mem_0_r_bits_resp ( r.resp  )
      ,.io_mem_0_r_bits_id   ( r.id    )
      ,.io_mem_0_r_bits_data ( r.data  )
      ,.io_mem_0_r_bits_last ( r.last  )
      ,.io_mem_0_r_bits_user ( 1'b0    )

      ,.io_mem_0_b_valid     ( wr.v     )
      ,.io_mem_0_b_ready     ( wr_ready )
      ,.io_mem_0_b_bits_resp ( wr.resp  )
      ,.io_mem_0_b_bits_id   ( wr.id    )
      ,.io_mem_0_b_bits_user ( 1'b0    )

      // we follow the "FPGA plan", because Berkeley "chip plan" currently broken
      ,.io_host_clk             ()
      ,.io_host_clk_edge        ()
      ,.io_host_debug_stats_csr ()

      ,.io_mem_backup_ctrl_en         (1'b0)
      ,.io_mem_backup_ctrl_in_valid   (1'b0)
      ,.io_mem_backup_ctrl_out_ready  (1'b0)
      ,.io_mem_backup_ctrl_out_valid  ()
      // end "FPGA plan"

      // this is the hostif; we need to attach it to the FSB as well
      ,.io_host_in_valid  ( htif_in_valid  )
      ,.io_host_in_ready  ( htif_in_ready  )
      ,.io_host_in_bits   ( htif_in_bits   )
      ,.io_host_out_valid ( htif_out_valid )
      ,.io_host_out_ready ( htif_out_ready )
      ,.io_host_out_bits  ( htif_out_bits  )
      );

endmodule
