#!/usr/bin/env bash

start=`date +%s`

python3 ./test.py

end=`date +%s`

runtime=$((end-start))
runtimeh=$((runtime/60))
runtimes=$((runtime-runtimeh*60))

echo "Runtime was : $runtimeh minutes $runtimes seconds"
echo ""
