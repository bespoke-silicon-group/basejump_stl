`define DQ_GROUP 2
//`define XILINX

module tx_bit_slice(
  input  reset,
  input  clk_0,
  input  clk_180,
  input  wrdata_en_even,
  input  wrdata_en_odd,
  input  wrdata_even,
  input  wrdata_odd,
  output dq_oe,
  output dq_o
);

  reg    wrdata_en_even_0, wrdata_en_odd_180;
  reg    wrdata_even_0, wrdata_odd_180;
  reg    sel_0, sel_180;
  wire   sel;

  always @(posedge clk_0) begin
    wrdata_en_even_0 <= wrdata_en_even;
    wrdata_even_0    <= wrdata_even;
  end

  always @(posedge clk_180) begin
    wrdata_en_odd_180 <= wrdata_en_odd;
    wrdata_odd_180    <= wrdata_odd;
  end

  // Johnson Counter
  always @(posedge clk_0)
    if(reset)
      sel_0 <= 1'b0;
    else
      sel_0 <= ~sel_180;

  always @(posedge clk_180)
    if(reset)
      sel_180 <= 1'b0;
    else
      sel_180 <= sel_0;

  assign sel = sel_0 ^ sel_180;

  // output 2:1 MUX
  assign dq_oe = sel? wrdata_en_even_0: wrdata_en_odd_180;
  assign dq_o  = sel? wrdata_even_0:    wrdata_odd_180;

endmodule

module rx_bit_slice (
  input       reset,
  input       clk,
  input [1:0] write_pointer,
  input [1:0] read_pointer,
  input       dq,
  input       dqs_p,
  input       dqs_n,
  output reg  rddata_even,
  output reg  rddata_odd
);

`ifdef XILINX
  (* KEEP = "TRUE" *) reg [3:0] data_even, data_odd;
`else
  reg   [3:0] data_even, data_odd;
`endif
  wire        data_even_mux, data_odd_mux;

  always @(posedge dqs_p)
    data_even[write_pointer] <= dq;

  always @(posedge dqs_n)
    data_odd[write_pointer] <= dq;

  assign data_even_mux = data_even[read_pointer];
  assign data_odd_mux  = data_odd[read_pointer];

  always @(posedge clk) begin
    rddata_even <= data_even_mux;
    rddata_odd  <= data_odd_mux;
  end

endmodule

module tx_byte_slice(
  input            reset,
  input            clk,
  input            clk_2x,
  input            wrdata_en,
  input     [15:0] wrdata,
  input      [1:0] wrdata_mask,
`ifdef XILINX
  (* KEEP = "TRUE" *) output reg       dm_oe_n,
  (* KEEP = "TRUE" *) output reg       dm_o,
  (* KEEP = "TRUE" *) output reg [7:0] dq_oe_n,
  (* KEEP = "TRUE" *) output reg [7:0] dq_o,
  (* KEEP = "TRUE" *) output reg       dqs_p_oe_n,
  (* KEEP = "TRUE" *) output reg       dqs_p_o,
  (* KEEP = "TRUE" *) output reg       dqs_n_oe_n,
  (* KEEP = "TRUE" *) output reg       dqs_n_o
`else
  output reg       dm_oe_n,
  output reg       dm_o,
  output reg [7:0] dq_oe_n,
  output reg [7:0] dq_o,
  output reg       dqs_p_oe_n,
  output reg       dqs_p_o,
  output reg       dqs_n_oe_n,
  output reg       dqs_n_o
`endif
);

  wire             clk_2x_n;
  reg              wrdata_en_90, wrdata_en_180, wrdata_en_270, wrdata_en_360;
  reg       [15:0] wrdata_90, wrdata_180, wrdata_270;
  reg        [1:0] wrdata_mask_90, wrdata_mask_180, wrdata_mask_270;
  reg              odd;

  assign clk_2x_n = ~clk_2x;

  always @(posedge clk_2x_n) begin
    wrdata_en_90 <= wrdata_en;
    wrdata_90 <= wrdata;
    wrdata_mask_90 <= wrdata_mask;
  end

  always @(posedge clk_2x)
    wrdata_en_180 <= wrdata_en;

  always @(posedge clk_2x)
    if(reset) begin
      dqs_p_oe_n <= 1'b1;
      dqs_n_oe_n <= 1'b1;
    end
    else begin
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
  ,input         rddata_en
  ,input         rp_inc
  ,output [15:0] rddata
  ,input   [7:0] dq_i
  ,input         dqs_p_i
  ,input         dqs_n_i
);

  wire           clk_180;
`ifdef XILINX
  (* KEEP = "TRUE" *) reg dqs_select;
`else
  reg            dqs_select;
`endif
  wire           dqs_p, dqs_n;

  reg      [1:0] write_pointer, read_pointer;

  genvar i;

  assign clk_180 = ~clk;

  always @(posedge clk_180)
    if(reset)
      dqs_select <= 1'b0;
    else
      dqs_select <= rddata_en;

  assign dqs_p = dqs_select? dqs_p_i: 1'b0;
  assign dqs_n = dqs_select? dqs_n_i: 1'b1;

  generate
    for(i=0;i<8;i=i+1) begin: one_bit
      rx_bit_slice rx_bit_slice(
        .reset          ( reset         ),
        .clk            ( clk           ),
        .write_pointer  ( write_pointer ),
        .read_pointer   ( read_pointer  ),
        .dq             ( dq_i[i]       ),
        .dqs_p          ( dqs_p         ),
        .dqs_n          ( dqs_n         ),
        .rddata_even    ( rddata[i]     ),
        .rddata_odd     ( rddata[i+8]   )
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

module byte_slice(
  input         reset,
  input         clk,
  input         clk_2x,
  input         wrdata_en,
  input  [15:0] wrdata,
  input   [1:0] wrdata_mask,
  output        dm_oe_n,
  output        dm_o,
  output  [7:0] dq_oe_n,
  output  [7:0] dq_o,
  output        dqs_p_oe_n,
  output        dqs_p_o,
  output        dqs_n_oe_n,
  output        dqs_n_o,
  input         rddata_en,
  input         rp_inc,
  output [15:0] rddata,
  input   [7:0] dq_i,
  input         dqs_p_i,
  input         dqs_n_i
);

  tx_byte_slice tx_byte_slice(
    .reset        ( reset        ),
    .clk          ( clk          ),
    .clk_2x       ( clk_2x       ),
    .wrdata_en    ( wrdata_en    ),
    .wrdata       ( wrdata       ),
    .wrdata_mask  ( wrdata_mask  ),
    .dm_oe_n      ( dm_oe_n      ),
    .dm_o         ( dm_o         ),
    .dq_oe_n      ( dq_oe_n      ),
    .dq_o         ( dq_o         ),
    .dqs_p_oe_n   ( dqs_p_oe_n   ),
    .dqs_p_o      ( dqs_p_o      ),
    .dqs_n_oe_n   ( dqs_n_oe_n   ),
    .dqs_n_o      ( dqs_n_o      )
  );

  rx_byte_slice rx_byte_slice(
    .reset        ( reset        ),
    .clk          ( clk          ),
    .rddata_en    ( rddata_en    ),
    .rp_inc       ( rp_inc       ),
    .rddata       ( rddata       ),
    .dq_i         ( dq_i         ),
    .dqs_p_i      ( dqs_p_i      ),
    .dqs_n_i      ( dqs_n_i      )
  );

endmodule

module dmc_phy(
  // dfi interface signals
  input                     dfi_clk,
  input                     dfi_clk_2x,
  input                     dfi_rst,
  input               [2:0] dfi_bank,
  input              [15:0] dfi_address,
  input                     dfi_cke,
  input                     dfi_cs_n,
  input                     dfi_ras_n,
  input                     dfi_cas_n,
  input                     dfi_we_n,
  input                     dfi_reset_n,
  input                     dfi_odt,
  input                     dfi_wrdata_en,
  input  [16*`DQ_GROUP-1:0] dfi_wrdata,
  input   [2*`DQ_GROUP-1:0] dfi_wrdata_mask,
  input                     dfi_rddata_en,
  output [16*`DQ_GROUP-1:0] dfi_rddata,
  output reg                dfi_rddata_valid,
  output                    locked,
  // dram interface signals
  output                    ck_p,
  output                    ck_n,
  output reg                cke,
  output reg          [2:0] ba,
  output reg         [15:0] a,
  output reg                cs_n,
  output reg                ras_n,
  output reg                cas_n,
  output reg                we_n,
  output reg                reset,
  output reg                odt,
  output    [`DQ_GROUP-1:0] dm_oe_n,
  output    [`DQ_GROUP-1:0] dm_o,
  output    [`DQ_GROUP-1:0] dqs_p_oe_n,
  output    [`DQ_GROUP-1:0] dqs_p_o,
  input     [`DQ_GROUP-1:0] dqs_p_i,
  output    [`DQ_GROUP-1:0] dqs_n_oe_n,
  output    [`DQ_GROUP-1:0] dqs_n_o,
  input     [`DQ_GROUP-1:0] dqs_n_i,
  output  [8*`DQ_GROUP-1:0] dq_oe_n,
  output  [8*`DQ_GROUP-1:0] dq_o,
  input   [8*`DQ_GROUP-1:0] dq_i
);

  reg                       rddata_en_180, rddata_en_360;

  wire                      clk_0, clk_180;

  genvar i;

  always @(posedge clk_180) begin
    if(dfi_rst) begin
      cke   <= 1'b0;
      ba    <= 3'b000;
      a     <= 16'h0;
      cs_n  <= 1'b1;
      ras_n <= 1'b1;
      cas_n <= 1'b1;
      we_n  <= 1'b1;
      reset <= 1'b1;
      odt   <= 1'b0;
    end
    else begin
      cke   <= dfi_cke;
      ba    <= dfi_bank;
      a     <= dfi_address;
      cs_n  <= dfi_cs_n;
      ras_n <= dfi_ras_n;
      cas_n <= dfi_cas_n;
      we_n  <= dfi_we_n;
      reset <= dfi_reset_n;
      odt   <= dfi_odt;
    end
  end

  always @(posedge clk_180)
    if(dfi_rst)
      rddata_en_180 <= 1'b0;
    else
      rddata_en_180 <= dfi_rddata_en;

  always @(posedge clk_0)
    if(dfi_rst) begin
      rddata_en_360 <= 1'b0;
      dfi_rddata_valid <= 1'b0;
    end
    else begin
      rddata_en_360 <= rddata_en_180;
      dfi_rddata_valid <= rddata_en_360;
    end

  assign clk_0   = dfi_clk;
  assign clk_180 = ~dfi_clk;

  assign ck_p  = clk_0;
  assign ck_n  = clk_180;

  generate
    for(i=0;i<`DQ_GROUP;i=i+1) begin: one_byte
      byte_slice byte_slice(
        .reset        ( dfi_rst            ),
        .clk          ( dfi_clk            ),
        .clk_2x       ( dfi_clk_2x         ),
        .wrdata_en    ( dfi_wrdata_en      ),
        .wrdata       ( {dfi_wrdata[8*`DQ_GROUP+8*i+7:8*`DQ_GROUP+8*i], dfi_wrdata[8*i+7:8*i]} ),
        .wrdata_mask  ( {dfi_wrdata_mask[`DQ_GROUP+i], dfi_wrdata_mask[i]} ),
        .dm_oe_n      ( dm_oe_n[i]         ),
        .dm_o         ( dm_o[i]            ),
        .dq_oe_n      ( dq_oe_n[8*i+7:8*i] ),
        .dq_o         ( dq_o[8*i+7:8*i]    ),
        .dqs_p_oe_n   ( dqs_p_oe_n[i]      ),
        .dqs_p_o      ( dqs_p_o[i]         ),
        .dqs_n_oe_n   ( dqs_n_oe_n[i]      ),
        .dqs_n_o      ( dqs_n_o[i]         ),
        .rddata_en    ( dfi_rddata_en      ),
        .rp_inc       ( rddata_en_360      ),
        .rddata       ( {dfi_rddata[8*`DQ_GROUP+8*i+7:8*`DQ_GROUP+8*i], dfi_rddata[8*i+7:8*i]} ),
        .dq_i         ( dq_i[8*i+7:8*i]    ),
        .dqs_p_i      ( dqs_p_i[i]         ),
        .dqs_n_i      ( dqs_n_i[i]         )
      );
    end
  endgenerate

endmodule
