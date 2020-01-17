/**
 *    bsg_nonsynth_test_dram_channel.v
 *
 */

module bsg_nonsynth_test_dram_channel
  #(parameter channel_addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter mem_els_p=2**23 // 512 MB total

    , parameter init_mem_p=0

    , parameter data_mask_width_lp=(data_width_p>>3)
    , parameter byte_offset_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
  )
  (
    input clk_i
    , input reset_i

    // ctrl interface
    , input read_v_i
    , input [channel_addr_width_p-1:0] read_addr_i
    , input write_v_i
    , input [channel_addr_width_p-1:0] write_addr_i

    // write channel
    , input data_v_i
    , input [data_width_p-1:0] data_i
    , output logic data_yumi_o

    // read channel
    , output logic data_v_o
    , output logic [data_width_p-1:0] data_o
  );

  logic [data_width_p-1:0] mem [mem_els_p-1:0];

  assign data_v_o = read_v_i;
  assign data_o = mem[read_addr_i[channel_addr_width_p-1:byte_offset_width_lp]];

  assign data_yumi_o = data_v_i & write_v_i;


  // zero out memory once at the beginning
  initial begin
    if (init_mem_p)
      for (integer i = 0; i < mem_els_p; i++)
        mem[i] = '0;
  end


  always_ff @ (posedge clk_i) begin
    if (~reset_i) begin
      if (write_v_i)
        mem[write_addr_i[channel_addr_width_p-1:byte_offset_width_lp]] <= data_i;
    end
  end


endmodule
