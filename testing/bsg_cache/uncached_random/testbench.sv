// Random cached and uncached requests through bsg_cache and
// bsg_cache_dma_to_wormhole, checked against a reference model.
//
// The adapter's link is split by the coordinate in each packet header: packets
// to dest_wh_cord_i go to a block memory, packets to dest_io_wh_cord_i to an
// IO memory (both bsg_nonsynth_wormhole_test_mem). Fills, evictions and
// flushes therefore run between and around the uncached requests.
//
// The reference model is a byte array for cached requests and a word array
// for uncached ones. Every response is compared with it, and at the end every
// word is read back: uncached words directly, cached words after their line
// has been flushed and invalidated, so that they come from the block memory.
// The request link is checked packet by packet as well: destination, the
// uncached_op flag, opcode and length of each header, and for uncached
// packets the order, address and data against the requests issued.
//
// The run is a series of phases with different shares of uncached requests,
// flushes and TAGST, and different stalls on the two link directions and on
// the cache output. See README.md.

`include "bsg_defines.sv"
`include "bsg_cache.svh"
`include "bsg_noc_links.svh"

// Each parameter takes its default from the macro of the same name in upper
// case, so that the Makefile can set it with +define+.
`ifndef WORD_TRACKING_P
  `define WORD_TRACKING_P 1
`endif
`ifndef DMA_RATIO_P
  `define DMA_RATIO_P 1
`endif
`ifndef BUFFER_RETURN_P
  `define BUFFER_RETURN_P 1
`endif
`ifndef ZERO_LATENCY_P
  `define ZERO_LATENCY_P 0
`endif
`ifndef SETS_P
  `define SETS_P 4
`endif
`ifndef WAYS_P
  `define WAYS_P 2
`endif
`ifndef BLOCK_SIZE_IN_WORDS_P
  `define BLOCK_SIZE_IN_WORDS_P 8
`endif
`ifndef SEED_P
  `define SEED_P 1
`endif
`ifndef OPS_P
  `define OPS_P 20000
`endif

module testbench;
  import bsg_cache_pkg::*;

  parameter word_tracking_p = `WORD_TRACKING_P;
  parameter dma_ratio_p = `DMA_RATIO_P;           // DMA data width in words
  parameter buffer_return_p = `BUFFER_RETURN_P;   // the adapter buffers returning flits
  parameter zero_latency_p = `ZERO_LATENCY_P;     // the IO memory answers a read in the cycle of its address flit
  parameter sets_p = `SETS_P;
  parameter ways_p = `WAYS_P;
  parameter block_size_in_words_p = `BLOCK_SIZE_IN_WORDS_P;
  parameter seed_p = `SEED_P;
  parameter ops_p = `OPS_P;                       // requests per phase

  localparam addr_width_lp = 16;
  localparam data_width_lp = 32;
  localparam dma_data_width_lp = data_width_lp*dma_ratio_p;
  localparam burst_len_lp = block_size_in_words_p/dma_ratio_p;
  localparam block_offset_lp = $clog2(block_size_in_words_p)+2;
  localparam way_offset_lp = block_offset_lp + ((sets_p > 1) ? $clog2(sets_p) : 0);
  localparam wh_cord_width_lp = 7;
  localparam wh_len_width_lp = 6;
  localparam wh_cid_width_lp = 1;
  localparam [wh_cord_width_lp-1:0] mem_cord_lp = 7'd1;
  localparam [wh_cord_width_lp-1:0] io_cord_lp = 7'd2;

  // Cached requests use four times as many words as the cache holds, so that
  // lines are evicted all the time. With more than one set, they stay out of
  // the last set: no line of it is ever valid, so a TAGST that writes an
  // invalid tag there can come at any point without changing what the model
  // expects.
  localparam range_words_lp = 4*sets_p*ways_p*block_size_in_words_p;
  localparam io_words_lp = 64;
  localparam num_phases_lp = 5;

  bit clk = 0;
  always #5 clk = ~clk;
  bit reset = 1;

  // ------------------------------------------------------------------------
  // random numbers: one stream for the requests, one for the stalls, so that
  // the requests of a seed do not depend on the stalls
  int unsigned stim_state, stall_state;

  function automatic int unsigned xorshift(input int unsigned s);
    s ^= s << 13;
    s ^= s >> 17;
    s ^= s << 5;
    return s;
  endfunction

  function automatic int unsigned rnd();
    stim_state = xorshift(stim_state);
    return stim_state;
  endfunction

  function automatic int unsigned stall_rnd();
    stall_state = xorshift(stall_state);
    return stall_state;
  endfunction

  // settings of the current phase, in percent
  int unsigned io_pct, flush_pct, tagst_pct, gap_pct;
  int unsigned req_stall_pct, resp_stall_pct, out_stall_pct;
  int unsigned seed, ops;

  // ------------------------------------------------------------------------
  // cache, adapter and the two memories
  `declare_bsg_cache_pkt_s(addr_width_lp, data_width_lp);
  `declare_bsg_cache_dma_pkt_s(addr_width_lp, block_size_in_words_p);
  `declare_bsg_ready_and_link_sif_s(dma_data_width_lp, wh_link_sif_s);
  `declare_bsg_cache_wh_header_flit_s(dma_data_width_lp, wh_cord_width_lp, wh_len_width_lp, wh_cid_width_lp);

  bsg_cache_pkt_s cache_pkt;
  bit v_li;
  logic yumi_lo, v_lo, yumi_li;
  logic [data_width_lp-1:0] data_lo;

  bsg_cache_dma_pkt_s dma_pkt;
  logic dma_pkt_v_lo, dma_pkt_yumi_li;
  logic dma_data_v_lo, dma_data_yumi_li, dma_data_v_li, dma_data_ready_and_lo;
  logic [dma_data_width_lp-1:0] dma_data_lo, dma_data_li;

  wh_link_sif_s wh_lo, wh_li;   // the adapter's link: its outputs and its inputs
  wh_link_sif_s mem_li, mem_lo, io_li, io_lo;

  bsg_cache #(
    .addr_width_p(addr_width_lp)
    ,.data_width_p(data_width_lp)
    ,.dma_data_width_p(dma_data_width_lp)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
    ,.word_tracking_p(word_tracking_p)
  ) cache (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.cache_pkt_i(cache_pkt)
    ,.v_i(v_li)
    ,.yumi_o(yumi_lo)
    ,.data_o(data_lo)
    ,.v_o(v_lo)
    ,.yumi_i(yumi_li)
    ,.dma_pkt_o(dma_pkt)
    ,.dma_pkt_v_o(dma_pkt_v_lo)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_li)
    ,.dma_data_i(dma_data_li)
    ,.dma_data_v_i(dma_data_v_li)
    ,.dma_data_ready_and_o(dma_data_ready_and_lo)
    ,.dma_data_o(dma_data_lo)
    ,.dma_data_v_o(dma_data_v_lo)
    ,.dma_data_yumi_i(dma_data_yumi_li)
    ,.v_we_o()
  );

  bsg_cache_dma_to_wormhole #(
    .dma_addr_width_p(addr_width_lp)
    ,.dma_burst_len_p(burst_len_lp)
    ,.dma_mask_width_p(block_size_in_words_p)
    ,.wh_flit_width_p(dma_data_width_lp)
    ,.wh_cid_width_p(wh_cid_width_lp)
    ,.wh_len_width_p(wh_len_width_lp)
    ,.wh_cord_width_p(wh_cord_width_lp)
    ,.buffer_return_p(buffer_return_p)
  ) dma_to_wh (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.dma_pkt_i(dma_pkt)
    ,.dma_pkt_v_i(dma_pkt_v_lo)
    ,.dma_pkt_yumi_o(dma_pkt_yumi_li)
    ,.dma_data_o(dma_data_li)
    ,.dma_data_v_o(dma_data_v_li)
    ,.dma_data_ready_and_i(dma_data_ready_and_lo)
    ,.dma_data_i(dma_data_lo)
    ,.dma_data_v_i(dma_data_v_lo)
    ,.dma_data_yumi_o(dma_data_yumi_li)
    ,.wh_link_sif_i(wh_li)
    ,.wh_link_sif_o(wh_lo)
    ,.my_wh_cord_i('0)
    ,.dest_wh_cord_i(mem_cord_lp)
    ,.dest_io_wh_cord_i(io_cord_lp)
    ,.my_wh_cid_i('0)
    ,.dest_wh_cid_i('0)
  );

  bsg_nonsynth_wormhole_test_mem #(
    .vcache_data_width_p(data_width_lp)
    ,.vcache_block_size_in_words_p(block_size_in_words_p)
    ,.vcache_dma_data_width_p(dma_data_width_lp)
    ,.num_vcaches_p(2)
    ,.wh_cid_width_p(wh_cid_width_lp)
    ,.wh_flit_width_p(dma_data_width_lp)
    ,.wh_cord_width_p(wh_cord_width_lp)
    ,.wh_len_width_p(wh_len_width_lp)
    ,.wh_ruche_factor_p(1)
    ,.no_concentration_p(1)
    ,.no_coordination_p(1)
    ,.is_io_mem_p(0)
    ,.mem_size_p(2**20)
  ) block_mem (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.wh_link_sif_i(mem_li)
    ,.wh_link_sif_o(mem_lo)
  );

  bsg_nonsynth_wormhole_test_mem #(
    .vcache_data_width_p(data_width_lp)
    ,.vcache_block_size_in_words_p(block_size_in_words_p)
    ,.vcache_dma_data_width_p(dma_data_width_lp)
    ,.num_vcaches_p(2)
    ,.wh_cid_width_p(wh_cid_width_lp)
    ,.wh_flit_width_p(dma_data_width_lp)
    ,.wh_cord_width_p(wh_cord_width_lp)
    ,.wh_len_width_p(wh_len_width_lp)
    ,.wh_ruche_factor_p(1)
    ,.no_concentration_p(1)
    ,.no_coordination_p(1)
    ,.is_io_mem_p(1)
    ,.zero_latency_p(zero_latency_p)
    ,.mem_size_p(2**20)
  ) io_mem (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.wh_link_sif_i(io_li)
    ,.wh_link_sif_o(io_lo)
  );

  // ------------------------------------------------------------------------
  // the link, with random stalls
  bit req_stall_r, resp_stall_r, out_stall_r;

  always @ (negedge clk) begin
    req_stall_r  <= (stall_rnd() % 100) < req_stall_pct;
    resp_stall_r <= (stall_rnd() % 100) < resp_stall_pct;
    out_stall_r  <= (stall_rnd() % 100) < out_stall_pct;
  end

  // requests: each packet goes to the memory that its header names
  bsg_cache_wh_header_flit_s req_hdr;
  assign req_hdr = wh_lo.data;

  bit in_pkt_r, to_io_r;
  int unsigned flits_left_r, pkt_len_r;

  wire to_io = in_pkt_r ? to_io_r : (req_hdr.cord == io_cord_lp);
  wire req_ready = (to_io ? io_lo.ready_and_rev : mem_lo.ready_and_rev) & ~req_stall_r;
  wire req_sent = wh_lo.v & req_ready;

  assign mem_li.data = wh_lo.data;
  assign mem_li.v = wh_lo.v & ~to_io & ~req_stall_r;
  assign io_li.data = wh_lo.data;
  assign io_li.v = wh_lo.v & to_io & ~req_stall_r;
  assign wh_li.ready_and_rev = req_ready;

  // responses: one request is outstanding at a time, so at most one memory
  // answers
  assign wh_li.v = (mem_lo.v | io_lo.v) & ~resp_stall_r;
  assign wh_li.data = io_lo.v ? io_lo.data : mem_lo.data;
  assign mem_li.ready_and_rev = wh_lo.ready_and_rev & ~resp_stall_r;
  assign io_li.ready_and_rev = wh_lo.ready_and_rev & ~resp_stall_r;
  wire resp_sent = wh_li.v & wh_lo.ready_and_rev;

  assign yumi_li = v_lo & ~out_stall_r;

  // ------------------------------------------------------------------------
  // reference model
  logic [7:0] mem_m [0:(1<<addr_width_lp)-1];
  logic [31:0] io_m [0:(1<<(addr_width_lp-2))-1];

  typedef struct packed {
    bsg_cache_opcode_e op;
    logic [addr_width_lp-1:0] addr;
    logic [31:0] data;
    logic [3:0] mask;
    logic [31:0] expected;
  } req_s;

  function automatic logic [31:0] m_word(input logic [addr_width_lp-1:0] a);
    logic [addr_width_lp-1:0] wa;
    wa = {a[addr_width_lp-1:2], 2'b00};
    return {mem_m[wa+3], mem_m[wa+2], mem_m[wa+1], mem_m[wa]};
  endfunction

  function automatic void m_store(input logic [addr_width_lp-1:0] a, input logic [31:0] d, input logic [3:0] m);
    logic [addr_width_lp-1:0] wa;
    wa = {a[addr_width_lp-1:2], 2'b00};
    for (int b = 0; b < 4; b++)
      if (m[b]) mem_m[wa+b] = d[8*b+:8];
  endfunction

  // the expected response; the model is updated as a side effect
  function automatic logic [31:0] model(input bsg_cache_opcode_e op, input logic [addr_width_lp-1:0] a,
                                        input logic [31:0] d, input logic [3:0] m);
    logic [31:0] w, r;
    logic [15:0] h;
    logic [7:0] b;
    w = m_word(a);
    h = a[1] ? w[31:16] : w[15:0];
    b = w[8*a[1:0]+:8];
    r = '0;
    case (op)
      LW, LWU: r = w;
      LH: r = {{16{h[15]}}, h};
      LHU: r = {16'b0, h};
      LB: r = {{24{b[7]}}, b};
      LBU: r = {24'b0, b};
      LM: r = w & {{8{m[3]}}, {8{m[2]}}, {8{m[1]}}, {8{m[0]}}};
      SW: m_store(a, d, 4'b1111);
      SH: m_store(a, {2{d[15:0]}}, a[1] ? 4'b1100 : 4'b0011);
      SB: m_store(a, {4{d[7:0]}}, 4'b0001 << a[1:0]);
      SM: m_store(a, d, m);
      AMOSWAP_W: begin r = w; m_store(a, d, 4'b1111); end
      AMOOR_W: begin r = w; m_store(a, w | d, 4'b1111); end
      UNCACHED_LW: r = io_m[a[addr_width_lp-1:2]];
      UNCACHED_SW: io_m[a[addr_width_lp-1:2]] = d;
      default: r = '0;   // TAGST, TAGFL, AFL, AFLINV
    endcase
    return r;
  endfunction

  // ------------------------------------------------------------------------
  // sending a request, and checking responses and packets
  req_s pending;          // the request at the cache input
  req_s response_q [$];   // accepted, response not seen yet
  req_s io_q [$];         // accepted uncached requests, packet not seen yet
  req_s io_req;           // the uncached request of the packet on the link
  int unsigned accepted_r, sent_r, received_r, idle_r;
  int unsigned io_issued_r, io_packets_r, io_reads_r, io_writes_r, mem_packets_r;
  longint unsigned cycle_r;

  task automatic send(input bsg_cache_opcode_e op, input logic [addr_width_lp-1:0] a,
                      input logic [31:0] d, input logic [3:0] m);
    int unsigned start;
    pending.op = op;
    pending.addr = a;
    pending.data = d;
    pending.mask = m;
    pending.expected = model(op, a, d, m);
    cache_pkt = '0;
    cache_pkt.opcode = op;
    cache_pkt.addr = a;
    cache_pkt.data = d;
    cache_pkt.mask = m;
    v_li = 1;
    start = accepted_r;
    @ (negedge clk);
    while (accepted_r == start) @ (negedge clk);
    v_li = 0;
    if ((rnd() % 100) < gap_pct) repeat (1 + (rnd() % 4)) @ (negedge clk);
  endtask

  task automatic fail(input string what);
    $display("[BSG_ERROR] %s (cycle %0d, seed %0d)", what, cycle_r, seed);
    $fatal(1, "uncached_random test failed");
  endtask

  always @ (posedge clk) begin
    if (reset) begin
      in_pkt_r <= 0;
      to_io_r <= 0;
      flits_left_r <= 0;
      pkt_len_r <= 0;
      accepted_r <= 0;
      sent_r <= 0;
      received_r <= 0;
      idle_r <= 0;
      cycle_r <= 0;
      io_issued_r <= 0;
      io_packets_r <= 0;
      io_reads_r <= 0;
      io_writes_r <= 0;
      mem_packets_r <= 0;
    end
    else begin
      cycle_r <= cycle_r + 1;

      // something must move within 200000 cycles
      idle_r <= ((v_li & yumi_lo) | (v_lo & yumi_li) | req_sent | resp_sent) ? 0 : idle_r + 1;
      if (idle_r > 200000)
        fail($sformatf("no progress: %0d requests sent, %0d responses, waiting on %s",
                       sent_r, received_r, pending.op.name()));

      // a request is accepted
      if (v_li & yumi_lo) begin
        accepted_r <= accepted_r + 1;
        sent_r <= sent_r + 1;
        response_q.push_back(pending);
        if (pending.op == UNCACHED_LW || pending.op == UNCACHED_SW) begin
          io_q.push_back(pending);
          io_issued_r <= io_issued_r + 1;
        end
      end

      // a response is taken
      if (v_lo & yumi_li) begin
        req_s e;
        if (response_q.size() == 0)
          fail($sformatf("response %0d (%h) with no request outstanding", received_r, data_lo));
        e = response_q.pop_front();
        if (data_lo !== e.expected)
          fail($sformatf("response %0d: %s addr=%h data=%h mask=%b: expected %h, got %h",
                         received_r, e.op.name(), e.addr, e.data, e.mask, e.expected, data_lo));
        received_r <= received_r + 1;
      end

      if (mem_lo.v & io_lo.v)
        fail("the block memory and the IO memory both answer");

      // a flit leaves the adapter
      if (req_sent) begin
        if (!in_pkt_r) begin
          // header
          to_io_r <= to_io;
          flits_left_r <= req_hdr.len;
          pkt_len_r <= req_hdr.len;
          in_pkt_r <= (req_hdr.len != 0);
          if (to_io) begin
            io_packets_r <= io_packets_r + 1;
            if (!req_hdr.uncached_op)
              fail("packet to the IO coordinate without uncached_op");
            if (!((req_hdr.opcode == e_cache_wh_read && req_hdr.len == 1)
                  || (req_hdr.opcode == e_cache_wh_write_non_masked && req_hdr.len == 2)))
              fail($sformatf("uncached packet with opcode %b and length %0d", req_hdr.opcode, req_hdr.len));
            if (io_q.size() == 0)
              fail("uncached packet with no uncached request outstanding");
            io_req = io_q.pop_front();
            if ((io_req.op == UNCACHED_SW) != (req_hdr.opcode == e_cache_wh_write_non_masked))
              fail($sformatf("uncached packet out of order: oldest request is %s addr=%h",
                             io_req.op.name(), io_req.addr));
            if (req_hdr.opcode == e_cache_wh_read) io_reads_r <= io_reads_r + 1;
            else io_writes_r <= io_writes_r + 1;
          end
          else begin
            mem_packets_r <= mem_packets_r + 1;
            if (req_hdr.cord != mem_cord_lp)
              fail($sformatf("packet to coordinate %0d", req_hdr.cord));
            if (req_hdr.uncached_op)
              fail("packet to the block memory with uncached_op set");
            if (!((req_hdr.opcode == e_cache_wh_read && req_hdr.len == 1)
                  || (req_hdr.opcode == e_cache_wh_write_non_masked && req_hdr.len == 1 + burst_len_lp)
                  || (req_hdr.opcode == e_cache_wh_write_masked && req_hdr.len == 2 + burst_len_lp)))
              fail($sformatf("block packet with opcode %b and length %0d", req_hdr.opcode, req_hdr.len));
          end
        end
        else begin
          flits_left_r <= flits_left_r - 1;
          if (flits_left_r == 1) in_pkt_r <= 0;
          if (to_io_r) begin
            if (flits_left_r == pkt_len_r) begin
              // address flit: the address of the word
              if (wh_lo.data !== dma_data_width_lp'({io_req.addr[addr_width_lp-1:2], 2'b00}))
                fail($sformatf("uncached address flit %h for %s addr=%h", wh_lo.data, io_req.op.name(), io_req.addr));
            end
            else begin
              // data flit: the word in the low bits
              if (wh_lo.data !== dma_data_width_lp'(io_req.data))
                fail($sformatf("uncached data flit %h for UNCACHED_SW addr=%h data=%h", wh_lo.data, io_req.addr, io_req.data));
            end
          end
        end
      end
    end
  end

  // ------------------------------------------------------------------------
  // requests
  function automatic logic [addr_width_lp-1:0] cached_addr();
    int unsigned w;
    w = rnd() % range_words_lp;
    if (sets_p > 1)
      while (((w / block_size_in_words_p) % sets_p) == sets_p-1) w = rnd() % range_words_lp;
    return addr_width_lp'((w << 2) | (rnd() & 3));
  endfunction

  function automatic logic [addr_width_lp-1:0] way_addr(input int unsigned way, input int unsigned index);
    return addr_width_lp'((way << way_offset_lp) | (index << block_offset_lp));
  endfunction

  task automatic random_request();
    int unsigned r;
    logic [addr_width_lp-1:0] a;
    logic [31:0] d;
    logic [3:0] m;
    r = rnd() % 100;
    a = cached_addr();
    d = rnd();
    m = rnd() & 4'hf;
    if (r < io_pct) begin
      // one address in eight is not word aligned
      a = addr_width_lp'(((rnd() % io_words_lp) << 2) | (((rnd() % 8) == 0) ? (rnd() & 3) : 0));
      if (rnd() & 1) send(UNCACHED_SW, a, d, m);
      else send(UNCACHED_LW, a, d, m);
    end
    else if ((r < io_pct + tagst_pct) && (sets_p > 1)) begin
      send(TAGST, way_addr(rnd() % ways_p, sets_p-1), 32'h0, m);
    end
    else if (r < io_pct + tagst_pct + flush_pct) begin
      case (rnd() % 3)
        0: send(AFL, a, d, m);
        1: send(AFLINV, a, d, m);
        default: send(TAGFL, way_addr(rnd() % ways_p, rnd() % sets_p), d, m);
      endcase
    end
    else begin
      case (rnd() % 16)
        0, 1, 2: send(LW, a, d, m);
        3: send(LH, a, d, m);
        4: send(LHU, a, d, m);
        5: send(LB, a, d, m);
        6: send(LBU, a, d, m);
        7: send(LM, a, d, m);
        8, 9, 10: send(SW, a, d, m);
        11: send(SH, a, d, m);
        12: send(SB, a, d, m);
        13: send(SM, a, d, m);
        14: send(AMOSWAP_W, {a[addr_width_lp-1:2], 2'b00}, d, m);
        default: send(AMOOR_W, {a[addr_width_lp-1:2], 2'b00}, d, m);
      endcase
    end
  endtask

  task automatic set_phase(input int unsigned p);
    case (p)
      // no stalls
      0: begin io_pct = 30; flush_pct = 5;  tagst_pct = 0; req_stall_pct = 0;  resp_stall_pct = 0;  out_stall_pct = 0;  gap_pct = 20; end
      // every direction stalls; TAGST behind the other requests
      1: begin io_pct = 30; flush_pct = 5;  tagst_pct = 8; req_stall_pct = 30; resp_stall_pct = 30; out_stall_pct = 30; gap_pct = 20; end
      // mostly uncached requests, back to back, into a slow link
      2: begin io_pct = 60; flush_pct = 5;  tagst_pct = 0; req_stall_pct = 60; resp_stall_pct = 10; out_stall_pct = 50; gap_pct = 0;  end
      // mostly cached requests with many flushes, and slow answers
      3: begin io_pct = 10; flush_pct = 15; tagst_pct = 8; req_stall_pct = 20; resp_stall_pct = 50; out_stall_pct = 20; gap_pct = 20; end
      // responses are rarely taken
      default: begin io_pct = 30; flush_pct = 5; tagst_pct = 0; req_stall_pct = 0; resp_stall_pct = 0; out_stall_pct = 80; gap_pct = 0; end
    endcase
  endtask

  task automatic drain();
    while (sent_r != received_r || !cache.sbuf_empty_lo || !cache.tbuf_empty_lo) @ (negedge clk);
    repeat (4) @ (negedge clk);
  endtask

  initial begin
    if (!$value$plusargs("seed=%d", seed)) seed = seed_p;
    if (!$value$plusargs("ops=%d", ops)) ops = ops_p;
    stim_state = seed*32'd2654435761 + 32'd12345;
    if (stim_state == 0) stim_state = 1;
    stall_state = seed*32'd40503 + 32'd977;
    if (stall_state == 0) stall_state = 7;
    // memory that was never written reads as zero from both test memories
    for (int i = 0; i < (1<<addr_width_lp); i++) mem_m[i] = 8'h00;
    for (int i = 0; i < (1<<(addr_width_lp-2)); i++) io_m[i] = 32'h0;

    cache_pkt = '0;
    v_li = 0;
    set_phase(0);
    repeat (4) @ (negedge clk);
    reset = 0;
    repeat (2) @ (negedge clk);

    // invalidate every line
    for (int way = 0; way < ways_p; way++)
      for (int index = 0; index < sets_p; index++)
        send(TAGST, way_addr(way, index), 32'h0, 4'h0);

    for (int unsigned p = 0; p < num_phases_lp; p++) begin
      set_phase(p);
      for (int unsigned i = 0; i < ops; i++) random_request();
    end
    set_phase(0);
    drain();

    // read everything back
    for (int unsigned i = 0; i < io_words_lp; i++)
      send(UNCACHED_LW, addr_width_lp'(i << 2), 32'h0, 4'h0);
    for (int unsigned i = 0; i < range_words_lp; i++) begin
      if (sets_p > 1 && ((i / block_size_in_words_p) % sets_p) == sets_p-1) continue;
      if ((i % block_size_in_words_p) == 0) send(AFLINV, addr_width_lp'(i << 2), 32'h0, 4'h0);
      send(LW, addr_width_lp'(i << 2), 32'h0, 4'h0);
    end
    drain();
    repeat (20) @ (negedge clk);

    if (io_q.size() != 0 || io_packets_r != io_issued_r || in_pkt_r)
      fail($sformatf("%0d uncached requests, %0d uncached packets, %0d not seen", io_issued_r, io_packets_r, io_q.size()));

    $display("[BSG_FINISH] uncached_random passed: seed=%0d requests=%0d uncached=%0d (%0d reads, %0d writes) block packets=%0d cycles=%0d",
             seed, sent_r, io_issued_r, io_reads_r, io_writes_r, mem_packets_r, cycle_r);
    $display("  word_tracking=%0d dma_ratio=%0d buffer_return=%0d zero_latency=%0d sets=%0d ways=%0d block=%0d",
             word_tracking_p, dma_ratio_p, buffer_return_p, zero_latency_p, sets_p, ways_p, block_size_in_words_p);
    $finish;
  end

endmodule
