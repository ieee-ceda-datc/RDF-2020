# Source the helper function definitions.
source ../plugin/mean_shift_clustering/procs.tcl

# Create ISPD'19 inputs: This will create the input file at "./mean_shift/input.txt"
generate_ispd19_mean_shift_input

exec ../plugin/mean_shift_clustering/clustering-a --MaxClusterSize 40 --MaxDisp 10 mean_shift/input.txt ./mean_shift/output.txt
exec /opt/xsite/cte/tools/python/3.6.1/bin/python3 ../plugin/mean_shift_clustering/process_output.py -o mean_shift
source ./mean_shift/output.tcl 

# suspend

refinePlace
