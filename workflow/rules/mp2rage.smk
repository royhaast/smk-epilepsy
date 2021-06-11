def mp2ragedir_search(wildcards):
    """
    This function will search for the directory on DATA_RAY that
    contains the B1+ corrected T1 map
    """
    studyid = recoding_dict[wildcards.subject]
    paths   = config['data']['mp2rage']

    indir = []
    for p, path in enumerate(paths):
        dirlist = os.listdir(path)

        regex   = studyid.replace('-','.').replace('_','.')
        pattern = re.compile(regex, re.IGNORECASE)
        
        datadir = [j for j in dirlist if pattern.search(j)]

        if len(datadir) != 0:
            mp2ragedir = os.path.join(path,datadir[0])
            # print(mp2ragedir)
            for dirpath, dirnames, filenames in os.walk(mp2ragedir):
                for file in filenames:
                    if 'T1map_B1corrected.nii' in file:
                        indir = dirpath
                        break
    
    return indir

# def collect_input(wildcards,modality=None):
#     subject = '{wildcards.subject}'.format(wildcards=wildcards)

#     return {
#         'inv1'    : 'deriv/gradcorrect/sub-{subject}/anat/sub-{subject}_inv-1_run-01_part-mag_MP2RAGE.nii.gz'.format(subject=subject),
#         'inv2'    : 'deriv/gradcorrect/sub-{subject}/anat/sub-{subject}_inv-2_run-01_part-mag_MP2RAGE.nii.gz'.format(subject=subject),
#         't1map'   : 'deriv/gradcorrect/sub-{subject}/anat/sub-{subject}_acq-MP2RAGE_run-01_T1map.nii.gz'.format(subject=subject),
#         'uni-den' : 'deriv/gradcorrect/sub-{subject}/anat/sub-{subject}_acq-MP2RAGE_run-01_T1w.nii.gz'.format(subject=subject),
#         'uni'     : 'deriv/gradcorrect/sub-{subject}/anat/sub-{subject}_acq-UNI_run-01_MP2RAGE.nii.gz'.format(subject=subject)
#     }

mp2rage_dict = {
            'inv1'    : 'inv-1_run-01_part-mag_MP2RAGE.nii.gz',
            'inv2'    : 'inv-2_run-01_part-mag_MP2RAGE.nii.gz',
            't1map'   : 'acq-MP2RAGE_run-01_T1map.nii.gz',
            'uni-den' : 'acq-MP2RAGE_run-01_T1w.nii.gz',
            'uni'     : 'acq-UNI_run-01_MP2RAGE.nii.gz'
            }

# Will locate the B1+ corrected T1 map and copy to deriv folder
# rule import_b1_corrected_data:
#     input: mp2ragedir_search
#     output: 
#         t1map = 'deriv/b1correction/sub-{subject}/anat/sub-{subject}_acq-MP2RAGE_proc-B1map_T1map.nii.gz'
#     container: config['containers']['fmriprep']
#     shell:
#         """
#         mri_convert {input}/T1map_B1corrected.nii {output} -nc
#         """

# Will take corrected T1 map and compute a MP2RAGE UNI image
rule generate_corrected_uni:
    input: 'deriv/b1correction/sub-{subject}/anat/sub-{subject}_acq-MP2RAGE_proc-B1map_T1map.nii.gz'
    output: 'deriv/b1correction/sub-{subject}/anat/sub-{subject}_acq-UNI_run-01_proc-B1map_MP2RAGE.nii.gz'
    params:
        wrapper = 'scripts/b1correct/b1correct.sh',
        b1correct = 'scripts/b1correct/b1correct.m' 
    group: 'mp2rage'   
    threads: 8
    resources:
        time = 120,
        mem_mb = 32000        
    shell:
        """
        bash {params.wrapper} {params.b1correct} `realpath {input}` `realpath {output}`
        """

# Will fix the orientation of the B1+ corrected data
rule reorient_to_std:
    input:
        t1w = 'deriv/b1correction/sub-{subject}/anat/sub-{subject}_acq-UNI_run-01_proc-B1map_MP2RAGE.nii.gz',
        t1 = 'deriv/b1correction/sub-{subject}/anat/sub-{subject}_acq-MP2RAGE_proc-B1map_T1map.nii.gz'
    output:
        t1w = 'deriv/presurfer/sub-{subject}/sub-{subject}_acq-UNI_run-01_proc-B1map_MP2RAGE.nii.gz',
        t1 = 'deriv/presurfer/sub-{subject}/sub-{subject}_acq-MP2RAGE_proc-B1map_T1map.nii.gz'
    params:
        inv2 = lambda wildcards: 'bids/sub-{subject}/anat/sub-{subject}_{suffix}'.format(subject=wildcards.subject, suffix=mp2rage_dict['inv2'])
    group: 'mp2rage'
    singularity: config['containers']['fmriprep']
    shell:
        """
        in_files="`basename {input.t1w}` `basename {input.t1}`"
        in_location=`dirname {input.t1w}`
        out_location=`dirname {output.t1w}`

        for in in $in_files ; do
            fslreorient2std $in_location/$in $out_location/$in ;
            fslcpgeom {params.inv2} $out_location/$in ;
            fslswapdim $out_location/$in -x y z $out_location/$in ;
        done
        """

# Will run presurfer (i.e, bias correction and brain extraction)
rule presurfer:
    input:
        uni = 'deriv/presurfer/sub-{subject}/sub-{subject}_acq-UNI_run-01_proc-B1map_MP2RAGE.nii.gz',
        inv2 = lambda wildcards: 'bids/sub-{subject}/anat/sub-{subject}_{suffix}'.format(subject=wildcards.subject, suffix=mp2rage_dict['inv2'])    
    output:
        t1w = 'deriv/presurfer/sub-{subject}/presurf_MPRAGEise/presurf_UNI/sub-{subject}_acq-UNI_run-01_proc-B1map_MP2RAGE_MPRAGEised_biascorrected.nii',
        mask = 'deriv/presurfer/sub-{subject}/presurf_MPRAGEise/presurf_UNI/sub-{subject}_acq-UNI_run-01_proc-B1map_MP2RAGE_MPRAGEised_brainmask.nii'
    params:
        wrapper = 'scripts/presurfer/presurfer.sh',
        presurf = 'scripts/presurfer/presurfer.m'
    group: 'mp2rage'        
    threads: 8
    resources:
        time = 120,
        mem_mb = 32000
    shell:
        """
        bash {params.wrapper} {params.presurf} {input.uni} {input.inv2}
        """

# Will denoise the presurfer output using SALNM filter and apply mask
rule ants_denoise:
    input: 
        t1w = 'deriv/presurfer/sub-{subject}/presurf_MPRAGEise/presurf_UNI/sub-{subject}_acq-UNI_run-01_proc-B1map_MP2RAGE_MPRAGEised_biascorrected.nii',
        mask = 'deriv/presurfer/sub-{subject}/presurf_MPRAGEise/presurf_UNI/sub-{subject}_acq-UNI_run-01_proc-B1map_MP2RAGE_MPRAGEised_brainmask.nii'
    output:
        denoised = 'deriv/presurfer/sub-{subject}/sub-{subject}_acq-MP2RAGE_run-01_proc-B1map_T1w.nii.gz',
        mgz = 'deriv/freesurfer/sub-{subject}/mri/orig/001.mgz'
    group: 'mp2rage'        
    container: config['containers']['fmriprep']
    threads: 8
    resources:
        time = 30,
        mem_mb = 32000    
    shell:
        """
        DenoiseImage -d 3 -i {input.t1w} -n Rician -s 1 -o {output.denoised} -v
        mri_mask {output.denoised} {input.mask} {output.mgz}
        """

# Will process the denoised image using FreeSurfer
rule freesurfer:
    input: 'deriv/freesurfer/sub-{subject}/mri/orig/001.mgz'
    output: 'deriv/freesurfer/sub-{subject}/scripts/recon-all.done'
    params:
        sd = 'deriv/freesurfer'
    group: 'mp2rage'        
    singularity: config['containers']['freesurfer']
    threads: 16
    resources:
        time = 600,
        mem_mb = 64000
    shell:
        """
        export SUBJECTS_DIR={params.sd}
        recon-all -all -s sub-{wildcards.subject} -hires -no-wsgcaatlas -notal-check -threads 16
        """


# rule skull_stripping:
#     input: 'deriv/mprageise/sub-{subject}/anat/sub-{subject}_acq-MP2RAGE_run-01_proc-B1map_T1w.nii.gz'
#     # input: lambda wildcards: 'deriv/gradcorrect/sub-{subject}/anat/sub-{subject}_{suffix}'.format(subject=wildcards.subject, suffix=mp2rage_dict[wildcards.modality])
#     output:
#         mask = 'deriv/skullstripping/sub-{subject}/sub-{subject}_brainmask.nii.gz',
#         t1w = 'deriv/skullstripping/sub-{subject}/mri/mimp2rage.nii'
#     # output: 'deriv/skullstripping_{modality}/sub-{subject}/sub-{subject}_brainmask.nii.gz'
#     params:
#         wrapper = 'scripts/skullstripping/skullstrip.sh',
#         cat12 = 'scripts/skullstripping/run_cat12.m'
#     threads: 8
#     resources:
#         time = 180,
#         mem_mb = 32000
#     shell:
#         """       
#         bash {params.wrapper} {params.cat12} {input} `realpath {output.mask}`
#         """

# rule mask_image:
#     input:
#         # t1w = lambda wildcards: 'deriv/gradcorrect/sub-{subject}/anat/sub-{subject}_{suffix}'.format(subject=wildcards.subject, suffix=mp2rage_dict['uni-den']), #unpack(collect_input),
#         t1w = 'deriv/skullstripping/sub-{subject}/mri/mimp2rage.nii',
#         mask = 'deriv/skullstripping/sub-{subject}/sub-{subject}_brainmask.nii.gz'
#     output: 'deriv/skullstripping/sub-{subject}/sub-{subject}_T1w_brain.nii.gz'
#     shell:
#         """
#         fslmaths {input.mask} -mul {input.t1w} {output}
#         """

# rule freesurfer:
#     input: 'deriv/skullstripping/sub-{subject}/sub-{subject}_T1w_brain.nii.gz'
#     output: 'deriv/freesurfer/sub-{subject}/scripts/recon-all.done'
#     params:
#         sd = 'deriv/freesurfer'
#     singularity: config['containers']['freesurfer']
#     threads: 8
#     resources:
#         time = 600,
#         mem_mb = 32000
#     shell:
#         """
#         export SUBJECTS_DIR={params.sd}
#         mkdir -p $SUBJECTS_DIR/sub-{wildcards.subject}/mri/orig
#         mri_convert {input} $SUBJECTS_DIR/sub-{wildcards.subject}/mri/orig/001.mgz -nc
#         recon-all -all -s sub-{wildcards.subject} -hires -no-wsgcaatlas -notal-check -threads 8
#         """
