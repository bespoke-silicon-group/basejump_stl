`include "bsg_defines.v"

`ifndef rp_group
 `define rp_group(x)
 `define rp_place(x)
 `define rp_endgroup(x)
 `define rp_fill(x)
 `define rp_array_dir(up)
`endif

module bsg_dmc_phy_tx_bit_slice
  (input        clk_2x_i
  ,input        wrdata_en_90_i
  ,input  [1:0] wrdata_90_i
  ,output logic dq_o
  ,output logic dq_oe_n_o);

  wire clk_2x_n = ~clk_2x_i;
  logic odd;

  always_ff @(posedge clk_2x_n) begin
    if(wrdata_en_90_i) begin
      odd <= ~odd;
      if(odd) begin
        dq_o <= wrdata_90_i[1];
      end
      else begin
        dq_o <= wrdata_90_i[0];
      end
      dq_oe_n_o <= 1'b0;
    end
    else begin
      odd <= 1'b0;
      dq_oe_n_o <= 1'b1;
    end
  end

endmodule

module bsg_dmc_phy_rx_bit_slice
  (input        clk_1x_i
  ,input  [1:0] write_pointer_i
  ,input  [1:0] read_pointer_i
  ,input        dq_i
  ,input        dqs_p_i
  ,input        dqs_n_i
  ,output logic rddata_even_o
  ,output logic rddata_odd_o);

  `rp_group (rpg) 
  `rp_place (hier rpg_even 0 0) 
  `rp_place (hier rpg_odd 1 0) 
  `rp_endgroup (rpg) 

  logic [3:0] data_even, data_odd;
  wire        data_even_mux, data_odd_mux;

  always_ff @(posedge dqs_p_i) begin
    `rp_group (rpg_even) 
    `rp_fill (0 0 UX) 
    `rp_array_dir (up) 
    `rp_endgroup (rpg_even) 
    data_even[write_pointer_i] <= dq_i;
  end

  always_ff @(posedge dqs_n_i) begin
    `rp_group (rpg_odd) 
    `rp_fill (0 0 UX) 
    `rp_array_dir (up) 
    `rp_endgroup (rpg_odd) 
    data_odd[write_pointer_i] <= dq_i;
  end

  assign data_even_mux = data_even[read_pointer_i];
  assign data_odd_mux  = data_odd[read_pointer_i];

  always_ff @(posedge clk_1x_i) begin
    rddata_even_o <= data_even_mux;
    rddata_odd_o  <= data_odd_mux;
  end

endmodule

module bsg_dmc_phy_bit_slice
  (input        clk_1x_i
  ,input        clk_2x_i
  ,input        dqs_p_i
  ,input        dqs_n_i
  ,input        wrdata_en_90_i
  ,input  [1:0] wrdata_90_i
  ,output       dq_o
  ,output       dq_oe_n_o
  ,input        dq_i
  ,input  [1:0] write_pointer_i
  ,input  [1:0] read_pointer_i
  ,output       rddata_even_o
  ,output       rddata_odd_o);

  bsg_dmc_phy_tx_bit_slice tx_bit_slice
    (.clk_2x_i       ( clk_2x_i       )
    ,.wrdata_en_90_i ( wrdata_en_90_i )
    ,.wrdata_90_i    ( wrdata_90_i    )
    ,.dq_o           ( dq_o           )
    ,.dq_oe_n_o      ( dq_oe_n_o      ));

  bsg_dmc_phy_rx_bit_slice rx_bit_slice
    (.clk_1x_i        ( clk_1x_i        )
    ,.write_pointer_i ( write_pointer_i )
    ,.read_pointer_i  ( read_pointer_i  )
    ,.dq_i            ( dq_i            )
    ,.dqs_p_i         ( dqs_p_i         )
    ,.dqs_n_i         ( dqs_n_i         )
    ,.rddata_even_o   ( rddata_even_o   )
    ,.rddata_odd_o    ( rddata_odd_o    ));

endmodule

module bsg_dmc_phy_byte_lane
  (input         reset_i
  ,input         clk_1x_i
  ,input         clk_2x_i
  ,input         wrdata_en_i
  ,input  [15:0] wrdata_i
  ,input   [1:0] wrdata_mask_i
  ,output        dm_oe_n_o
  ,output        dm_o
  ,output  [7:0] dq_oe_n_o
  ,output  [7:0] dq_o
  ,output logic  dqs_p_oe_n_o
  ,output logic  dqs_p_o
  ,output logic  dqs_n_oe_n_o
  ,output logic  dqs_n_o
  ,input         rp_inc_i
  ,output [15:0] rddata_o
  ,input   [7:0] dq_i
  ,input         dqs_p_i
  ,input         dqs_n_i
);

  wire clk_1x_p = clk_1x_i;
  wire clk_2x_p = clk_2x_i;
  wire clk_2x_n = ~clk_2x_i;

  logic        wrdata_en_90, wrdata_en_180;
  logic [15:0] wrdata_90, wrdata_180;
  logic  [1:0] wrdata_mask_90, wrdata_mask_180;

  logic  [1:0] write_pointer, read_pointer;

  genvar i;

  always_ff @(posedge clk_2x_n) begin
    wrdata_en_90 <= wrdata_en_i;
    wrdata_90 <= wrdata_i;
    wrdata_mask_90 <= wrdata_mask_i;
  end

  always_ff @(posedge clk_2x_p) begin
    wrdata_en_180 <= wrdata_en_i;
  end

  always_ff @(posedge clk_2x_p) begin
    dqs_p_oe_n_o <= ~(wrdata_en_i | wrdata_en_180);
    dqs_n_oe_n_o <= ~(wrdata_en_i | wrdata_en_180);
  end

  always_ff @(posedge clk_2x_p) begin
    if(wrdata_en_i || wrdata_en_180) begin
      dqs_p_o <= ~dqs_p_o;
      dqs_n_o <= ~dqs_n_o;
    end
    else begin
      dqs_p_o <= 1'b1;
      dqs_n_o <= 1'b0;
    end
  end

  always_ff @(posedge dqs_n_i or posedge reset_i) begin
    if(reset_i)
      write_pointer <= 'b0;
    else
      write_pointer <= write_pointer + 1'b1;
  end

  always_ff @(posedge clk_1x_p) begin
    if(reset_i)
      read_pointer <= 'b0;
    else if(rp_inc_i)
      read_pointer <= read_pointer + 1'b1;
  end

  for(i=0;i<8;i++) begin: bs
    bsg_dmc_phy_bit_slice dq_bit_slice
      (.clk_1x_i        ( clk_1x_i      )
      ,.clk_2x_i        ( clk_2x_i      )
      ,.dqs_p_i         ( dqs_p_i       )
      ,.dqs_n_i         ( dqs_n_i       )
      ,.wrdata_en_90_i  ( wrdata_en_90  )
      ,.wrdata_90_i     ( {wrdata_90[8+i], wrdata_90[i]} )
      ,.dq_o            ( dq_o[i]       )
      ,.dq_oe_n_o       ( dq_oe_n_o[i]  )
      ,.dq_i            ( dq_i[i]       )
      ,.write_pointer_i ( write_pointer )
      ,.read_pointer_i  ( read_pointer  )
      ,.rddata_even_o   ( rddata_o[i]   )
      ,.rddata_odd_o    ( rddata_o[8+i] ));
  end

  bsg_dmc_phy_tx_bit_slice dm_bit_slice
    (.clk_2x_i       ( clk_2x_i       )
    ,.wrdata_en_90_i ( wrdata_en_90   )
    ,.wrdata_90_i    ( wrdata_mask_90 )
    ,.dq_o           ( dm_o           )
    ,.dq_oe_n_o      ( dm_oe_n_o      ));

endmodule

/**
 *  bsg_dmc_phy.v
 *
 *  - DFI compatible.
 *  - 16-bit address, 32-bit data to off-chip DRAM devices.
 *  - organized as multiple byte lanes.
 *  - reconfigurable time window for input dqs enable
 *
 *  @author Chun
 */

module bsg_dmc_phy #
  (parameter  dq_data_width_p = "inv"
  ,localparam dq_group_lp     = dq_data_width_p >> 3)
  // dfi interface signals
  (input                          dfi_clk_1x_i
  ,input                          dfi_clk_2x_i
  ,input                          dfi_rst_i
  ,input                    [2:0] dfi_bank_i
  ,input                   [15:0] dfi_address_i
  ,input                          dfi_cke_i
  ,input                          dfi_cs_n_i
  ,input                          dfi_ras_n_i
  ,input                          dfi_cas_n_i
  ,input                          dfi_we_n_i
  ,input                          dfi_reset_n_i
  ,input                          dfi_odt_i
  ,input                          dfi_wrdata_en_i
  ,input  [2*dq_data_width_p-1:0] dfi_wrdata_i
  ,input      [2*dq_group_lp-1:0] dfi_wrdata_mask_i
  ,input                          dfi_rddata_en_i
  ,output [2*dq_data_width_p-1:0] dfi_rddata_o
  ,output logic                   dfi_rddata_valid_o
  // dram interface signals
  ,output                         ck_p_o
  ,output                         ck_n_o
  ,output logic                   cke_o
  ,output logic             [2:0] ba_o
  ,output logic            [15:0] a_o
  ,output logic                   cs_n_o
  ,output logic                   ras_n_o
  ,output logic                   cas_n_o
  ,output logic                   we_n_o
  ,output logic                   reset_o
  ,output logic                   odt_o
  ,output       [dq_group_lp-1:0] dm_oe_n_o
  ,output       [dq_group_lp-1:0] dm_o
  ,output       [dq_group_lp-1:0] dqs_p_oe_n_o
  ,output       [dq_group_lp-1:0] dqs_p_ie_n_o
  ,output       [dq_group_lp-1:0] dqs_p_o
  ,input        [dq_group_lp-1:0] dqs_p_i
  ,output       [dq_group_lp-1:0] dqs_n_oe_n_o
  ,output       [dq_group_lp-1:0] dqs_n_ie_n_o
  ,output       [dq_group_lp-1:0] dqs_n_o
  ,input        [dq_group_lp-1:0] dqs_n_i
  ,output     [8*dq_group_lp-1:0] dq_oe_n_o
  ,output     [8*dq_group_lp-1:0] dq_o
  ,input      [8*dq_group_lp-1:0] dq_i
  // input dqs enable calibration signal (4 taps)
  ,input                    [2:0] dqs_sel_cal);

  wire clk_1x_p = dfi_clk_1x_i;
  wire clk_1x_n = ~dfi_clk_1x_i;
  wire clk_2x_p = dfi_clk_2x_i;
  wire clk_2x_n = ~dfi_clk_2x_i;

  logic        [7:0][0:0] rddata_en;
  logic                   dqs_select;
  logic                   rp_inc;

  logic [dq_group_lp-1:0] dqs_p_ie_n;
  logic [dq_group_lp-1:0] dqs_n_ie_n;

  genvar i;

  always_ff @(posedge clk_1x_n) begin
    if(dfi_rst_i) begin
      cke_o   <= 1'b0;
      ba_o    <= 3'b000;
      a_o     <= 16'h0;
      cs_n_o  <= 1'b1;
      ras_n_o <= 1'b1;
      cas_n_o <= 1'b1;
      we_n_o  <= 1'b1;
      reset_o <= 1'b1;
      odt_o   <= 1'b0;
    end
    else begin
      cke_o   <= dfi_cke_i;
      ba_o    <= dfi_bank_i;
      a_o     <= dfi_address_i;
      cs_n_o  <= dfi_cs_n_i;
      ras_n_o <= dfi_ras_n_i;
      cas_n_o <= dfi_cas_n_i;
      we_n_o  <= dfi_we_n_i;
      reset_o <= dfi_reset_n_i;
      odt_o   <= dfi_odt_i;
    end
  end

  assign rddata_en[0] = dfi_rddata_en_i;

  always_ff @(posedge clk_2x_n) begin
    if(dfi_rst_i) begin
      rddata_en[1] <= 1'b0;
      rddata_en[3] <= 1'b0;
      rddata_en[5] <= 1'b0;
      rddata_en[7] <= 1'b0;
    end
    else begin
      rddata_en[1] <= rddata_en[0];
      rddata_en[3] <= rddata_en[2];
      rddata_en[5] <= rddata_en[4];
      rddata_en[7] <= rddata_en[6];
    end
  end

  always_ff @(posedge clk_2x_p) begin
    if(dfi_rst_i) begin
      rddata_en[2] <= 1'b0;
      rddata_en[4] <= 1'b0;
      rddata_en[6] <= 1'b0;
    end
    else begin
      rddata_en[2] <= rddata_en[1];
      rddata_en[4] <= rddata_en[3];
      rddata_en[6] <= rddata_en[5];
    end
  end

  always_ff @(posedge clk_1x_p) begin
    if(dfi_rst_i)
      rp_inc <= 1'b0;
    else
      rp_inc <= dqs_select;
  end

  bsg_mux #
    (.width_p ( 1 )
    ,.els_p   ( 8 ))
  mux
    (.data_i  ( rddata_en   )
    ,.sel_i   ( dqs_sel_cal )
    ,.data_o  ( dqs_select  ));

  always_ff @(posedge clk_1x_p) begin
    if(dfi_rst_i)
      dfi_rddata_valid_o <= 1'b0;
    else
      dfi_rddata_valid_o <= rp_inc;
  end

  assign ck_p_o = clk_1x_p;
  assign ck_n_o = clk_1x_n;

  assign dqs_p_ie_n = ~{dq_group_lp{dqs_select}};
  assign dqs_n_ie_n = ~{dq_group_lp{dqs_select}};

  assign dqs_p_ie_n_o = dqs_p_ie_n;
  assign dqs_n_ie_n_o = dqs_n_ie_n;

  logic [7:0] dfi_wrdata_array [((dq_data_width_p>>3)<<1)-1:0];
  logic [7:0] dfi_rddata_array [((dq_data_width_p>>3)<<1)-1:0];

  bsg_make_2D_array #
    (.width_p (8)
    ,.items_p ((dq_data_width_p>>3)<<1))
  wrdata_array
    (.i       (dfi_wrdata_i)
    ,.o       (dfi_wrdata_array));

  bsg_flatten_2D_array #
    (.width_p (8)
    ,.items_p ((dq_data_width_p>>3)<<1))
  rddata_array
    (.i       (dfi_rddata_array)
    ,.o       (dfi_rddata_o));

  for(i=0;i<dq_group_lp;i=i+1) begin: lane
    bsg_dmc_phy_byte_lane byte_lane
      (.reset_i       ( dfi_rst_i                                                )
      ,.clk_1x_i      ( clk_1x_p                                                 )
      ,.clk_2x_i      ( clk_2x_p                                                 )
      ,.wrdata_en_i   ( dfi_wrdata_en_i                                          )
      ,.wrdata_i      ( {dfi_wrdata_array[dq_group_lp+i], dfi_wrdata_array[i]}   )
      ,.wrdata_mask_i ( {dfi_wrdata_mask_i[dq_group_lp+i], dfi_wrdata_mask_i[i]} )
      ,.dm_oe_n_o     ( dm_oe_n_o[i]                                             )
      ,.dm_o          ( dm_o[i]                                                  )
      ,.dq_oe_n_o     ( dq_oe_n_o[8*i+:8]                                        )
      ,.dq_o          ( dq_o[8*i+:8]                                             )
      ,.dqs_p_oe_n_o  ( dqs_p_oe_n_o[i]                                          )
      ,.dqs_p_o       ( dqs_p_o[i]                                               )
      ,.dqs_n_oe_n_o  ( dqs_n_oe_n_o[i]                                          )
      ,.dqs_n_o       ( dqs_n_o[i]                                               )
      ,.rp_inc_i      ( rp_inc                                                   )
      ,.rddata_o      ( {dfi_rddata_array[dq_group_lp+i], dfi_rddata_array[i]}   )
      ,.dq_i          ( dq_i[8*i+:8]                                             )
      ,.dqs_p_i       ( dqs_p_i[i]                                               )
      ,.dqs_n_i       ( dqs_n_i[i]                                               ));
  end

endmodule
