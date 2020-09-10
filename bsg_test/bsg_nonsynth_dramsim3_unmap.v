/////////////////////////////////
// bsg_nonsynth_dramsim3_unmap //
/////////////////////////////////
`include "bsg_defines.v"

module bsg_nonsynth_dramsim3_unmap
  import bsg_dramsim3_pkg::*;
  #(parameter channel_addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter num_channels_p="inv"
    , parameter num_columns_p="inv"
    , parameter address_mapping_p="inv"
    , parameter channel_select_p="inv"
    , parameter debug_p=0
    , parameter lg_num_channels_lp=`BSG_SAFE_CLOG2(num_channels_p)
    , parameter lg_num_columns_lp=`BSG_SAFE_CLOG2(num_columns_p)
    , parameter data_mask_width_lp=(data_width_p>>3)
    , parameter byte_offset_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
    , parameter addr_width_lp=lg_num_channels_lp+channel_addr_width_p
    )
   (
    input logic [addr_width_lp-1:0] mem_addr_i
    , output logic [channel_addr_width_p-1:0] ch_addr_o
    );

    if (address_mapping_p == e_ro_ra_bg_ba_co_ch) begin
      assign ch_addr_o
        = {
           mem_addr_i[channel_addr_width_p+lg_num_channels_lp-1:byte_offset_width_lp+lg_num_channels_lp],
           {byte_offset_width_lp{1'b0}}
           };
    end

    else if (address_mapping_p == e_ro_ra_bg_ba_ch_co) begin
      assign ch_addr_o
        = {
           mem_addr_i[addr_width_lp-1:lg_num_channels_lp+lg_num_columns_lp+byte_offset_width_lp],
           mem_addr_i[lg_num_columns_lp+byte_offset_width_lp-1:byte_offset_width_lp],
           {byte_offset_width_lp{1'b0}}
           };
    end

endmodule // bsg_nonsynth_dramsim3_unmap
