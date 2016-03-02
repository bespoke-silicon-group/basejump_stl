module bsg_vscale_hasti_converter #
  ( parameter haddr_width_p    = `HASTI_ADDR_WIDTH

   ,parameter hdata_width_p    = `HASTI_BUS_WIDTH
   ,parameter hdata_nbytes_p   = `HASTI_BUS_NBYTES

   ,parameter htrans_width_p   = `HASTI_TRANS_WIDTH
   ,parameter htrans_idle_p    = `HASTI_TRANS_IDLE
   ,parameter htrans_busy_p    = `HASTI_TRANS_BUSY
   ,parameter htrans_nonseq_p  = `HASTI_TRANS_NONSEQ
   ,parameter htrans_seq_p     = `HASTI_TRANS_SEQ

   ,parameter hprot_width_p    = `HASTI_PROT_WIDTH
   ,parameter hprot_noprot_p   = `HASTI_NO_PROT

   ,parameter hburst_width_p   = `HASTI_BURST_WIDTH
   ,parameter hburst_single_p  = `HASTI_BURST_SINGLE

   ,parameter hresp_width_p    = `HASTI_RESP_WIDTH
   ,parameter hresp_okay_p     = `HASTI_RESP_OKAY
   ,parameter hresp_error_p    = `HASTI_RESP_ERROR

   ,parameter hsize_width_p    = `HASTI_SIZE_WIDTH
   ,parameter hsize_byte_p     = `HASTI_SIZE_BYTE
   ,parameter hsize_halfword_p = `HASTI_SIZE_HALFWORD
   ,parameter hsize_word_p     = `HASTI_SIZE_WORD
  )
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
  logic [1:0]                     notrans_r;
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
          notrans_r[i] <= 1'b1;
        end
      else
        begin
          rvalid_r[i] <= ~w_r[i] & ~m_yumi_i[i];

          if(notrans_r[i] | (w_r[i] & m_yumi_i[i]) | (~w_r[i] & m_v_i[i]))
            begin
              addr_r[i]    <= haddr_i[i];
              wsize_r[i]   <= hsize_i[i];
              w_r[i]       <= hwrite_i[i];
              rvalid_r[i]  <= ~hwrite_i[i];
              notrans_r[i] <= ~(htrans_i[i] == htrans_nonseq_p);
            end
        end
    end

    assign m_v_o[i]    = (~reset_i) & (~notrans_r[i]) & (w_r[i] | rvalid_r[i]);
    assign m_w_o[i]    = w_r[i];
    assign m_addr_o[i] = addr_r[i];
    assign m_data_o[i] = hwdata_i[i];
    assign m_mask_o[i] = ~wmask[i];

    assign hrdata_o[i] = m_data_i[i];
    assign hready_o[i] = (w_r[i] & m_yumi_i[i]) | (~w_r[i] & m_v_i[i]);
    assign hresp_o[i]  = hresp_okay_p;
  end

endmodule
