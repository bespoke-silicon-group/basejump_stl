/*
* Rich Park
* September 2014
* 
* This module checks the calibration sequence during phase 1
* of the BSG calibration procedure.
*/
module phase1_checker #(parameter width_p = -1)
(
	  input clk
	  ,input reset
	  ,input enable
	  ,input logic [width_p:0] neg_valid_data_i
	  ,input logic [width_p:0] pos_valid_data_i
      ,output logic [width_p-1:0] bit_slip_vector_o
	  ,output logic cal_done_o
	  ,output logic timed_out_o
);

localparam cal_threshold_p = 1000;
localparam time_out_threshold_p = 10 * cal_threshold_p;

logic [$clog2(cal_threshold_p)-1: 0] aligned_count;
logic [$clog2(time_out_threshold_p)-1: 0] time_out_r;


logic pos_match, neg_match, match, has_flipped, match_value;
logic [width_p-1:0] bit_slip_vector;

assign cal_done_o =  (aligned_count >= cal_threshold_p);
assign timed_out_o = time_out_r >= time_out_threshold_p;
assign bit_slip_vector_o = bit_slip_vector;

always_ff @ (posedge clk) begin
	if (reset) begin
		time_out_r <= 0;
		aligned_count <= 0;
//        bit_slip_vector[0] <= 0;
        has_flipped <= 0;
        match_value <= 0;
	end else if (enable) begin 
		aligned_count <= match? aligned_count + 2 : 0;
		time_out_r <= time_out_r + 2;
        
        if (~pos_match && pos_valid_data_i[width_p]) begin
            if (|bit_slip_vector_o && ~has_flipped) begin
                has_flipped <= 1;
            end else if (|bit_slip_vector_o && has_flipped) begin
                has_flipped <= 0;
            end else begin
                match_value <= 1;
            end
        end
	end
end

always_comb begin:check_for_match
    neg_match = neg_valid_data_i[0] ? &neg_valid_data_i[width_p-1:0] : ~(|neg_valid_data_i[width_p-1:0]);
    pos_match = pos_valid_data_i[0] ? &pos_valid_data_i[width_p-1:0] : ~(|pos_valid_data_i[width_p-1:0]); 
    match = pos_match && neg_match;
end:check_for_match

genvar i;

generate
for (i = 0; i < width_p; i = i + 1) begin:bit_slip
    always_ff @ (posedge clk) begin
        if (reset) begin
            bit_slip_vector[i] <= 1'b0;
        end else if (~pos_match && pos_valid_data_i[width_p]) begin
            if (|bit_slip_vector_o && ~has_flipped) begin
                bit_slip_vector[i] <= bit_slip_vector[i] ^ 1'b1;
            end else if (|bit_slip_vector_o && has_flipped) begin
                bit_slip_vector[i] <= 1'b0;
            end else if (pos_valid_data_i[i] != match_value) begin
                bit_slip_vector[i] <= 1'b1;            
            end
        end
    end
end:bit_slip
endgenerate
endmodule
