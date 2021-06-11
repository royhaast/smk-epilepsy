#!usr/bin/bash

: '
This script reads in a MP2RAGE T1 map and converts it to a MP2RAGE UNI image. 
Currently it will use the parameters specified in the parameters.mat variable.

Requirements:
- MATLAB
- MP2RAGE-related scripts (https://github.com/JosePMarques/MP2RAGE-related-scripts)
- Parameters specified in the MP2RAGE variable (i.e., within the parameters.mat file)
'

module load matlab

script=$1
script_dir=`readlink -f $script`
script_dir=$(dirname "${script_dir}")
script=`basename $script .m`

in=$2
out=$3

pushd $script_dir
    matlab -nosplash -nodisplay -nodesktop -r "${script}('${in}','${out}'); quit"
popd