#!/usr/bin/bash
source ./bcache_func.bash || exit 2
att_det_loop=10

n=1
while ((n<=$att_det_loop)); do
	detach_cache
	sleep 3
	attach_cache
	sleep 3
	echo "iteraton $n done"
	let n++
done
