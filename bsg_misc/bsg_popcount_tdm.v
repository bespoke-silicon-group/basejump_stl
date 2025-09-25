// Popcount TDM Generator
// Automatically generated using bsg_popcount_tdm.py
// DO NOT MODIFY
// This generator can create a popcount adder tree based on
// how many widths were specified in the main .py file

module bsg_popcount_tdm #(parameter `BSG_INV_PARAM(width_p=4))
    (input [width_p-1:0] i
     , output [$clog2(width_p+1)-1:0] o
    );

    if (width_p == 1) begin: width_1 
        wire [$clog2(width_p+1)-1:0] s_o;
        wire [$clog2(width_p+1)-1:0] c_o;
        wire [0:0] COLUMN0;
        assign COLUMN0[0] = i[0];
        assign s_o[0] = i[0];
        assign c_o[0] = 1'b0;
        assign o = s_o + c_o;
        // s_o[0] --> 0.0
        // c_o[0] --> 0.0

        // max S --> 0
        // max C --> 0

    end

    else if (width_p == 2) begin: width_1 
        wire [$clog2(width_p+1)-1:0] s_o;
        wire [$clog2(width_p+1)-1:0] c_o;
        wire [1:0] COLUMN0;
        assign COLUMN0[0] = i[0];
        assign COLUMN0[1] = i[1];
        assign s_o[0] = i[0];
        assign c_o[0] = i[1];
        wire [-1:0] COLUMN1;
        assign s_o[1] = 1'b0;
        assign c_o[1] = 1'b0;
        assign o = s_o + c_o;
        // s_o[0] --> 0.0
        // s_o[1] --> 0.0
        // c_o[0] --> 0.0
        // c_o[1] --> 0.0

        // max S --> 0
        // max C --> 0

    end

    else if (width_p == 4) begin: width_1 
        wire [$clog2(width_p+1)-1:0] s_o;
        wire [$clog2(width_p+1)-1:0] c_o;
        wire [3:0] COLUMN0;
        assign COLUMN0[0] = i[0];
        assign COLUMN0[1] = i[1];
        assign COLUMN0[2] = i[2];
        assign COLUMN0[3] = i[3];
        wire [0:0] t0_n;
        wire [0:0] t1_n;
        assign t1_n[0] = i[0] ^ i[1];
        assign s_o[0] = t1_n[0] ^ i[2];
        wire [0:0] t2_n;
        assign t2_n[0] = i[0] & i[1];
        wire [0:0] t3_n;
        assign t3_n[0] = i[0] & i[2];
        wire [0:0] t4_n;
        assign t4_n[0] = i[1] & i[2];
        assign t0_n[0] = t2_n[0] | t3_n[0] | t4_n[0];
        assign c_o[0] = i[3];
        wire [0:0] COLUMN1;
        assign COLUMN1[0] = t0_n[0];
        assign s_o[1] = t0_n[0];
        assign c_o[1] = 1'b0;
        wire [-1:0] COLUMN2;
        assign s_o[2] = 1'b0;
        assign c_o[2] = 1'b0;
        assign o = s_o + c_o;
        // s_o[0] --> 2.0
        // s_o[1] --> 1.0
        // s_o[2] --> 0.0
        // c_o[0] --> 0.0
        // c_o[1] --> 0.0
        // c_o[2] --> 0.0

        // max S --> 2.0
        // max C --> 0

    end

    else if (width_p == 8) begin: width_1 
        wire [$clog2(width_p+1)-1:0] s_o;
        wire [$clog2(width_p+1)-1:0] c_o;
        wire [7:0] COLUMN0;
        assign COLUMN0[0] = i[0];
        assign COLUMN0[1] = i[1];
        assign COLUMN0[2] = i[2];
        assign COLUMN0[3] = i[3];
        assign COLUMN0[4] = i[4];
        assign COLUMN0[5] = i[5];
        assign COLUMN0[6] = i[6];
        assign COLUMN0[7] = i[7];
        wire [0:0] t5_n;
        wire [0:0] t6_n;
        wire [0:0] t7_n;
        assign t7_n[0] = i[0] ^ i[1];
        assign t5_n[0] = t7_n[0] ^ i[2];
        wire [0:0] t8_n;
        assign t8_n[0] = i[0] & i[1];
        wire [0:0] t9_n;
        assign t9_n[0] = i[0] & i[2];
        wire [0:0] t10_n;
        assign t10_n[0] = i[1] & i[2];
        assign t6_n[0] = t8_n[0] | t9_n[0] | t10_n[0];
        wire [0:0] t11_n;
        wire [0:0] t12_n;
        wire [0:0] t13_n;
        assign t13_n[0] = i[3] ^ i[4];
        assign t11_n[0] = t13_n[0] ^ i[5];
        wire [0:0] t14_n;
        assign t14_n[0] = i[3] & i[4];
        wire [0:0] t15_n;
        assign t15_n[0] = i[3] & i[5];
        wire [0:0] t16_n;
        assign t16_n[0] = i[4] & i[5];
        assign t12_n[0] = t14_n[0] | t15_n[0] | t16_n[0];
        wire [0:0] t17_n;
        wire [0:0] t18_n;
        assign t18_n[0] = i[6] ^ i[7];
        assign s_o[0] = t18_n[0] ^ t5_n[0];
        wire [0:0] t19_n;
        assign t19_n[0] = i[6] & i[7];
        wire [0:0] t20_n;
        assign t20_n[0] = i[6] & t5_n[0];
        wire [0:0] t21_n;
        assign t21_n[0] = i[7] & t5_n[0];
        assign t17_n[0] = t19_n[0] | t20_n[0] | t21_n[0];
        assign c_o[0] = t11_n[0];
        wire [2:0] COLUMN1;
        assign COLUMN1[0] = t6_n[0];
        assign COLUMN1[1] = t12_n[0];
        assign COLUMN1[2] = t17_n[0];
        wire [0:0] t22_n;
        assign s_o[1] = t6_n[0] ^ t12_n[0];
        assign t22_n[0] = t6_n[0] & t12_n[0];
        assign c_o[1] = t17_n[0];
        wire [0:0] COLUMN2;
        assign COLUMN2[0] = t22_n[0];
        assign s_o[2] = t22_n[0];
        assign c_o[2] = 1'b0;
        wire [-1:0] COLUMN3;
        assign s_o[3] = 1'b0;
        assign c_o[3] = 1'b0;
        assign o = s_o + c_o;
        // s_o[0] --> 3.0
        // s_o[1] --> 2.0
        // s_o[2] --> 1.5
        // s_o[3] --> 0.0
        // c_o[0] --> 2.0
        // c_o[1] --> 3.0
        // c_o[2] --> 0.0
        // c_o[3] --> 0.0

        // max S --> 3.0
        // max C --> 3.0

    end


endmodule // bsg_popcount_tdm
