#!/usr/bin/env bash

start=`date +%s`

docker-compose -f ./docker-compose.yml up -d

end=`date +%s`

runtime=$((end-start))
runtimeh=$((runtime/60))
runtimes=$((runtime-runtimeh*60))

echo "Runtime was : $runtimeh minutes $runtimes seconds"
echo ""
