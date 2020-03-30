module test_master 
  import bsg_cache_pkg::*;
  #(parameter id_p="inv"
    , parameter addr_width_p="inv"
    , parameter data_width_p="inv"
  
    , parameter bsg_cache_pkt_width_lp=`bsg_cache_pkt_width(addr_width_p,data_width_p)
  )
  (
    input clk_i
    , input reset_i
    
    , output logic v_o
    , output logic [bsg_cache_pkt_width_lp-1:0] cache_pkt_o
    , input yumi_i

    , input v_i
    , input [data_width_p-1:0] data_i
    , output logic yumi_o

    , output logic done_o
    , output time first_access_time_o
    , output integer load_count_o
    , output integer store_count_o
  );

  localparam rom_addr_width_lp = 20;
  logic tr_done_lo;
  logic [rom_addr_width_lp-1:0] rom_addr;
  logic [4+bsg_cache_pkt_width_lp-1:0] rom_data;

  `declare_bsg_cache_pkt_s(addr_width_p,data_width_p);
  bsg_cache_pkt_s cache_pkt;
  assign cache_pkt_o = cache_pkt;

  bsg_trace_replay #(
    .payload_width_p(bsg_cache_pkt_width_lp)
    ,.rom_addr_width_p(rom_addr_width_lp)
    ,.debug_p(2)
  ) tr0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.en_i(1'b1)

    ,.v_i(1'b0)
    ,.data_i('0)
    ,.ready_o()

    ,.v_o(v_o)
    ,.data_o(cache_pkt)
    ,.yumi_i(yumi_i) 

    ,.rom_addr_o(rom_addr)
    ,.rom_data_i(rom_data)

    ,.done_o(tr_done_lo)
    ,.error_o()
  );

  localparam filename_lp = 
    (id_p == 0) ? "trace_0.tr" : 
    (id_p == 1) ? "trace_1.tr" : 
    (id_p == 2) ? "trace_2.tr" : 
    (id_p == 3) ? "trace_3.tr" : 
    (id_p == 4) ? "trace_4.tr" : 
    (id_p == 5) ? "trace_5.tr" : 
    (id_p == 6) ? "trace_6.tr" : 
    (id_p == 7) ? "trace_7.tr" : 
    (id_p == 8) ? "trace_8.tr" : 
    (id_p == 9) ? "trace_9.tr" : 
    (id_p == 10) ? "trace_10.tr" : 
    (id_p == 11) ? "trace_11.tr" : 
    (id_p == 12) ? "trace_12.tr" : 
    (id_p == 13) ? "trace_13.tr" : 
    (id_p == 14) ? "trace_14.tr" : 
    (id_p == 15) ? "trace_15.tr" : "invalid";
    
  bsg_nonsynth_test_rom #(
    .filename_p(filename_lp)
    ,.data_width_p(4+bsg_cache_pkt_width_lp)
    ,.addr_width_p(rom_addr_width_lp)
  ) rom0 (
    .addr_i(rom_addr)
    ,.data_o(rom_data)
  );

  assign yumi_o = v_i; // accept right away

  integer sent_r;
  integer recv_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      sent_r <= '0;
      recv_r <= '0;
    end
    else begin
      if (v_o & yumi_i) begin
        sent_r <= sent_r + 1;
      end

      if (v_i & yumi_o) begin
        recv_r <= recv_r + 1;
      end
    end
  end

  assign done_o = tr_done_lo & (sent_r == recv_r);

  //// profile
  logic first_access_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      first_access_time_o <= '0;
      first_access_r <= 1'b0;
      load_count_o <= '0;
      store_count_o <= '0;
    end 
    else begin
      if (v_o & yumi_i) begin
        if (cache_pkt.opcode == LW) begin
          load_count_o <= load_count_o + 1;
          if (~first_access_r) begin
            first_access_r <= 1'b1;
            first_access_time_o <= $time();
          end
        end
        else if (cache_pkt.opcode == SW) begin
          store_count_o <= store_count_o + 1;
          if (~first_access_r) begin
            first_access_r <= 1'b1;
            first_access_time_o <= $time();
          end
        end
      end
    end
  end
  //////////


endmodule
