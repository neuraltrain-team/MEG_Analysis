# -*- coding: utf-8 -*-
"""
MNE BIDS Pipeline: 
Step 4: Autoreject

@author: JulianKeil
"""

# 0. Import basic libraries
import os
import mne
from mne_bids import (BIDSPath)
from autoreject import AutoReject

## 0.1 Set data path
bids_derivs = 'C:/Users/neuraltrainlab/Documents/CamCan/MEG/BIDSData/derivatives/mne-bids-pipeline/'
out_path = 'C:/Users/neuraltrainlab/Documents/CamCan/MEG/CleanData/'

## 0.2 Set File and Folder Names
bids_fname = [item for item in os.listdir(bids_derivs) if os.path.isdir(os.path.join(bids_derivs, item))]

# 1. Loop participants
for v in bids_fname:
    print(v)
    if v[0:3]=='sub': # only include if folder starts with sub
        sub_split = v.split("-")
        bids_path = BIDSPath(subject=sub_split[1], session='01', task='audiovisual', processing='clean',
                             root=bids_derivs)
        
        inpath = str(bids_path.root)
        subpath = '/sub-'+sub_split[1]+'/ses-01/meg/'
        indat = '/'+bids_path.basename+'_epo.fif'
        outdat = bids_path.basename+'_rej_epo.fif'
        outlog = bids_path.basename+'_rej_epo.npz'
        
        # 1.1 Reading BIDS works with read_raw_bids
        raw = mne.read_epochs(inpath+subpath+indat)
            
        # Reject Data
        rej = AutoReject(random_state = 100).fit(raw[:20])
        rej_epochs, reject_log = rej.transform(raw, return_log=True)
        
        rej_epochs.save(out_path+outdat,overwrite=True)
        reject_log.save(out_path+outlog,overwrite=True)

