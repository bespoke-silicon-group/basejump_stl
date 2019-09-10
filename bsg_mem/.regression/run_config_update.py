import json
import sys 
import re

# Reading the input json file
filenames = [
"bsg_cam_1r1w.json",
"bsg_mem_1r1w.json",
"bsg_mem_1r1w_async.json",
"bsg_mem_1r1w_sync.json",
"bsg_mem_1r1w_sync_mask_write_bit.json",
"bsg_mem_1r1w_sync_mask_write_var.json",
"bsg_mem_1rw_sync.json",
"bsg_mem_1rw_sync_mask_write_bit.json",
"bsg_mem_1rw_sync_mask_write_byte.json",
"bsg_mem_1rw_sync_mask_write_var.json",
"bsg_mem_2r1w.json",
"bsg_mem_2r1w_sync.json",
"bsg_mem_3r1w.json",
"bsg_mem_banked_crossbar.json",
"bsg_mem_multiport.json",
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

    