#!/bin/bash

TARGET_RUN="/opt/qemu-custom/bin/qemu-riscv64 -L /opt/riscv/sysroot -cpu rv64,v=true,zba=true,zbb=true,zbs=true,vlen=128,vext_spec=v1.0 -d plugin -plugin /home/tomlord/workspace/Speckle/insn.so -D"
INPUT_TYPE=ref #this line was auto-generated from gen_binaries.sh
                # this allows us to externally set the INPUT_TYPE this script will execute

BENCHMARKS=(400.perlbench 401.bzip2 403.gcc 429.mcf 445.gobmk 456.hmmer 458.sjeng 462.libquantum 464.h264ref 471.omnetpp 473.astar)
# BENCHMARKS=(401.bzip2)

base_dir=$PWD
# Find the next available output directory number
output_num=0
while [ -d "${base_dir}/output_${output_num}" ]; do
    ((output_num++))
done
output_dir="${base_dir}/output_${output_num}"
mkdir -p "${output_dir}"

# Function to run a single benchmark
run_benchmark() {
    local b=$1
    local base_dir=$2
    local output_dir=$3
    
    echo " -== ${b} ==-"
    
    # 為每個 benchmark 創建獨立的子目錄
    local benchmark_output_dir="${output_dir}/${b}"
    mkdir -p "${benchmark_output_dir}"
    
    cd ${base_dir}/${b}
    SHORT_EXE=${b##*.}
    if [ $b == "483.xalancbmk" ]; then 
        SHORT_EXE=Xalan
    fi
    if [ $b == "482.sphinx3" ]; then
        SHORT_EXE=sphinx_livepretend
    fi
    
    # 讀取命令文件
    IFS=$'\n' read -d '' -r -a commands < ${base_dir}/commands/${b}.${INPUT_TYPE}.cmd
    
    # 創建 benchmark 的總體輸出文件
    local benchmark_log="${benchmark_output_dir}/${b}_complete.log"
    echo "Starting benchmark ${b} at $(date)" > "${benchmark_log}"
    
    # 執行命令
    count=0
    for input in "${commands[@]}"; do
        if [[ ${input:0:1} != '#' ]]; then
            # 個別命令的輸出文件
            local cmd_log="${benchmark_output_dir}/${SHORT_EXE}_${count}.log"
            cmd="${TARGET_RUN} ${cmd_log} ${SHORT_EXE} ${input}"
            
            echo "Executing: $cmd" | tee -a "${benchmark_log}"
            eval $cmd 2>&1 | tee -a "${benchmark_log}"
            
            ((count++))
        fi
    done
    
    echo "Completed ${b} at $(date)" >> "${benchmark_log}"
    echo "Completed ${b}"
}

# Export the function and variables so they can be used by parallel
export -f run_benchmark
export TARGET_RUN
export INPUT_TYPE
export base_dir
export output_dir

# Run benchmarks in parallel (max 8 threads)
printf "%s\n" "${BENCHMARKS[@]}" | parallel -j 8 run_benchmark {} "$base_dir" "$output_dir"

echo ""
echo "Done!"
