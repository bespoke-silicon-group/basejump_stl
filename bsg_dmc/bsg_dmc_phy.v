`ifndef rp_group
 `define rp_group(x)
 `define rp_place(x)
 `define rp_endgroup(x)
 `define rp_fill(x)
 `define rp_array_dir(up)
`endif
module bsg_dmc_phy_tx_bit_slice
  (input        clk_2x_n
  ,input        wrdata_en_90
  ,input  [1:0] wrdata_90
  ,output logic dq_o
  ,output logic dq_oe_n);
  logic odd;
  always @(posedge clk_2x_n) begin
    if(wrdata_en_90) begin
      odd <= ~odd;
      if(odd) begin
        dq_o <= wrdata_90[1];
      end
      else begin
        dq_o <= wrdata_90[0];
      end
      dq_oe_n <= 1'b0;
    end
    else begin
      odd <= 1'b0;
      dq_oe_n <= 1'b1;
    end
  end
endmodule

module bsg_dmc_phy_rx_bit_slice
  (input        clk
  ,input  [1:0] write_pointer
  ,input  [1:0] read_pointer
  ,input        dq_i
  ,input        dqs_p
  ,input        dqs_n
  ,output logic rddata_even
  ,output logic rddata_odd);

  `rp_group (rpg) 
  `rp_place (hier rpg_even 0 0) 
  `rp_place (hier rpg_odd 1 0) 
  `rp_endgroup (rpg) 

  logic [3:0] data_even, data_odd;
  wire        data_even_mux, data_odd_mux;

  always @(posedge dqs_p) begin
    `rp_group (rpg_even) 
    `rp_fill (0 0 UX) 
    `rp_array_dir (up) 
    `rp_endgroup (rpg_even) 
    data_even[write_pointer] <= dq_i;
  end

  always @(posedge dqs_n) begin
    `rp_group (rpg_odd) 
    `rp_fill (0 0 UX) 
    `rp_array_dir (up) 
    `rp_endgroup (rpg_odd) 
    data_odd[write_pointer] <= dq_i;
  end

  assign data_even_mux = data_even[read_pointer];
  assign data_odd_mux  = data_odd[read_pointer];

  always @(posedge clk) begin
    rddata_even <= data_even_mux;
    rddata_odd  <= data_odd_mux;
  end

endmodule

module bsg_dmc_phy_bit_slice
  (input        clk
  ,input        clk_2x_n
  ,input        dqs_p
  ,input        dqs_n
  ,input        wrdata_en_90
  ,input  [1:0] wrdata_90
  ,output logic dq_o
  ,output logic dq_oe_n
  ,input        dq_i
  ,input  [1:0] write_pointer
  ,input  [1:0] read_pointer
  ,output logic rddata_even
  ,output logic rddata_odd);

  bsg_dmc_phy_tx_bit_slice tx_bit_slice
    (.clk_2x_n      ( clk_2x_n      )
    ,.wrdata_en_90  ( wrdata_en_90  )
    ,.wrdata_90     ( wrdata_90     )
    ,.dq_o          ( dq_o          )
    ,.dq_oe_n       ( dq_oe_n       ));

  bsg_dmc_phy_rx_bit_slice rx_bit_slice
    (.clk           ( clk           )
    ,.write_pointer ( write_pointer )
    ,.read_pointer  ( read_pointer  )
    ,.dq_i          ( dq_i          )
    ,.dqs_p         ( dqs_p         )
    ,.dqs_n         ( dqs_n         )
    ,.rddata_even   ( rddata_even   )
    ,.rddata_odd    ( rddata_odd    ));

endmodule

module tx_byte_slice
  (input              clk_2x
  ,input              clk_2x_n
  ,input              wrdata_en
  ,input       [15:0] wrdata
  ,input        [1:0] wrdata_mask
  ,output logic       dm_oe_n
  ,output logic       dm_o
  ,output logic [7:0] dq_oe_n
  ,output logic [7:0] dq_o
  ,output logic       dqs_p_oe_n
  ,output logic       dqs_p_o
  ,output logic       dqs_n_oe_n
  ,output logic       dqs_n_o
);

  logic            wrdata_en_90, wrdata_en_180, wrdata_en_270, wrdata_en_360;
  logic     [15:0] wrdata_90, wrdata_180, wrdata_270;
  logic      [1:0] wrdata_mask_90, wrdata_mask_180, wrdata_mask_270;
  logic            odd;

  always @(posedge clk_2x_n) begin
    wrdata_en_90 <= wrdata_en;
    wrdata_90 <= wrdata;
    wrdata_mask_90 <= wrdata_mask;
  end

  always @(posedge clk_2x)
    wrdata_en_180 <= wrdata_en;

  always @(posedge clk_2x) begin
    dqs_p_oe_n <= ~(wrdata_en | wrdata_en_180);
    dqs_n_oe_n <= ~(wrdata_en | wrdata_en_180);
  end

  always @(posedge clk_2x)
    if(wrdata_en || wrdata_en_180) begin
      dqs_p_o <= ~dqs_p_o;
      dqs_n_o <= ~dqs_n_o;
    end
    else begin
      dqs_p_o <= 1'b1;
      dqs_n_o <= 1'b0;
    end

  always @(posedge clk_2x_n) begin
    if(wrdata_en_90) begin
      odd <= ~odd;
      if(odd) begin
        dq_o <= wrdata_90[15:8];
        dm_o <= wrdata_mask_90[1];
      end
      else begin
        dq_o <= wrdata_90[7:0];
        dm_o <= wrdata_mask_90[0];
      end
      dq_oe_n <= 8'h0;
      dm_oe_n <= 1'b0;
    end
    else begin
      odd <= 1'b0;
      dq_oe_n <= 8'hff;
      dm_oe_n <= 1'b1;
    end
  end

endmodule

module rx_byte_slice
  (input         reset
  ,input         clk
  ,input         dqs_select
  ,input         rp_inc
  ,output [15:0] rddata
  ,input   [7:0] dq_i
  ,input         dqs_p_i
  ,input         dqs_n_i);

  logic          dqs_p, dqs_n;

  logic    [1:0] write_pointer, read_pointer;

  genvar i;

  assign dqs_p = dqs_select? dqs_p_i: 1'b0;
  assign dqs_n = dqs_select? dqs_n_i: 1'b1;

  generate
    for(i=0;i<8;i=i+1) begin: one_bit
      bsg_dmc_phy_rx_bit_slice rx_bit_slice
       (.clk            ( clk           )
       ,.write_pointer  ( write_pointer )
       ,.read_pointer   ( read_pointer  )
       ,.dq_i           ( dq_i[i]       )
       ,.dqs_p          ( dqs_p         )
       ,.dqs_n          ( dqs_n         )
       ,.rddata_even    ( rddata[i]     )
       ,.rddata_odd     ( rddata[i+8]   )
      );
    end
  endgenerate

  always @(posedge dqs_n or posedge reset)
    if(reset)
      write_pointer <= 'b0;
    else
      write_pointer <= write_pointer + 1'b1;

  always @(posedge clk)
    if(reset)
      read_pointer <= 'b0;
    else if(rp_inc)
      read_pointer <= read_pointer + 1'b1;

endmodule

module byte_slice
  (input         reset
  ,input         clk
  ,input         clk_2x
  ,input         clk_2x_n
  ,input         wrdata_en
  ,input  [15:0] wrdata
  ,input   [1:0] wrdata_mask
  ,output        dm_oe_n
  ,output        dm_o
  ,output  [7:0] dq_oe_n
  ,output  [7:0] dq_o
  ,output logic  dqs_p_oe_n
  ,output logic  dqs_p_o
  ,output logic  dqs_n_oe_n
  ,output logic  dqs_n_o
  ,input         dqs_select
  ,input         rp_inc
  ,output [15:0] rddata
  ,input   [7:0] dq_i
  ,input         dqs_p_i
  ,input         dqs_n_i
);

  logic          wrdata_en_90, wrdata_en_180;
  logic   [15:0] wrdata_90, wrdata_180;
  logic    [1:0] wrdata_mask_90, wrdata_mask_180;

  logic          dqs_p, dqs_n;
  logic    [1:0] write_pointer, read_pointer;

  genvar i;

  always @(posedge clk_2x_n) begin
    wrdata_en_90 <= wrdata_en;
    wrdata_90 <= wrdata;
    wrdata_mask_90 <= wrdata_mask;
  end

  always @(posedge clk_2x)
    wrdata_en_180 <= wrdata_en;

  always @(posedge clk_2x) begin
    dqs_p_oe_n <= ~(wrdata_en | wrdata_en_180);
    dqs_n_oe_n <= ~(wrdata_en | wrdata_en_180);
  end

  always @(posedge clk_2x)
    if(wrdata_en || wrdata_en_180) begin
      dqs_p_o <= ~dqs_p_o;
      dqs_n_o <= ~dqs_n_o;
    end
    else begin
      dqs_p_o <= 1'b1;
      dqs_n_o <= 1'b0;
    end

  assign dqs_p = dqs_select? dqs_p_i: 1'b0;
  assign dqs_n = dqs_select? dqs_n_i: 1'b1;

  always @(posedge dqs_n or posedge reset)
    if(reset)
      write_pointer <= 'b0;
    else
      write_pointer <= write_pointer + 1'b1;

  always @(posedge clk)
    if(reset)
      read_pointer <= 'b0;
    else if(rp_inc)
      read_pointer <= read_pointer + 1'b1;

  generate
    for(i=0;i<8;i++) begin: bs
      bsg_dmc_phy_bit_slice dq_bit_slice
        (.clk           ( clk           )
        ,.clk_2x_n      ( clk_2x_n      )
        ,.dqs_p         ( dqs_p         )
        ,.dqs_n         ( dqs_n         )
        ,.wrdata_en_90  ( wrdata_en_90  )
        ,.wrdata_90     ( {wrdata_90[8+i], wrdata_90[i]} )
        ,.dq_o          ( dq_o[i]       )
        ,.dq_oe_n       ( dq_oe_n[i]    )
        ,.dq_i          ( dq_i[i]       )
        ,.write_pointer ( write_pointer )
        ,.read_pointer  ( read_pointer  )
        ,.rddata_even   ( rddata[i]     )
        ,.rddata_odd    ( rddata[8+i]   ));
    end
  endgenerate

  bsg_dmc_phy_tx_bit_slice dm_bit_slice
    (.clk_2x_n      ( clk_2x_n       )
    ,.wrdata_en_90  ( wrdata_en_90   )
    ,.wrdata_90     ( wrdata_mask_90 )
    ,.dq_o          ( dm_o           )
    ,.dq_oe_n       ( dm_oe_n        ));

endmodule

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
  ,output reg                     dfi_rddata_valid_o
  // dram interface signals
  ,output                         ck_p_o
  ,output                         ck_n_o
  ,output reg                     cke_o
  ,output reg               [2:0] ba_o
  ,output reg              [15:0] a_o
  ,output reg                     cs_n_o
  ,output reg                     ras_n_o
  ,output reg                     cas_n_o
  ,output reg                     we_n_o
  ,output reg                     reset_o
  ,output reg                     odt_o
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
  ,input                    [1:0] dqs_sel_cal);

  logic                           clk_1x_0, clk_1x_180;
  logic                           clk_2x_0, clk_2x_180;

  logic                [3:0][0:0] rddata_en;
  logic                           dqs_select;
  logic                           rp_inc;

  genvar i;

  always @(posedge clk_1x_180) begin
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

  always @(posedge clk_2x_180)
    if(dfi_rst_i) begin
      rddata_en[1] <= 1'b0;
      rddata_en[3] <= 1'b0;
    end
    else begin
      rddata_en[1] <= rddata_en[0];
      rddata_en[3] <= rddata_en[2];
    end

  always @(posedge clk_2x_0)
    if(dfi_rst_i)
      rddata_en[2] <= 1'b0;
    else
      rddata_en[2] <= rddata_en[1];

  always @(posedge clk_1x_0)
    if(dfi_rst_i)
      rp_inc <= 1'b0;
    else
      rp_inc <= dqs_select;

  bsg_mux #
    (.width_p ( 1 )
    ,.els_p   ( 4 ))
  mux
    (.data_i  ( rddata_en   )
    ,.sel_i   ( dqs_sel_cal )
    ,.data_o  ( dqs_select  ));


  always @(posedge clk_1x_0)
    if(dfi_rst_i)
      dfi_rddata_valid_o <= 1'b0;
    else
      dfi_rddata_valid_o <= rp_inc;

  assign clk_2x_0   = dfi_clk_2x_i;
  assign clk_2x_180 = ~dfi_clk_2x_i;
  assign clk_1x_0   = dfi_clk_1x_i;
  assign clk_1x_180 = ~dfi_clk_1x_i;
  assign ck_p_o     = clk_1x_0;
  assign ck_n_o     = clk_1x_180;

  assign dqs_p_ie_n_o = ~{dq_group_lp{rddata_en[0] | dqs_select}};
  assign dqs_n_ie_n_o = ~{dq_group_lp{rddata_en[0] | dqs_select}};

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

  generate
    for(i=0;i<dq_group_lp;i=i+1) begin: one_byte
      byte_slice byte_slice
        (.reset       ( dfi_rst_i                                                )
        ,.clk         ( clk_1x_0                                                 )
        ,.clk_2x      ( clk_2x_0                                                 )
        ,.clk_2x_n    ( clk_2x_180                                               )
        ,.wrdata_en   ( dfi_wrdata_en_i                                          )
        ,.wrdata      ( {dfi_wrdata_array[dq_group_lp+i], dfi_wrdata_array[i]}   )
        ,.wrdata_mask ( {dfi_wrdata_mask_i[dq_group_lp+i], dfi_wrdata_mask_i[i]} )
        ,.dm_oe_n     ( dm_oe_n_o[i]                                             )
        ,.dm_o        ( dm_o[i]                                                  )
        ,.dq_oe_n     ( dq_oe_n_o[8*i+:8]                                        )
        ,.dq_o        ( dq_o[8*i+:8]                                             )
        ,.dqs_p_oe_n  ( dqs_p_oe_n_o[i]                                          )
        ,.dqs_p_o     ( dqs_p_o[i]                                               )
        ,.dqs_n_oe_n  ( dqs_n_oe_n_o[i]                                          )
        ,.dqs_n_o     ( dqs_n_o[i]                                               )
        ,.dqs_select  ( dqs_select                                               )
        ,.rp_inc      ( rp_inc                                                   )
        ,.rddata      ( {dfi_rddata_array[dq_group_lp+i], dfi_rddata_array[i]}   )
        ,.dq_i        ( dq_i[8*i+:8]                                             )
        ,.dqs_p_i     ( dqs_p_i[i]                                               )
        ,.dqs_n_i     ( dqs_n_i[i]                                               ));
    end
  endgenerate

endmodule
