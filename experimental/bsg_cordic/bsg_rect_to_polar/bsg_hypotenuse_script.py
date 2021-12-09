import math, sys

def lookup_compute(posprec, precision_result):
    lookup=[]
    for j in range(0,posprec+1):
        m=(math.atan2(1,2**j)*180)/math.pi
        lookup.append(format(round(m*(2**precision_result)),'x'))
    return lookup

def constant_compute(posprec, ansbitlen):
    const=1
    for i in range(0,posprec):
        comp = math.cos(math.atan2(1,2**i))
        const=const*comp
    const = format(round(const*(2**(ansbitlen-1))),'x')
    return const

def signed_constant(ansbitlen):
    const = "1"
    for i in range(0,ansbitlen-1):
        const = const + str(0)
    return (hex(int(const, 2)))

def signed_constant2(ansbitlen):
    const = ""
    for i in range(0,ansbitlen):
        const = const + str(1)
    return (hex(int(const, 2)))

def bsg_sine_cosine_init(angbitlen, ansbitlen, posprec):
    print('''
    module bsg_cordic_hypotenuse #(precis_p = %(p)d, ang_width_p = %(g)d, ans_width_p = %(s)d, scale_width_p = %(sw)d)
    (
    input clk_i
    ,input signed [ans_width_p-1:0] x_i
    ,input signed [ans_width_p-1:0] y_i
    ,input ready_i
    ,input val_i
    ,output signed [ans_width_p-1:0] mag_o
    ,output signed [ang_width_p-1:0] angl_o
    ,output ready_o
    ,output val_o
    );
    
    logic [ans_width_p-1:0] x_set, y_set;
    logic signed [ans_width_p-1:0] x_in, y_in;
    logic val_in;
    logic signed [precis_p+1:0][ans_width_p-1:0] x ;
    logic signed [precis_p+1:0][ans_width_p-1:0] y ;
    logic signed [precis_p+1:0][ang_width_p-1:0] ang ;
    logic [precis_p+1:0] val ;
    logic [precis_p+1:0] switch ;
    logic [precis_p+1:0] quad_x ;
    logic [precis_p+1:0] quad_y ;
    logic signed [precis_p:0][ans_width_p-1:0] x_ans ;
    logic signed [precis_p:0][ans_width_p-1:0] y_ans ;
    logic signed [precis_p:0][ang_width_p-1:0] ang_ans ; 
    logic [precis_p:0] val_ans ;
    logic [precis_p:0] switch_ans ;
    logic [precis_p:0] quad_x_ans ;
    logic [precis_p:0] quad_y_ans ;
    logic val_out;
    wire stall_pipe = val_o & (~ready_i);
    
    ''' %{'s':ansbitlen, 'g':angbitlen, 'p':posprec, 'sw':precisionbitlen})
    return

def lookup_initialization(posprec, angbitlen, result):
    print("    localparam [precis_p:0][ang_width_p-1:0] ang_lookup_lp={" )
    for i in range(posprec,0,-1):
        print("     %(g)d'h%(r)s," %{'g':angbitlen,'r':result[i] })
    print("     %(g)d'h%(r)s };" %{'g':angbitlen,'r':result[0] })
    return

def main_body_print(precisionbitlen, constant, angbitlen, ninetyconstant, one_eighty_constant):
    print('''
    wire quad_x_init = x_i[ans_width_p-1];
    wire quad_y_init = y_i[ans_width_p-1];
    
    always_ff @(posedge clk_i) begin
    if(~stall_pipe) begin
        y_in <= (quad_y_init) ? ~y_i + 1 : y_i;
        x_in <= (quad_x_init) ? ~x_i + 1 : x_i;
        val_in <= val_i;
    end
    end

    wire switch_op = (x_in < y_in);
    assign x_set = ( switch_op ) ? y_in : x_in;
    assign y_set = ( switch_op ) ? x_in : y_in;
    
    always_ff @(posedge clk_i) begin
        if(~stall_pipe) begin
            x[0] <= x_set;
            y[0] <= y_set;
          ang[0] <= 0;
          val[0] <= val_in;
          switch[0] <= switch_op; 
          quad_y[0] <= quad_y_init;
          quad_x[0] <= quad_x_init;
        end
        else if(stall_pipe) begin
            x[0] <= x[0];
            y[0] <= y[0];
          ang[0] <= ang[0];
          val[0] <= val[0];
          switch[0] <= switch[0]; 
          quad_y[0] <= quad_y[0];
          quad_x[0] <= quad_x[0];
        end
    end 
    
    genvar i;
    
    generate
        for(i = 0; i <= precis_p ; i = i+1)
            begin : stage
               bsg_cordic_rect_to_polar_stage #(.stage_p(i), .ang_width_p(ang_width_p), .ans_width_p(ans_width_p)) cs
                       (.x_i(x[i])
                        ,.y_i(y[i])
                        ,.ang_i(ang[i])
                        ,.ang_lookup_i(ang_lookup_lp[i])
                        ,.val_i(val[i])
                        ,.switch_i(switch[i])
                        ,.quad_x_i(quad_x[i])
                        ,.quad_y_i(quad_y[i])
                        ,.x_o(x_ans[i])
                        ,.y_o(y_ans[i])
                        ,.ang_o(ang_ans[i])
                        ,.val_o(val_ans[i])
                        ,.switch_o(switch_ans[i])
                        ,.quad_x_o(quad_x_ans[i])
                        ,.quad_y_o(quad_y_ans[i])
                        );
          
                    always_ff @(posedge clk_i)
                      begin
                        if(~stall_pipe) begin
                            x[i+1] <= x_ans[i];
                            y[i+1] <= y_ans[i];
                            ang[i+1] <= ang_ans[i];
                            val[i+1] <= val_ans[i];
                            switch[i+1] <= switch_ans[i];
                            quad_x[i+1] <= quad_x_ans[i];
                            quad_y[i+1] <= quad_y_ans[i];
                        end
                        else if(stall_pipe) begin
                            x[i+1] <= x[i+1];
                            y[i+1] <= y[i+1];
                            ang[i+1] <= ang[i+1];
                            val[i+1] <= val[i+1];
                            switch[i+1] <= switch[i+1];
                            quad_x[i+1] <= quad_x[i+1];
                            quad_y[i+1] <= quad_y[i+1];
                        end
                        end
                 end
          
            endgenerate
            /* verilator lint_off UNUSED */
            
            logic [ans_width_p+scale_width_p-1:0] scaling_ans_n;
            logic [ans_width_p-1:0] scaling_ans_r;
            logic [ang_width_p-1:0] shift_ang_n, shift_ang_r;
            
            assign scaling_ans_n = (x[precis_p+1]* %(p)d'h%(c)s)>>>(scale_width_p - 1);
            wire [ang_width_p-1:0] ang_sec_half = %(a)d'h%(nc)s - ang[precis_p+1];
            assign shift_ang_n = switch[precis_p+1]? ang_sec_half: ang[precis_p+1];
            
            always_ff@(posedge clk_i) begin
                scaling_ans_r <= scaling_ans_n[ans_width_p-1:0];
                shift_ang_r <= shift_ang_n;
                val_out <= val[precis_p+1];
            end
            
            wire [ang_width_p-1:0] shift_ang_first = shift_ang_r;
            wire [ang_width_p-1:0] shift_ang_second = %(a)d'h%(oc)s - shift_ang_r;
            wire [ang_width_p-1:0] shift_ang_third = ~(%(a)d'h%(oc)s - shift_ang_r)+1;
            wire [ang_width_p-1:0] shift_ang_fourth = ~shift_ang_r + 1;
            wire [ang_width_p-1:0] select_quad_y1 = quad_y[precis_p+1] ? shift_ang_fourth : shift_ang_first;
            wire [ang_width_p-1:0] select_quad_y2 = quad_y[precis_p+1] ? shift_ang_third : shift_ang_second;
            
            assign angl_o = quad_x[precis_p+1] ? select_quad_y2 : select_quad_y1;
            assign mag_o = scaling_ans_r;
            assign val_o = val_out;
            assign ready_o = ~stall_pipe & val_out;
            
endmodule
'''% {'c':constant, 'p': precisionbitlen,'a':angbitlen, 'nc':ninetyconstant, 'oc':one_eighty_constant})
    return


angbitlen = (int)(sys.argv[1])
ansbitlen = (int)(sys.argv[2])
posprec = (int)(sys.argv[3])
precision = (int)(sys.argv[4])
precisionbitlen = (int)(sys.argv[5])
startquant_pow = (int)(sys.argv[6])
lookup = lookup_compute(posprec, precision)
bsg_sine_cosine_init(angbitlen, ansbitlen, posprec)
lookup_initialization(posprec, angbitlen, lookup)
constant = constant_compute(posprec, precisionbitlen)
ninetyconstant = format(90*(2**precision),'x')
one_eighty_constant = format(180*(2**precision),'x')
main_body_print(precisionbitlen, constant, angbitlen, ninetyconstant, one_eighty_constant)
signedconst = signed_constant(angbitlen)
signedconst2 = signed_constant2(angbitlen)

# This file object is used to create a header file facilitating the passing of parameters of the module to
# Verilator for testing purposes. 
f_params = open("params_def.h","w+")
f_params.write('#ifndef PARAMS_DEF\n')
f_params.write('#define PARAMS_DEF\n')
f_params.write('int anglen = %(g)d;\n'%{'g':angbitlen})
f_params.write('int anslen = %(s)d;\n'%{'s':ansbitlen})
f_params.write('int startquant_pow = %(s)d;\n'%{'s':startquant_pow})
f_params.write('int precis_p = %(p)d;\n'%{'p':posprec})
f_params.write('int precision = %(p)d;\n'%{'p':precision})
f_params.write('long int signedconst = %(sc)s;\n'%{'sc':signedconst})
f_params.write('long int signedconst2 = %(scc)s;\n'%{'scc':signedconst2})
f_params.write('#endif')
f_params.close()