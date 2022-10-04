# This script takes in a regression list in YAML format, parses it and launches regressions in the output dir passed as commandline arg
# TODO: 
# - add regression statistics
# - add support to compile and launch DVE as well
# Point of contact: Akash S (akashs3@uw.edu)

import yaml, getopt, sys, io, os, random, re

simv = ''
seed_for_randomisation = 0;
cov_opts = ''
errors = ''

def main(argv):
	global errors
	yaml, output_dir = get_cmdline_options(argv)
	regression_dict = parse_yaml(yaml)
	launch_regression(regression_dict, output_dir)

	if errors != '':
		print ' ERRORS found in the regression. Check error.log in the regression directory!\n'
		f = open(output_dir + "/errors.log", "w")
		f.write(errors)


def get_cmdline_options(argv):
	yaml = 'regression_list.yaml'
	output_dir = '.'
	global simv, seed_for_randomisation, cov_opts

	try:
		opts, args = getopt.getopt(argv,"hy:o:s:r:c",["yaml=","output_dir=", "simv=", "random_seed=", "cov_enable"])
	except getopt.GetoptError:
		print 'incorrect script call'
		print_help();
		sys.exit(2)

	#print(opts)
	for opt, arg in opts:
		if opt == '-h':
			print_help()
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

def print_help():
	print ("""This script is used to launch a set of tests listed in a YAML script in the DMC testbench.
			   		Usage:
			   		-> -y / --yaml : absolute path to the YAML script
					-> -o / --output_dir : absolute path to output directory
					-> -s / --simv : absolute path to simv
					-> -r / --random_seed : random seed based on which script randomises seeds to launch tests
					-> -c / --cov_enable : use when running coverage regressions
    """)
	sys.exit()

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

		parse_log(seed_path)

def parse_log(seed_path):
	global errors

	log_name = seed_path + '/run.log'
	#os.system("cd " + seed_path)
	file = open(log_name, 'r')
	file_contents = file.readlines()

	for line in file_contents:
		match1 = re.search(r'^ERROR', line)
		if match1:
			errors += log_name + " : "
			errors += line + "\n"

		match2 = re.search(r'^UVM_FATAL.*', line)
		if match2:
			if(not re.search(r'^UVM_FATAL\s\:', line)):
				errors += log_name + " : "
				errors += line + "\n"

		match3 = re.search(r'^UVM_ERROR.*', line)
		if match3:
			if(not re.search(r'^UVM_ERROR\s\:', line)):				
				errors += log_name + " : "
				errors += line + "\n"

main(sys.argv[1:])
