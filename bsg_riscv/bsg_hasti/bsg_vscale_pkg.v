package bsg_vscale_pkg;

   // hasti constants
   parameter haddr_width_p    = `HASTI_ADDR_WIDTH;
                                                     
   parameter hdata_width_p    = `HASTI_BUS_WIDTH;
   parameter hdata_nbytes_p   = `HASTI_BUS_NBYTES;
                                                     
   parameter htrans_width_p   = `HASTI_TRANS_WIDTH; 
   parameter htrans_idle_p    = `HASTI_TRANS_IDLE;
   parameter htrans_busy_p    = `HASTI_TRANS_BUSY;
   parameter htrans_nonseq_p  = `HASTI_TRANS_NONSEQ;
   parameter htrans_seq_p     = `HASTI_TRANS_SEQ; 
                                                     
   parameter hprot_width_p    = `HASTI_PROT_WIDTH;
   parameter hprot_noprot_p   = `HASTI_NO_PROT;
                                                     
   parameter hburst_width_p   = `HASTI_BURST_WIDTH;
   parameter hburst_single_p  = `HASTI_BURST_SINGLE;
                                                     
   parameter hresp_width_p    = `HASTI_RESP_WIDTH;
   parameter hresp_okay_p     = `HASTI_RESP_OKAY;
   parameter hresp_error_p    = `HASTI_RESP_ERROR;
                                                     
   parameter hsize_width_p    = `HASTI_SIZE_WIDTH;
   parameter hsize_byte_p     = `HASTI_SIZE_BYTE;
   parameter hsize_halfword_p = `HASTI_SIZE_HALFWORD;
   parameter hsize_word_p     = `HASTI_SIZE_WORD;

   // htif constants
   parameter htif_pcr_width_p = `HTIF_PCR_WIDTH;
   parameter csr_addr_width_p = `CSR_ADDR_WIDTH;

endpackage
