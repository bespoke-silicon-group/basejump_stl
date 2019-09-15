# BSG Generic Cocotb User Instructions

This testing directory uses the BSG generic cocotb testing infrastructure. This
testing infrastructure is built on top of cocotb and is intended to make it
easy to setup and run a cocotb testbench across multiple parameterizations of
the design under test.

## Running The Makefile

To run all of the test, simply run:

```
$ make
```

This will go through all parameterizations of the design under test and run all
test cases for each parameterization. You can also specify the `-j#` (where `#`
is a number) when executing the makefile (e.g. `$ make -j4`). This will run the
testbench on `#` parameterizations in parallel.

To clean up the testing directory, simply run:

```
$ make clean
```

This will clean the current directory but will not delete your test runs. To
truly delete everything, run:

```
$ make deep_clean
```

### Running a specific parameterization

To run the testbench on a single parameterization, use the following:

```
$ make test.<name>
```

Each parameterization has a name, which is the first item in the
`BSG_PARAM_SWEEP_PARAMS_*` variables. For example, take the following
parameterization definitions that we might find:

```
BSG_PARAM_SWEEP_PARAMS_1 = small  width_p=1   els_p=2
BSG_PARAM_SWEEP_PARAMS_2 = large  width_p=64  els_p=1024
```

Here we have 2 parameterizations: the first is called `small` which will set
the `width_p` and `els_p` toplevel parameters of the design under test to 1 and
2 resepctivly, while the second is called `large` which will set the `width_p`
and `els_p` toplevel parameters of the design under test to 64 and 1024
resepctivly.

Therefore, if we ran `$ make` the testbench would be run on both the `small`
and `large` parameterizations, however we can use `$ make test.small` to only
run the testbench on just the small parameterization. Similarly we can use `$
make test.large` to run the testbech on just the large parameterization. The
target `$ make test.all` is an alias that is used to run on every
parameterization (what the makefile defaults to).

You can cleanup an individual test as well by using the following:

```
$ make clean.test.<name>
```

So if you wanted to re-run just the `small` parameterization, you can run `$
make clean.test.small test.small` which will just delete and then run the
`small` parameterization. There is also a target `$ make clean.test.all` which
will clean all parameterizations (used by `$ make deep_clean`).

### Running specific test case(s)

To run a specific set of test cases, use the following:

```
$ make TESTCASE=<cases>
```

Here cases is a comma separated list of all the test cases that you want to
execute. All other test cases will be skipped.

Inside the cocotb testbench python script, you can (and probably will) define
multiple test cases. These are functions that have the `@cocotb.test()`
annotation applied to them. Each of these functions is a test case with the
name of the test case being the name of the function. For example, say you have
the following test cases:

```
@cocotb.test()
def test_one (dut):
    ...

@cocotb.test()
def test_two (dut):
    ...

@cocotb.test()
def test_three (dut):
    ...
```

We can run just `test_one()` by using `$ make TESTCASE=test_one`. If we also
wanted to run `test_three()` we could modify our make command to `$ make
TESTCASE=test_one,test_three`.

Finally, we can specify specific test cases with specitic parameterizations by
mixing the two syntaxes. For example, to run only `test_one()` on the `small`
parameterization defined above we can execute `$ make test.small
TESTCASE=test_one`. Pretty cool!

### Building and Cleaning External Tools

The makefile should automatically build the external tools required to run a
testbench if they don't exist when you first try and run a testbench; however,
you can still use `$ make build_tools` and `$ make clean_tools` to manually
build or clean (delete) them. All of the testbenches use the same set of
external tools that only need to be built once. These exists in the cocotb
testing `common/` directory.

## Setting up the Makefile

The `Makefile` in this directory is based off the tempalte makefile found at
inside the cocotb testing directory at `common/tempalte/Makefile`. In general,
there are 3 things that need to be setup: the simulation tool (vcs), the
design, and the parameterizations.

### Setting up the simulator (VCS)

If you have access to `bsg_cadenv` and are running on a machine that is
compatible with `bsg_cadenv` then you can simply put the `bsg_cadenv` repo in
the same direcotry as `basejump_stl` and you are good to go! Otherwise, you can
manually set the variable `LM_LICENSE_FILE` to point to the available license
server and the variable `VCS_HOME` to the VCS home directory (the one with
`bin/` in it).

### Setting up the design

For the design there are 4 variables that must be set. These variables are:

1. `BSG_TOPLEVEL_MODULE` - the name of the toplevel module under test.
2. `BSG_PY_TEST_MODULES` - a comma separated list of python modules to drive
	 the testbench. The name the python modules are usually the name of the
	 python scripts without the file path or extension (e.g. `./test_bsg.py` =>
	 `test_bsg`).
3. `BSG_VERILOG_SOURCES` - a space separated list of all RTL files required to
	 build the design.
4. `BSG_VERILOG_INCDIRS` - a space separated list of include search
	 directories.

### Setting up the parameterizations

For each parameterization, you will create a variable called
`BSG_PARAM_SWEEP_PARAMS_#` where `#` is the number associated with the
parameterization. **Note**: Best practice for the parameterization numbers is
to have all numbers continuously increasing starting with 1.

Each `BSG_PARAM_SWEEP_PARAMS_#` variable is a space separated list with the
following format:

```
BSG_PARAM_SWEEP_PARAMS_# = <name> [[parameter_name=value] ...]
```

The first item (which must exist!) is the `<name>` of the parameterization.
Mentioned before, this allows you to run tests on just this parameterization if
you want. This will also be the name of the directory where tests for this
parameterization are run. All subsequent items make up the actuall
parameterization. For each toplevel parameter you want to set, add an item in
the format `parameter_name=value`. You may specify zero or more parameters this
way.

Finally, set the `BSG_PARAM_SWEEP_COUNT_START` and `BSG_PARAM_SWEEP_COUNT_STOP`
variables equal to the first and last parameterization you want to instantiate
(inclusive). This should correspond with the `#` value in the
`BSG_PARAM_SWEEP_PARAMS_#` variables.

Below is an example of a design with 3 parameterizations:

```
BSG_PARAM_SWEEP_PARAMS_1 = default
BSG_PARAM_SWEEP_PARAMS_2 = small  width_p=1   els_p=2
BSG_PARAM_SWEEP_PARAMS_3 = large  width_p=64  els_p=1024

BSG_PARAM_SWEEP_COUNT_START = 1
BSG_PARAM_SWEEP_COUNT_STOP  = 3
```

## Creating Cocotb Testbenches

Checkout the [cocotb
documentation](https://cocotb.readthedocs.io/en/latest/introduction.html), it
is really good!

## Useful Links

1. [Cocotb Documentation](https://cocotb.readthedocs.io/en/latest/introduction.html)
2. [Cocotb Source Code](https://github.com/cocotb/cocotb)

