# This script takes in a regression list in YAML format, parses it and launches regressions in the output dir passed as commandline arg
# TODO: 
# - Add code to check if a test has passed or not; 
# - add regression statistics
# - add support to compile and launch DVE as well
# Point of contact: Akash S (akashs3@uw.edu)

import yaml, getopt, sys, io, os, random

simv = ''
seed_for_randomisation = 0;
cov_opts = ''

def main(argv):
	yaml, output_dir = get_cmdline_options(argv)
	regression_dict = parse_yaml(yaml)
	launch_regression(regression_dict, output_dir)

def get_cmdline_options(argv):
	yaml = 'regression_list.yaml'
	output_dir = '.'
	global simv, seed_for_randomisation, cov_opts

	try:
		opts, args = getopt.getopt(argv,"hy:o:s:r:c",["yaml=","output_dir=", "simv=", "random_seed=", "cov_enable"])
	except getopt.GetoptError:
		print 'incorrect script call'
		sys.exit(2)

	print(opts)
	for opt, arg in opts:
		if opt == '-h':
		   print 'test.py -i <inputfile> -o <outputfile>'
		   sys.exit()
		elif opt in ("-y", "--yaml"):
		   	yaml = arg
		elif opt in ("-o", "--output_dir"):
			output_dir = arg
		elif opt in ("-s", "--simv"):
			simv = arg
		elif opt in ("-r", "--random_seed"):
			seed_for_randomisation = arg			
		elif opt in ("-c", "--cov_enable"):
			cov_opts = ' -cm line+cond+fsm+tgl+path '

	return yaml, output_dir

def parse_yaml(yaml_file):
	print ("Parsing " + yaml_file)

	with io.open(yaml_file) as f:
	    regression_dict = yaml.safe_load(f)

	return regression_dict

def launch_regression(regression_dict, output_dir):
	print ("Parsing done. Launching regression at " + output_dir)

	if(not os.path.isdir(output_dir)):
		os.system("mkdir " + output_dir)
	
	os.system("cd " + output_dir)
	
	for test, test_details in regression_dict.items():
			test_path = output_dir + "/" + test
			os.system("mkdir " + test_path)
			os.system("cd " + test_path)
			print ("Launching test: " + test + "\n")		
			launch_individual_tests(test_details, test_path)

def launch_individual_tests(test_properties, test_path):
	random.seed(seed_for_randomisation)
	for i in range(test_properties["seed_count"]):
		rand_seed = random.randint(0, 10000000)
		seed_path = test_path + "/" + str(i)
		print ("Launching test in " + seed_path)
		os.system("mkdir " + seed_path)
		os.system("cd " + seed_path)
		print("Launching: " + simv + " " + test_properties["args"] + " +ntb_random_seed=" + str(rand_seed) + " -l " + seed_path + "/run.log +vpdfile+" + seed_path + "/waves.vpd" + cov_opts)
		os.system(simv + " " + test_properties["args"] + "+ntb_random_seed=" + str(rand_seed) + " +vpdfile+" + seed_path + "/waves.vpd > " + seed_path + "/run.log" + cov_opts)


main(sys.argv[1:])
