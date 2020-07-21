module basic_checker
  import bsg_cache_pkg::*;
  #(parameter data_width_p="inv"
    , parameter addr_width_p="inv"
    , parameter mem_size_p="inv"

    , parameter data_mask_width_lp=(data_width_p>>3)
    , parameter cache_pkt_width_lp= `bsg_cache_pkt_width(addr_width_p,data_width_p)
  ) 
  (
    input clk_i
    , input reset_i
      
    , input en_i

    , input [cache_pkt_width_lp-1:0] cache_pkt_i
    , input v_i
    , input ready_o

    , input [data_width_p-1:0] data_o
    , input v_o
    , input yumi_i
  );


  `declare_bsg_cache_pkt_s(addr_width_p,data_width_p);

  bsg_cache_pkt_s cache_pkt;
  assign cache_pkt = cache_pkt_i;

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

  logic [data_width_p-1:0] load_mask;
  bsg_expand_bitmask #(
    .in_width_p(4)
    ,.expand_p(8)
  ) eb (
    .i(cache_pkt.mask)
    ,.o(load_mask)
  );

  always_comb begin
    case (cache_pkt.opcode)
      LW: load_data_final = load_data;
      LH: load_data_final = {{16{half_sel[15]}}, half_sel};
      LB: load_data_final = {{24{byte_sel[7]}}, byte_sel};
      LHU: load_data_final = {{16{1'b0}}, half_sel};
      LBU: load_data_final = {{24{1'b0}}, byte_sel};
      LM: load_data_final = load_data & load_mask;
      default: load_data_final = '0;
    endcase
  end



  integer send_id, recv_id;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      send_id <= '0;
      recv_id <= '0;
      for (integer i = 0; i < mem_size_p; i++)
        shadow_mem[i] = '0;
    end
    else begin

      if (en_i) begin

        // input recorder
        if (v_i & ready_o) begin
          case (cache_pkt.opcode)
            TAGST: begin
              result[send_id] = '0;
              send_id++;
            end
            LM, LW, LH, LB, LHU, LBU: begin
              result[send_id] = load_data_final;
              send_id++;
            end
            SW, SH, SB, SM: begin
              result[send_id] = '0;
              send_id++;
              for (integer i = 0; i < data_mask_width_lp; i++)
                if (store_mask[i])
                  shadow_mem[cache_pkt_word_addr][8*i+:8] <= store_data[8*i+:8];
            end
            AMOSWAP_W: begin
              result[send_id] <= load_data;
              send_id <= send_id + 1;
              shadow_mem[cache_pkt_word_addr] <= cache_pkt.data;
            end
            AMOADD_W: begin
              result[send_id] <= load_data;
              send_id <= send_id + 1;
              shadow_mem[cache_pkt_word_addr] <= cache_pkt.data + load_data;
            end
            AMOXOR_W: begin
              result[send_id] <= load_data;
              send_id <= send_id + 1;
              shadow_mem[cache_pkt_word_addr] <= cache_pkt.data ^ load_data;
            end
            AMOAND_W: begin
              result[send_id] <= load_data;
              send_id <= send_id + 1;
              shadow_mem[cache_pkt_word_addr] <= cache_pkt.data & load_data;
            end
            AMOOR_W: begin
              result[send_id] <= load_data;
              send_id <= send_id + 1;
              shadow_mem[cache_pkt_word_addr] <= cache_pkt.data | load_data;
            end
            AMOMIN_W: begin
              result[send_id] <= load_data;
              send_id <= send_id + 1;
              shadow_mem[cache_pkt_word_addr] <= ($signed(cache_pkt.data) < $signed(load_data))
                ? cache_pkt.data
                : load_data;
            end
            AMOMAX_W: begin
              result[send_id] <= load_data;
              send_id <= send_id + 1;
              shadow_mem[cache_pkt_word_addr] <= ($signed(cache_pkt.data) > $signed(load_data))
                ? cache_pkt.data
                : load_data;
            end
            AMOMINU_W: begin
              result[send_id] <= load_data;
              send_id <= send_id + 1;
              shadow_mem[cache_pkt_word_addr] <= (cache_pkt.data < load_data)
                ? cache_pkt.data
                : load_data;
            end
            AMOMAXU_W: begin
              result[send_id] <= load_data;
              send_id <= send_id + 1;
              shadow_mem[cache_pkt_word_addr] <= (cache_pkt.data > load_data)
                ? cache_pkt.data
                : load_data;
            end
            ALOCK, AUNLOCK, TAGFL, AFLINV: begin
              result[send_id] = '0;
              send_id++;
            end
          endcase
        end

        // output checker
        if (v_o & yumi_i) begin
          assert(result[recv_id] == data_o)
            else $fatal("[BSG_FATAL] output does not match expected result. Id=%d, Expected: %x. Actual: %x.",
                    recv_id, result[recv_id], data_o);
          recv_id++;
        end
      end
    end
  end

  
endmodule
