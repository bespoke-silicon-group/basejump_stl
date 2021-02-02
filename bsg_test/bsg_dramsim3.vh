`ifndef BSG_DRAMSIM3_VH
`define BSG_DRAMSIM3_VH

`define dramsim3_ba_width(num_ba_mp) $clog2(num_ba_mp)
`define dramsim3_bg_width(num_bg_mp) $clog2(num_bg_mp)
`define dramsim3_co_width(num_columns_mp) $clog2(num_columns_mp)
`define dramsim3_ro_width(num_rows_mp) $clog2(num_rows_mp)
`define dramsim3_ra_width(num_ranks_mp) $clog2(num_ranks_mp)
`define dramsim3_byte_offset_width(data_width_mp) \
  $clog2(data_width_mp>>3)

`define dramsim3_ba_width_pkg(dram_pkg) \
  `dramsim3_ba_width(dram_pkg::num_ba_p)

`define dramsim3_bg_width_pkg(dram_pkg) \
  `dramsim3_bg_width(dram_pkg::num_bg_p)

`define dramsim3_co_width_pkg(dram_pkg) \
  `dramsim3_co_width(dram_pkg::num_columns_p)

`define dramsim3_ro_width_pkg(dram_pkg) \
  `dramsim3_ro_width(dram_pkg::num_rows_p)

`define dramsim3_ra_width_pkg(dram_pkg) \
  `dramsim3_ra_width(dram_pkg::num_ranks_p)

`define dramsim3_byte_offset_width_pkg(dram_pkg) \
  `dramsim3_byte_offset_width(dram_pkg::data_width_p)

`endif
