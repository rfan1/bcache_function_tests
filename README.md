# bcache_function_tests
Basic function tests for bcache

1) Install the required packages for bcache tests: (for different OS release, you may need add required package repository)
 bcache-tools - Basic CLI for bcache
 fio          - Load i/o stress tool
 python3      - "bcache-status" command needs python environment
 axel         - Downloads a file from a FTP or HTTP server through multiple connection
 
 You can also use the below command to install them
 # ./bcache_main.bash -i
 
 2) For more detail usage, please use the below manual page:
 
 # ./bcache_main.bash -h
   Usage: bcache_main.bash [OPTION]...
    -i   Install the required packages: bcache-tools, python, fio etc
    -c   Create/setup bcache environment
    -d   Delete bcache devices and clean test environment
    -w   Change writeback percent: 0-100
    -p   Replacement Policy "lru fifo random"
    -l   Load fio stress, default fio config file "bcache.fio"
    -f   fio configuration file, combind with "-l" option
    -g   trigger gc
    -v   flash volume 
    -r   Run the multi-threading i/o test
    -h   Show this help
    
 3) Adjustable parameters (examples as below, you should modify them based on your tests)
   **att_det_loop"** in "loop_detach_attach.bash"** 
      - The loop number of bcache devices detach/attach
    
    Others are in "bcache_main.bash"
   - File download target direcotory
     **target_dir=/tmp/pythonmp**
   
   - Threading for "axel" downloading
     **num_thread=10**    
   
   - Download url
     **url=https://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-DVD-x86_64-Current.iso**
     
   - Md5_sum value for downloaded file
     **md5_sum=916073802c22fad15d819f6ecf015905**
   
   - Bcache device used for muti-threading i/o tests
     **file_io_dev=/dev/bcache0**
                              

