#!/bin/bash
source /opt/venv/bin/activate
source scl_source enable devtoolset-11
source scl_source enable rh-git218

exec "$@"
