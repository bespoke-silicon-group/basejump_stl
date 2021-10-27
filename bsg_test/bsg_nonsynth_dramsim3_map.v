/////////////////////////////////
// bsg_nonsynth_dramsim3_map.v //
/////////////////////////////////
`include "bsg_defines.v"

module bsg_nonsynth_dramsim3_map
  import bsg_dramsim3_pkg::*;
  #(parameter `BSG_INV_PARAM(channel_addr_width_p)
    , parameter `BSG_INV_PARAM(data_width_p)
    , parameter `BSG_INV_PARAM(num_channels_p)
    , parameter `BSG_INV_PARAM(num_columns_p)
    , parameter `BSG_INV_PARAM(num_rows_p)
    , parameter `BSG_INV_PARAM(num_ba_p)
    , parameter `BSG_INV_PARAM(num_bg_p)
    , parameter `BSG_INV_PARAM(num_ranks_p)
    , parameter `BSG_INV_PARAM(address_mapping_p)
    , parameter `BSG_INV_PARAM(channel_select_p)
    , parameter debug_p=0
    , parameter lg_num_channels_lp=$clog2(num_channels_p)
    , parameter lg_num_columns_lp=$clog2(num_columns_p)
    , parameter lg_num_rows_lp=$clog2(num_rows_p)
    , parameter lg_num_ba_lp=$clog2(num_ba_p)
    , parameter lg_num_bg_lp=$clog2(num_bg_p)
    , parameter lg_num_ranks_lp=$clog2(num_ranks_p)
    , parameter data_mask_width_lp=(data_width_p>>3)
    , parameter byte_offset_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
    , parameter addr_width_lp=lg_num_channels_lp+channel_addr_width_p
    )
   (
    input logic [channel_addr_width_p-1:0] ch_addr_i
    , output logic [addr_width_lp-1:0] mem_addr_o
   );

  localparam co_pos_lp = byte_offset_width_lp;
  localparam ba_pos_lp = co_pos_lp + lg_num_columns_lp;
  localparam bg_pos_lp = ba_pos_lp + lg_num_ba_lp;
  localparam ra_pos_lp = bg_pos_lp + lg_num_bg_lp;
  localparam ro_pos_lp = ra_pos_lp + lg_num_ranks_lp;

  if (address_mapping_p == e_ro_ra_bg_ba_co_ch) begin
    assign mem_addr_o
      = {
         ch_addr_i[channel_addr_width_p-1:byte_offset_width_lp],
         {lg_num_channels_lp!=0{`BSG_MAX(lg_num_channels_lp, 1)'(channel_select_p)}},
         {byte_offset_width_lp{1'b0}}
         };
  end

  else if (address_mapping_p == e_ro_ra_bg_ba_ch_co) begin
    assign mem_addr_o
      = {
         ch_addr_i[channel_addr_width_p-1:lg_num_columns_lp+byte_offset_width_lp],
         {lg_num_channels_lp!=0{`BSG_MAX(lg_num_channels_lp, 1)'(channel_select_p)}},
         ch_addr_i[lg_num_columns_lp+byte_offset_width_lp-1:byte_offset_width_lp],
         {byte_offset_width_lp{1'b0}}
         };
  end
  else if (address_mapping_p == e_ro_ch_ra_ba_bg_co) begin
    assign mem_addr_o
      = {
         ch_addr_i[ro_pos_lp+:lg_num_rows_lp],
         {lg_num_channels_lp!=0{`BSG_MAX(lg_num_channels_lp, 1)'(channel_select_p)}},
         {lg_num_ranks_lp!=0{ch_addr_i[ra_pos_lp+:`BSG_MAX(lg_num_ranks_lp, 1)]}},
         {lg_num_ba_lp!=0{ch_addr_i[ba_pos_lp+:`BSG_MAX(lg_num_ba_lp, 1)]}},
         {lg_num_bg_lp!=0{ch_addr_i[bg_pos_lp+:`BSG_MAX(lg_num_bg_lp, 1)]}},
         ch_addr_i[co_pos_lp+:lg_num_columns_lp],
         {byte_offset_width_lp{1'b0}}
         };
  end

endmodule // bsg_nonsynth_dramsim3_map

`BSG_ABSTRACT_MODULE(bsg_nonsynth_dramsim3_map)
