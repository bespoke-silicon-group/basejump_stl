```

Each tile sends a packet to every tile in the network.
Once every tile has received packets from all tiles, the test finishes.

HOW TO RUN
----------

- run "make" with a valid set of parameters.
  NUM_X     = number of tiles in x  (default: 16)
  NUM_Y     = number of tiles in y  (default: 8)
  XY_ORDER  = XY dimension order?   (default: 1)
  DIMS_P    = dimension of router   (default: 2)
  RUCHE_X   = ruche factor in X     (default: 0)
  RUCHE_Y   = ruche factor in Y     (default: 0)

  e.g.) make DIMS_P=3 RUCHE_X=3 XY_ORDER=0
  e.g.) make DIMS_P=2 XY_ORDER=1

- run "./test.sh" to run a set of test parameters.
```
