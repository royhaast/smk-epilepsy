#!/usr/bin/python
# import modules
import os
import sys
import json
import glob
import re
import shutil

#takes one argument (path to multiecho folder)
print('epi fieldmap corrector')

funcdir = sys.argv[1]
print(funcdir)

fmapdir = sys.argv[2]
print(fmapdir)

#puts all json and nifti files in the folder into lists
json_files = sorted(glob.glob(funcdir + "/*bold.json"))
nifti_files = sorted(glob.glob(funcdir + "/*bold.nii.gz"))
print(json_files)
print(nifti_files)
for i,k in zip(json_files, nifti_files):

    fmap_nifti_out = re.sub("_bold", "_epi", k)
    fmap_nifti_out = re.sub("func", "fmap", fmap_nifti_out)
    os.system("fslroi {} {} 0 5".format(k,fmap_nifti_out))

    if "LR" in i:
        intendedfor = re.sub("LR", "RL", k)
    elif "RL" in i:
        intendedfor = re.sub("RL", "LR", k)

    if "run-01" in i:
        intendedfor = re.sub("run-01", "run-02", intendedfor)
    elif "run-02" in i:
        intendedfor = re.sub("run-02", "run-01", intendedfor)

    # Copy, open and append json file
    fmap_json_out = re.sub("_bold", "_epi", i)
    fmap_json_out = re.sub("func", "fmap", fmap_json_out)
    shutil.copy(i, fmap_json_out)

    with open(fmap_json_out, "r") as data_file:
        data = json.load(data_file)

    data['IntendedFor'] = "/".join(intendedfor.split('/')[-2:])

    with open(fmap_json_out, "w") as data_file:
        json.dump(data, data_file, indent=4)

if len(nifti_files) > 1:
    os.system("touch {}".format(sys.argv[3]))