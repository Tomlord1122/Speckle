#!/bin/bash

TARGET_RUN="/opt/qemu/bin/qemu-aarch64 -d plugin -plugin /home/tomlord/workspace/Speckle/insn.so -plugin /home/tomlord/workspace/Speckle/libhowvec.so -D"
INPUT_TYPE=ref # THIS MUST BE ON LINE 4 for an external sed command to work!
                # this allows us to externally set the INPUT_TYPE this script will execute

# BENCHMARKS=(400.perlbench 447.dealII)
BENCHMARKS=(400.perlbench 401.bzip2 403.gcc 429.mcf 445.gobmk 456.hmmer 458.sjeng 462.libquantum 464.h264ref 471.omnetpp 473.astar 433.milc 444.namd 450.soplex 470.lbm 482.sphinx3)

base_dir=$PWD
for b in ${BENCHMARKS[@]}; do

   echo " -== ${b} ==-"
   mkdir -p ${base_dir}/output

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
         cmd="${TARGET_RUN} ${base_dir}/output/${SHORT_EXE}.${count}.log ${SHORT_EXE} ${input}"
         parallel_commands+=("$cmd")
         ((count++))
      fi
   done

   # execute commands in parallel using GNU Parallel
   printf "%s\n" "${parallel_commands[@]}" | parallel -j 4

   echo ""

done

echo ""
echo "Done!"
