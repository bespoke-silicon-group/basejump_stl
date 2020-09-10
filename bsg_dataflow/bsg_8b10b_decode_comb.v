// Based on US Patent # 4,486,739 (expired)
// Byte Oriented DC Balanced 8B/10B Partitioned Block Transmission Code
// Author: Franaszek et al.
//
// https://patentimages.storage.googleapis.com/67/2d/ad/0258c2f0d807bf/US4486739.pdf
//
`include "bsg_defines.v"

module bsg_8b10b_decode_comb
( input        [9:0] data_i
, input              rd_i

, output logic [7:0] data_o
, output logic       k_o
, output logic       rd_o

, output logic       data_err_o
, output logic       rd_err_o
);

  wire A = data_i[0];
  wire B = data_i[1];
  wire C = data_i[2];
  wire D = data_i[3];
  wire E = data_i[4];
  wire I = data_i[5];
  wire F = data_i[6];
  wire G = data_i[7];
  wire H = data_i[8];
  wire J = data_i[9];

  // Commonly found functions (some in patent, others are not)
  wire AxorB   = A ^ B;
  wire AandB   = A & B;
  wire NAandNB = ~A & ~B;

  wire CxorD   = C ^ D;
  wire CandD   = C & D;
  wire NCandND = ~C & ~D;

  wire ExnorI  = ~(E ^ I);
  wire EandI   = E & I;
  wire NEandNI = ~E & ~I;

  wire FxorG   = F ^ G;
  wire FandG   = F & G;
  wire NFandNG = ~F & ~G;

  wire HxorJ   = H ^ J;
  wire HandJ   = H & J;
  wire NHandNJ = ~H & ~J;

  // From FIG. 10
  wire P22 = (AandB & NCandND) | (CandD & NAandNB) | (AxorB & CxorD);
  wire P13 = (AxorB & NCandND) | (CxorD & NAandNB);
  wire P31 = (AxorB & CandD)   | (CxorD & AandB);

  // From FIG. 11
  wire N0 = P22 &  A &  C & ExnorI;
  wire N1 = P22 & ~A & ~C & ExnorI;
  wire N2 = P22 &  B &  C & ExnorI;
  wire N3 = P22 & ~B & ~C & ExnorI;
  wire N4 = NAandNB & NEandNI;
  wire N5 = AandB & EandI;
  wire N6 = P13 & D & EandI;
  wire N7 = P13 & ~I;
  wire N8 = P13 & ~E;
  wire N9 = P31 &  I;

  wire N10 = CandD & EandI;
  wire N11 = NCandND & NEandNI;
  wire N12 = ~E & I & G & HandJ;
  wire N13 = E & ~I & ~G & NHandNJ;

  assign k_o = (N10 | N11) | (N12 & P13) | (N13 & P31);

  // From FIG. 12
  wire M0 = N1 | N8;
  wire M1 = N5 | N11 | N9;
  wire M2 = N9 | N2  | N6;
  wire M3 = N0 | N8;
  wire M4 = N8 | N11 | N4;
  wire M5 = N1 | N7;
  wire M6 = N6 | N3;

  wire T0 = M6 | M0 | M1;
  wire T1 = M1 | M3 | M2;
  wire T2 = M2 | M0 | M4;
  wire T3 = M1 | M3 | M6;
  wire T4 = M5 | M4 | M6; 

  assign data_o[0] = A ^ T0;
  assign data_o[1] = B ^ T1;
  assign data_o[2] = C ^ T2;
  assign data_o[3] = D ^ T3;
  assign data_o[4] = E ^ T4;

  // From FIG.13
  wire N14 = G & HandJ;
  wire N15 = HandJ & F;
  wire N16 = FandG & J;
  wire N17 = NFandNG & ~H;
  wire N18 = NFandNG & HandJ;
  wire N19 = ~F & NHandNJ;
  wire N20 = NHandNJ & ~G;
  wire N21 = ~HandJ & ~NHandNJ & N11;

  wire M7  = N14 | N15 | N21;
  wire M8  = N16 | N17 | N18;
  wire M9  = N19 | N21 | N20;
  wire M10 = N20 | N15 | N21;

  wire T5 = M7 | M8;
  wire T6 = M8 | M9;
  wire T7 = M8 | M10;

  assign data_o[5] = F ^ T5;
  assign data_o[6] = G ^ T6;
  assign data_o[7] = H ^ T7;

  // Everything else is not found in the patent

  wire rd6p = (P31 & ~NEandNI)  | (P22 & EandI);      // 5b/6b code disparity +2
  wire rd6n = (P13 & ~EandI)    | (P22 & NEandNI);    // 5b/6b code disparity -2
  wire rd4p = (FxorG & HandJ)   | (HxorJ & FandG);    // 3b/4b code disparity +2
  wire rd4n = (FxorG & NHandNJ) | (HxorJ & NFandNG);  // 3b/4b code disparity -2

  assign rd_o = ~NHandNJ & (rd4p | HandJ | (((D | ~NEandNI) & ((rd_i & P31) |
                ((rd_i | ~P13) & EandI) | (((rd_i & P22) | P31) & ~(NEandNI)) |
                (D & EandI))) & ((FandG & NHandNJ) | N18 | (FxorG & HxorJ))));

  assign data_err_o = (NAandNB & NCandND) |
                      (AandB & CandD) |
                      (NFandNG & NHandNJ) |
                      (FandG & HandJ) |
                      (EandI & FandG & H) |
                      (NEandNI & N17) |
                      (E & ~I & N14) |
                      (~E & I & N20) |
                      (~P31 & N13) |
                      (~P13 & N12) |
                      (N7 & ~E) |
                      (N9 & E) |
                      (FandG & NHandNJ & rd6p) |
                      (N18 & rd6n) |
                      (N10 & N17) |
                      (N11 & FandG & H) |
                      (rd6p & rd4p) |
                      (rd6n & rd4n) |
                      (AandB & C & NEandNI & (NFandNG | rd4n)) |
                      (NAandNB & ~C & EandI & (FandG | rd4p)) |
                      (((EandI & N20) | (NEandNI & N14)) & ~(CandD & E) & ~(NCandND & ~E));


  // Running disparity errors detection
  assign rd_err_o = (rd6p & rd4p)          | (rd6n & rd4n)              | // Delta disparity check
                    (rd_i & rd6p)          | (~rd_i & rd6n)             | // Disparity check for 5b/6b code
                    (rd_i & ~rd6n & FandG) | (~rd_i & ~rd6p & NFandNG)  | // Disparity check for 3b/4b code
                    (rd_i & ~rd6n & rd4p)  | (~rd_i & ~rd6p & rd4n)     | // Resulting disparity check
                    (rd_i & AandB & C)     | (~rd_i & NAandNB & ~C);      // Additional check for DX.Y = D7.?

endmodule

