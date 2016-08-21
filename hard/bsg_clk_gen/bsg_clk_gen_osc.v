// TSMC 250nm implementation of the clock generator's ring
// oscillator. A non-process specific implementation can
// be found at:
//
//      bsg_ip_cores/bsg_clk_gen/bsg_clk_gen_osc.v
// 
// This module should replace the non-process specific
// implementation when being synthesized.
//
module bsg_clk_gen_osc (clk, rst, adg_ctrl, cdt, fdt, pwr_off);

output clk;
input [1:0]adg_ctrl;			//16/8
input [1:0]cdt;					//0-6
input [1:0]fdt;					//fine tune
input rst;
input pwr_off;

//ADG
ADG_16 ADG1 (.Y(adg_o2), .A(clk_fb), .ctrl(adg_ctrl[1]), .rst(rst_n));
ADG_8 ADG2 (.Y(adg_o3), .A(adg_o2), .ctrl(adg_ctrl[0]), .rst(rst_n));

//CDT
//Syncronizer for CDT[1:0]
DFFNRX4 CDT0_SYNC_1 (.Q(cdt_r0_meta), .QN(cdt_r0_meta_n), .CKN(adg_o3_d8), .D(cdt[0]),.RN(rst_n));
DFFNRX4 CDT1_SYNC_1 (.Q(cdt_r1_meta), .QN(cdt_r1_meta_n), .CKN(adg_o3_d8), .D(cdt[1]),.RN(rst_n));
DFFNRX4 CDT0_SYNC_2 (.Q(cdt_r0_sync), .QN(cdt_r0_sync_n), .CKN(adg_o3_d8), .D(cdt_r0_meta),.RN(rst_n));
DFFNRX4 CDT1_SYNC_2 (.Q(cdt_r1_sync), .QN(cdt_r1_sync_n), .CKN(adg_o3_d8), .D(cdt_r1_meta),.RN(rst_n));
//

DFFNRX4 DFFNR1 (.Q(cdt_r0), .QN(cdt_r0_n), .CKN(adg_o3_d8), .D(cdt_r0_sync), .RN(rst_n));
DFFNRX4 DDFNR2 (.Q(cdt_r1), .QN(cdt_r1_n), .CKN(adg_o3_d8), .D(cdt_r1_sync), .RN(rst_n));

MXI4X4 M1 (.Y(m1out), .A(adg_o3), .B(adg_o3_d2), .C(adg_o3_d4), .D(adg_o3_d6), .S0(cdt_r0_n), .S1(cdt_r1_n));

CLKINVX2 I11 (.Y(adg_o3_d1), .A(adg_o3));
CLKINVX2 I12 (.Y(adg_o3_d2), .A(adg_o3_d1)); 
CLKINVX2 I13 (.Y(adg_o3_d3), .A(adg_o3_d2)); 
CLKINVX2 I14 (.Y(adg_o3_d4), .A(adg_o3_d3)); 
CLKINVX2 I15 (.Y(adg_o3_d5), .A(adg_o3_d4)); 
CLKINVX2 I16 (.Y(adg_o3_d6), .A(adg_o3_d5)); 
//Two floating inverters for same loading
CLKINVX2 I17 (.Y(adg_o3_d7), .A(adg_o3_d6)); 
CLKINVX2 I18 (.Y(adg_o3_d8), .A(adg_o3_d7)); 

//FDT
CLKINVX2 I39 (.Y(ft1), .A(m1out));

CLKINVX2 I40 (.Y(ft2), .A(m1out));
//Cap=1*0.0098pF
CLKINVX12 I40_1 (.Y(net1), .A(ft2)); 

CLKINVX2 I41 (.Y(ft3), .A(m1out));
//Cap=2*0.0098pF
CLKINVX12 I41_1 (.Y(net2), .A(ft3));
CLKINVX12 I41_2 (.Y(net5), .A(ft3));

CLKINVX2 I42 (.Y(ft4), .A(m1out));
//Cap=3*0.0098pF
CLKINVX12 I42_1 (.Y(net3), .A(ft4));
CLKINVX12 I42_2 (.Y(net4), .A(ft4));
CLKINVX12 I42_3 (.Y(net6), .A(ft4));


CLKINVX2 I43_1 (.Y(m1out_cloud1), .A(m1out)); 
CLKINVX2 I43_2 (.Y(m1out_cloud2), .A(m1out_cloud1));
CLKINVX2 I43_3 (.Y(m1out_cloud3), .A(m1out_cloud2));
CLKINVX2 I43_4 (.Y(m1out_cloud4), .A(m1out_cloud3));
//.subckt DFFNX4 Q QN CKN D RN
//Syncronizer for FDT[1:0]
DFFNRX4 FDT0_SYNC_1 (.Q(fdt_r0_meta), .QN(fdt_r0_meta_n), .CKN(m1out_cloud4), .D(fdt[0]),.RN(rst_n));
DFFNRX4 FDT1_SYNC_1 (.Q(fdt_r1_meta), .QN(fdt_r1_meta_n), .CKN(m1out_cloud4), .D(fdt[1]),.RN(rst_n));
DFFNRX4 FDT0_SYNC_2 (.Q(fdt_r0_sync), .QN(fdt_r0_sync_n), .CKN(m1out_cloud4), .D(fdt_r0_meta),.RN(rst_n));
DFFNRX4 FDT1_SYNC_2 (.Q(fdt_r1_sync), .QN(fdt_r1_sync_n), .CKN(m1out_cloud4), .D(fdt_r1_meta),.RN(rst_n));
//
DFFNRX4 DFFN11 (.Q(fdt_r0), .QN(fdt_r0_n), .CKN(m1out_cloud4), .D(fdt_r0_sync), .RN(rst_n));
DFFNRX4 DDFN12 (.Q(fdt_r1), .QN(fdt_r1_n), .CKN(m1out_cloud4), .D(fdt_r1_sync), .RN(rst_n));

MXI4X4 M2 (.Y(m2out), .A(ft1), .B(ft2), .C(ft3), .D(ft4), .S0(fdt_r0_n), .S1(fdt_r1_n));


//Reset circuit
CLKINVX2 IRST (.Y(rst_n), .A(rst));
AND2X4 A1 (.Y(clk_fb_int), .A(rst_n), .B(m2out));

//power_off functionality
//add 1 more inverter for power_off mode
CLKINVX2 IPWR (.Y(clk_fb_int_n), .A(clk_fb_int));
MX2X4 M3 (.Y(clk_fb), .A(clk_fb_int), .B(clk_fb_int_n), .S0(pwr_off));

//Final Driver, 16x provides confidence of drive strength
CLKINVX16 ICLK (.Y(clk), .A(m2out));

endmodule


module ADG_8 (Y, A, ctrl, rst);
input A, ctrl, rst;
output Y;

//Syncronizer for ADG[0]
DFFRX4 ADG0_SYNC_1 (.Q(ctrl_meta), .QN(ctrl_meta_n), .CK(net2), .D(ctrl),.RN(rst));
DFFRX4 ADG0_SYNC_2 (.Q(ctrl_sync), .QN(ctrl_sync_n), .CK(net2), .D(ctrl_meta),.RN(rst));


//
DFFRX4 DFF1 (.Q(ctrl_r), .QN(ctrl_r_n), .CK(net2), .D(ctrl_sync), .RN(rst));
AND2X4 A1 (.Y(net0), .A(A), .B(ctrl_r));
AND2X4 A2 (.Y(net1), .A(A), .B(ctrl_r_inv));
CLKINVX2 I4 (.Y(ctrl_r_inv), .A(ctrl_r));

//Mux for loading the non-delay path
MXI4X4 M1 (.Y(m1out), .A(net0), .B(net0), .C(net0), .D(net0), .S0(1'b0), .S1(1'b0));
MXI4X4 M2 (.Y(m2out), .A(net0), .B(net0), .C(net01), .D(net02), .S0(1'b0), .S1(1'b0));

DLY_CHAIN_8 D1 (.Y(net1_d), .A(net1));  
NOR2X4 N5 (.Y(net2), .A(net0), .B(net1_d));
CLKINVX2 I7 (.Y(Y), .A(net2));

endmodule

module ADG_16 (Y, A, ctrl, rst);
input A, ctrl, rst;
output Y;

//Syncronizer for ADG[1]
DFFRX4 ADG0_SYNC_1 (.Q(ctrl_meta), .QN(ctrl_meta_n), .CK(net2), .D(ctrl),.RN(rst));
DFFRX4 ADG0_SYNC_2 (.Q(ctrl_sync), .QN(ctrl_sync_n), .CK(net2), .D(ctrl_meta),.RN(rst));


//
DFFRX4 DFF1 (.Q(ctrl_r), .QN(ctrl_r_n), .CK(net2), .D(ctrl_sync), .RN(rst));
AND2X4 A1 (.Y(net0), .A(A), .B(ctrl_r));
AND2X4 A2 (.Y(net1), .A(A), .B(ctrl_r_inv));
CLKINVX2 I4 (.Y(ctrl_r_inv), .A(ctrl_r));

//Mux for loading the non-delay path
MXI4X4 M1 (.Y(m1out), .A(net0), .B(net0), .C(net0), .D(net0), .S0(1'b0), .S1(1'b0));
MXI4X4 M2 (.Y(m2out), .A(net0), .B(net0), .C(net01), .D(net02), .S0(1'b0), .S1(1'b0));

DLY_CHAIN_16 D1 (.Y(net1_d), .A(net1));  
NOR2X4 N5 (.Y(net2), .A(net0), .B(net1_d));
CLKINVX2 I7 (.Y(Y), .A(net2));

endmodule


module DLY_CHAIN_8 (Y, A);
input A;
output Y;

CLKINVX2 I1 (.Y(inv1), .A(A));
CLKINVX2 I2 (.Y(inv2), .A(inv1));
CLKINVX2 I3 (.Y(inv3), .A(inv2));
CLKINVX2 I4 (.Y(inv4), .A(inv3));
CLKINVX2 I5 (.Y(inv5), .A(inv4));
CLKINVX2 I6 (.Y(inv6), .A(inv5));
CLKINVX2 I7 (.Y(inv7), .A(inv6));
CLKINVX2 I8 (.Y(Y), .A(inv7));

MXI4X4 M1 (.Y(m1out),.A(inv2), .B(inv4), .C(inv6), .D(Y), .S0(1'b0), .S1(1'b0));

endmodule

module DLY_CHAIN_16 (Y, A);
input A;
output Y;

CLKINVX2 I1 (.Y(inv1), .A(A));
CLKINVX2 I2 (.Y(inv2), .A(inv1));
CLKINVX2 I3 (.Y(inv3), .A(inv2));
CLKINVX2 I4 (.Y(inv4), .A(inv3));
CLKINVX2 I5 (.Y(inv5), .A(inv4));
CLKINVX2 I6 (.Y(inv6), .A(inv5));
CLKINVX2 I7 (.Y(inv7), .A(inv6));
CLKINVX2 I8 (.Y(inv8), .A(inv7));

MXI4X4 M1 (.Y(m1out),.A(inv2), .B(inv4), .C(inv6), .D(inv8), .S0(1'b0), .S1(1'b0));

CLKINVX2 I11 (.Y(inv9), .A(inv8));
CLKINVX2 I12 (.Y(inv10),.A(inv9));
CLKINVX2 I13 (.Y(inv11),.A(inv10));
CLKINVX2 I14 (.Y(inv12),.A(inv11));
CLKINVX2 I15 (.Y(inv13),.A(inv12));
CLKINVX2 I16 (.Y(inv14),.A(inv13));
CLKINVX2 I17 (.Y(inv15),.A(inv14));
CLKINVX2 I18 (.Y(Y), .A(inv15));

MXI4X4 M2 (.Y(m2out),.A(inv10), .B(inv12), .C(inv14), .D(Y), .S0(1'b0), .S1(1'b0));

endmodule


