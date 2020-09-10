/**
 *    bsg_nonsynth_mem_1r1w_sync_mask_write_byte_dma.v
 *
 * If a read and write are issued to the same address the new value is read back.
 *
 */

`include "bsg_defines.v"

module bsg_nonsynth_mem_1r1w_sync_mask_write_byte_dma
  #(parameter width_p="inv"
    , parameter els_p=-1
    , parameter id_p="inv"
    , parameter data_width_in_bytes_lp=(width_p>>3)
    , parameter write_mask_width_lp=data_width_in_bytes_lp
    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    , parameter byte_offset_width_lp=$clog2(data_width_in_bytes_lp)
    , parameter init_mem_p=0
  )
  (
    input clk_i
    , input reset_i

    // ctrl interface
    , input r_v_i
    , input [addr_width_lp-1:0] r_addr_i

    , input                           w_v_i
    , input [addr_width_lp-1:0]       w_addr_i
    , input [width_p-1:0]             w_data_i
    , input [write_mask_width_lp-1:0] w_mask_i

    // read channel
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
  logic [addr_width_lp+byte_offset_width_lp-1:0] read_byte_addr;
  assign read_byte_addr = { r_addr_i, {(byte_offset_width_lp){1'b0}} };

  logic [width_p-1:0] data_r;
  
   always_ff @(negedge clk_i) begin
     if (r_v_i) begin
      for (integer byte_id = 0; byte_id < data_width_in_bytes_lp; byte_id++) begin
	   data_r[byte_id*8+:8] <= bsg_mem_dma_get(memory, read_byte_addr+byte_id);
      end
     end

   end

  // most client code expects outputs to change at the positive edge
  always_ff @(posedge clk_i) begin
      data_o <= data_r;    
   end

  
  /////////////////
  // write logic //
  /////////////////
  logic [addr_width_lp+byte_offset_width_lp-1:0] write_byte_addr;
  assign write_byte_addr = { w_addr_i, {(byte_offset_width_lp){1'b0}} };

  logic [width_p-1:0] mem_data_li;
  logic               write_valid;

  assign write_valid = ~reset_i & w_v_i;  

  assign mem_data_li = w_data_i;

   always_ff @(posedge clk_i) begin
      for (integer byte_id = 0; byte_id < data_width_in_bytes_lp; byte_id++) begin
	 if (write_valid & w_mask_i[byte_id])
	   bsg_mem_dma_set(memory, write_byte_addr+byte_id, mem_data_li[byte_id*8+:8]);

      end
   end

endmodule
