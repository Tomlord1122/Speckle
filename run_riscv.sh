#!/bin/bash

TARGET_RUN="/opt/qemu-custom/bin/qemu-riscv64 -L /opt/riscv/sysroot -cpu rv64,v=true,zba=true,zbb=true,zbs=true,vlen=128,vext_spec=v1.0 -d plugin -plugin /home/tomlord/workspace/Speckle/insn.so -D"
INPUT_TYPE=ref # THIS MUST BE ON LINE 4 for an external sed command to work!
                # this allows us to externally set the INPUT_TYPE this script will execute

BENCHMARKS=(400.perlbench 401.bzip2 403.gcc 429.mcf 445.gobmk 456.hmmer 458.sjeng 464.h264ref 471.omnetpp 473.astar 453.povray 450.soplex)
# BENCHMARKS=(400.perlbench 401.bzip2 403.gcc 429.mcf 445.gobmk 456.hmmer 458.sjeng 462.libquantum 464.h264ref 471.omnetpp 473.astar 433.milc 444.namd 447.dealII 450.soplex 453.povray 470.lbm 482.sphinx3)

base_dir=$PWD
# Find the next available output directory number
output_num=0
while [ -d "${base_dir}/output_${output_num}" ]; do
    ((output_num++))
done
output_dir="${base_dir}/output_${output_num}"
mkdir -p "${output_dir}"

for b in ${BENCHMARKS[@]}; do
   echo " -== ${b} ==-"

   cd ${base_dir}/${b}
   SHORT_EXE=${b##*.} # cut off the numbers ###.short_exe
   if [ $b == "483.xalancbmk" ]; then 
      SHORT_EXE=Xalan #WTF SPEC???
   fi
   if [ $b == "482.sphinx3" ]; then
      SHORT_EXE=sphinx_livepretend
   fi
   
   # read the command file
   IFS=$'\n' read -d '' -r -a commands < ${base_dir}/commands/${b}.${INPUT_TYPE}.cmd

   # prepare commands for parallel execution
   parallel_commands=()
   count=0
   for input in "${commands[@]}"; do
      if [[ ${input:0:1} != '#' ]]; then # allow us to comment out lines in the cmd files
         # Use the new output directory path
         cmd="${TARGET_RUN} ${output_dir}/${SHORT_EXE}_${count}.log ${SHORT_EXE} ${input}"
         parallel_commands+=("$cmd")
         ((count++))
      fi
   done

   # execute commands in parallel using GNU Parallel
   printf "%s\n" "${parallel_commands[@]}" | parallel -j 2

   echo ""

done

echo ""
echo "Done!"
