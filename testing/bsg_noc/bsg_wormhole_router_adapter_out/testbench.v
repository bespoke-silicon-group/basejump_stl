module testbench();
 
  parameter x_cord_width_p=2;
  parameter y_cord_width_p=2;
  parameter max_payload_width_p = 17;
  parameter max_num_flit_p = 3;
  localparam len_width_lp = `BSG_SAFE_CLOG2(max_num_flit_p);
  localparam max_packet_width_lp = (max_payload_width_p+len_width_lp+y_cord_width_p+x_cord_width_p);
  localparam flit_width_lp =
    (max_packet_width_lp/max_num_flit_p)+((max_packet_width_lp%max_num_flit_p) == 0 ? 0 : 1);

 
  logic clk;
  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) clock_gen (
    .o(clk)
  );

  logic reset;
  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(4)
    ,.reset_cycles_hi_p(4)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  `declare_bsg_ready_and_link_sif_s(flit_width_lp, bsg_ready_and_link_sif_s);

  logic [max_packet_width_lp-1:0] data_li;
  logic v_li, ready_and_lo;
  logic [max_packet_width_lp-1:0] packet_lo, data_lo;
  logic v_lo, ready_and_li;
  logic [1:0] count;

  bsg_counter_clear_up #(
    .max_val_p(3)
    ,.init_val_p(0)
  ) counter (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.clear_i(ready_and_li * v_lo)
    ,.up_i(v_li & ready_and_lo)
    ,.count_o(count)
  );

  bsg_wormhole_router_adapter_out #(
    .flit_width_p(flit_width_lp)
    ,.max_payload_width_p(max_payload_width_p)
    ,.cord_width_p(x_cord_width_p + y_cord_width_p)
    ,.len_width_p(len_width_lp) 
  ) adapter (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.link_v_i(v_li)
    ,.link_data_i(data_li[0+:flit_width_lp])
    ,.link_ready_and_o(ready_and_lo)

    ,.packet_o(packet_lo)
    ,.packet_v_o(v_lo)
    ,.packet_yumi_i(v_lo & ready_and_li)
  );

  wire [22:0] mask_3 = 23'b11111111111111111111111;
  wire [22:0] mask_2 = 23'b00000001111111111111111;
  wire [22:0] mask_1 = 23'b00000000000000011111111;

  always_comb begin
    case(count)
      0: data_lo = '0;
      1: data_lo = packet_lo & mask_1;
      2: data_lo = packet_lo & mask_2;
      3: data_lo = packet_lo & mask_3;
      default: data_lo = '0;
    endcase
  end

  parameter rom_addr_width_p = 10;

  logic [rom_addr_width_p-1:0] rom_addr;
  logic [max_packet_width_lp+4-1:0] rom_data;
  logic done;
  bsg_fsb_node_trace_replay #(
    .ring_width_p(max_packet_width_lp)
    ,.rom_addr_width_p(rom_addr_width_p)
  ) tr (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.en_i(~reset)

    ,.v_i(v_lo)
    ,.data_i(data_lo)
    ,.ready_o(ready_and_li)

    ,.v_o(v_li)
    ,.data_o(data_li)
    ,.yumi_i(v_li & ready_and_lo)

    ,.rom_addr_o(rom_addr)
    ,.rom_data_i(rom_data)

    ,.done_o(done)
    ,.error_o()
  );
  
  bsg_trace_rom #(
    .width_p(max_packet_width_lp+4)
    ,.addr_width_p(rom_addr_width_p)
  ) rom (
   .addr_i(rom_addr)
   ,.data_o(rom_data)
  );

  initial begin
    //wait(done);
    for (int i = 0; i < 300; i++) begin
      @(posedge clk);
    end
    $finish;
  end 

endmodule
