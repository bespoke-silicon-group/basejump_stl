

module bsg_cordic_sine_cosine_stage #(parameter   stage_p = 1, ang_width_p, ans_width_p)
   ( input  signed [ans_width_p-1:0] x_i
    ,input  signed [ans_width_p-1:0] y_i
    ,input  signed [ang_width_p-1:0] ang_i
    ,input  signed [ang_width_p-1:0] ang_lookup_i
    ,input val_i
    ,input sign_op_cos_i
    ,input sign_op_sin_i
    ,output signed [ans_width_p-1:0] x_o
    ,output signed [ans_width_p-1:0] y_o
    ,output signed [ang_width_p-1:0] ang_o
    ,output val_o
    ,output sign_op_cos_o
    ,output sign_op_sin_o
    );
 
   wire [ans_width_p-1:0] y_shift =(y_i) >>> stage_p;
   wire [ans_width_p-1:0] x_shift = x_i >>> stage_p;
   wire rot_op;

   assign rot_op = ang_i[ang_width_p-1] ? 1 : 0;
   assign ang_o = rot_op ? ang_i+ang_lookup_i : ang_i-ang_lookup_i;
   assign x_o = rot_op ? (x_i + y_shift) : (x_i -  y_shift);
   assign y_o = rot_op ? (y_i - x_shift) : (y_i +  x_shift);
   assign sign_op_cos_o = sign_op_cos_i;
   assign sign_op_sin_o = sign_op_sin_i; 
   assign val_o = val_i;


endmodule