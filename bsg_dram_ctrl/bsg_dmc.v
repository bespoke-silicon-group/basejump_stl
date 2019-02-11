module bsg_dmc #
  (parameter UI_ADDR_WIDTH  = 28
  ,parameter UI_DATA_WIDTH  = 128
  ,parameter DFI_DATA_WIDTH = 32
  ,parameter DQ_GROUP       = 2)
  // Global asynchronous reset
  (input                            sys_rst
  // User interface signals
  ,input        [UI_ADDR_WIDTH-1:0] app_addr
  ,input                      [2:0] app_cmd
  ,input                            app_en
  ,output                           app_rdy
  ,input                            app_wdf_wren
  ,input        [UI_DATA_WIDTH-1:0] app_wdf_data
  ,input   [(UI_DATA_WIDTH>>3)-1:0] app_wdf_mask
  ,input                            app_wdf_end
  ,output                           app_wdf_rdy
  ,output                           app_rd_data_valid
  ,output       [UI_DATA_WIDTH-1:0] app_rd_data
  ,output                           app_rd_data_end
  ,input                            app_ref_req
  ,output                           app_ref_ack
  ,input                            app_zq_req
  ,output                           app_zq_ack
  ,input                            app_sr_req
  ,output                           app_sr_active
  // Status signal
  ,output                           init_calib_complete
  // DDR interface signals
  ,output                           ddr_ck_p_o
  ,output                           ddr_ck_n_o
  ,output                           ddr_cke_o
  ,output                     [2:0] ddr_ba_o
  ,output                    [15:0] ddr_addr_o
  ,output                           ddr_cs_n_o
  ,output                           ddr_ras_n_o
  ,output                           ddr_cas_n_o
  ,output                           ddr_we_n_o
  ,output                           ddr_reset_n_o
  ,output                           ddr_odt_o

  ,output [(DFI_DATA_WIDTH>>4)-1:0] ddr_dm_oen_o
  ,output [(DFI_DATA_WIDTH>>4)-1:0] ddr_dm_o
  ,output [(DFI_DATA_WIDTH>>4)-1:0] ddr_dqs_p_oen_o
  ,output [(DFI_DATA_WIDTH>>4)-1:0] ddr_dqs_p_ien_o
  ,output [(DFI_DATA_WIDTH>>4)-1:0] ddr_dqs_p_o
  ,input  [(DFI_DATA_WIDTH>>4)-1:0] ddr_dqs_p_i
  ,output [(DFI_DATA_WIDTH>>4)-1:0] ddr_dqs_n_oen_o
  ,output [(DFI_DATA_WIDTH>>4)-1:0] ddr_dqs_n_ien_o
  ,output [(DFI_DATA_WIDTH>>4)-1:0] ddr_dqs_n_o
  ,input  [(DFI_DATA_WIDTH>>4)-1:0] ddr_dqs_n_i
  ,output [(DFI_DATA_WIDTH>>1)-1:0] ddr_dq_oen_o
  ,output [(DFI_DATA_WIDTH>>1)-1:0] ddr_dq_o
  ,input  [(DFI_DATA_WIDTH>>1)-1:0] ddr_dq_i

  //
`ifdef XILINX
  // Reference clock ports
  ,input                            clk_ref_p
  ,input                            clk_ref_n
  // User interface clock
  ,output                           ui_clk
`else
  ,input                            ui_clk

  ,input                            dfi_clk_2x
  ,input                            dfi_clk
`endif
  ,output                           ui_clk_sync_rst

  //
  ,output                    [11:0] device_temp
);

  reg                               ui_reset, ui_reset_sync;
  reg                               dfi_reset, dfi_reset_sync;

`ifdef XILINX
  wire                              dfi_clk_2x;
  wire                              dfi_clk;

  wire                              locked;
`endif

  wire                        [2:0] dfi_bank;
  wire                       [15:0] dfi_address;
  wire                              dfi_cke;
  wire                              dfi_cs_n;
  wire                              dfi_ras_n;
  wire                              dfi_cas_n;
  wire                              dfi_we_n;
  wire                              dfi_reset_n;
  wire                              dfi_odt;
  wire                              dfi_wrdata_en;
  wire         [DFI_DATA_WIDTH-1:0] dfi_wrdata;
  wire    [(DFI_DATA_WIDTH>>3)-1:0] dfi_wrdata_mask;
  wire                              dfi_rddata_en;
  wire         [DFI_DATA_WIDTH-1:0] dfi_rddata;
  wire                              dfi_rddata_valid;
/*
  reg                        [31:0] slv_reg0;
  reg                        [31:0] slv_reg1;
  reg                        [31:0] slv_reg2;
  reg                        [31:0] slv_reg3;
  reg                        [31:0] slv_reg4;
  reg                        [31:0] slv_reg5;
  reg                        [31:0] slv_reg6;
  reg                        [31:0] slv_reg7;
  reg                        [31:0] slv_reg8;
  reg                        [31:0] slv_reg9;
  reg                        [31:0] slv_reg10;
  reg                        [31:0] slv_reg11;
  reg                        [31:0] slv_reg12;
  reg                        [31:0] slv_reg13;
  reg                        [31:0] slv_reg14;
  reg                        [31:0] slv_reg15;
*/

  wire    [(DFI_DATA_WIDTH>>4)-1:0] ddr_dqs_90;
  wire    [(DFI_DATA_WIDTH>>4)-1:0] ddr_dqs_270;

  //initial begin
  localparam slv_reg0  = 0;
  localparam slv_reg1  = 1;
  localparam slv_reg2  = 15;
  localparam slv_reg3  = 2;
  localparam slv_reg4  = 7;
  localparam slv_reg5  = 1;
  localparam slv_reg6  = 2;
  localparam slv_reg7  = 7;
  localparam slv_reg8  = 3;
  localparam slv_reg9  = 7;
  localparam slv_reg10 = 3;
  localparam slv_reg11 = 3;
  localparam slv_reg12 = 1023;
  localparam slv_reg13 = 1;
  localparam slv_reg14 = 'h25;
  localparam slv_reg15 = 'h2eb;
  //end

/*
  genvar                            i;

  generate
    for(i=0;i<(DFI_DATA_WIDTH>>1);i=i+1) begin: dq
      IOBUF #(
        .DRIVE(12),             // Specify the output drive strength
        .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
        .IOSTANDARD("DEFAULT"), // Specify the I/O standard
        .SLEW("SLOW")           // Specify the output slew rate
      ) IOBUF_inst (
        .O(dq_i[i]),            // Buffer output
        .IO(ddr_dq[i]),         // Buffer inout port (connect directly to top-level port)
        .I(dq_o[i]),            // Buffer input
        .T(dq_oe_n[i])          // 3-state enable input, high=input, low=output
      );
    end
  endgenerate

  generate
    for(i=0;i<(DFI_DATA_WIDTH>>4);i=i+1) begin: dm
      IOBUF #(
        .DRIVE(12),             // Specify the output drive strength
        .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
        .IOSTANDARD("DEFAULT"), // Specify the I/O standard
        .SLEW("SLOW")           // Specify the output slew rate
      ) IOBUF_inst (
        .O(),                   // Buffer output
        .IO(ddr_dm[i]),         // Buffer inout port (connect directly to top-level port)
        .I(dm_o[i]),            // Buffer input
        .T(dm_oe_n[i])          // 3-state enable input, high=input, low=output
      );
    end
  endgenerate

  generate
    for(i=0;i<(DFI_DATA_WIDTH>>4);i=i+1) begin: dqs
      IOBUF #(
        .DRIVE(12),             // Specify the output drive strength
        .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
        .IOSTANDARD("DEFAULT"), // Specify the I/O standard
        .SLEW("SLOW")           // Specify the output slew rate
      ) IOBUF_inst_p (
        .O(dqs_p_i[i]),         // Buffer output
        .IO(ddr_dqs_p[i]),      // Buffer inout port (connect directly to top-level port)
        .I(dqs_p_o[i]),         // Buffer input
        .T(dqs_p_oe_n[i])       // 3-state enable input, high=input, low=output
      );
      IOBUF #(
        .DRIVE(12),             // Specify the output drive strength
        .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
        .IOSTANDARD("DEFAULT"), // Specify the I/O standard
        .SLEW("SLOW")           // Specify the output slew rate
      ) IOBUF_inst_n (
        .O(dqs_n_i[i]),         // Buffer output
        .IO(ddr_dqs_n[i]),      // Buffer inout port (connect directly to top-level port)
        .I(dqs_n_o[i]),         // Buffer input
        .T(dqs_n_oe_n[i])       // 3-state enable input, high=input, low=output
      );
    end
  endgenerate
*/
`ifdef XILINX
  clock_generator clock_generator
    (.sys_rst    (sys_rst)
    ,.clk_ref_p  (clk_ref_p)
    ,.clk_ref_n  (clk_ref_n)
    ,.locked     (locked)
    ,.ui_clk     (ui_clk)
    ,.dfi_clk_2x (dfi_clk_2x)
    ,.dfi_clk    (dfi_clk));

  always @(posedge ui_clk or negedge sys_rst)
    if(!sys_rst)
      {ui_reset, ui_reset_sync} <= 2'b11;
    else
      {ui_reset, ui_reset_sync} <= {ui_reset_sync, ~locked};

  assign ui_clk_sync_rst = ui_reset;

  always @(posedge dfi_clk or negedge sys_rst)
    if(!sys_rst)
      {dfi_reset, dfi_reset_sync} <= 2'b11;
    else
      {dfi_reset, dfi_reset_sync} <= {dfi_reset_sync, ~locked};
`else
  always @(posedge ui_clk or negedge sys_rst)
    if(!sys_rst)
      {ui_reset, ui_reset_sync} <= 2'b11;
    else
      {ui_reset, ui_reset_sync} <= {ui_reset_sync, 1'b0};

  assign ui_clk_sync_rst = ui_reset;

  always @(posedge dfi_clk or negedge sys_rst)
    if(!sys_rst)
      {dfi_reset, dfi_reset_sync} <= 2'b11;
    else
      {dfi_reset, dfi_reset_sync} <= {dfi_reset_sync, 1'b0};
`endif

  bsg_dmc_controller #
    (.UI_ADDR_WIDTH     (UI_ADDR_WIDTH)
    ,.UI_DATA_WIDTH     (UI_DATA_WIDTH)
    ,.DFI_DATA_WIDTH    (DFI_DATA_WIDTH))
  dmc_controller
    // User interface clock and reset
    (.ui_clk            ( ui_clk            )
    ,.ui_clk_sync_rst   ( ui_reset          )
    // User interface signals
    ,.app_addr          ( app_addr          )
    ,.app_cmd           ( app_cmd           )
    ,.app_en            ( app_en            )
    ,.app_rdy           ( app_rdy           )
    ,.app_wdf_wren      ( app_wdf_wren      )
    ,.app_wdf_data      ( app_wdf_data      )
    ,.app_wdf_mask      ( app_wdf_mask      )
    ,.app_wdf_end       ( app_wdf_end       )
    ,.app_wdf_rdy       ( app_wdf_rdy       )
    ,.app_rd_data_valid ( app_rd_data_valid )
    ,.app_rd_data       ( app_rd_data       )
    ,.app_rd_data_end   ( app_rd_data_end   )
    ,.app_ref_req       ( app_ref_req       )
    ,.app_ref_ack       ( app_ref_ack       )
    ,.app_zq_req        ( app_zq_req        )
    ,.app_zq_ack        ( app_zq_ack        )
    ,.app_sr_req        ( app_sr_req        )
    ,.app_sr_active     ( app_sr_active     )
    // DDR PHY interface clock and reset
    ,.dfi_clk           ( dfi_clk           )
    ,.dfi_clk_2x        ( dfi_clk_2x        )
    ,.dfi_clk_sync_rst  ( dfi_reset         )
    // DDR PHY interface signals
    ,.dfi_bank          ( dfi_bank          )
    ,.dfi_address       ( dfi_address       )
    ,.dfi_cke           ( dfi_cke           )
    ,.dfi_cs_n          ( dfi_cs_n          )
    ,.dfi_ras_n         ( dfi_ras_n         )
    ,.dfi_cas_n         ( dfi_cas_n         )
    ,.dfi_we_n          ( dfi_we_n          )
    ,.dfi_reset_n       ( dfi_reset_n       )
    ,.dfi_odt           ( dfi_odt           )
    ,.dfi_wrdata_en     ( dfi_wrdata_en     )
    ,.dfi_wrdata        ( dfi_wrdata        )
    ,.dfi_wrdata_mask   ( dfi_wrdata_mask   )
    ,.dfi_rddata_en     ( dfi_rddata_en     )
    ,.dfi_rddata        ( dfi_rddata        )
    ,.dfi_rddata_valid  ( dfi_rddata_valid  )
    // Control and Status Registers
    ,.slv_reg0          ( slv_reg0          )
    ,.slv_reg1          ( slv_reg1          )
    ,.slv_reg2          ( slv_reg2          )
    ,.slv_reg3          ( slv_reg3          )
    ,.slv_reg4          ( slv_reg4          )
    ,.slv_reg5          ( slv_reg5          )
    ,.slv_reg6          ( slv_reg6          )
    ,.slv_reg7          ( slv_reg7          )
    ,.slv_reg8          ( slv_reg8          )
    ,.slv_reg9          ( slv_reg9          )
    ,.slv_reg10         ( slv_reg10         )
    ,.slv_reg11         ( slv_reg11         )
    ,.slv_reg12         ( slv_reg12         )
    ,.slv_reg13         ( slv_reg13         )
    ,.slv_reg14         ( slv_reg14         )
    ,.slv_reg15         ( slv_reg15         )
    //
    ,.init_calib_complete (init_calib_complete )
    );

  bsg_dmc_phy #(.DQ_GROUP(DQ_GROUP)) dmc_phy
    // DDR PHY interface clock and reset
    (.dfi_clk           ( dfi_clk           )
    ,.dfi_clk_2x        ( dfi_clk_2x        )
    ,.dfi_rst           ( dfi_reset         )
    //
    ,.dfi_bank          ( dfi_bank          )
    ,.dfi_address       ( dfi_address       )
    ,.dfi_cke           ( dfi_cke           )
    ,.dfi_cs_n          ( dfi_cs_n          )
    ,.dfi_ras_n         ( dfi_ras_n         )
    ,.dfi_cas_n         ( dfi_cas_n         )
    ,.dfi_we_n          ( dfi_we_n          )
    ,.dfi_reset_n       ( dfi_reset_n       )
    ,.dfi_odt           ( dfi_odt           )
    ,.dfi_wrdata_en     ( dfi_wrdata_en     )
    ,.dfi_wrdata        ( dfi_wrdata        )
    ,.dfi_wrdata_mask   ( dfi_wrdata_mask   )
    ,.dfi_rddata_en     ( dfi_rddata_en     )
    ,.dfi_rddata        ( dfi_rddata        )
    ,.dfi_rddata_valid  ( dfi_rddata_valid  )
    //
    ,.locked            (                   )
    //
    ,.ck_p              ( ddr_ck_p_o          )
    ,.ck_n              ( ddr_ck_n_o          )
    ,.cke               ( ddr_cke_o           )
    ,.ba                ( ddr_ba_o            )
    ,.a                 ( ddr_addr_o          )
    ,.cs_n              ( ddr_cs_n_o          )
    ,.ras_n             ( ddr_ras_n_o         )
    ,.cas_n             ( ddr_cas_n_o         )
    ,.we_n              ( ddr_we_n_o          )
    ,.reset             ( ddr_reset_n_o       )
    ,.odt               ( ddr_odt_o           )
    ,.dm_oe_n           ( ddr_dm_oen_o        )
    ,.dm_o              ( ddr_dm_o            )
    ,.dqs_p_oe_n        ( ddr_dqs_p_oen_o     )
    ,.dqs_p_ie_n        ( ddr_dqs_p_ien_o     )
    ,.dqs_p_o           ( ddr_dqs_p_o         )
    ,.dqs_p_i           ( ddr_dqs_90          )
    ,.dqs_n_oe_n        ( ddr_dqs_n_oen_o     )
    ,.dqs_n_ie_n        ( ddr_dqs_n_ien_o     )
    ,.dqs_n_o           ( ddr_dqs_n_o         )
    ,.dqs_n_i           ( ddr_dqs_270         )
    ,.dq_oe_n           ( ddr_dq_oen_o        )
    ,.dq_o              ( ddr_dq_o            )
    ,.dq_i              ( ddr_dq_i            ));

  assign #1 ddr_dqs_90 = ddr_dqs_p_i;
  assign #1 ddr_dqs_270 = ~ddr_dqs_p_i;

endmodule
