def dcmdir_search(wildcards):
    studyid  = recoding_dict[wildcards.subject]
    study    = 'epi' if 'EPI' in studyid else 'epinov'
    studydir = os.path.join(config['data']['raw'],study)
    
    dirlist  = [i for i in os.listdir(studydir) if os.path.isdir(os.path.join(studydir,i))]
    dcmdir   = [j for j in dirlist if re.match(fnmatch.translate(studyid), j, re.IGNORECASE)]

    return os.path.join(studydir,dcmdir[0])

# Filter dicoms and archive into tar file
rule prepare_tar:
    input: 
        dcmdir = dcmdir_search 
    output:
        tmpdir = directory('tar/sub-{subject}/tmp')
    params:
        filters = config['include']
    run:
        import os, re, fnmatch
        
        dirlist = ''
        for path, subdirs, files in os.walk(input.dcmdir):
            for subdir in subdirs:
                for pattern in params.filters:            
                    if re.match(fnmatch.translate('{}'.format(pattern)), subdir, re.IGNORECASE):
                        dirlist += str(os.path.join(input.dcmdir,path,subdir,' '))

        os.system('mkdir -p {}'.format(os.path.join(output.tmpdir,'dicoms')))
        os.system('cp -r {} {}'.format(dirlist, os.path.join(output.tmpdir,'dicoms')))
        
rule dicom2tar:
    input:
        dcmdir = 'tar/sub-{subject}/tmp'       
    output:
        tarfiles = 'tar/sub-{subject}/sub-{subject}_tar.files',
    params:
        outdir = os.path.join(config['data']['tar'],'sub-{subject}'),
        dicom2tar = config['containers']['dicom2tar']
    shell:
        "singularity run {params.dicom2tar} {input.dcmdir}/dicoms {params.outdir} && "  
        "if [[ $(ls {params.outdir}/*.tar) ]] ; then ls {params.outdir}/*tar > {output.tarfiles} ; fi && "
        "rm -rf {input.dcmdir}/dicoms"
    
# To convert (filtered) files in tar file to BIDS
rule tar2bids:
    input:
        tarfiles = 'tar/sub-{subject}/sub-{subject}_tar.files',
    output: 'bids/sub-{subject}/tar2bids.done'
    params:
        tar = 'tar/sub-{subject}/sub-{subject}.tar',
        outdir = 'bids',
        heuristics = config['heuristics'],
        script = '/home/rhaast/00_SOFTWARE/tar2bids/tar2bids',
        tsv = 'bids/sub-{subject}/sub-{subject}_scans.tsv',
        tar2bids = config['containers']['tar2bids']
    shell:
        "while read tar ; do "
        "   mv $tar {params.tar} ; "
        "   singularity exec {params.tar2bids} {params.script} -T sub-{{subject}} -o {params.outdir} -h {params.heuristics} {params.tar} ; "
        "   mv {params.tar} $tar ; "
        "done < {input.tarfiles} && "
        "if [ -f {params.tsv} ] ; then echo 'tar2bids done' > {output} ; fi"
