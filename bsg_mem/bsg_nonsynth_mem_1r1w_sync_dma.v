/**
 *    bsg_nonsynth_test_dram_channel.v
 *
 */

module bsg_nonsynth_mem_1r1w_sync_dma
  #(parameter width_p="inv"
    , parameter els_p=-1
    , parameter id_p="inv"
    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    , parameter data_width_in_bytes_lp=(width_p>>3)
    , parameter init_mem_p=0
  )
  (
    input clk_i
    , input reset_i

    // ctrl interface
    , input read_v_i
    , input [addr_width_lp-1:0] read_addr_i

    , input write_v_i
    , input [addr_width_lp-1:0] write_addr_i

    // write channel
    , input data_v_i
    , input [width_p-1:0] data_i

    // read channel
    , output logic data_v_o
    , output logic [width_p-1:0] data_o
  );

  import "DPI-C" context function
    chandle bsg_mem_dma_init(longint unsigned id,
                                       longint unsigned channel_addr_width_fp,
                                       longint unsigned data_width_fp,
                                       longint unsigned mem_els_fp,
				       longint unsigned init_mem_fp);

  import "DPI-C" context function
    byte unsigned bsg_mem_dma_get(chandle handle, longint unsigned addr);

  import "DPI-C" context function
    void bsg_mem_dma_set(chandle handle, longint unsigned addr, byte val);

  chandle memory;


  initial begin
    memory
      = bsg_mem_dma_init(id_p, addr_width_lp, width_p, els_p, init_mem_p);
  end

  ////////////////
  // read logic //
  ////////////////

  logic [width_p-1:0] mem_data_lo;
  logic               data_v_lo;

   always_ff @(negedge clk_i) begin
      for (integer byte_id = 0; byte_id < data_width_in_bytes_lp; byte_id++) begin
	 if (read_v_i)
	   mem_data_lo[byte_id*8+:8] <= bsg_mem_dma_get(memory, read_addr_i+byte_id);

      end

      data_v_lo <= read_v_i;

   end

  assign data_v_o = data_v_lo;
  assign data_o = mem_data_lo;


  /////////////////
  // write logic //
  /////////////////

  logic [width_p-1:0] mem_data_li;
  logic               write_valid;

  assign write_valid = ~reset_i & write_v_i & data_v_i;

  assign mem_data_li = data_i;

   always_ff @(posedge clk_i) begin
      for (integer byte_id = 0; byte_id < data_width_in_bytes_lp; byte_id++) begin
	 if (write_valid)
	   bsg_mem_dma_set(memory, write_addr_i+byte_id, mem_data_li[byte_id*8+:8]);

      end
   end

endmodule
