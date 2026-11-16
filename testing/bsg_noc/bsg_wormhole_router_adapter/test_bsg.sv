`include "bsg_defines.sv"
`include "bsg_wormhole_router.svh"

// Round-trip complete packets through the two adapters. Exercise payloads
// narrower than, equal to, and wider than a flit, and a partial final flit.
// Every packet uses the maximum legal encoded length for its geometry.
// Continuous input traffic fills the FIFOs when the link/output are stalled.
// Payloads include all ones, all zeros, walking ones, and varying bit patterns.
module test_bsg;
  localparam cases_lp = 5;
  localparam int flit_widths_lp [cases_lp] = '{32, 16, 8, 16, 8};
  localparam int payload_widths_lp [cases_lp] = '{16, 4, 16, 16, 17};

  bit clk;
  bit reset = 1;
  logic [cases_lp-1:0] done;
  bsg_nonsynth_clock_gen #(.cycle_time_p(10)) clock_gen (.o(clk));

  for (genvar i = 0; i < cases_lp; i++) begin: cases
    test_wormhole_loopback
      #(.flit_width_p(flit_widths_lp[i])
        ,.payload_width_p(payload_widths_lp[i])
        ,.stall_interval_p(`STALL_INTERVAL_P)
        ) loopback
      (.clk_i(clk), .reset_i(reset), .done_o(done[i]));
  end

  initial begin
    repeat (4) @(posedge clk);
    #1 reset = 0;
    wait (&done);
    repeat (4) @(posedge clk);
    #1;
    $display("[BSG_FINISH] 160 packets across 5 geometries; stall interval %0d",
             `STALL_INTERVAL_P);
    $finish;
  end

  initial begin
    #200000;
    $fatal(1, "[BSG_ERROR] timeout");
  end
endmodule

module test_wormhole_loopback
  #(parameter flit_width_p = 32
    , parameter payload_width_p = 16
    , parameter stall_interval_p = 1
    )
  (input clk_i, input reset_i, output done_o);

  localparam cord_width_lp = 4;
  localparam len_width_lp = 4;
  localparam packet_width_lp = payload_width_p + len_width_lp + cord_width_lp;
  localparam max_flits_lp = `BSG_CDIV(packet_width_lp, flit_width_p);
  localparam packets_lp = 32;

  int unsigned sent_r, received_r, cycle_r;
  logic [packet_width_lp-1:0] packet_li, packet_lo;
  logic packet_v_li, packet_ready_lo, packet_v_lo, packet_yumi_li;
  logic [flit_width_p-1:0] link_data;
  logic link_v, link_ready, link_enable;

  function automatic logic [packet_width_lp-1:0] packet_for(input int unsigned seq);
    logic [payload_width_p-1:0] payload;
    case (seq % 4)
      0: payload = '1;
      1: payload = '0;
      2: payload = payload_width_p'(1) << ((seq / 4) % payload_width_p);
      3: payload = payload_width_p'(64'hA5C3_BEEF_1234_8765
                                   ^ (64'(seq) * 64'h9E37_79B9_7F4A_7C15));
    endcase
    return {payload, len_width_lp'(max_flits_lp-1), cord_width_lp'(seq)};
  endfunction

  assign packet_li = packet_for(sent_r);
  assign packet_v_li = ~reset_i && (sent_r < packets_lp);
  assign link_enable = (cycle_r % stall_interval_p == 0);
  assign packet_yumi_li = packet_v_lo && (cycle_r % stall_interval_p == 0);
  assign done_o = (received_r == packets_lp);

  bsg_wormhole_router_adapter_in
    #(.max_payload_width_p(payload_width_p)
      ,.len_width_p(len_width_lp)
      ,.cord_width_p(cord_width_lp)
      ,.flit_width_p(flit_width_p)
      ) adapter_in
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.packet_i(packet_li)
     ,.packet_v_i(packet_v_li)
     ,.packet_ready_and_o(packet_ready_lo)
     ,.link_data_o(link_data)
     ,.link_v_o(link_v)
     ,.link_ready_and_i(link_ready & link_enable)
     );

  bsg_wormhole_router_adapter_out
    #(.max_payload_width_p(payload_width_p)
      ,.len_width_p(len_width_lp)
      ,.cord_width_p(cord_width_lp)
      ,.flit_width_p(flit_width_p)
      ) adapter_out
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.link_data_i(link_data)
     ,.link_v_i(link_v & link_enable)
     ,.link_ready_and_o(link_ready)
     ,.packet_o(packet_lo)
     ,.packet_v_o(packet_v_lo)
     ,.packet_yumi_i(packet_yumi_li)
     );

  always @(posedge clk_i) begin
    if (reset_i) begin
      sent_r <= 0;
      received_r <= 0;
      cycle_r <= 0;
    end
    else begin
      cycle_r <= cycle_r + 1;
      if (packet_v_li && packet_ready_lo)
        sent_r <= sent_r + 1;
      if (packet_v_lo) begin
        if (received_r >= packets_lp || packet_lo !== packet_for(received_r))
          $fatal(1, "[BSG_ERROR] payload=%0d flit=%0d packet=%0d expected=%h received=%h",
                 payload_width_p, flit_width_p, received_r, packet_for(received_r), packet_lo);
        if (packet_yumi_li)
          received_r <= received_r + 1;
      end
    end
  end
endmodule
