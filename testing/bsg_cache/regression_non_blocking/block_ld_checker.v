module block_ld_checker
  import bsg_cache_non_blocking_pkg::*;
  #(parameter data_width_p="inv"
    , parameter id_width_p="inv"
    , parameter addr_width_p="inv"
    , parameter block_size_in_words_p="inv"
    , parameter cache_pkt_width_lp="inv"
    , parameter mem_size_p="inv"
  )
  (
    input clk_i
    , input reset_i
    , input en_i  
  
    , input v_i
    , input ready_o
    , input [cache_pkt_width_lp-1:0] cache_pkt_i

    , input v_o
    , input yumi_i
    , input [data_width_p-1:0] data_o
    , input [id_width_p-1:0] id_o
  );

  `declare_bsg_cache_non_blocking_pkt_s(id_width_p,addr_width_p,data_width_p);
  bsg_cache_non_blocking_pkt_s cache_pkt;
  assign cache_pkt = cache_pkt_i;

  // consistency checking
  logic [data_width_p-1:0] shadow_mem [mem_size_p-1:0];    // indexed by addr.
  logic [block_size_in_words_p-1:0][data_width_p-1:0] result [*]; // indexed by id.
  integer load_idx [*];

  always_ff @ (posedge clk_i) begin

    if (reset_i) begin

      for (integer i = 0; i < mem_size_p; i++)
        shadow_mem[i] <= '0;

    end
    else begin    
      if (v_i & ready_o & en_i) begin

        if (cache_pkt.opcode == TAGST) begin
          result[cache_pkt.id][0] = '0;
        end
        else if (cache_pkt.opcode == BLOCK_LD) begin
          for (integer i = 0; i < block_size_in_words_p; i++)
            result[cache_pkt.id][i] = shadow_mem[cache_pkt.addr[2+:`BSG_SAFE_CLOG2(mem_size_p)]+i];
          load_idx[cache_pkt.id] = 0;
        end
        else if (cache_pkt.opcode == SW) begin
          shadow_mem[cache_pkt.addr[2+:`BSG_SAFE_CLOG2(mem_size_p)]] = cache_pkt.data;
          result[cache_pkt.id][0] = '0;
        end
        else if (cache_pkt.opcode == LW) begin
          result[cache_pkt.id][0] = shadow_mem[cache_pkt.addr[2+:`BSG_SAFE_CLOG2(mem_size_p)]];
        end
        else if (cache_pkt.opcode == AFLINV) begin
          result[cache_pkt.id][0] = '0;
        end

      end
    end


    if (~reset_i & v_o & yumi_i & en_i) begin

      $display("id=%d, data=%x", id_o, data_o);

      if (load_idx.exists(id_o)) begin
        assert(result[id_o][load_idx[id_o]] == data_o)
          else $fatal("Output does not match expected result. Id= %d, Expected: %x. Actual: %x",
                id_o, result[id_o][load_idx[id_o]], data_o);
        load_idx[id_o]++;
      end
      else begin
        assert(result[id_o][0] == data_o)
          else $fatal("Output does not match expected result. Id= %d, Expected: %x. Actual: %x",
                id_o, result[id_o][0], data_o);
      end
    end

  end

endmodule
