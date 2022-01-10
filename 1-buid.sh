start=`date +%s`

rm log.txt
Now=$(date +%d-%b-%H_%M)
docker image rm --force "postgres:latest"
docker build --no-cache -f Dockerfile -t "postgres:latest" . 2> ./log.txt

end=`date +%s`

runtime=$((end-start))
runtimeh=$((runtime/60))
runtimes=$((runtime-runtimeh*60))

echo "Total runtime was : $runtimeh minutes $runtimes seconds"
echo "" >> ./log.txt
echo "Total runtime was : $runtimeh minutes $runtimes seconds" >> ./log.txt
echo ""
