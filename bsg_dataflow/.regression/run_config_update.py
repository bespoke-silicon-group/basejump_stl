import json
import sys 
import re

# Reading the input json file
filenames = [
"bsg_1_to_n_tagged.json",
"bsg_1_to_n_tagged_fifo.json",
"bsg_1_to_n_tagged_fifo_shared.json",
"bsg_8b10b_decode_comb.json",
"bsg_8b10b_encode_comb.json",
"bsg_8b10b_shift_decoder.json",
"bsg_channel_narrow.json",
"bsg_channel_tunnel.json",
"bsg_channel_tunnel_in.json",
"bsg_channel_tunnel_out.json",
"bsg_compare_and_swap.json",
"bsg_credit_to_token.json",
"bsg_fifo_1r1w_large.json",
"bsg_fifo_1r1w_large_banked.json",
"bsg_fifo_1r1w_narrowed.json",
"bsg_fifo_1r1w_pseudo_large.json",
"bsg_fifo_1r1w_small.json",
"bsg_fifo_1rw_large.json",
"bsg_fifo_shift_datapath.json",
"bsg_fifo_tracker.json",
"bsg_flatten_2D_array.json",
"bsg_flow_convert.json",
"bsg_flow_counter.json",
"bsg_make_2D_array.json",
"bsg_one_fifo.json",
"bsg_parallel_in_serial_out.json",
"bsg_permute_box.json",
"bsg_ready_to_credit_flow_converter.json",
"bsg_relay_fifo.json",
"bsg_round_robin_1_to_n.json",
"bsg_round_robin_2_to_2.json",
"bsg_round_robin_fifo_to_fifo.json",
"bsg_round_robin_n_to_1.json",
"bsg_sbox.json",
"bsg_scatter_gather.json",
"bsg_serial_in_parallel_out.json",
"bsg_serial_in_parallel_out_full.json",
"bsg_shift_reg.json",
"bsg_two_buncher.json",
"bsg_two_fifo.json",
]

for config_input in filenames:
#print(config_input)
#print(re.split('\.|\/',config_input))
  #config_output = re.split('\.|\/',config_input)[-2] + '_updated.json'
  #print(config_output)
  config_output = config_input
  run_config = []
  new_const = []
  inc_path = []
  
  with open(config_input) as f:
    data = json.load(f)
    design_name = data['design_name']
    fl = data['filelist']
    if 'include_path' in data.keys():
      inc_path = data['include_path']
  
    for each_config in data['run_config']:
      name = each_config['name']
      desc = each_config['description']
      params = each_config['parameters']
      constr = each_config['constraints']
      ds = each_config['design_size']
      # modify the constraints
      # clk type constr
      # new_constr_clk_type = {}
      if constr['clk_port_name'] == 'virtual':
        new_constr_clk_type = {\
          'type':'clock', \
          'name':'vclk', \
          'port':constr['clk_port_name'], \
          'period':constr['clock_period'], \
          'uncertainty':constr['uncertainty']
        }
      else:
        new_constr_clk_type = {\
          'type':'clock', \
          'name':'clk', \
          'port':constr['clk_port_name'], \
          'period':constr['clock_period'], \
          'uncertainty':constr['uncertainty']
        }
  
      # input type constr
      # new_constr_input_type = {}
      new_constr_input_type = {\
        'type':'input', \
        'clock':new_constr_clk_type['name'], \
        'port':'all', \
        'delay':constr['input'] 
      }
  
      # output type constr
      # new_constr_output_type = {}
      new_constr_output_type = {\
        'type':'output', \
        'clock':new_constr_clk_type['name'], \
        'port':'all', \
        'delay':constr['output']
      }
  
      new_const = [new_constr_clk_type, new_constr_input_type, new_constr_output_type]
  
      run_config_dict = {\
        'name':name, \
        'description':desc, \
        'design_size':ds, \
        'parameters':params, \
        'constraints':new_const \
      }
  
      run_config.append(run_config_dict)
  
    if inc_path:
      design = {\
        'design_name':design_name, \
        'filelist':fl,\
        'include_path':inc_path,\
        'run_config':run_config \
      }
    
    else:
      design = {\
        'design_name':design_name, \
        'filelist':fl,\
        'run_config':run_config \
      }
  
    a = json.dumps(design, indent=4, sort_keys=False)
  
    with open(config_output, 'w') as f:
      f.write(a)

    