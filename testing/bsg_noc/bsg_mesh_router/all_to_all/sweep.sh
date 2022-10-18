run_test() {
  DIMS_P=$1
  RUCHE_X=$2
  RUCHE_Y=$3
  XY_ORDER=$4
  DEPOPULATED=$5
  echo DIMS_P=${DIMS_P} RUCHE_X=${RUCHE_X} RUCHE_Y=${RUCHE_Y} XY_ORDER=${XY_ORDER} DEPOPULATED=${DEPOPULATED} >> results.txt
  make DIMS_P=${DIMS_P} RUCHE_X=${RUCHE_X} RUCHE_Y=${RUCHE_Y} XY_ORDER=${XY_ORDER} DEPOPULATED=${DEPOPULATED}
  cat vcs.log | grep "BSG_FINISH" >> results.txt
}

rm -f results.txt

# 2D mesh
run_test 2 0 0 1 1
run_test 2 0 0 0 1

# Half Ruche X
run_test 3 3 0 1 1
run_test 3 3 0 0 1
run_test 3 3 0 1 0
run_test 3 3 0 0 0

# Full Ruche
run_test 4 3 2 1 1
run_test 4 3 2 0 1
run_test 4 3 2 1 0
run_test 4 3 2 0 0

cat results.txt
