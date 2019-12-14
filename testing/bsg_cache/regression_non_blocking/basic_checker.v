module basic_checker 
  import bsg_cache_non_blocking_pkg::*;
  #(parameter data_width_p="inv"
    , parameter id_width_p="inv"
    , parameter addr_width_p="inv"
    , parameter cache_pkt_width_lp="inv"
    , parameter data_mask_width_lp=(data_width_p>>3)
    , parameter mem_size_p="inv"
  )
  (
    input clk_i
    , input reset_i

    , input en_i

    , input [cache_pkt_width_lp-1:0] cache_pkt_i
    , input ready_o
    , input v_i

    , input [id_width_p-1:0] id_o
    , input [data_width_p-1:0] data_o
    , input v_o
    , input yumi_i
  );

  `declare_bsg_cache_non_blocking_pkt_s(id_width_p,addr_width_p,data_width_p);
  bsg_cache_non_blocking_pkt_s cache_pkt;
  assign cache_pkt = cache_pkt_i;
 


  // shadow mem
  logic [data_width_p-1:0] shadow_mem [mem_size_p-1:0];
  logic [data_width_p-1:0] result [*];

  wire [addr_width_p-1:0] cache_pkt_word_addr = cache_pkt.addr[addr_width_p-1:2];

  // store logic
  logic [data_width_p-1:0] store_data;
  logic [data_mask_width_lp-1:0] store_mask;

  always_comb begin
    case (cache_pkt.opcode)
      SW: begin
        store_data = cache_pkt.data;
        store_mask = 4'b1111;
      end
      SH: begin
        store_data = {2{cache_pkt.data[15:0]}};
        store_mask = {
          {2{ cache_pkt.addr[1]}},
          {2{~cache_pkt.addr[1]}}
        };
      end
      SB: begin
        store_data = {4{cache_pkt.data[7:0]}};
        store_mask = {
           cache_pkt.addr[1] &  cache_pkt.addr[0],
           cache_pkt.addr[1] & ~cache_pkt.addr[0],
          ~cache_pkt.addr[1] &  cache_pkt.addr[0],
          ~cache_pkt.addr[1] & ~cache_pkt.addr[0]
        };
      end
      SM: begin
        store_data = cache_pkt.data;
        store_mask = cache_pkt.mask;
      end
      default: begin
        store_data = '0;
        store_mask = '0;
      end
    endcase
  end

  // load logic
  logic [data_width_p-1:0] load_data, load_data_final;
  logic [7:0] byte_sel;
  logic [15:0] half_sel;

  assign load_data = shadow_mem[cache_pkt_word_addr];

  bsg_mux #(
    .els_p(4)
    ,.width_p(8)
  ) byte_mux (
    .data_i(load_data)
    ,.sel_i(cache_pkt.addr[1:0])
    ,.data_o(byte_sel)
  );

  bsg_mux #(
    .els_p(2)
    ,.width_p(16)
  ) half_mux (
    .data_i(load_data)
    ,.sel_i(cache_pkt.addr[1])
    ,.data_o(half_sel)
  );

  always_comb begin
    case (cache_pkt.opcode)
      LW: load_data_final = load_data;
      LH: load_data_final = {{16{half_sel[15]}}, half_sel};
      LB: load_data_final = {{24{byte_sel[7]}}, byte_sel};
      LHU: load_data_final = {{16{1'b0}}, half_sel};
      LBU: load_data_final = {{24{1'b0}}, byte_sel};
      default: load_data_final = '0;
    endcase
  end


  always_ff @ (posedge clk_i) begin

    if (reset_i) begin

      for (integer i = 0; i < mem_size_p; i++)
        shadow_mem[i] <= '0;

    end
    else begin
      if (en_i) begin
        if (v_i & ready_o) begin
          case (cache_pkt.opcode)
            TAGST: begin
              result[cache_pkt.id] = '0;
            end

            ALOCK, AUNLOCK: begin
              result[cache_pkt.id] = '0;
            end

            TAGFL, AFL, AFLINV: begin
              result[cache_pkt.id] = '0;
            end

            SB, SH, SW, SM: begin
              result[cache_pkt.id] = '0;
              for (integer i = 0; i < data_mask_width_lp; i++)
                if (store_mask[i])
                  shadow_mem[cache_pkt_word_addr][8*i+:8] <= store_data[8*i+:8];
            end

            LW, LH, LB, LHU, LBU: begin
              result[cache_pkt.id] = load_data_final;
            end
          endcase
        end
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
