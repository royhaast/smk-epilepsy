def mp2ragedir_search(wildcards):
    studyid = recoding_dict[wildcards.subject]
    paths   = config['data']['mp2rage']
    datadir = None
    
    p = 1
    while not datadir:
        dirlist = [i for i in os.listdir(mp2ragedir) if os.path.isdir(os.path.join(paths[p],i))]
        datadir = [j for j in dirlist if re.match(fnmatch.translate(paths[p]), j, re.IGNORECASE)]
        if datadir:
            mp2ragedir = os.path.join(paths[p],datadir[0])
            break
        else:
            p += 1
    
    return mp2ragedir

rule import_b1_corrected_data:
    input: mp2ragedir_search
    output:
        'deriv/mp2rage/sub-{subject}/'
    