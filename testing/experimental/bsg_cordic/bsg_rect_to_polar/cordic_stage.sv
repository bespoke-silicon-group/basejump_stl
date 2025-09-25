 

 module cordic_stage #(parameter   stage_p = 1, ang_width_p, ans_width_p)
   (
     input  signed [ans_width_p-1:0] x_i
    ,input  signed [ans_width_p-1:0] y_i
    ,input  signed [ang_width_p-1:0] ang_i
    ,input  signed [ang_width_p-1:0] ang_lookup_i
    ,input val_i
    ,input switch_i
    ,input quad_x_i
    ,input quad_y_i
    ,output signed [ans_width_p-1:0] x_o
    ,output signed [ans_width_p-1:0] y_o
    ,output signed [ang_width_p-1:0] ang_o
    ,output val_o
    ,output switch_o
    ,output quad_x_o
    ,output quad_y_o
    );
 
   wire [ans_width_p-1:0] y_shift =(y_i) >>> stage_p;
   wire [ans_width_p-1:0] x_shift = x_i >>> stage_p;
   
   assign ang_o = (y_i[ans_width_p-1]) ? (ang_i-ang_lookup_i) : (ang_i + ang_lookup_i);
   assign x_o = (y_i[ans_width_p-1]) ? (x_i - y_shift) : (x_i +  y_shift);
   assign y_o = (y_i[ans_width_p-1]) ? (y_i + x_shift) : (y_i -  x_shift);
   assign switch_o = switch_i;
   assign quad_y_o = quad_y_i;
   assign quad_x_o = quad_x_i;
   assign val_o = val_i;
endmodule
