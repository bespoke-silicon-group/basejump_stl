
module bsg_cordic_exponential_stage_negative #(parameter stage_p = 1, neg_prec_p, ans_width_p, ang_width_p)
    (
     input  signed [ans_width_p-1:0] x_i
    ,input  signed [ans_width_p-1:0] y_i
    ,input  signed [ang_width_p-1:0] ang_i
    ,input  signed [ang_width_p-1:0] ang_lookup_i
    ,input val_i
    ,output signed [ans_width_p-1:0] x_o
    ,output signed [ans_width_p-1:0] y_o
    ,output signed [ang_width_p-1:0] ang_o
    ,output val_o
    );

    wire [ans_width_p-1:0] y_shift = y_i >>> neg_prec_p - stage_p + 2;
    wire [ans_width_p-1:0] x_shift = x_i >>> neg_prec_p - stage_p + 2;
    wire rot_op;

    assign rot_op = ang_i[ang_width_p-1] ? 1 : 0;
    assign ang_o = rot_op ? ang_i + ang_lookup_i : ang_i - ang_lookup_i;
    assign x_o = rot_op ? (x_i - y_i + y_shift) : (x_i + y_i -  y_shift);
    assign y_o = rot_op ? (y_i - x_i + x_shift) : (y_i + x_i -  x_shift);
    assign val_o = val_i;
    
endmodule
