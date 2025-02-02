/**
 *    bsg_hashing_ipoly.sv
 *    
 *    Reusable logic for IPOLY hashing (combinational logic only);
 *
 *    num_banks_p = number of banks;
 *    upper_width_p = upper index width;
 *    
 *    The following notes have been copied from:
 *    https://github.com/gpgpu-sim/gpgpu-sim_distribution/blob/master/src/gpgpu-sim/hashing.cc
 *
 *    Set Indexing function from "Pseudo-randomly interleaved memory."
 *    Rau, B. R et al.
 *    ISCA 1991
 *    http://citeseerx.ist.psu.edu/viewdoc/download;jsessionid=348DEA37A3E440473B3C075EAABC63B6?doi=10.1.1.12.7149&rep=rep1&type=pdf
 *
 *    equations are corresponding to IPOLY(37) and are adopted from:
 *    "Sacat: streaming-aware conflict-avoiding thrashing-resistant gpgpu
 *    cache management scheme." Khairy et al. IEEE TPDS 2017.
 *
 *    equations for 8 banks are corresponding to IPOLY(13)
 *    equations for 16 banks are corresponding to IPOLY(15)
 *    equations for 32 banks are corresponding to IPOLY(37)
 *    equations for 64 banks are corresponding to IPOLY(67)
 *    To see all the IPOLY equations for all the degrees, see
 *    http://wireless-systems.ece.gatech.edu/6604/handouts/Peterson's%20Table.pdf
 *
 *    We generate these equations using GF(2) arithmetic:
 *    http://www.ee.unb.ca/cgi-bin/tervo/calc.pl?num=&den=&f=d&e=1&m=1
 *
 *    We go through all the strides 128 (10000000), 256 (100000000),...  and
 *    do modular arithmetic in GF(2) Then, we create the H-matrix and group
 *    each bit together, for more info read the ISCA 1991 paper
 *
 *    IPOLY hashing guarantees conflict-free for all 2^n strides which widely
 *    exit in GPGPU applications and also show good performance for other
 *    strides.
 *
 */

`include "bsg_defines.sv"


module bsg_hashing_ipoly
  #(parameter `BSG_INV_PARAM(num_banks_p)
    , parameter `BSG_INV_PARAM(upper_width_p)
    , localparam lg_num_banks_lp=`BSG_SAFE_CLOG2(num_banks_p)
  )
  (
    input [upper_width_p-1:0] upper_bits_i
    , input [lg_num_banks_lp-1:0] bank_id_i
    , output logic [lg_num_banks_lp-1:0] new_bank_id_o
  );


  // renaming for brevity;
  wire [upper_width_p-1:0] a = upper_bits_i;
  wire [lg_num_banks_lp-1:0] b = bank_id_i;
  
  if (num_banks_p == 4) begin
    assign new_bank_id_o[0]  = b[0] ^ a[10] ^ a[9] ^ a[7] ^ a[6] ^ a[4] ^ a[3] ^ a[1] ^ a[0];
    assign new_bank_id_o[1]  = b[1] ^ a[11] ^ a[9] ^ a[8] ^ a[6] ^ a[5] ^ a[3] ^ a[2] ^ a[0];
  end
  else if (num_banks_p == 8) begin
    assign new_bank_id_o[0]  = b[0] ^ a[11] ^ a[9] ^ a[8] ^ a[7] ^ a[4] ^ a[2] ^ a[1] ^ a[0];
    assign new_bank_id_o[1]  = b[1] ^ a[12] ^ a[10] ^ a[9] ^ a[8] ^ a[5] ^ a[3] ^ a[2] ^ a[1];
    assign new_bank_id_o[2]  = b[2] ^ a[13] ^ a[10] ^ a[8] ^ a[7] ^ a[6] ^ a[3] ^ a[1] ^ a[0];
  end
  else if (num_banks_p == 16) begin
    assign new_bank_id_o[0]  = b[0] ^ a[11] ^ a[10] ^ a[9] ^ a[8] ^ a[6] ^ a[4] ^ a[3] ^ a[0];
    assign new_bank_id_o[1]  = b[1] ^ a[12] ^ a[8]  ^ a[7] ^ a[6] ^ a[5] ^ a[3] ^ a[1] ^ a[0];
    assign new_bank_id_o[2]  = b[2] ^ a[9]  ^ a[8]  ^ a[7] ^ a[6] ^ a[4] ^ a[2] ^ a[1];
    assign new_bank_id_o[3]  = b[3] ^ a[10] ^ a[9]  ^ a[8] ^ a[7] ^ a[5] ^ a[3] ^ a[2];
  end
  else if (num_banks_p == 32) begin
    assign new_bank_id_o[0]  = b[0] ^ a[13] ^ a[12] ^ a[11] ^ a[10] ^ a[9]  ^ a[6] ^ a[5] ^ a[3] ^ a[0];
    assign new_bank_id_o[1]  = b[1] ^ a[14] ^ a[13] ^ a[12] ^ a[11] ^ a[10] ^ a[7] ^ a[6] ^ a[4] ^ a[1];
    assign new_bank_id_o[2]  = b[2] ^ a[14] ^ a[10] ^ a[9]  ^ a[8]  ^ a[7]  ^ a[6] ^ a[3] ^ a[2] ^ a[0];
    assign new_bank_id_o[3]  = b[3] ^ a[11] ^ a[10] ^ a[9]  ^ a[8]  ^ a[7]  ^ a[4] ^ a[3] ^ a[1];
    assign new_bank_id_o[4]  = b[4] ^ a[12] ^ a[11] ^ a[10] ^ a[9]  ^ a[8]  ^ a[5] ^ a[4] ^ a[2];
  end
  else if (num_banks_p == 64) begin
    assign new_bank_id_o[0]  = b[0] ^ a[18] ^ a[17] ^ a[16] ^ a[15] ^ a[12] ^ a[10] ^ a[6] ^ a[5] ^ a[0];
    assign new_bank_id_o[1]  = b[1] ^ a[15] ^ a[13] ^ a[12] ^ a[11] ^ a[10] ^ a[7]  ^ a[5] ^ a[1] ^ a[0];
    assign new_bank_id_o[2]  = b[2] ^ a[16] ^ a[14] ^ a[13] ^ a[12] ^ a[11] ^ a[8]  ^ a[6] ^ a[2] ^ a[1];
    assign new_bank_id_o[3]  = b[3] ^ a[17] ^ a[15] ^ a[14] ^ a[13] ^ a[12] ^ a[9]  ^ a[7] ^ a[3] ^ a[2];
    assign new_bank_id_o[4]  = b[4] ^ a[18] ^ a[16] ^ a[15] ^ a[14] ^ a[13] ^ a[10] ^ a[8] ^ a[4] ^ a[3];
    assign new_bank_id_o[5]  = b[5] ^ a[17] ^ a[16] ^ a[15] ^ a[14] ^ a[11] ^ a[9]  ^ a[5] ^ a[4];
  end
  else begin
    // Not supported;
    $error("num_banks_p not supported: %d", num_banks_p);
  end

endmodule

`BSG_ABSTRACT_MODULE(bsg_hashing_ipoly)
