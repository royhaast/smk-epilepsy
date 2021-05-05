rule bold_fieldmap:
    input: 'bids/sub-{subject}/tar2bids.done'
    output: touch('logs/sub-{subject}/epi_fieldmap.done')
    params:
        funcdir = 'bids/sub-{subject}/func',
        fmapdir = 'bids/sub-{subject}/fmap',
        checkpoint = 'bids/sub-{subject}/epi_acquired.done'
    container: config['containers']['fmriprep']
    shell:
        "python scripts/epi_fmap_corrector.py {params.funcdir} {params.fmapdir} {params.checkpoint}"

rule bold_preprocessing:
    input: 'logs/sub-{subject}/epi_fieldmap.done'
    output: touch('logs/sub-{subject}/fmriprep.done')
    params:
        checkpoint = 'bids/sub-{subject}/epi_acquired.done',
        fmriprep = config['containers']['fmriprep'],
        fmriprep_params = "-w work --skip_bids_validation --cifti-output 91k"
    shell:
        "if [ -f {params.checkpoint} ] ; then "
        "   singularity run {params.fmriprep} bids deriv/fmriprep participant --participant-label {wildcards.subject} {params.fmriprep_params} ; "
        "else "
        "   echo 'no epi found, not running fmriprep' ; "
        "fi "