/**
 *    bsg_nonsynth_mem_1r1w_sync_dma.v
 *
 */

`include "bsg_defines.v"

module bsg_nonsynth_mem_1r1w_sync_dma
  #(parameter width_p="inv"
    , parameter els_p=-1
    , parameter id_p="inv"
    , parameter data_width_in_bytes_lp=(width_p>>3)
    , parameter write_mask_width_lp=data_width_in_bytes_lp
    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    , parameter byte_offset_width_lp=`BSG_SAFE_CLOG2(data_width_in_bytes_lp)
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

    // read channel
    , output logic [width_p-1:0] data_o
  );

  bsg_nonsynth_mem_1r1w_sync_mask_write_byte_dma
    #(.width_p(width_p)
      ,.els_p(els_p)
      ,.id_p(id_p)
      ,.init_mem_p(init_mem_p))
  mem
    (.*
     ,.w_mask_i('1));  
  
endmodule
