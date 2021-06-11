# def dcmdir_search(wildcards):
#     studyid  = recoding_dict[wildcards.subject]
#     study    = 'epi' if 'EPI' in studyid else 'epinov'
#     studydir = os.path.join(config['data']['raw'],study)
    
#     dirlist  = [i for i in os.listdir(studydir) if os.path.isdir(os.path.join(studydir,i))]
#     dcmdir   = [j for j in dirlist if re.match(fnmatch.translate(studyid), j, re.IGNORECASE)]

#     return os.path.join(studydir,dcmdir[0])

# # Filter dicoms and archive into tar file
# rule prepare_tar:
#     input: 
#         dcmdir = dcmdir_search 
#     output:
#         tmpdir = directory('tar/sub-{subject}/tmp')
#     params:
#         filters = config['include']
#     run:
#         import os, re, fnmatch
        
#         dirlist = ''
#         for path, subdirs, files in os.walk(input.dcmdir):
#             for subdir in subdirs:
#                 for pattern in params.filters:            
#                     if re.match(fnmatch.translate('{}'.format(pattern)), subdir, re.IGNORECASE):
#                         dirlist += str(os.path.join(input.dcmdir,path,subdir,' '))

#         os.system('mkdir -p {}'.format(os.path.join(output.tmpdir,'dicoms')))
#         os.system('cp -r {} {}'.format(dirlist, os.path.join(output.tmpdir,'dicoms')))
        
# rule dicom2tar:
#     input:
#         dcmdir = 'tar/sub-{subject}/tmp'       
#     output:
#         tarfiles = 'tar/sub-{subject}/sub-{subject}_tar.files',
#     params:
#         outdir = os.path.join(config['data']['tar'],'sub-{subject}'),
#         dicom2tar = config['containers']['dicom2tar']
#     shell:
#         "singularity run {params.dicom2tar} {input.dcmdir}/dicoms {params.outdir} && "  
#         "if [[ $(ls {params.outdir}/*.tar) ]] ; then ls {params.outdir}/*tar > {output.tarfiles} ; fi && "
#         "rm -rf {input.dcmdir}/dicoms"
    
# # To convert (filtered) files in tar file to BIDS
# rule tar2bids:
#     input:
#         tarfiles = 'tar/sub-{subject}/sub-{subject}_tar.files',
#     output: 'bids/sub-{subject}/tar2bids.done'
#     params:
#         tar = 'tar/sub-{subject}/sub-{subject}.tar',
#         outdir = 'bids',
#         heuristics = config['heuristics'],
#         script = '/home/rhaast/00_SOFTWARE/tar2bids/tar2bids',
#         tsv = 'bids/sub-{subject}/sub-{subject}_scans.tsv',
#         tar2bids = config['containers']['tar2bids']
#     shell:
#         "while read tar ; do "
#         "   mv $tar {params.tar} ; "
#         "   singularity exec {params.tar2bids} {params.script} -T sub-{{subject}} -o {params.outdir} -h {params.heuristics} {params.tar} ; "
#         "   mv {params.tar} $tar ; "
#         "done < {input.tarfiles} && "
#         "if [ -f {params.tsv} ] ; then echo 'tar2bids done' > {output} ; fi"

# # Characterize dataset
# rule count_data:
#     input: expand('bids/sub-{s}/tar2bids.done', s=subjects)
#     output: 'bids/dataset_characteristics.csv'
#     params: 
#         subjects = subjects,
#         columns = ['Subject','T1w','FLAIR','dwi','epi','bold']
#     group: 'bids'
#     run:
#         import os, re, fnmatch
#         import numpy as np
#         import pandas as pd

#         df = pd.DataFrame(columns=params.columns)    

#         for s, subject in enumerate(subjects):
#             counts = np.zeros(len(params.columns[1:]))

#             for sfx, suffix in enumerate(params.columns[1:]):
#                 for root, dirs, files in os.walk('bids/sub-{}'.format(subject)):
#                     for file in files:    
#                         if file.endswith('{}.nii.gz'.format(suffix)):
#                             counts[sfx] += 1
#             df.loc[s] = np.hstack(('sub-{}'.format(subject),counts)) 
#         df.to_csv(output[0],index=False)

# Gradient distortion correction
rule gradcorrect:
    input: 'bids/sub-{subject}/tar2bids.done'
    output: directory('deriv/gradcorrect/sub-{subject}')
    params:
        gradcorrect = config['containers']['gradcorrect'],
        script = 'scripts/gradcorrect/run.sh',
        coeff = 'resources/coeff_SC72CD.grad'
    resources:
        mem_mb = 64000,
        time = 240
    shell:
        """
        singularity exec {params.gradcorrect} {params.script} bids deriv/gradcorrect participant --grad_coeff_file {params.coeff} --participant_label {wildcards.subject}
        """