`include "bsg_defines.sv"

// A 24-bit packet in 8-bit flits has capacity for three flits. Encoding len=3
// requests four flits and must trigger the adapter's own length diagnostic.
// Hold the link stalled so a downstream counter overflow cannot mask the bug.
module test_invalid_len;
  bit clk;
  bit reset = 1;
  logic packet_v = 0;
  bsg_nonsynth_clock_gen #(.cycle_time_p(10)) clock_gen (.o(clk));

  bsg_wormhole_router_adapter_in
    #(.max_payload_width_p(16)
      ,.len_width_p(4)
      ,.cord_width_p(4)
      ,.flit_width_p(8)
      ) dut
    (.clk_i(clk)
     ,.reset_i(reset)
     ,.packet_i({16'hbeef, 4'd3, 4'h1})
     ,.packet_v_i(packet_v)
     ,.packet_ready_and_o()
     ,.link_data_o()
     ,.link_v_o()
     ,.link_ready_and_i(1'b0)
     );

  initial begin
    repeat (4) @(posedge clk);
    #1;
    reset = 0;
    packet_v = 1;
    @(posedge clk);
    #1 packet_v = 0;
    repeat (2) @(posedge clk);
    // VCS may continue after $error; the Makefile checks the diagnostic text.
    $finish;
  end

  initial begin
    #1000;
    $fatal(1, "[BSG_ERROR] timeout");
  end
endmodule
