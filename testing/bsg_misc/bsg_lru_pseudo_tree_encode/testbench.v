module testbench();

  localparam ways_p = 8;   
  localparam lg_ways_lp =`BSG_SAFE_CLOG2(ways_p);

  logic [ways_p-2:0] lru_li;
  logic [lg_ways_lp-1:0] way_id_lo;

  bsg_lru_pseudo_tree_encode #(
    .ways_p(ways_p)
  ) DUT (
    .lru_i(lru_li)
    ,.way_id_o(way_id_lo)
  );

  task test(
    input [ways_p-2:0] lru
    , input [lg_ways_lp-1:0] expected
  );

    lru_li = lru;
    #10;
    assert(expected == way_id_lo) else
      $fatal("[BSG_FATAL] expected: %b, actual: %b", expected, way_id_lo);
    #10;

  endtask

  initial begin
    // 0
    test(7'b000_0000, 3'b000);
    test(7'b000_0100, 3'b000);
    test(7'b111_0100, 3'b000);
    test(7'b101_0100, 3'b000);

    // 1
    test(7'b000_1000, 3'b001);
    test(7'b000_1100, 3'b001);
    test(7'b100_1000, 3'b001);
    test(7'b110_1000, 3'b001);

    // 2
    test(7'b000_0010, 3'b010);
    test(7'b000_1010, 3'b010);
    test(7'b100_1010, 3'b010);
    test(7'b110_1010, 3'b010);

    // 3
    test(7'b001_0010, 3'b011);
    test(7'b001_0110, 3'b011);
    test(7'b101_0110, 3'b011);
    test(7'b111_0110, 3'b011);

    // 4
    test(7'b000_0001, 3'b100);
    test(7'b000_1001, 3'b100);
    test(7'b001_1001, 3'b100);
    test(7'b101_1001, 3'b100);


    // 5
    test(7'b010_0001, 3'b101);
    test(7'b010_0011, 3'b101);
    test(7'b010_1011, 3'b101);
    test(7'b011_1011, 3'b101);

    // 6
    test(7'b000_0101, 3'b110);
    test(7'b010_0101, 3'b110);
    test(7'b011_0101, 3'b110);
    test(7'b011_1101, 3'b110);

    // 7
    test(7'b100_0101, 3'b111);
    test(7'b100_0111, 3'b111);
    test(7'b111_1111, 3'b111);
    test(7'b101_1111, 3'b111);

    $display("[BSG_FINISH] Test Successful!");
    $finish; 
  end

endmodule
