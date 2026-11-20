`include "bsg_defines.sv"
`include "bsg_cache.svh"
`include "bsg_noc_links.svh"

module testbench;
  import bsg_cache_pkg::*;

  parameter dma_ratio_p=1;
  parameter word_tracking_p=1;
  parameter stall_p=0;
  parameter buffer_return_p=1;
  parameter zero_latency_p=0;
  parameter sets_p=128;
  parameter ways_p=8;
  parameter block_size_in_words_p=8;
  parameter addr_width_p=16;
  localparam dma_data_width_p=32*dma_ratio_p;
  localparam set_offset_lp=$clog2(block_size_in_words_p)+2;
  localparam way_offset_lp=$clog2(sets_p)+set_offset_lp;

  bit clk=0;
  always #5 clk=~clk;
  bit reset=1;
  bit v_li;
  logic yumi_lo, v_lo, yumi_li;
  logic [31:0] cache_data_lo;
  integer cycles_r, sent_r, recv_r, tag_writes_r, io_headers_r;
  integer req_stalls_r, resp_stalls_r, cpu_stalls_r;

  `declare_bsg_cache_pkt_s(addr_width_p,32);
  `declare_bsg_cache_dma_pkt_s(addr_width_p,block_size_in_words_p);
  `declare_bsg_ready_and_link_sif_s(dma_data_width_p, wh_link_sif_s);
  `declare_bsg_cache_wh_header_flit_s(dma_data_width_p,7,4,1);

  bsg_cache_pkt_s cache_pkt;
  bsg_cache_dma_pkt_s dma_pkt;
  logic dma_pkt_v_lo, dma_pkt_yumi_li;
  logic dma_data_v_lo, dma_data_yumi_li, dma_data_v_li, dma_data_ready_and_lo;
  logic [dma_data_width_p-1:0] dma_data_lo, dma_data_li;
  wh_link_sif_s wh_link_sif_lo, wh_link_sif_li, mem_link_sif_lo, mem_link_sif_li;
  bsg_cache_wh_header_flit_s header_flit;
  assign header_flit=wh_link_sif_lo.data;

  wire req_en = !stall_p || (cycles_r % 3 == 0);
  wire resp_en = !stall_p || (cycles_r % 5 == 0);
  assign mem_link_sif_li.data = wh_link_sif_lo.data;
  assign mem_link_sif_li.v = wh_link_sif_lo.v & req_en;
  assign wh_link_sif_li.ready_and_rev = mem_link_sif_lo.ready_and_rev & req_en;
  assign wh_link_sif_li.data = mem_link_sif_lo.data;
  assign wh_link_sif_li.v = mem_link_sif_lo.v & resp_en;
  assign mem_link_sif_li.ready_and_rev = wh_link_sif_lo.ready_and_rev & resp_en;
  assign yumi_li = v_lo & (!stall_p || (cycles_r % 4 == 0));

  bsg_cache #(
    .addr_width_p(addr_width_p), .data_width_p(32), .dma_data_width_p(dma_data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p), .sets_p(sets_p), .ways_p(ways_p), .word_tracking_p(word_tracking_p)
  ) cache (
    .clk_i(clk), .reset_i(reset), .cache_pkt_i(cache_pkt), .v_i(v_li), .yumi_o(yumi_lo)
    ,.data_o(cache_data_lo), .v_o(v_lo), .yumi_i(yumi_li), .v_we_o()
    ,.dma_pkt_o(dma_pkt), .dma_pkt_v_o(dma_pkt_v_lo), .dma_pkt_yumi_i(dma_pkt_yumi_li)
    ,.dma_data_i(dma_data_li), .dma_data_v_i(dma_data_v_li), .dma_data_ready_and_o(dma_data_ready_and_lo)
    ,.dma_data_o(dma_data_lo), .dma_data_v_o(dma_data_v_lo), .dma_data_yumi_i(dma_data_yumi_li)
  );

  bsg_cache_dma_to_wormhole #(
    .dma_addr_width_p(addr_width_p), .dma_burst_len_p(block_size_in_words_p/dma_ratio_p), .dma_mask_width_p(block_size_in_words_p)
    ,.wh_flit_width_p(dma_data_width_p), .wh_cid_width_p(1), .wh_len_width_p(4), .wh_cord_width_p(7)
    ,.buffer_return_p(buffer_return_p)
  ) dma2wh (
    .clk_i(clk), .reset_i(reset), .dma_pkt_i(dma_pkt), .dma_pkt_v_i(dma_pkt_v_lo), .dma_pkt_yumi_o(dma_pkt_yumi_li)
    ,.dma_data_o(dma_data_li), .dma_data_v_o(dma_data_v_li), .dma_data_ready_and_i(dma_data_ready_and_lo)
    ,.dma_data_i(dma_data_lo), .dma_data_v_i(dma_data_v_lo), .dma_data_yumi_o(dma_data_yumi_li)
    ,.wh_link_sif_i(wh_link_sif_li), .wh_link_sif_o(wh_link_sif_lo)
    ,.my_wh_cord_i('0), .dest_wh_cord_i(7'd1), .dest_io_wh_cord_i(7'd2)
    ,.my_wh_cid_i('0), .dest_wh_cid_i('0)
  );

  bsg_nonsynth_wormhole_test_mem #(
    .vcache_data_width_p(32), .vcache_block_size_in_words_p(block_size_in_words_p), .vcache_dma_data_width_p(dma_data_width_p)
    ,.num_vcaches_p(2), .wh_cid_width_p(1), .wh_flit_width_p(dma_data_width_p)
    ,.wh_cord_width_p(7), .wh_len_width_p(4), .wh_ruche_factor_p(1)
    ,.no_concentration_p(1), .no_coordination_p(1), .is_io_mem_p(1), .mem_size_p(2**20)
    ,.zero_latency_p(zero_latency_p)
  ) io_mem (
    .clk_i(clk), .reset_i(reset), .wh_link_sif_i(mem_link_sif_li), .wh_link_sif_o(mem_link_sif_lo)
  );

  integer remaining_r;
  integer issued=0, io_issued=0, io_sent_r, io_checked_r;
  logic [31:0] expected_li, expected_results [32768];
  logic [addr_width_p-1:0] io_addr [32768];
  logic [31:0] io_data [32768];
  logic io_write [32768];
  logic packet_write_r;
  bit io_only_phase=0;
  logic wh_stalled_r, cpu_stalled_r;
  logic [dma_data_width_p-1:0] wh_data_r;
  logic [31:0] cpu_data_r;
  always @(posedge clk) begin
    if (reset) begin
      cycles_r <= 0;
      sent_r <= 0;
      recv_r <= 0;
      tag_writes_r <= 0;
      io_headers_r <= 0;
      remaining_r <= 0;
      req_stalls_r <= 0;
      resp_stalls_r <= 0;
      cpu_stalls_r <= 0;
      io_sent_r <= 0;
      io_checked_r <= 0;
      packet_write_r <= 0;
      wh_stalled_r <= 0;
      cpu_stalled_r <= 0;
    end else begin
      if (wh_stalled_r)
        assert(wh_link_sif_lo.v && wh_link_sif_lo.data === wh_data_r)
          else $fatal(1,"Wormhole output changed under backpressure");
      if (cpu_stalled_r)
        assert(v_lo && cache_data_lo === cpu_data_r)
          else $fatal(1,"Cache response changed under backpressure");
      wh_stalled_r <= wh_link_sif_lo.v && !wh_link_sif_li.ready_and_rev;
      cpu_stalled_r <= v_lo && !yumi_li;
      wh_data_r <= wh_link_sif_lo.data;
      cpu_data_r <= cache_data_lo;
      if (io_only_phase)
        assert(!cache.tag_mem_v_li && !cache.data_mem_v_li && !cache.stat_mem_v_li
          && (!word_tracking_p || !cache.track_mem_v_li))
          else $fatal(1,"Uncached operation accessed cache memories");
      cycles_r <= cycles_r+1;
      if (wh_link_sif_lo.v && !wh_link_sif_li.ready_and_rev) req_stalls_r <= req_stalls_r+1;
      if (mem_link_sif_lo.v && !mem_link_sif_li.ready_and_rev) resp_stalls_r <= resp_stalls_r+1;
      if (v_lo && !yumi_li) cpu_stalls_r <= cpu_stalls_r+1;
      if (yumi_lo) begin
        expected_results[sent_r] <= expected_li;
        sent_r <= sent_r+1;
        if (cache_pkt.opcode == UNCACHED_LW || cache_pkt.opcode == UNCACHED_SW) begin
          io_addr[io_sent_r] <= cache_pkt.addr;
          io_data[io_sent_r] <= cache_pkt.data;
          io_write[io_sent_r] <= cache_pkt.opcode == UNCACHED_SW;
          io_sent_r <= io_sent_r+1;
        end
      end
      if (yumi_li) begin
        assert(cache_data_lo === expected_results[recv_r])
          else $fatal(1,"response=%0d expected=%h actual=%h",recv_r,expected_results[recv_r],cache_data_lo);
        recv_r <= recv_r+1;
      end
      if (cache.tag_mem_v_li & cache.tag_mem_w_li) tag_writes_r <= tag_writes_r+1;
      if (wh_link_sif_lo.v & wh_link_sif_li.ready_and_rev) begin
        if (remaining_r == 0) begin
          assert(io_checked_r < io_sent_r)
            else $fatal(1,"Unexpected IO transaction");
          assert(header_flit.uncached_op && header_flit.cord == 7'd2)
            else $fatal(1, "Incorrect uncached header/destination");
          assert((header_flit.opcode == e_cache_wh_read && header_flit.len == 1)
            || (header_flit.opcode == e_cache_wh_write_non_masked && header_flit.len == 2))
            else $fatal(1, "Incorrect uncached packet length/opcode");
          assert((header_flit.opcode == e_cache_wh_write_non_masked) == io_write[io_checked_r])
            else $fatal(1,"IO operation order mismatch");
          packet_write_r <= io_write[io_checked_r];
          remaining_r <= int'(header_flit.len);
          io_headers_r <= io_headers_r+1;
        end else begin
          if ((!packet_write_r && remaining_r == 1) || (packet_write_r && remaining_r == 2)) begin
            assert(wh_link_sif_lo.data == dma_data_width_p'(io_addr[io_checked_r]))
              else $fatal(1,"IO address mismatch expected=%h actual=%h",io_addr[io_checked_r],wh_link_sif_lo.data);
          end else begin
            assert(wh_link_sif_lo.data == dma_data_width_p'(io_data[io_checked_r]))
              else $fatal(1,"IO store data mismatch");
          end
          if (remaining_r == 1) io_checked_r <= io_checked_r+1;
          remaining_r <= remaining_r-1;
        end
      end
    end
  end

  task automatic send(input bsg_cache_opcode_e op, input logic [addr_width_p-1:0] addr, input logic [31:0] data, expected);
    if (clk) @(negedge clk);
    issued++;
    if (op == UNCACHED_LW || op == UNCACHED_SW) io_issued++;
    cache_pkt='0;
    cache_pkt.opcode=op;
    cache_pkt.addr=addr;
    cache_pkt.data=data;
    expected_li=expected;
    v_li=1;
    do @(posedge clk); while (!yumi_lo);
    @(negedge clk); v_li=0;
  endtask

  integer tag_writes_before;
  initial begin
    cache_pkt='0;
    v_li=0;
    repeat (4) @(negedge clk);
    reset=0;
    for (integer way=0; way<ways_p; way++)
      for (integer index=0; index<sets_p; index++) send(TAGST,16'((way<<way_offset_lp)|(index<<set_offset_lp)),0,0);
    send(TAGST,0,32'h80000000,0);
    send(SW,0,32'hdeadbeef,0);
    wait(sent_r == recv_r && cache.sbuf_empty_lo && cache.tbuf_empty_lo);
    repeat (2) @(negedge clk);
    io_only_phase=1;
    @(negedge clk); tag_writes_before=tag_writes_r;
    send(UNCACHED_LW,{addr_width_p{1'b1}} & ~addr_width_p'(3),0,0);
    for (integer i=0; i<64; i++) send(UNCACHED_SW,16'(i*4),32'h80000000+i,0);
    send(UNCACHED_SW,16'h4004,32'h55667788,0);
    for (integer i=63; i>=0; i--) send(UNCACHED_LW,16'(i*4),0,32'h80000000+i);
    send(UNCACHED_LW,16'h4004,0,32'h55667788);
    send(UNCACHED_SW,16'hfffc,32'hffffffff,0);
    send(UNCACHED_SW,16'h7ffc,32'h76543210,0);
    send(UNCACHED_LW,16'hfffc,0,32'hffffffff);
    send(UNCACHED_LW,16'h7ffc,0,32'h76543210);
    wait(sent_r == recv_r && io_checked_r == io_sent_r);
    @(negedge clk); io_only_phase=0;
    for (integer i=0; i<256; i++) begin
      send(SW,0,32'hdead0000+i,0);
      send(UNCACHED_SW,0,32'h12340000+i,0);
      send(LW,0,0,32'hdead0000+i);
      send(UNCACHED_LW,0,0,32'h12340000+i);
    end
    send(LW,0,0,32'hdead00ff);
    send(TAGLA,0,0,0);
    wait(sent_r == recv_r && io_checked_r == io_sent_r);
    repeat (10) @(negedge clk);
    assert(tag_writes_r == tag_writes_before && io_headers_r == io_issued && io_sent_r == io_issued && sent_r == issued && sent_r == recv_r)
      else $fatal(1, "Uncached operation changed tags or lost a request");
    assert(!stall_p || (req_stalls_r > 0 && resp_stalls_r > 0 && cpu_stalls_r > 0))
      else $fatal(1, "Backpressure was not exercised");
    $display("[BSG_FINISH] Uncached test passed: dma_ratio=%0d tracking=%0d stall=%0d buffer_return=%0d requests=%0d",
      dma_ratio_p,word_tracking_p,stall_p,buffer_return_p,sent_r);
    $finish;
  end
  initial begin #1000000; $fatal(1, "Timeout"); end
endmodule
