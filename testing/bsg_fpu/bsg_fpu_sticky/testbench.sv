module testbench();
 
  parameter period = 2;

  logic [12:0] input0;  
  logic [`BSG_WIDTH(13)-1:0] shamt0;
  logic sticky0;

  bsg_fpu_sticky #(.width_p(13)) fpu_sticky0 (
    .i(input0)
    ,.shamt_i(shamt0)
    ,.sticky_o(sticky0)
  );

  logic [15:0] input1;  
  logic [`BSG_WIDTH(16)-1:0] shamt1;
  logic sticky1;

  bsg_fpu_sticky #(.width_p(16)) fpu_sticky1 (
    .i(input1)
    ,.shamt_i(shamt1)
    ,.sticky_o(sticky1)
  );

  
  initial begin
    $vcdpluson;
    input0 = 13'b0_0100_0000_1100;
    shamt0 = 0;
    for (int i = 0; i <= 13; i++) begin
      #(period);
      shamt0 = shamt0 + 1;
    end
    
    input0 = 13'b0_0100_1000_0000;
    shamt0 = 0;
    for (int i = 0; i <= 13; i++) begin
      #(period);
      shamt0 = shamt0 + 1;
    end

    input0 = 13'b0_1100_0000_0000;
    shamt0 = 0;
    for (int i = 0; i <= 13; i++) begin
      #(period);
      shamt0 = shamt0 + 1;
    end

    input0 = 13'b1_0000_0000_0000;
    shamt0 = 0;
    for (int i = 0; i <= 13; i++) begin
      #(period);
      shamt0 = shamt0 + 1;
    end

    input1 = 16'b0010_0000_0000_0010;
    shamt1 = 0;
    for (int i = 0; i <= 16; i++) begin
      #(period);
      shamt1 = shamt1 + 1;
    end

  end


endmodule
