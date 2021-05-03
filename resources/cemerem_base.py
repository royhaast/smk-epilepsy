import os

def create_key(template, outtype=('nii.gz'), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return (template, outtype, annotation_classes)

def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where

    allowed template fields - follow python string module:

    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """

    #MP2RAGE
    inv1_mp2rage_m = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_inv-1_run-{item:02d}_part-mag_MP2RAGE')
    inv2_mp2rage_m = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_inv-2_run-{item:02d}_part-mag_MP2RAGE')
    inv1_mp2rage_p = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_inv-1_run-{item:02d}_part-phase_MP2RAGE')
    inv2_mp2rage_p = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_inv-2_run-{item:02d}_part-phase_MP2RAGE')    
    uni_mp2rage    = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_acq-UNI_run-{item:02d}_MP2RAGE')    
    t1w            = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_acq-MP2RAGE_run-{item:02d}_T1w')
    t1map          = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_acq-MP2RAGE_run-{item:02d}_T1map')

    #FLAWS
    inv1_flaws_m = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_inv-1_run-{item:02d}_part-mag_FLAWS')
    inv2_flaws_m = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_inv-2_run-{item:02d}_part-mag_FLAWS')
    inv1_flaws_p = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_inv-1_run-{item:02d}_part-phase_FLAWS')
    inv2_flaws_p = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_inv-2_run-{item:02d}_part-phase_FLAWS')    
    uni_flaws    = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_acq-UNI_run-{item:02d}_FLAWS')    
    t1w_flaws    = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_acq-FLAWS_run-{item:02d}_T1w')
    t1map_flaws  = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_acq-FLAWS_run-{item:02d}_T1map')    
    flaws        = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_acq-FLAWS_run-{item:02d}') 

    #ME-GRE
    me_gre_m = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_run-{item:02d}_echo_part-mag_MEGRE') 
    me_gre_p = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_run-{item:02d}_echo_part-phase_MEGRE')

    #DWI
    dwi_ap       = create_key('{bids_subject_session_dir}/dwi/{bids_subject_session_prefix}_dir-{dir}_run-{item:02d}_dwi')
    dwi_pa       = create_key('{bids_subject_session_dir}/dwi/{bids_subject_session_prefix}_dir-{dir}_run-{item:02d}_dwi')

    #BOLD
    rest_lr      = create_key('{bids_subject_session_dir}/func/{bids_subject_session_prefix}_task-rest_dir-{dir}_run-{item:02d}_bold')
    rest_rl      = create_key('{bids_subject_session_dir}/func/{bids_subject_session_prefix}_task-rest_dir-{dir}_run-{item:02d}_bold')

    #SPACE
    t2           = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_acq-SPACE_run-{item:02d}_T2w')
    flair        = create_key('{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_acq-SPACE_run-{item:02d}_FLAIR')

    #FMAP
    fmap_b1_m    = create_key('{bids_subject_session_dir}/fmap/{bids_subject_session_prefix}_part-mag_run-{item:02d}_TB1TFL')
    fmap_b1_p    = create_key('{bids_subject_session_dir}/fmap/{bids_subject_session_prefix}_part-phase_run-{item:02d}_TB1TFL')

    #SODIUM
    na_modspokes = create_key('{bids_subject_session_dir}/sodium/{bids_subject_session_prefix}_acq-23Na_run-{item:02d}_echo_modspokes')
    na_b0b1_m    = create_key('{bids_subject_session_dir}/sodium/{bids_subject_session_prefix}_acq-23Na_run-{item:02d}_echo_part-mag_B0B1map')
    na_b0b1_r    = create_key('{bids_subject_session_dir}/sodium/{bids_subject_session_prefix}_acq-23Na_run-{item:02d}_echo_part-real_B0B1map')

    info = {inv1_mp2rage_m:[],
            inv2_mp2rage_m:[],
            inv1_mp2rage_p:[],
            inv2_mp2rage_p:[],            
            uni_mp2rage:[],            
            t1w:[],
            t1map:[],

            inv1_flaws_m:[],
            inv2_flaws_m:[],
            inv1_flaws_p:[],
            inv2_flaws_p:[],            
            uni_flaws:[],            
            t1w_flaws:[],
            t1map_flaws:[],
            flaws:[],

            me_gre_m:[],
            me_gre_p:[],

            t2:[],flair:[],

            dwi_ap:[],dwi_pa:[],
            rest_lr:[],rest_rl:[],

            fmap_b1_m:[],fmap_b1_p:[],

            na_modspokes:[], na_b0b1_m:[], na_b0b1_r:[]
    }

    for idx, s in enumerate(seqinfo):
        #MP2RAGE
        if ('mp2rage' in (s.series_description).lower()):
            if ('inv1' in (s.series_description).strip().lower()):
                if ('phs' in (s.series_description).strip().lower()):
                    info[inv1_mp2rage_p].append({'item': s.series_id,'part':'phase'})
                else:
                    info[inv1_mp2rage_m].append({'item': s.series_id,'part':'mag'})
            if ('inv2' in (s.series_description).strip().lower()):
                if ('phs' in (s.series_description).strip().lower()):
                    info[inv2_mp2rage_p].append({'item': s.series_id,'part':'phase'})
                else:
                    info[inv2_mp2rage_m].append({'item': s.series_id,'part':'mag'})
            if ('uni_images' in (s.series_description).strip().lower()):
                info[uni_mp2rage].append({'item': s.series_id})
            if ('uni-den' in (s.series_description).strip().lower()):
                info[t1w].append({'item': s.series_id})                                                
            if ('t1_images' in (s.series_description).strip().lower()):
                info[t1map].append({'item': s.series_id})

        #FLAWS
        if ('flaws' in (s.series_description).strip().lower()):
            if ('inv1' in (s.series_description).strip().lower()):
                if ('phs' in (s.series_description).strip().lower()):
                    info[inv1_flaws_p].append({'item': s.series_id,'part':'phase'})
                else:
                    info[inv1_flaws_m].append({'item': s.series_id,'part':'mag'})
            if ('inv2' in (s.series_description).strip().lower()):
                if ('phs' in (s.series_description).strip().lower()):
                    info[inv2_flaws_p].append({'item': s.series_id,'part':'phase'})
                else:
                    info[inv2_flaws_m].append({'item': s.series_id,'part':'mag'})
            if ('uni_images' in (s.series_description).strip().lower()):
                info[uni_flaws].append({'item': s.series_id})
            if ('uni-den' in (s.series_description).strip().lower()):
                info[t1w_flaws].append({'item': s.series_id})                                                
            if ('t1_images' in (s.series_description).strip().lower()):
                info[t1map_flaws].append({'item': s.series_id})
            if ('FLAWS' in (s.series_description).strip()):
                info[flaws].append({'item': s.series_id})

        #ME-GRE
        if ('qsm2_separated' in (s.series_description).strip().lower()):
            if ('M' in s.image_type[2].strip()):
                info[me_gre_m].append({'item': s.series_id})
            if ('P' in s.image_type[2].strip()):
                info[me_gre_p].append({'item': s.series_id})

        #Timeseries data
        #DWI and BOLD
        if s.dim4 > 2 :
            if ('dti' in (s.series_description).strip().lower()):
                if ('ap' in (s.series_description).strip().lower()):
                    info[dwi_ap].append({'item': s.series_id,'dir':'AP'})
                elif ('pa' in (s.series_description).strip().lower()):
                    info[dwi_pa].append({'item': s.series_id,'dir':'PA'})
            elif ('ep2d' in (s.series_description).strip().lower()):
                if ('boldrl' in (s.series_description).strip().lower()) or ('bold_rl' in (s.series_description).strip().lower()):
                    info[rest_rl].append({'item': s.series_id,'dir':'RL'})
                elif ('boldlr' in (s.series_description).strip().lower()) or ('bold_lr' in (s.series_description).strip().lower()):
                    info[rest_lr].append({'item': s.series_id,'dir':'LR'})

        #SPACE
        if ('space' in (s.series_description).strip().lower()):
            if ('spc3d' in (s.sequence_name).strip().lower()):
                info[t2].append({'item': s.series_id})
            elif ('spcirr3d' in (s.sequence_name).strip().lower()):
                info[flair].append({'item': s.series_id})            

        #FMAP
        if ('b1map' in (s.series_description).strip().lower()):
            if ('M' in s.image_type[2].strip()):
                info[fmap_b1_m].append({'item': s.series_id,'part':'mag'})
            if ('P' in s.image_type[2].strip()):
                info[fmap_b1_p].append({'item': s.series_id,'part':'phase'})

        #SODIUM
        if ('23na' in (s.series_description).strip().lower()) or ('sod' in (s.series_description).strip().lower()):
            if ('modified_spokes' in (s.series_description).strip().lower()):
                info[na_modspokes].append({'item': s.series_id})
            else:
                if ('M' in s.image_type[2].strip()):
                    info[na_b0b1_m].append({'item': s.series_id})
                if ('R' in s.image_type[2].strip()):
                    info[na_b0b1_r].append({'item': s.series_id})                    

    return info