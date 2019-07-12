/**
 *  testbench.v
 *
 */


module testbench();

localparam width_p = 32;
localparam ring_width_p = width_p + 1;
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

logic [width_p-1:0] a_r;
logic signed_r;
logic v_r;

logic [width_p-1:0] z_lo;
logic invalid_lo;


bsg_fpu_f2i #(
  .e_p(8)
  ,.m_p(23)
) dut (
  .a_i(a_r)
  ,.signed_i(signed_r)

  ,.z_o(z_lo)
  ,.invalid_o(invalid_lo)
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

  ,.v_i(v_r)
  ,.data_i(tr_data_li)
  ,.ready_o(tr_ready_lo)

  ,.v_o(tr_v_lo)
  ,.data_o(tr_data_lo)
  ,.yumi_i(tr_yumi_li)

  ,.rom_addr_o(rom_addr)
  ,.rom_data_i(rom_data)

  ,.done_o(done_lo)
  ,.error_o()
);

assign {signed_li, a_li} = tr_data_lo;

bsg_fpu_trace_rom #(
  .width_p(ring_width_p+4)
  ,.addr_width_p(rom_addr_width_p)
) rom (
  .addr_i(rom_addr)
  ,.data_o(rom_data)
);

assign tr_data_li = {
  invalid_lo
  ,z_lo
};

logic [width_p-1:0] a_n;
logic signed_n;
logic v_n;

always_comb begin
  if (v_r == 1'b0) begin
    tr_yumi_li = tr_v_lo;
    v_n = tr_v_lo;
    signed_n = tr_v_lo
      ? tr_data_lo[width_p]
      : signed_r;
    a_n = tr_v_lo
      ? tr_data_lo[0+:width_p]
      : a_r;
  end
  else begin
    tr_yumi_li = 1'b0;
    v_n = ~tr_ready_lo;
    a_n = a_r;
  end
end

always_ff @ (posedge clk) begin
  if (reset) begin
    a_r <= '0;
    v_r <= 1'b0;
    signed_r <= 1'b0;
  end
  else begin
    a_r <= a_n;
    v_r <= v_n;
    signed_r <= signed_n;
  end
end


initial begin
  wait(done_lo);
  $finish;
end

endmodule
