module testbench();

  localparam width_p = 8;
  logic [width_p-1:0] li;
  logic [`BSG_SAFE_CLOG2(width_p)-1:0] addr_lo;
  logic v_lo;

  bsg_priority_encode #(
    .width_p(8)
    ,.lo_to_hi_p(1)
  ) pe (
    .i(li)
    ,.addr_o(addr_lo)
    ,.v_o(v_lo)
  );

  initial begin
    li = 8'b0;
    #(10);
    assert(v_lo == 1'b0);
    assert(addr_lo == 8'b0);

    li = 8'b1;
    #(10);
    assert(v_lo == 1'b1);
    assert(addr_lo == 8'b0);

    li = 8'b11;
    #(10);
    assert(v_lo == 1'b1);
    assert(addr_lo == 8'b0);

    li = 8'b10;
    #(10);
    assert(v_lo == 1'b1);
    assert(addr_lo == 8'b1);

    li = 8'b100;
    #(10);
    assert(v_lo == 1'b1);
    assert(addr_lo == 8'd2);

    li = 8'b1000;
    #(10);
    assert(v_lo == 1'b1);
    assert(addr_lo == 8'd3);

    li = 8'b1000_0000;
    #(10);
    assert(v_lo == 1'b1);
    assert(addr_lo == 8'd7);

    li = 8'b1010_0000;
    #(10);
    assert(v_lo == 1'b1);
    assert(addr_lo == 8'd5);

    li = 8'b1011_0000;
    #(10);
    assert(v_lo == 1'b1);
    assert(addr_lo == 8'd4);
  end

endmodule
