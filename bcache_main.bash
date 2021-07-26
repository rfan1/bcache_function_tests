#!/bin/bash
source ./bcache_func.bash || exit 2


#----------------------------------------------------------------------
# global variables
# you should modify them based on your test requirement
#----------------------------------------------------------------------
# Define the directories which to be use for multi-processing i/o test on bcacache device
# Define the device which to to used as file io
target_dir=/tmp/pythonmp
num_thread=10
url=https://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-DVD-x86_64-Current.iso
md5_sum=916073802c22fad15d819f6ecf015905
file_io_dev=/dev/bcache0
#----------------------------------------------------------------------
# main program
#----------------------------------------------------------------------

function usage {
    cat <<EOF
Usage: ${0##*/} [OPTION]...
    -i   Install the required packages: bcache-tools, python, fio etc
    -c   Create/setup bcache environment
    -d   Delete bcache devices and clean test environment
    -w   Change writeback percent: 0-100
    -p   Replacement Policy "lru fifo random"
    -l   Load fio stress
    -f   fio configuration file, combind with "-l" option
    -g   trigger gc
    -v   flash volume 
    -r   Run the test
    -h   Show this help
EOF
}

function parse_cmdline {
   while getopts icdlw:pf:gv:rh opt;
   do
        case $opt in
            i) pkg_install; ;;
	    c) make_cache; ;;
	    d) clean_up; ;;
	    w) wb_percent=${OPTARG};writeback_percent $wb_percent; ;;
	    p) cache_replacement_policy; ;;
            l) loadio=true; ;;
            f) opt_conf=${OPTARG}; ;;
	    g) gc; ;;
	    v) vol_size=${OPTARG}; flash_vol_create $vol_size; ;;
            h) usage; exit 0 ;;
            r) opt_run=true ;;
        esac
    done
}

parse_cmdline "$@"

# I/O tests are based on your requirement, the default bcache.fio file is a sameple file only
if [[ "$loadio" == "true" ]]; then
    if [[ -z "$opt_conf" ]]; then 
	    fio_stress 
    else 
	    fio_stress $opt_conf
    fi
fi

if [[ "$opt_run" == "true" ]]; then
	cd $target_dir
	file_name=`echo $url | awk -F/ '{print $NF}'`
	md5_sum1=`md5sum $file_name |awk '{print $1}'`
	if [[ "$md5_sum" == "$md5_sum1" ]]; then
		echo "multi-thread copy PASS"
		exit 0
	else
		echo "multi-thread copy FAIL"
		exit 1
	fi
fi
