/**
 *  bsg_sticky.v
 *
 *  calculate the sticky bit, for given input and shift amount.
 *
 *  @author Tommy Jung
 */

module bsg_sticky #(parameter width_p="inv") (
  input [width_p-1:0] a_i // input
  ,input [`BSG_WIDTH(width_p)-1:0] shamt_i // shift amount
  ,output logic sticky_o
);

  genvar i;

  // or of two
  logic [(width_p/2)-1:0] or2;
  for (i = 0; i < width_p/2; i++) begin
    assign or2[i] = |a_i[2*i+:2];
  end

  // or of four
  logic [(width_p/4)-1:0] or4;
  for (i = 0; i < width_p/4; i++) begin
    assign or4[i] = |or2[2*i+:2];  
  end

  // chain of or4
  logic [(width_p/4)-1:0] or4_chain;
  for (i = 0; i < width_p/4; i++) begin
    if (i == 0) begin
      assign or4_chain[i] = or4[i];
    end
    else begin
      assign or4_chain[i] = or4[i] | or4_chain[i-1];
    end
  end

  // group or
  logic [width_p-1:0] group_or;
  for (i = 0; i < width_p; i++) begin
    if (i == 0) begin
      assign group_or[i] = a_i[0];
    end
    else if (i == 1) begin
      assign group_or[i] = or2[0];
    end
    else if (i == 2) begin
      assign group_or[i] = or2[0] | a_i[2];
    end
    else if (i == 3) begin
      assign group_or[i] = or4[0];
    end
    else begin
      if (i % 4 == 0) begin
        assign group_or[i] = or4_chain[(i/4)-1] | a_i[i];
      end
      else if (i % 4 == 1) begin
        assign group_or[i] = or4_chain[(i/4)-1] | or2[i/2];
      end
      else if (i % 4 == 2) begin
        assign group_or[i] = or4_chain[(i/4)-1] | or2[(i/2)-1] | a_i[i];
      end
      else begin
        assign group_or[i] = or4_chain[i/4];
      end
    end
  end

  // answer
  logic [width_p:0] answer;
  assign answer = {group_or, 1'b0};

  // final output
  assign sticky_o = answer[shamt_i];

endmodule
