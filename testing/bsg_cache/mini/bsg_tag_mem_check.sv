`include "bsg_defines.sv"

module bsg_tag_mem_check #(
  parameter width_p=184
  ,parameter sets_p=128
  ,parameter num_dma_p=8
)(
  input clk_i
  ,input reset_i
  ,input [width_p-1:0] data_i
  ,input v_i
  ,input w_i
  ,input [width_p-1:0] w_mask_i
  ,input [`BSG_SAFE_CLOG2(sets_p)-1:0] addr_i
  ,input [width_p-1:0] shadow_tag_mem_i [sets_p-1:0]
  ,input check_en_i
  ,input [`BSG_SAFE_CLOG2(num_dma_p)-1:0] id_i
  // ,output logic [width_p-1:0] tag_mem_copy_o [sets_p-1:0]
);

  integer i;
  integer set_idx;
  // integer mismatch_count = 0;

  logic [width_p-1:0] tag_mem_copy [sets_p-1:0];

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      for (i = 0; i < sets_p; i++) tag_mem_copy[i] <= '0;
    end
    else begin

      if (v_i && w_i) begin
        tag_mem_copy[addr_i] <= (data_i & w_mask_i);
      end

      if (check_en_i) begin
      // for (dma_idx = 0; dma_idx < num_dma_p; dma_idx = dma_idx + 1) begin
        for (set_idx = 0; set_idx < sets_p; set_idx++) begin

          // TODO:shadow_tag_mem[dma_idx][set_idx] has to be replaced with the actual shadow tag memory data output form
          assert(shadow_tag_mem_i[set_idx] == tag_mem_copy[set_idx])
            else $fatal(1, "[BSG_FATAL] Mismatch at cache %0d, set %0d: Cache = %h, Shadow = %h", 
                  id_i,
                  set_idx, 
                  tag_mem_copy[set_idx], 
                  shadow_tag_mem_i[set_idx]);
          //   mismatch_count++;
        end

      // if (mismatch_count == 0) begin
      //   $display("Test PASSED: All shadow tags match cache tags.");
      // end else begin
      //   $display("Test FAILED: %0d mismatches detected.", mismatch_count);
      // end
      end
    end
  end


endmodule

`BSG_ABSTRACT_MODULE(bsg_tag_mem_check)