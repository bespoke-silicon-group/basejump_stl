module tag_checker 
  import bsg_cache_non_blocking_pkg::*;
  #(parameter id_width_p="inv"
    , parameter data_width_p="inv"
    , parameter addr_width_p="inv"
    , parameter cache_pkt_width_lp="inv"
    , parameter ways_p="inv"
    , parameter sets_p="inv"
    , parameter tag_width_lp="inv"
    , parameter block_size_in_words_p="inv"

    , parameter block_offset_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)+`BSG_SAFE_CLOG2(block_size_in_words_p)
    , parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    , parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
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


  `declare_bsg_cache_non_blocking_tag_info_s(tag_width_lp);
  bsg_cache_non_blocking_tag_info_s [ways_p-1:0][sets_p-1:0] shadow_tag;
  logic [data_width_p-1:0] result [*]; // indexed by id.

  wire [lg_ways_lp-1:0] addr_way = cache_pkt.addr[block_offset_width_lp+lg_sets_lp+:lg_ways_lp];
  wire [lg_sets_lp-1:0] addr_index = cache_pkt.addr[block_offset_width_lp+:lg_sets_lp];




  always_ff @ (posedge clk_i) begin
    if (reset_i) begin

      for (integer i = 0; i < ways_p; i++)
        for (integer j = 0; j < ways_p; j++)
          shadow_tag[i][j] <= '0;

    end
    else begin 
      if (v_i & ready_o & en_i) begin
        case (cache_pkt.opcode)

          TAGST: begin
            result[cache_pkt.id] = '0;
            shadow_tag[addr_way][addr_index].tag <= cache_pkt.data[0+:tag_width_lp];
            shadow_tag[addr_way][addr_index].valid <= cache_pkt.data[data_width_p-1];
            shadow_tag[addr_way][addr_index].lock <= cache_pkt.data[data_width_p-2];
          end

          TAGLV: begin
            result[cache_pkt.id] = '0;
            result[cache_pkt.id][1] = shadow_tag[addr_way][addr_index].lock;
            result[cache_pkt.id][0] = shadow_tag[addr_way][addr_index].valid;
          end
      
          TAGLA: begin
            result[cache_pkt.id] = {
              shadow_tag[addr_way][addr_index].tag,
              addr_index,
              {block_offset_width_lp{1'b0}}
            };
          end

        endcase
      end
    end


    if (~reset_i & v_o & yumi_i & en_i) begin
      $display("id=%d, data=%x", id_o, data_o);
      assert(result[id_o] == data_o)
        else $fatal("[BSG_FATAL] Output does not match expected result. Id= %d, Expected: %x. Actual: %x",
              id_o, result[id_o], data_o);
    end

  end
endmodule
