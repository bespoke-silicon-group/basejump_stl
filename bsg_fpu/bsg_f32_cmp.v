/**
 *  bsg_f32_cmp.v
 *
 *  32-bit floating-point comparator.
 *
 *  @author Tommy Jung
 */

// ---------------
// subop encoding
// ---------------
// 0    =       eq
// 1    !=      ne	
// 2    >       gt	
// 3    <       lt
// 4    >=      ge
// 5    <=      le
// ---------------

module bsg_f32_cmp (
    input [31:0] a_i,       // op a
    input [31:0] b_i,       // op b
    input [2:0] subop_i,    // subop
    output logic z_o,       // output
    output logic invalid_o  // invalid exception
);

logic a_zero, a_nan, a_sig_nan, a_infty;
logic b_zero, b_nan, b_sig_nan, b_infty;
logic mag_a_lt;
logic eq, ne, gt, lt, ge, le;

bsg_f32_preprocess a_preprocess (
    .a_i(a_i),
    .zero_o(a_zero),
    .nan_o(a_nan),
    .sig_nan_o(a_sig_nan),
    .infty_o(a_infty)
);

bsg_f32_preprocess b_preprocess (
    .a_i(b_i),
    .zero_o(b_zero),
    .nan_o(b_nan),
    .sig_nan_o(b_sig_nan),
    .infty_o(b_infty)
);

bsg_less_than #(.width_p(31)) lt_mag (
    .a_i(a_i[30:0]),
    .b_i(b_i[30:0]),
    .lt_o(mag_a_lt)
);

always_comb begin
    if (a_nan & b_nan) begin
        eq = 0; ne = 1;
        gt = 0; lt = 0;
        ge = 0; le = 0;
    end
    else if (a_nan ^ b_nan) begin
        eq = 0; ne = 1;
        gt = 0; lt = 0;
        ge = 0; le = 0;
    end
    else if (~a_nan & ~b_nan) begin
        if (a_zero & b_zero) begin
            eq = 1; ne = 0;
            gt = 0; lt = 0;
            ge = 1; le = 1; 
        end	
        else begin
            // a and b are neither NaNs nor zeros.
            // compare sign and compare magnitude.
            eq = (a_i == b_i);
            ne = ~eq;
            case ({a_i[31], b_i[31]})
                2'b00: begin
                    gt = ~mag_a_lt & ~eq;
                    lt = mag_a_lt;
                    ge = ~mag_a_lt | eq;
                    le = mag_a_lt | eq; 	
                end
                2'b01: begin 
                    gt = 1;
                    lt = 0;
                    ge = ~lt;
                    le = ~gt;	
                end
                2'b10: begin
                    gt = 0;
                    lt = 1;
                    ge = ~lt;
                    le = ~gt;	
                end
                2'b11: begin
                    gt = mag_a_lt;
                    lt = ~mag_a_lt & ~eq;
                    ge = mag_a_lt | eq;
                    le = ~mag_a_lt | eq; 	
                end
            endcase
        end
    end
end

always_comb begin
    case (subop_i)
        3'd0: z_o = eq;
        3'd1: z_o = ne;
        3'd2: z_o = gt;
        3'd3: z_o = lt;
        3'd4: z_o = ge;
        3'd5: z_o = le;
    endcase
end 

assign invalid_o = a_sig_nan | b_sig_nan;

endmodule
