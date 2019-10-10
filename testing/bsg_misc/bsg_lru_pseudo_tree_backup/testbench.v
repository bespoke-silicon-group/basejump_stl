module testbench();

  parameter ways_p = 8;
  parameter lg_ways_lp = `BSG_SAFE_CLOG2(ways_p);

  logic [ways_p-2:0] lru_bits_li;
  logic [ways_p-1:0] disabled_ways_li;
  logic [lg_ways_lp-1:0] lru_way_id_lo;

  bsg_lru_pseudo_tree_backup #(
    .ways_p(ways_p)
  ) lru (
    .lru_bits_i(lru_bits_li)
    ,.disabled_ways_i(disabled_ways_li)
    ,.lru_way_id_o(lru_way_id_lo)
  );

  task test(
    input [ways_p-2:0] lru_bits
    , input [ways_p-1:0] disabled_ways
    , input [lg_ways_lp-1:0] expected
  );

    lru_bits_li = lru_bits;
    disabled_ways_li = disabled_ways;
    #10; 
    assert(lru_way_id_lo == expected)
      else $fatal("Expected: %b, Actual: %b", expected, lru_way_id_lo);
    #10; 

  endtask

  initial begin
    test(7'b000_0000, 8'b0000_0000, 3'd0);
    test(7'b000_0000, 8'b0000_0001, 3'd1);
    test(7'b000_0000, 8'b0000_0011, 3'd2);
    test(7'b000_0000, 8'b0000_0111, 3'd3);
    test(7'b000_0000, 8'b0000_1111, 3'd4);
    test(7'b000_0000, 8'b0001_1111, 3'd5);
    test(7'b000_0000, 8'b0011_1111, 3'd6);
    test(7'b000_0000, 8'b0111_1111, 3'd7);

    test(7'b000_1101, 8'b0000_0000, 3'd6);
    test(7'b000_1101, 8'b0100_0000, 3'd7);
    test(7'b000_1101, 8'b1100_0000, 3'd4);
    test(7'b000_1101, 8'b1101_0000, 3'd5);
    test(7'b000_1101, 8'b1111_0000, 3'd1);
    test(7'b000_1101, 8'b1111_0010, 3'd0);
    test(7'b000_1101, 8'b1111_0011, 3'd2);
    test(7'b000_1101, 8'b1111_0111, 3'd3);
    test(7'b000_1101, 8'b1111_1011, 3'd2);

    test(7'b011_0110, 8'b0000_0000, 3'd3);
    test(7'b011_0110, 8'b0000_1000, 3'd2);
    test(7'b011_0110, 8'b0000_1100, 3'd0);
    test(7'b011_0110, 8'b0000_1101, 3'd1);
    test(7'b011_0110, 8'b0000_1111, 3'd6);
    test(7'b011_0110, 8'b0100_1111, 3'd7);
    test(7'b011_0110, 8'b1100_1111, 3'd5);
    test(7'b011_0110, 8'b1110_1111, 3'd4);

    $display("[BSG_PASS] Test Successful!");

    $finish;
  end


endmodule
