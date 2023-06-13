package bsg_dramsim3_pkg;
`include "bsg_defines.sv"

  localparam int max_cfgs = 128;
  localparam int lg_max_cfgs = `BSG_SAFE_CLOG2(max_cfgs);

  typedef enum bit [lg_max_cfgs-1:0] {
    e_ro_ra_bg_ba_ch_co,
    e_ro_ra_bg_ba_co_ch,
    e_ro_ch_ra_ba_bg_co
  } bsg_dramsim3_address_mapping_e;

endpackage // bsg_dramsim3_pkg

// this models 8 legacy-mode channels of an 8gb chip
// x128 is the data width of one legacy mode channel
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
  parameter bsg_dramsim3_pkg::bsg_dramsim3_address_mapping_e address_mapping_p=bsg_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;

  typedef struct packed {
    logic [$clog2(num_rows_p)-1:0] ro;
    logic [$clog2(num_bg_p)-1:0] bg;
    logic [$clog2(num_ba_p)-1:0] ba;
    logic [$clog2(num_columns_p)-1:0] co;
    logic [$clog2(data_width_p>>3)-1:0] byte_offset;
  } dram_ch_addr_s;

endpackage // bsg_dramsim3_hbm2_8gb_x128_pkg

// this models 16 pseudo-channels of an 8gb chip
// with 32 banks (4 bank groups, 8 banks per group)
// x64 is due to the halved data width of a pseudo-channel
// from a 128-bit legacy mode channel
package bsg_dramsim3_hbm2_8gb_x64_32ba_pkg;
  parameter int tck_ps = 1000;
  parameter int channel_addr_width_p = 29;
  parameter int data_width_p=256;
  parameter int num_channels_p=16;
  parameter int num_columns_p=32;
  parameter int num_rows_p=16384;
  parameter int num_ba_p=4;
  parameter int num_bg_p=8;
  parameter int num_ranks_p=1;
  parameter longint size_in_bits_p=2**36; // 8GB (64Gb)
  parameter string config_p="HBM2_8Gb_x64_32ba.ini";
  parameter bsg_dramsim3_pkg::bsg_dramsim3_address_mapping_e address_mapping_p=bsg_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;

  typedef struct packed {
    logic [$clog2(num_rows_p)-1:0] ro;
    logic [$clog2(num_bg_p)-1:0] bg;
    logic [$clog2(num_ba_p)-1:0] ba;
    logic [$clog2(num_columns_p)-1:0] co;
    logic [$clog2(data_width_p>>3)-1:0] byte_offset;
  } dram_ch_addr_s;

endpackage

// this models a single pseudo-channel of the 16gb chip
// this lets us model a scaled-down version of the larger chip
// and reduce simulations memory footprint
// x64 is due to the halved data width of a pseudo-channel
// from a 128-bit legacy mode channel
package bsg_dramsim3_hbm2_1gb_x64_32ba_pkg;
  parameter int tck_ps = 1000;
  parameter int channel_addr_width_p = 30;
  parameter int data_width_p=256;
  parameter int num_channels_p=1;
  parameter int num_columns_p=32;
  parameter int num_rows_p=32768;
  parameter int num_ba_p=4;
  parameter int num_bg_p=8;
  parameter int num_ranks_p=1;
  parameter longint size_in_bits_p=2**33; // 1GB (8Gb)
  parameter string config_p="HBM2_1Gb_x64_32ba.ini";
  parameter bsg_dramsim3_pkg::bsg_dramsim3_address_mapping_e address_mapping_p=bsg_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;

  typedef struct packed {
    logic [$clog2(num_rows_p)-1:0] ro;
    logic [$clog2(num_bg_p)-1:0] bg;
    logic [$clog2(num_ba_p)-1:0] ba;
    logic [$clog2(num_columns_p)-1:0] co;
    logic [$clog2(data_width_p>>3)-1:0] byte_offset;
  } dram_ch_addr_s;

endpackage

// this models two pseudo-channels of the 16gb chip
// this lets us model a scaled-down version of the larger chip
// and reduce simulations memory footprint
// x64 is due to the halved data width of a pseudo-channel
// from a 128-bit legacy mode channel
package bsg_dramsim3_hbm2_2gb_x64_32ba_pkg;
  parameter int tck_ps = 1000;
  parameter int channel_addr_width_p = 30;
  parameter int data_width_p=256;
  parameter int num_channels_p=2;
  parameter int num_columns_p=32;
  parameter int num_rows_p=32768;
  parameter int num_ba_p=4;
  parameter int num_bg_p=8;
  parameter int num_ranks_p=1;
  parameter longint size_in_bits_p=2**34; // 2GB (16Gb)
  parameter string config_p="HBM2_2Gb_x64_32ba.ini";
  parameter bsg_dramsim3_pkg::bsg_dramsim3_address_mapping_e address_mapping_p=bsg_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;

  typedef struct packed {
    logic [$clog2(num_rows_p)-1:0] ro;
    logic [$clog2(num_bg_p)-1:0] bg;
    logic [$clog2(num_ba_p)-1:0] ba;
    logic [$clog2(num_columns_p)-1:0] co;
    logic [$clog2(data_width_p>>3)-1:0] byte_offset;
  } dram_ch_addr_s;

endpackage

// this 16 pseudo-channels of the 16gb chip
// x64 is due to the halved data width of a pseudo-channel
// from a 128-bit legacy mode channel
package bsg_dramsim3_hbm2_16gb_x64_pkg;
  parameter int tck_ps = 1000;
  parameter int channel_addr_width_p = 30;
  parameter int data_width_p=256;
  parameter int num_channels_p=16;
  parameter int num_columns_p=32;
  parameter int num_rows_p=32768;
  parameter int num_ba_p=4;
  parameter int num_bg_p=8;
  parameter int num_ranks_p=1;
  parameter longint size_in_bits_p=2**37; // 16GB (128Gb)
  parameter string config_p="HBM2_16Gb_x64.ini";
  parameter bsg_dramsim3_pkg::bsg_dramsim3_address_mapping_e address_mapping_p=bsg_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;

  typedef struct packed {
    logic [$clog2(num_rows_p)-1:0] ro;
    logic [$clog2(num_bg_p)-1:0] bg;
    logic [$clog2(num_ba_p)-1:0] ba;
    logic [$clog2(num_columns_p)-1:0] co;
    logic [$clog2(data_width_p>>3)-1:0] byte_offset;
  } dram_ch_addr_s;

endpackage

// this models 8 legacy-mode channels of the 4gb chip
// x128 is the data width of one legacy mode channel  
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
  parameter bsg_dramsim3_pkg::bsg_dramsim3_address_mapping_e address_mapping_p=bsg_dramsim3_pkg::e_ro_ra_bg_ba_ch_co;

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
  parameter bsg_dramsim3_pkg::bsg_dramsim3_address_mapping_e address_mapping_p=bsg_dramsim3_pkg::e_ro_ch_ra_ba_bg_co;

  typedef struct packed {
    logic [$clog2(num_rows_p)-1:0] ro;
    logic [$clog2(num_ba_p)-1:0] ba;
    logic [$clog2(num_columns_p)-1:0] co;
    logic [$clog2(data_width_p>>3)-1:0] byte_offset;
  } dram_ch_addr_s;

endpackage // bsg_dramsim3_lpddr3_8gb_x32_1600_pkg

package bsg_dramsim3_lpddr_2Gb_x16_pkg;
  parameter int tck_ps=4800;
  parameter int channel_addr_width_p=30;
  parameter int data_width_p=512;
  parameter int num_channels_p=1;
  parameter int num_columns_p=256;
  parameter int num_rows_p=16384;
  parameter int num_ba_p=4;
  parameter int num_bg_p=1;
  parameter int num_ranks_p=1;
  parameter longint size_in_bits_p=2**33; // 1GB (8Gb)
  parameter string config_p="lpddr_2Gb_x16.ini";
  parameter address_mapping_p=bsg_dramsim3_pkg::e_ro_ch_ra_ba_bg_co;
  
  typedef struct packed {
    logic [$clog2(num_rows_p)-1:0] ro;
    logic [$clog2(num_ba_p)-1:0] ba;
    logic [$clog2(num_columns_p)-1:0] co;
    logic [$clog2(data_width_p>>3)-1:0] byte_offset;
  } dram_ch_addr_s;
  
endpackage // bsg_dramsim3_lpddr_2Gb_x16_pkg
