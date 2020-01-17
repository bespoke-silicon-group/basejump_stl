module cache_miss_counter 
  (
    input clk_i
    , input reset_i

    , input miss_v
  );

  integer count_r;
  logic miss_r;

  localparam filename_p = "miss_latency.txt";

  integer fd;

  initial begin
    fd = $fopen(filename_p, "w");
    $fwrite(fd, "");
    $fclose(fd);

    forever begin
      @(negedge clk_i) begin

        if (miss_r & ~miss_v) begin
          fd = $fopen(filename_p, "a");
          $fwrite(fd, "%t,%d\n", $time, count_r);
          $fclose(fd);
        end
      end
    end
  end

  always_ff @ (negedge clk_i) begin
    if (reset_i) begin
      count_r <= 0;
      miss_r <= 1'b0;
    end
    else begin
      miss_r <= miss_v;
      count_r <= miss_v
        ? count_r + 1
        : 0;
    end
  end

endmodule
