/**
 *  testbench.v
 *
 */


module testbench();

localparam width_p = 32;
localparam ring_width_p = width_p*2 + 1;
localparam rom_addr_width_p = 32;

logic clk;
logic reset;

bsg_nonsynth_clock_gen #(
  .cycle_time_p(10)
) clock_gen (
  .o(clk)
);

bsg_nonsynth_reset_gen #(
  .reset_cycles_lo_p(4)
  ,.reset_cycles_hi_p(4)
) reset_gen (
  .clk_i(clk)
  ,.async_reset_o(reset)
);

logic v_li;
logic [width_p-1:0] a_li;
logic [width_p-1:0] b_li;
logic sub_li;
logic ready_lo;

logic v_lo;
logic yumi_li;
logic [width_p-1:0] z_lo;

logic unimplemented;
logic invalid;
logic overflow;
logic underflow;

bsg_fpu_add_sub #(
  .e_p(8)
  ,.m_p(23)
) dut (
  .clk_i(clk)
  ,.reset_i(reset)
  ,.en_i(1'b1)

  ,.v_i(v_li)
  ,.a_i(a_li)
  ,.b_i(b_li)
  ,.sub_i(sub_li)
  ,.ready_o(ready_lo)
  
  ,.v_o(v_lo)
  ,.z_o(z_lo)
  ,.yumi_i(yumi_li)

  ,.unimplemented_o(unimplemented)
  ,.invalid_o(invalid)
  ,.overflow_o(overflow)
  ,.underflow_o(underflow)
);

logic [ring_width_p-1:0] tr_data_li;
logic tr_ready_lo;

logic tr_v_lo;
logic [ring_width_p-1:0] tr_data_lo;
logic tr_yumi_li;

logic [rom_addr_width_p-1:0] rom_addr;
logic [ring_width_p+4-1:0] rom_data;

logic done_lo;

bsg_fsb_node_trace_replay #(
  .ring_width_p(ring_width_p)
  ,.rom_addr_width_p(rom_addr_width_p)
) tr (
  .clk_i(clk)
  ,.reset_i(reset)
  ,.en_i(1'b1)

  ,.v_i(v_lo)
  ,.data_i(tr_data_li)
  ,.ready_o(tr_ready_lo)

  ,.v_o(v_li)
  ,.data_o(tr_data_lo)
  ,.yumi_i(tr_yumi_li)

  ,.rom_addr_o(rom_addr)
  ,.rom_data_i(rom_data)

  ,.done_o(done_lo)
  ,.error_o()
);

bsg_fpu_trace_rom #(
  .width_p(ring_width_p+4)
  ,.addr_width_p(rom_addr_width_p)
) rom (
  .addr_i(rom_addr)
  ,.data_o(rom_data)
);

assign yumi_li = v_lo & tr_ready_lo;
assign tr_yumi_li = v_li & ready_lo;

assign {sub_li, a_li, b_li} = tr_data_lo;
assign tr_data_li = {
  {ring_width_p-width_p-4{1'b0}},
  unimplemented,
  invalid,
  overflow,
  underflow,
  z_lo
};

initial begin
  wait(done_lo);
  $finish;
end

endmodule
