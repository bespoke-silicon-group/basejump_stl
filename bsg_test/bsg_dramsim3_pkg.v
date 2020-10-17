package bsg_dramsim3_pkg;
`include "bsg_defines.v"

  localparam int max_cfgs = 128;
  localparam int lg_max_cfgs = `BSG_SAFE_CLOG2(max_cfgs);

  typedef enum bit [lg_max_cfgs-1:0] {
    e_ro_ra_bg_ba_ch_co,
    e_ro_ra_bg_ba_co_ch,
    e_ro_ch_ra_ba_bg_co
  } bsg_dramsim3_address_mapping_e;

endpackage // bsg_dramsim3_pkg

package bsg_dramsim3_hbm2_8gb_x128_pkg;
  parameter int tck_ps = 1000;
  parameter int channel_addr_width_p = 30;
  parameter int data_width_p=256;
  parameter int num_channels_p=8;
  parameter int num_columns_p=64;
  parameter int num_rows_p=32768;
  parameter int num_ba_p=4;
  parameter int num_bg_p=4;
  parameter int num_ranks_p=1;
  parameter longint size_in_bits_p=2**36; // 8GB (64Gb)
  parameter string config_p="HBM2_8Gb_x128.ini";
  parameter address_mapping_p=bsg_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;

  typedef struct packed {
    logic [$clog2(num_rows_p)-1:0] ro;
    logic [$clog2(num_bg_p)-1:0] bg;
    logic [$clog2(num_ba_p)-1:0] ba;
    logic [$clog2(num_columns_p)-1:0] co;
    logic [$clog2(data_width_p>>3)-1:0] byte_offset;
  } dram_ch_addr_s;

endpackage // bsg_dramsim3_hbm2_8gb_x128_pkg

package bsg_dramsim3_hbm2_4gb_x128_pkg;
  parameter int tck_ps = 1000;
  parameter int channel_addr_width_p = 29;
  parameter int data_width_p=256;
  parameter int num_channels_p=8;
  parameter int num_columns_p=64;
  parameter int num_rows_p=16384;
  parameter int num_ba_p=4;
  parameter int num_bg_p=4;
  parameter int num_ranks_p=1;
  parameter longint size_in_bits_p=2**35; // 4GB (32Gb)
  parameter string config_p="HBM2_4Gb_x128.ini";
  parameter address_mapping_p=bsg_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;

  typedef struct packed {
    logic [$clog2(num_rows_p)-1:0] ro;
    logic [$clog2(num_bg_p)-1:0] bg;
    logic [$clog2(num_ba_p)-1:0] ba;
    logic [$clog2(num_columns_p)-1:0] co;
    logic [$clog2(data_width_p>>3)-1:0] byte_offset;
  } dram_ch_addr_s;

endpackage // bsg_dramsim3_hbm2_8gb_x128_pkg

package bsg_dramsim3_lpddr3_8gb_x32_1600_pkg;
  parameter int tck_ps = 1250;
  parameter int channel_addr_width_p = 31;
  parameter int data_width_p=512;
  parameter int num_channels_p=1;
  parameter int num_columns_p=128;
  parameter int num_rows_p=32768;
  parameter int num_ba_p=8;
  parameter int num_bg_p=1;
  parameter int num_ranks_p=1;
  parameter longint size_in_bits_p=2**34; // 2GB (16Gb)
  parameter string config_p="LPDDR3_8Gb_x32_1600.ini";
  parameter address_mapping_p=bsg_dramsim3_pkg::e_ro_ch_ra_ba_bg_co;

  typedef struct packed {
    logic [$clog2(num_rows_p)-1:0] ro;
    logic [$clog2(num_ba_p)-1:0] ba;
    logic [$clog2(num_columns_p)-1:0] co;
    logic [$clog2(data_width_p>>3)-1:0] byte_offset;
  } dram_ch_addr_s;

endpackage // bsg_dramsim3_lpddr3_8gb_x32_1600_pkg

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
