package bsg_nonsynth_dramsim3_pkg;
`include "bsg_defines.v"

  localparam int max_cfgs = 128;
  localparam int lg_max_cfgs = `BSG_SAFE_CLOG2(max_cfgs);

  typedef enum bit [lg_max_cfgs-1:0] {
    e_ro_ra_bg_ba_ch_co,
    e_ro_ra_bg_ba_co_ch,
    e_ro_ch_ra_ba_bg_co
  } bsg_nonsynth_dramsim3_address_mapping_e;

endpackage // bsg_nonsynth_dramsim3_pkg

package bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg;
  parameter int tck_ps = 1000;
  parameter int channel_addr_width_p = 30;
  parameter int data_width_p=256;
  parameter int num_channels_p=8;
  parameter int num_columns_p=64;
  parameter longint size_in_bits_p=2**36; // 8GB (64Gb)
  parameter string config_p="HBM2_8Gb_x128.ini";
  parameter address_mapping_p=bsg_nonsynth_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;

endpackage // bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg

package bsg_nonsynth_dramsim3_hbm2_4gb_x128_pkg;
  parameter int tck_ps = 1000;
  parameter int channel_addr_width_p = 29;
  parameter int data_width_p=256;
  parameter int num_channels_p=8;
  parameter int num_columns_p=64;
  parameter longint size_in_bits_p=2**35; // 8GB (64Gb)
  parameter string config_p="HBM2_4Gb_x128.ini";
  parameter address_mapping_p=bsg_nonsynth_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;

endpackage // bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg
