`define RAMULATOR

module testbench();

  bit clk;
  bit reset;
  
  // 500 MHz
  bsg_nonsynth_clock_gen #(
    .cycle_time_p(2000)
  ) cg0 (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(20)
  ) rg0 (
    .clk_i(clk)
    ,.async_reset_o(reset) 
  );


  localparam num_channels_p = 8;
  localparam channel_addr_width_p = 29;
  localparam data_width_p = 512;
  localparam data_mask_width_lp = (data_width_p>>3);

  logic [num_channels_p-1:0] valid;
  logic [num_channels_p-1:0] write_not_read;
  logic [num_channels_p-1:0][channel_addr_width_p-1:0] ch_addr_li;
  logic [num_channels_p-1:0] yumi;

  logic [num_channels_p-1:0] data_v_li;
  logic [num_channels_p-1:0][data_width_p-1:0] data_li;
  logic [num_channels_p-1:0][data_mask_width_lp-1:0] mask_li;
  logic [num_channels_p-1:0] data_yumi_lo;

  logic [num_channels_p-1:0] data_v_lo;
  logic [num_channels_p-1:0][data_width_p-1:0] data_lo;

  bsg_nonsynth_ramulator_hbm #(
    .channel_addr_width_p(channel_addr_width_p)
    ,.num_channels_p(num_channels_p)
    ,.data_width_p(data_width_p)
    ,.debug_p(1)
  ) hbm0 (
    .clk_i(clk)
    ,.reset_i(reset)
   
    ,.v_i(valid)
    ,.write_not_read_i(write_not_read)
    ,.ch_addr_i(ch_addr_li)
    ,.yumi_o(yumi)

    ,.data_v_i(data_v_li)
    ,.data_i(data_li)
    ,.data_yumi_o(data_yumi_lo)

    ,.data_v_o(data_v_lo)
    ,.data_o(data_lo)
    ,.read_done_ch_addr_o()
    
  ); 



  // trace replay
  //
  typedef struct packed {
    logic write_not_read;
    logic [channel_addr_width_p-1:0] ch_addr;
  } hbm_trace_s;

  localparam ring_width_p = $bits(hbm_trace_s);
  localparam rom_addr_width_p=20;

  hbm_trace_s [num_channels_p-1:0] tr_data_lo;
  logic [num_channels_p-1:0] tr_v_lo;
  logic [num_channels_p-1:0] tr_yumi_li;

  logic [num_channels_p-1:0][4+ring_width_p-1:0] rom_data;
  logic [num_channels_p-1:0][rom_addr_width_p-1:0] rom_addr;

  logic [num_channels_p-1:0] ch_done;

  for (genvar i = 0; i < num_channels_p; i++) begin

    bsg_fsb_node_trace_replay #(
      .ring_width_p(ring_width_p)  
      ,.rom_addr_width_p(rom_addr_width_p)
    ) tr (
      .clk_i(clk)
      ,.reset_i(reset)
      ,.en_i(1'b1)

      ,.v_i(1'b0)
      ,.data_i('0)
      ,.ready_o()

      ,.v_o(tr_v_lo[i])
      ,.data_o(tr_data_lo[i])
      ,.yumi_i(tr_yumi_li[i])

      ,.rom_addr_o(rom_addr[i])
      ,.rom_data_i(rom_data[i])

      ,.done_o(ch_done[i])
      ,.error_o()
    );

    bsg_nonsynth_test_rom #(
      .data_width_p(ring_width_p+4)
      ,.addr_width_p(rom_addr_width_p)
      ,.filename_p("trace_0.tr")
    ) rom0 (
      .addr_i(rom_addr[i])
      ,.data_o(rom_data[i]) 
    );

    assign write_not_read[i] = tr_data_lo[i].write_not_read;
    assign ch_addr_li[i] = tr_data_lo[i].ch_addr;
    assign valid[i] = tr_v_lo[i];
    assign tr_yumi_li[i] = yumi[i];

  end

   logic done;

   bsg_reduce #(
     .width_p(num_channels_p)
     ,.and_p(1)
   ) reduce_done (
     .i(ch_done)
     ,.o(done)
   );

  always @(posedge clk)
    begin
       if (done)
         $finish;
    end

endmodule
