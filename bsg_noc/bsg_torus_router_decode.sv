`include "bsg_defines.sv"


module bsg_torus_router_decode
  import bsg_noc_pkg::*;
  #(parameter `BSG_INV_PARAM(x_cord_width_p)
    , `BSG_INV_PARAM(y_cord_width_p)
    , `BSG_INV_PARAM(XY_order_p)
    , `BSG_INV_PARAM(vc_id_p)   // this VC's id;
    , `BSG_INV_PARAM(num_vc_p)

    , `BSG_INV_PARAM(base_x_cord_p)
    , `BSG_INV_PARAM(base_y_cord_p)
    , `BSG_INV_PARAM(num_tiles_x_p)
    , `BSG_INV_PARAM(num_tiles_y_p)

    , `BSG_INV_PARAM(from_p)

    , parameter dims_p=2
    , localparam sw_dirs_lp=(dims_p*2)+1
    , localparam vc_dirs_lp=(num_vc_p*dims_p*2)+1
  )
  (
    input   [x_cord_width_p-1:0] dest_x_i
    , input [y_cord_width_p-1:0] dest_y_i
    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i
    , output logic [sw_dirs_lp-1:0]  sw_dir_sel_o
    , output logic [vc_dirs_lp-1:0] vc_dir_sel_o
  );


  // my base cord;
  wire [x_cord_width_p-1:0] my_base_x = my_x_i - x_cord_width_p'(base_x_cord_p);
  wire [y_cord_width_p-1:0] my_base_y = my_y_i - y_cord_width_p'(base_y_cord_p);

  // my logical torus cord;
  wire [x_cord_width_p-1:0] my_torus_x = ((my_x_i % 2) == 0)
    ? x_cord_width_p'(my_base_x/2)
    : (x_cord_width_p'(num_tiles_x_p-1) - x_cord_width_p'(my_base_x/2));
  wire [y_cord_width_p-1:0] my_torus_y = ((my_y_i % 2) == 0)
    ? y_cord_width_p'(my_base_y/2)
    : (y_cord_width_p'(num_tiles_y_p-1) - y_cord_width_p'(my_base_y/2));

  // target cord;
  wire [x_cord_width_p-1:0] target_base_x = dest_x_i - x_cord_width_p'(base_x_cord_p);
  wire [y_cord_width_p-1:0] target_base_y = dest_y_i - y_cord_width_p'(base_y_cord_p);

  // target torus cord;
  wire [x_cord_width_p-1:0] target_torus_x = ((dest_x_i % 2) == 0)
    ? x_cord_width_p'(target_base_x/2)
    : x_cord_width_p'((num_tiles_x_p-1) - (target_base_x/2));
  wire [y_cord_width_p-1:0] target_torus_y = ((dest_y_i % 2) == 0)
    ? y_cord_width_p'(target_base_y/2)
    : y_cord_width_p'((num_tiles_y_p-1) - (target_base_y/2));


  // Compare coordinates;
  wire x_eq = (dest_x_i == my_x_i);
  wire y_eq = (dest_y_i == my_y_i);

  
  // X torus distance;
  logic [x_cord_width_p-1:0] x_cw_dist, x_ccw_dist;

  always_comb begin
    // Clockwise dist;
    x_cw_dist = (target_torus_x > my_torus_x)
      ? (target_torus_x - my_torus_x)
      : (num_tiles_x_p + target_torus_x - my_torus_x);

    // counter-cw dist;
    x_ccw_dist = (num_tiles_x_p - x_cw_dist) % num_tiles_x_p;
  end


  // Y torus distance;
  logic [y_cord_width_p-1:0] y_cw_dist, y_ccw_dist;

  always_comb begin
    // Clockwise dist;
    y_cw_dist = (target_torus_y > my_torus_y)
      ? (target_torus_y - my_torus_y)
      : (num_tiles_y_p + target_torus_y - my_torus_y);

    // counter-cw dist;
    y_ccw_dist = (num_tiles_y_p - y_cw_dist) % num_tiles_y_p;
  end





  // Routing rule;
  localparam sw_idx_width_lp = `BSG_SAFE_CLOG2(sw_dirs_lp);
  localparam vc_idx_width_lp = `BSG_SAFE_CLOG2(num_vc_p);
  logic [sw_idx_width_lp-1:0] dir_sel_id;
  logic [vc_idx_width_lp-1:0] vc_sel_id;


if (XY_order_p) begin

  /*            YX-order            */
  wire from_PEW = (from_p == E) || (from_p == W) || (from_p == P);

  always_comb begin

    if (x_eq) begin
      // Go vertical;
      if (y_eq) begin
        // To Proc;
        dir_sel_id = P;
        vc_sel_id = 1'b0;
      end
      else begin

        if (y_cw_dist < y_ccw_dist) begin
          // Go clockwise;
          if (my_y_i % 2 == 0) begin
            dir_sel_id = S;
            vc_sel_id = (my_base_y == (num_tiles_y_p/2)-2)
              ? 1'b1    // dateline;
              : (from_PEW ? 1'b0 : vc_id_p);
          end
          else begin
            dir_sel_id = N;
            vc_sel_id = (from_PEW ? 1'b0 : vc_id_p);
          end
        end
        else if (y_cw_dist > y_ccw_dist) begin
          // go counter-clockwise;
          if (my_y_i % 2 == 0) begin
            dir_sel_id = N;
            vc_sel_id = (my_base_y == (num_tiles_y_p/2))
              ? 1'b1    // dateline;
              : (from_PEW ? 1'b0 : vc_id_p);
          end
          else begin
            dir_sel_id = S;
            vc_sel_id = (from_PEW ? 1'b0 : vc_id_p);
          end
        end
        else begin
          // tie-breaker;
          if (my_torus_y % 2 == 0) begin
            // Go clockwise;
            if (my_y_i % 2 == 0) begin
              dir_sel_id = S;
              vc_sel_id = (my_base_y == (num_tiles_y_p/2)-2)
                ? 1'b1    // dateline;
                : (from_PEW ? 1'b0 : vc_id_p);
            end
            else begin
              dir_sel_id = N;
              vc_sel_id = (from_PEW ? 1'b0 : vc_id_p);
            end
          end
          else begin
            // go counter-clockwise;
            if (my_y_i % 2 == 0) begin
              dir_sel_id = N;
              vc_sel_id = (my_base_y == (num_tiles_y_p/2))
                ? 1'b1    // dateline;
                : (from_PEW ? 1'b0 : vc_id_p);
            end
            else begin
              dir_sel_id = S;
              vc_sel_id = (from_PEW ? 1'b0 : vc_id_p);
            end
          end
        end
      end

    end
    else begin

      // Go horizontal;
      if (x_cw_dist < x_ccw_dist) begin
        // go clockwise;
        if (my_x_i % 2 == 0) begin
          dir_sel_id = E;
          vc_sel_id = (my_base_x == (num_tiles_x_p/2)-2)
            ? 1'b1    // dateline;
            : vc_id_p;
        end
        else begin
          dir_sel_id = W;
          vc_sel_id = vc_id_p;
        end
      end
      else if (x_cw_dist > x_ccw_dist) begin
        // go counter-clockwise
        if (my_x_i % 2 == 0) begin
          dir_sel_id = W;
          vc_sel_id = (my_base_x == (num_tiles_x_p/2))
            ? 1'b1    // dateline;
            : vc_id_p;
        end
        else begin
          dir_sel_id = E;
          vc_sel_id = vc_id_p;
        end
      end
      else begin
        //  tie-breaker;
        if (my_torus_x % 2 == 0) begin
          // go clockwise;
          if (my_x_i % 2 == 0) begin
            dir_sel_id = E;
            vc_sel_id = (my_base_x == (num_tiles_x_p/2)-2)
              ? 1'b1    // dateline;
              : vc_id_p;
          end
          else begin
            dir_sel_id = W;
            vc_sel_id = vc_id_p;
          end
        end
        else begin
          // go counter-clockwise
          if (my_x_i % 2 == 0) begin
            dir_sel_id = W;
            vc_sel_id = (my_base_x == (num_tiles_x_p/2))
              ? 1'b1    // dateline;
              : vc_id_p;
          end
          else begin
            dir_sel_id = E;
            vc_sel_id = vc_id_p;
          end
        end
      end 
      
    end
  end

end
/*            YX-order            */
else begin

  wire from_SNP = (from_p == S) || (from_p == N) || (from_p == P);

  always_comb begin
    if (y_eq) begin
      // Go horizontal;
      if (x_eq) begin
        // To Proc;
        dir_sel_id = P;
        vc_sel_id = 1'b0;
      end
      else begin
        // Go horizontal;
        if (x_cw_dist < x_ccw_dist) begin
          // go clockwise;
          if (my_x_i % 2 == 0) begin
            dir_sel_id = E;
            vc_sel_id = (my_base_x == (num_tiles_x_p/2)-2)
              ? 1'b1    // dateline;
              : (from_SNP ? 1'b0 : vc_id_p);
          end
          else begin
            dir_sel_id = W;
            vc_sel_id = (from_SNP ? 1'b0 : vc_id_p);
          end
        end
        else if (x_cw_dist > x_ccw_dist) begin
          // go counter-clockwise
          if (my_x_i % 2 == 0) begin
            dir_sel_id = W;
            vc_sel_id = (my_base_x == (num_tiles_x_p/2))
              ? 1'b1    // dateline;
              : (from_SNP ? 1'b0 : vc_id_p);
          end
          else begin
            dir_sel_id = E;
            vc_sel_id = (from_SNP ? 1'b0 : vc_id_p);
          end
        end
        else begin
          //  tie-breaker;
          if (my_torus_x % 2 == 0) begin
            // go clockwise;
            if (my_x_i % 2 == 0) begin
              dir_sel_id = E;
              vc_sel_id = (my_base_x == (num_tiles_x_p/2)-2)
                ? 1'b1    // dateline;
              : (from_SNP ? 1'b0 : vc_id_p);
            end
            else begin
              dir_sel_id = W;
              vc_sel_id = (from_SNP ? 1'b0 : vc_id_p);
            end
          end
          else begin
            // go counter-clockwise
            if (my_x_i % 2 == 0) begin
              dir_sel_id = W;
              vc_sel_id = (my_base_x == (num_tiles_x_p/2))
                ? 1'b1    // dateline;
                : (from_SNP ? 1'b0 : vc_id_p);
            end
            else begin
              dir_sel_id = E;
              vc_sel_id = (from_SNP ? 1'b0 : vc_id_p);
            end
          end
        end 
      end
    end
    else begin


      // Go vertical;
      if (y_cw_dist < y_ccw_dist) begin
        // Go clockwise;
        if (my_y_i % 2 == 0) begin
          dir_sel_id = S;
          vc_sel_id = (my_base_y == (num_tiles_y_p/2)-2)
            ? 1'b1    // dateline;
            : vc_id_p;
        end
        else begin
          dir_sel_id = N;
          vc_sel_id = vc_id_p;
        end
      end
      else if (y_cw_dist > y_ccw_dist) begin
        // go counter-clockwise;
        if (my_y_i % 2 == 0) begin
          dir_sel_id = N;
          vc_sel_id = (my_base_y == (num_tiles_y_p/2))
            ? 1'b1    // dateline;
            : vc_id_p;
        end
        else begin
          dir_sel_id = S;
          vc_sel_id = vc_id_p;
        end
      end
      else begin
        // tie-breaker;
        if (my_torus_y % 2 == 0) begin
          // Go clockwise;
          if (my_y_i % 2 == 0) begin
            dir_sel_id = S;
            vc_sel_id = (my_base_y == (num_tiles_y_p/2)-2)
              ? 1'b1    // dateline;
              : vc_id_p;
          end
          else begin
            dir_sel_id = N;
            vc_sel_id = vc_id_p;
          end
        end
        else begin
          // go counter-clockwise;
          if (my_y_i % 2 == 0) begin
            dir_sel_id = N;
            vc_sel_id = (my_base_y == (num_tiles_y_p/2))
              ? 1'b1    // dateline;
              : vc_id_p;
          end
          else begin
            dir_sel_id = S;
            vc_sel_id = vc_id_p;
          end
        end
      end
    end

  end
end


  assign sw_dir_sel_o = sw_dirs_lp'(1'b1 << dir_sel_id);
  assign vc_dir_sel_o = vc_dirs_lp'((dir_sel_id == P)
    ? (1'b1)
    : (1'b1 << ((num_vc_p*dir_sel_id)-1+vc_sel_id)));
 


endmodule


`BSG_ABSTRACT_MODULE(bsg_torus_router_decode)
