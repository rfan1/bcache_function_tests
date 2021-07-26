#!/usr/bin/bash

function pkg_install() {
	log_file=logs/pkg_install.log
	zypper --non-interactive in bcache-tools fio python3 | tee $log_file
	if [ $? -ne 0 ]; then
            echo "package installation FAIL" | tee -a $log_file
            exit 1
        else
            echo "package installation PASS" | tee -a $log_file
	    exit 0
        fi
}

function fio_stress() {
        conf_file=${1:-'bcache.fio'} 	
        fio $conf_file
}

function make_cache() {
	log_file=logs/make_cache.log
	echo -n "input the device names to be used as cache, split by space:"
	read cache_dev
	echo -n "input the devices name to be used as backend, split by space:"
	read backend_dev
	make-bcache -B $backend_dev -C $cache_dev -w4k -b1M --writeback | tee $log_file
        if [ $? -ne 0 ]; then
            echo "cache creating FAIL" | tee -a $log_file
            exit 1
        else
	    bcache-status | tee -a $log_file
	    sleep 3
	    bcache-status |grep "\[writeback\]"
	    if [ $? -ne 0 ]; then
            	echo "cache creating PASS" | tee -a $log_file
            	exit 0
	    else
		echo "cache mode check FAIL" | tee -a $log_file
		exit 1
            fi
       fi
}

function attach_cache() {
	log_file=logs/attach_cache.log
	cache_dev=`bcache show |grep \(cache |awk '{print $1}'`
	echo -ne "cache dev is \n$cache_dev \nStart to attch it to backend devices\n"
        for i in `bcache show |grep \(data |grep 'no cache' |awk '{print $1}'`;do bcache attach $cache_dev $i;done	
	result=`bcache show |grep \(data |grep 'no cache'`
	if [ -z "$result" ]; then
		echo "attach cache PASS" | tee $log_file
	else
		echo "attach cache FAIL" | tee $log_file
		exit 1
	fi
}

function detach_cache() {
	log_file=logs/detach_cache.log
	back_dev=`bcache show |grep \(data |awk '{print $1}'`
	echo -ne "backend devices are(is) \n$back_dev \nStart to detach them(it)\n"
	for i in $back_dev
	do
	       	bcache detach $i;
		if [ $? -ne 0 ]; then
                        echo "detach cache FAIL" | tee  $log_file
                        exit 1
                fi
		sleep 3
		bcache-super-show -f $i | grep dev.data.cache_state |grep detached
		if [ $? -ne 0 ]; then
                        echo "check cache status FAIL" | tee $log_file
                        exit 1
                fi
	done
	echo "detach cache PASS" |tee -a $log_file
}

function chg_cache_mode() {
	log_file=logs/chg_cache_mode.log
	backend_dev=`bcache show|grep \(data |awk '{print $1}'| awk -F"/dev/" '{print $2}' | sed -n '1p'`
	for i in writethrough writeback writearound none
       	do
	       	bcache set-cachemode /dev/$backend_dev
	       	sleep 3
		grep -nr "[$i]" /sys/block/$backend_dev/bcache/cache_mode | tee $log_file
		if [ $? -ne 0 ]; then
			echo "cache mode change FAIL" | tee -a  $log_file
			exit 1
		fi
	done
	echo "cache mode change PASS" | tee -a $log_file
}

function writeback_rate_debug() {
	backend_dev=`bcache show|grep \(data |awk '{print $1}'| awk -F"/dev/" '{print $2}' | sed -n '1p'`
	for i in 1 2 3 4 5;do cat /sys/block/$backend_dev/bcache/writeback_rate_debug;sleep 5;done
}


function writeback_percent() {
	log_file=logs/writeback_percent.log
	percent="$1"
	backend_dev=`bcache show|grep \(data |awk '{print $1}'| awk -F"/dev/" '{print $2}' | sed -n '1p'`
	echo "the writeback percent value should be between 0 to 100, the default vaule is 10"
	echo $percent > /sys/block/$backend_dev/bcache/writeback_percent
	grep $percent /sys/block/$backend_dev/bcache/writeback_percent
	if [ $? -ne 0 ]; then
               echo "writeback percent change FAIL" | tee -a  $log_file
               exit 1
       else
	       echo "writeback percent change PASS" | tee -a  $log_file
	       exit 0
        fi

}

function cache_replacement_policy() {
	log_file=logs/cache_replacement_policy.log
	cache_dev=`bcache show |grep \(cache |awk '{print $1}' | awk -F"/dev/" '{print $2}'`
	for i in lru fifo random
	do
		echo $i >/sys/block/$cache_dev/bcache/cache_replacement_policy
		sleep 5
		bcache-status | grep "\[$i\]"
		if [ $? -ne 0 ]; then
               		 echo "cache replacement policy FAIL" | tee -a  $log_file
              		 exit 1
	        fi
	done	
     	echo "cache replacement policy PASS" | tee -a  $log_file
        exit 0
}

function flash_vol_create() {
	log_file=logs/flash_vol_create.log
	cache_dev=`bcache show |grep \(cache |awk '{print $1}'`
	cacheuuid=`bcache-status |grep UUID|awk '{print $2}'`
	vol_size=$1
	echo $vol_size > /sys/fs/bcache/$cacheuuid/flash_vol_create
	if [ $? -ne 0 ]; then
                         echo "flash volume create FAIL" | tee  $log_file
                         exit 1
                else
                        echo "flash volume create PASS" | tee  $log_file
	fi
	sleep 3
	vol_name=`lsblk $cache_dev | sed -n '$p' | awk '{print $1}' | awk -F └─ '{print $2}'`
	mkfs -t ext4 /dev/$vol_name
	if [ $? -ne 0 ]; then
                         echo "mkfs on flash volume FAIL" | tee -a $log_file
                         exit 1
                else
                        echo "mkfs on flash volume PASS" | tee  -a $log_file
                        exit 0
        fi
}

function gc() {
	log_file=logs/flash_vol_create.log
	cacheuuid=`bcache-status |grep UUID|awk '{print $2}'`
	echo 1 > /sys/fs/bcache/$cacheuuid/internal/trigger_gc
	if [ $? -ne 0 ]; then
                         echo "gc FAIL" | tee  $log_file
                         exit 1
                else
                        echo "gc PASS" | tee  $log_file
			exit 0
        fi
}

function clean_up() {
    log_file=logs/clean_up.log
    for i in `bcache show | grep dev | awk '{print $1}'`;do bcache unregister $i | tee $log_file; wipefs -fa $i |tee -a $log_file;done
    a=`bcache show | grep dev`
    if [ -z "$a" ]; then
	    echo "Environment clean up PASS" | tee -a $log_file
	    exit 0
    else
	    echo "Environment clean up FAIL" | tee -a $log_file
	    exit 1
    fi
}
