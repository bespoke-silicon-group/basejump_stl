
`include "bsg_defines.sv"
`include "bsg_tag.svh"

program testbench #(
    parameter `BSG_INV_PARAM(els_p)
  , parameter `BSG_INV_PARAM(width_p)
  , localparam lg_width_lp = `BSG_WIDTH(width_p)
)
(
    input  bit   clk_i
  , output logic reset_o
  , output logic data_o
  , output logic v_o
  , input        ready_and_i
);
  `declare_bsg_tag_header_s(els_p,lg_width_lp)

  localparam max_packet_len_lp = `bsg_tag_max_packet_len(els_p,lg_width_lp);
  localparam actual_packet_len_lp = $bits(bsg_tag_header_s) + width_p;
  task automatic tag_write_bit (
      input next_bit_i
  );
    wait(ready_and_i == 1'b1);

    v_o = 1'b1;
    data_o = next_bit_i;
    @(posedge clk_i)
    v_o = 1'b0;
  endtask

  task automatic tag_write_packet (
      input data_not_reset
    , input [`BSG_SAFE_CLOG2(els_p)-1:0] nodeID
    , input [width_p-1:0] payload
  );
    // Start of packet
    tag_write_bit(1'b1);

    // Payload len
    for(int unsigned i = 0; i < `BSG_WIDTH(width_p);i++)
      tag_write_bit(width_p[i]);

    // data_not_reset
    tag_write_bit(data_not_reset);

    // nodeID
    for(int unsigned i = 0; i < `BSG_SAFE_CLOG2(els_p);i++)
      tag_write_bit(nodeID[i]);

    // Payload
    for(int unsigned i = 0; i < width_p;i++)
      tag_write_bit(payload[i]);

  endtask

  initial begin
    reset_o = 1'b1;
    v_o = 1'b0;
    @(posedge clk_i);
    reset_o = 1'b0;

    // Reset bsg_master:
    // We need this because otherwise zeros_ctr_r in the tag master will never
    //   be zero, though in hardware it should eventually be set to 0.
    tag_write_bit(1'b1);
    while(master.state_r != 2'b00) begin
      tag_write_bit(1'b0);
    end
    $display("master init at time: %t", $time);
    // Reset bsg client0
    tag_write_packet(0, 0, '1);
    // Set value of client0 to 0
    tag_write_packet(1, 0, 'h0);
    // Set value of client0 to 1
    tag_write_packet(1, 0, 'h1);
    // Set value of client0 to 2
    tag_write_packet(1, 0, 'h2);

    // We need at least 4 additional toggles (regardless of width_p and els_p):
    repeat (4) tag_write_bit(1'b0);
    repeat (32) @(posedge clk_i);
    assert(client[0].client.recv_data_r_o == 'h2) $display("Simulation Passed");
      else $display("Simulation Failed");
  end

endprogram

