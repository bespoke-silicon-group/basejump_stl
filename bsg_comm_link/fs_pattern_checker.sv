/*
* Rich Park
* September 2014
* 
* This module implements the verification sequence checking  algorithm 
* that is described in the BSG calibration procedure Google Document.
*/
module fs_pattern_checker #( parameter width_p = -1 
                            ,parameter words_per_cal_round_p = 16)
(
	  input clk
	  ,input reset
      ,input enable
	  ,input logic [width_p-1+1:0] neg_valid_data_i
	  ,input logic [width_p-1+1:0] pos_valid_data_i

      ,output logic all_packets_received_o

	  ,output logic checker_success_o
	  ,output logic checker_timed_out_o
  );

// TODO choose threshold values
localparam cal_threshold_p = 2 ** (width_p-1) - 1;
localparam time_out_threshold_p=2 * cal_threshold_p;

logic [$clog2(cal_threshold_p): 0] combo_count;
logic [$clog2(time_out_threshold_p): 0] time_out_r;


logic match_fsfs, match_sfsf;
logic [width_p-1+1:0] s0, s1, sm1, sm2;
logic [5:0] counter_r, counter_n;

assign checker_success_o =  (combo_count >= cal_threshold_p);
assign checker_timed_out_o = time_out_r >= time_out_threshold_p;
assign all_packets_received_o = counter_r == words_per_cal_round_p;

always_ff @ (posedge clk) begin
    if (reset) begin
        s0 <= 0;
        s1 <= 0;
		sm1 <= 0;
		sm2 <= 0;
		time_out_r <= 0;
        combo_count <= 0;
        counter_r <= 0;
    end else if (enable) begin
        counter_r <= counter_n;

        if (neg_valid_data_i[width_p] && pos_valid_data_i[width_p]) begin
            s1 <= pos_valid_data_i;
            s0 <= neg_valid_data_i;
            sm1 <= s1;
            sm2 <= s0;
            combo_count <= match_fsfs || match_sfsf ? combo_count + 2 : 0;
            time_out_r <= time_out_r + 1;
        end else if (neg_valid_data_i[width_p]) begin
            s1 <= neg_valid_data_i;
            s0 <= s1;
            sm1 <= s0;
            sm2 <= sm1;
            combo_count <= match_fsfs || match_sfsf ? combo_count + 1 : 0;
            time_out_r <= time_out_r + 1;
        end else if (pos_valid_data_i[width_p]) begin
            s1 <= pos_valid_data_i;
            s0 <= s1;
            sm1 <= s0;
            sm2 <= sm1;
            combo_count <= match_fsfs || match_sfsf ? combo_count + 1 : 0;
            time_out_r <= time_out_r + 1;
        end
    end else begin
        counter_r <= 0;
    end
end

always_comb begin
    counter_n = counter_r;

    if (neg_valid_data_i[width_p] && pos_valid_data_i[width_p]) begin
        counter_n = counter_r + 2;
    end else if (neg_valid_data_i[width_p] || pos_valid_data_i[width_p]) begin
        counter_n = counter_r + 1;
    end
end

always_comb begin:checkFSFS
	match_fsfs = ((&s0) ? sm1 + 1 == s1 : sm1 == s1) &&
    ((&sm2) ? s0 == {1'b1, {width_p {1'b0}}} : (sm2 + 1) == s0);
end:checkFSFS

//TODO: update the checkSFSF block to reflect the changes in checkFSFS
always_comb begin:checkSFSF
	match_sfsf = ((sm1 + 1) == s1) &&
    ((&sm1) ? sm2 + 1 == s0 : sm2 == s0);
end:checkSFSF
endmodule
