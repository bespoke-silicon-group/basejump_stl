/**
 *    bsg_nonsynth_ramulator_hbm_channel.v
 *
 */

module bsg_nonsynth_test_dram_channel
  #(parameter channel_addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter mem_els_p=2**23 // 512 MB total
    , parameter channel_id_p="inv"

    , parameter data_mask_width_lp=(data_width_p>>3)
    , parameter byte_offset_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
    , parameter data_width_in_bytes_lp = data_mask_width_lp
    , parameter init_mem_p=0
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

  import "DPI-C" context function
    chandle bsg_test_dram_channel_init(longint unsigned id,
                                       longint unsigned channel_addr_width_fp,
                                       longint unsigned data_width_fp,
                                       longint unsigned mem_els_fp,
				       longint unsigned init_mem_fp);

  import "DPI-C" context function
    byte unsigned bsg_test_dram_channel_get(chandle handle, longint unsigned addr);

  import "DPI-C" context function
    void bsg_test_dram_channel_set(chandle handle, longint unsigned addr, byte val);

  chandle memory;


  initial begin
    memory
      = bsg_test_dram_channel_init(channel_id_p, channel_addr_width_p, data_width_p, mem_els_p, init_mem_p);
  end

  ////////////////
  // read logic //
  ////////////////

  logic [7:0] mem_data_lo [0:data_width_in_bytes_lp-1];
  logic       data_v_lo;

   always_ff @(negedge clk_i) begin
      for (integer byte_id = 0; byte_id < data_width_in_bytes_lp; byte_id++) begin
	 if (read_v_i)
	   mem_data_lo[byte_id] <= bsg_test_dram_channel_get(memory, read_addr_i+byte_id);

      end

      data_v_lo <= '0;
      if (read_v_i)
	data_v_lo <= '1;

   end

  assign data_v_o = data_v_lo;

  for (genvar byte_id = 0; byte_id < data_width_in_bytes_lp; byte_id++) begin
    assign data_o[byte_id*8+:8] = mem_data_lo[byte_id];
  end


  /////////////////
  // write logic //
  /////////////////

  logic [7:0] mem_data_li [0:data_width_in_bytes_lp-1];
  logic      write_valid;

  assign write_valid = ~reset_i & write_v_i & data_v_i;

  for (genvar byte_id = 0; byte_id < data_width_in_bytes_lp; byte_id++) begin
    assign mem_data_li[byte_id] = data_i[byte_id*8+:8];
  end

   always_ff @(posedge clk_i) begin
      for (integer byte_id = 0; byte_id < data_width_in_bytes_lp; byte_id++) begin
	 if (write_valid)
	   bsg_test_dram_channel_set(memory, write_addr_i+byte_id, mem_data_li[byte_id]);

      end
   end

   assign data_yumi_o = write_valid;


endmodule
