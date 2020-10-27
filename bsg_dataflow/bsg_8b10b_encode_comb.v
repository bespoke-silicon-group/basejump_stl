// Based on US Patent # 4,486,739 (expired)
// Byte Oriented DC Balanced 8B/10B Partitioned Block Transmission Code
// Author: Franaszek et al.
//
// https://patentimages.storage.googleapis.com/67/2d/ad/0258c2f0d807bf/US4486739.pdf
//
`include "bsg_defines.v"

module bsg_8b10b_encode_comb
( input        [7:0] data_i
, input              k_i
, input              rd_i
  
, output logic [9:0] data_o
, output logic       rd_o
, output logic       kerr_o
);

  wire A = data_i[0];
  wire B = data_i[1];
  wire C = data_i[2];
  wire D = data_i[3];
  wire E = data_i[4];
  wire F = data_i[5];
  wire G = data_i[6];
  wire H = data_i[7];

  // From FIG. 3
  wire AxorB = A ^ B;
  wire CxorD = C ^ D;
  wire AandB = A & B;
  wire CandD = C & D;
  wire NAandNB = ~A & ~B;
  wire NCandND = ~C & ~D;

  wire L22 = (AandB & NCandND) | (CandD & NAandNB) | (AxorB & CxorD);
  wire L40 = AandB & CandD;
  wire L04 = NAandNB & NCandND;
  wire L13 = (AxorB & NCandND) | (CxorD & NAandNB);
  wire L31 = (AxorB & CandD) | (CxorD & AandB);

  // From FIG. 4
  wire FxorG = F ^ G;
  wire FandG = F & G;
  wire NFandNG = ~F & ~G;
  wire NFandNGandNH = NFandNG & ~H;
  wire FxorGandK = FxorG & k_i;
  wire FxorGandNH = FxorG & ~H;
  wire FandGandH = FandG & H;

  wire S = (rd_i & L31 & D & ~E) | (~rd_i & L13 & ~D & E);

  // Form FIG. 5
  wire T0 = L13 & D & E;   // Intermediate net

  wire PDM1S6 = T0 | (~L22 & ~L31 & ~E);
  wire ND0S6 = PDM1S6;
  wire PD0S6 = (E & ~L22 & ~L13) | k_i;
  wire NDM1S6 = (L31 & ~D & ~E) | PD0S6;
  wire NDM1S4 = FandG;
  wire ND0S4 = NFandNG;
  wire PDM1S4 = NFandNG | FxorGandK;
  wire PD0S4 = FandGandH;

  // From FIG. 6
  wire COMPLS6 = (NDM1S6 & rd_i) | (~rd_i & PDM1S6);
  wire NDL6 = (PD0S6 & ~COMPLS6) | (COMPLS6 & ND0S6) | (~ND0S6 & ~PD0S6 & rd_i);
  wire COMPLS4 = (NDM1S4 & NDL6) | (~NDL6 & PDM1S4 );

  assign rd_o = (NDL6 & ~PD0S4 & ~ND0S4) | (ND0S4 & COMPLS4) | (~COMPLS4 & PD0S4);

  // From FIG. 7
  wire N0 = A;
  wire N1 = (~L40 & B) | L04;
  wire N2 = (L04 | C) | T0;
  wire N3 = D & ~L40;
  wire N4 = (~T0 & E) | (~E & L13);
  wire N5 = (~E & L22) | (L22 & k_i) | (L04 & E) | (E & L40) | (E & L13 & ~D);

  assign data_o[0] = N0 ^ COMPLS6;
  assign data_o[1] = N1 ^ COMPLS6;
  assign data_o[2] = N2 ^ COMPLS6;
  assign data_o[3] = N3 ^ COMPLS6;
  assign data_o[4] = N4 ^ COMPLS6;
  assign data_o[5] = N5 ^ COMPLS6;

  // From FIG. 8
  wire T1 = (S & FandGandH) | (FandGandH & k_i);  // Intermediate net

  wire N6 = ~(~F | T1);
  wire N7 = G | NFandNGandNH;
  wire N8 = H;
  wire N9 = T1 | FxorGandNH;

  assign data_o[6] = N6 ^ COMPLS4;
  assign data_o[7] = N7 ^ COMPLS4;
  assign data_o[8] = N8 ^ COMPLS4;
  assign data_o[9] = N9 ^ COMPLS4;

  // Not in patent
  assign kerr_o = k_i & ~(NAandNB & CandD & E) & ~(FandGandH & E & L31) ; 

endmodule

