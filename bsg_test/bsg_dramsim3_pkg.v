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
  parameter int num_ba_p=4;
  parameter int num_bg_p=4;
  parameter longint size_in_bits_p=2**36; // 8GB (64Gb)
  parameter string config_p="HBM2_8Gb_x128.ini";
  parameter address_mapping_p=bsg_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;

endpackage // bsg_dramsim3_hbm2_8gb_x128_pkg

package bsg_dramsim3_hbm2_4gb_x128_pkg;
  parameter int tck_ps = 1000;
  parameter int channel_addr_width_p = 29;
  parameter int data_width_p=256;
  parameter int num_channels_p=8;
  parameter int num_columns_p=64;
  parameter int num_ba_p=4;
  parameter int num_bg_p=4;
  parameter longint size_in_bits_p=2**35; // 4GB (32Gb)
  parameter string config_p="HBM2_4Gb_x128.ini";
  parameter address_mapping_p=bsg_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;
endpackage // bsg_dramsim3_hbm2_8gb_x128_pkg

`define dramsim3_ba_width(num_ba_mp) $clog2(num_ba_mp)
`define dramsim3_bg_width(num_bg_mp) $clog2(num_bg_mp)
`define dramsim3_co_width(num_columns_mp) $clog2(num_columns_mp)
`define dramsim3_byte_offset_width(data_width_mp) \
  $clog2(data_width_mp>>3)

`define dramsim3_ro_width(ch_addr_width_mp, data_width_mp, num_ba_mp, num_bg_mp, num_columns_mp) \
  (ch_addr_width_mp   \
   - `dramsim3_ba_width(num_ba_mp)   \
   - `dramsim3_bg_width(num_bg_mp)   \
   - `dramsim3_co_width(num_columns_mp)   \
   - `dramsim3_byte_offset_width(data_width_mp))

`define declare_dramsim3_ch_addr_s(typename_mp, ch_addr_width_mp, data_width_mp, num_ba_mp, num_bg_mp, num_columns_mp) \
  typedef struct packed { \
    logic [`dramsim3_ro_width(ch_addr_width_mp, data_width_mp, num_ba_mp, num_bg_mp, num_columns_mp)-1:0] ro; \
    logic [`dramsim3_bg_width(num_bg_mp)-1:0] bg; \
    logic [`dramsim3_ba_width(num_ba_mp)-1:0] ba; \
    logic [`dramsim3_co_width(num_columns_mp)-1:0] co; \
    logic [`dramsim3_byte_offset_width(data_width_mp)-1:0] byte_offset; \
  } typename_mp

`define declare_dramsim3_ch_addr_s_with_pkg(typename_mp, dram_pkg) \
  `declare_dramsim3_ch_addr_s(typename_mp, \
                              dram_pkg::channel_addr_width_p, \
                              dram_pkg::data_width_p, \
                              dram_pkg::num_ba_p, \
                              dram_pkg::num_bg_p, \
                              dram_pkg::num_columns_p)
