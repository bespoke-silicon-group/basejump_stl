import bsg_vscale_pkg::*;

`include "bsg_defines.v"

module bsg_vscale_hasti_converter
  ( input clk_i
   ,input reset_i

   // proc
   ,input  [1:0][haddr_width_p-1:0]  haddr_i
   ,input  [1:0]                     hwrite_i
   ,input  [1:0][hsize_width_p-1:0]  hsize_i
   ,input  [1:0][hburst_width_p-1:0] hburst_i
   ,input  [1:0]                     hmastlock_i
   ,input  [1:0][hprot_width_p-1:0]  hprot_i
   ,input  [1:0][htrans_width_p-1:0] htrans_i
   ,input  [1:0][hdata_width_p-1:0]  hwdata_i
   ,output [1:0][hdata_width_p-1:0]  hrdata_o
   ,output [1:0]                     hready_o
   ,output [1:0]                     hresp_o    

   // memory
   ,output [1:0]                          m_v_o
   ,output [1:0]                          m_w_o
   ,output [1:0] [haddr_width_p-1:0]      m_addr_o
   ,output [1:0] [hdata_width_p-1:0]      m_data_o
   ,output [1:0] [(hdata_width_p>>3)-1:0] m_mask_o
   ,input  [1:0]                          m_yumi_i
   ,input  [1:0]                          m_v_i
   ,input  [1:0] [hdata_width_p-1:0]      m_data_i 
  );

   
  logic [1:0][hsize_width_p-1:0]  wsize_r;
  logic [1:0][haddr_width_p-1:0]  addr_r;
  logic [1:0]                     w_r;
  logic [1:0]                     rvalid_r;
  logic [1:0]                     trans_r;
  logic [1:0][hdata_nbytes_p-1:0] wmask;

  genvar i;

  for(i=0; i<2; i=i+1)
  begin
    assign wmask[i] = ((wsize_r[i] == 0) ? 
                       hdata_nbytes_p'(1) 
                       : ((wsize_r[i] == 1) ? 
                          hdata_nbytes_p'(3) 
                          : hdata_nbytes_p'(15)
                         )
                      ) << addr_r[i][1:0];
    
    always_ff @(posedge clk_i)
    begin
      if(reset_i)
        begin
          addr_r[i]    <= 0;
          wsize_r[i]   <= 0;
          w_r[i]       <= 0;
          rvalid_r[i]  <= 1'b0;
          trans_r[i]   <= 1'b0;
        end
      else
        begin
          rvalid_r[i] <= ~w_r[i] & ~m_yumi_i[i];

          if(~trans_r[i] | (w_r[i] & m_yumi_i[i]) | (~w_r[i] & m_v_i[i]))
            begin
              addr_r[i]    <= haddr_i[i];
              wsize_r[i]   <= hsize_i[i];
              w_r[i]       <= hwrite_i[i];
              rvalid_r[i]  <= ~hwrite_i[i];
              trans_r[i]   <= (htrans_i[i] == htrans_nonseq_p) & ~(m_v_o[i] & ~m_w_o[i] & m_yumi_i[i]);
            end
        end
    end

    assign m_v_o[i]    = (~reset_i) & ((trans_r[i] & (w_r[i] | rvalid_r[i]))
                                       | (~trans_r[i] & ~hwrite_i[i] & (htrans_i[i] == htrans_nonseq_p))
                                      );
    assign m_w_o[i]    = w_r[i];
    assign m_addr_o[i] = trans_r[i] ? addr_r[i] : haddr_i[i];
    assign m_data_o[i] = hwdata_i[i];
    assign m_mask_o[i] = ~wmask[i];

    assign hrdata_o[i] = m_data_i[i];
    assign hready_o[i] = (w_r[i] & m_yumi_i[i]) | (~w_r[i] & m_v_i[i]);
    assign hresp_o[i]  = hresp_okay_p;
  end

endmodule
