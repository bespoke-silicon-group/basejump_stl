package bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg;
  parameter int channel_addr_width_p = 30;
  parameter int data_width_p=512;
  parameter int num_channels_p=8;
  parameter longint size_p=2**36; // 8GB (64Gb)
  parameter string config_p="HBM2_8Gb_x128.ini";  
endpackage
