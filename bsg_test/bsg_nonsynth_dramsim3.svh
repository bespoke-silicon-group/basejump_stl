`ifndef BSG_NONSYNTH_DRAMSIM3_SVH
`define BSG_NONSYNTH_DRAMSIM3_SVH

// Shortcut for instantiating an HBM2 8GB x128 stack
`define bsg_nonsynth_dramsim3_hbm2_8gb_x128_trace_file \
"bsg_nonsynth_dramsim3_hbm2_8gb_x128_trace.txt"

`define _bsg_nonsynth_dramsim3_hbm2_8gb_x128_base_parameters \
    .channel_addr_width_p(bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg::channel_addr_width_p) \
    ,.data_width_p(bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg::data_width_p) \
    ,.num_channels_p(bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg::num_channels_p) \
    ,.num_columns_p(bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg::num_columns_p) \
    ,.size_p(bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg::size_p) \
    ,.address_mapping_p(bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg::address_mapping_p) \
    ,.config_p(bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg::config_p) \
    ,.trace_file_p(`bsg_nonsynth_dramsim3_hbm2_8gb_x128_trace_file)

`define bsg_nonsynth_dramsim3_hbm2_8gb_x128 \
  bsg_nonsynth_dramsim3 \
  #(`_bsg_nonsynth_dramsim3_hbm2_8gb_x128_base_parameters)

`define bsg_nonsynth_dramsim3_hbm2_8gb_x128_dbg \
  bsg_nonsynth_dramsim3 \
  #(`_bsg_nonsynth_dramsim3_hbm2_8gb_x128_base_parameters \
    ,.debug_p(1))

`endif
