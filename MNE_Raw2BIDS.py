# -*- coding: utf-8 -*-
"""
MNE BIDS Pipeline: 
Step 1: Read Raw data and convert to BIDS

@author: JulianKeil
"""
# 0. import basic libraries
import os
import mne
from mne_bids import (write_raw_bids, BIDSPath)

## 0.1 Set data path
data_path = 'C:/Users/neuraltrainlab/Documents/CamCan/MEG/RawData'
output_path = 'C:/Users/neuraltrainlab/Documents/CamCan/MEG/BIDSData'

## 0.2 Set File and Folder Names
raw_fname = os.listdir(data_path)

# 1. Loop Participants
i = 0 # index
for v in raw_fname:
    i = i+1
    # 1. Read in the Raw Data
    indat = os.path.join(data_path,v)
    raw = mne.io.read_raw(indat)
    
    ## 1.1. Get the events
    events = mne.find_events(raw, min_duration=0.002)
    
    ## 1.2 Define Event IDs -> Information is stored in the Events channel STI 014
    event_id = {'AuditoryLow': 6, 'AuditoryMid': 7, 
                'AuditoryHigh': 8, 'Visual': 9}
    
    ## 1.3 Specify Power Line Frequency
    raw.info['line_freq'] = 50
    
    # 2. Export as BIDS
    ## 2.1 Set up BIDS information
    task = 'audiovisual'
    bids_path = BIDSPath(
        subject= str(i),
        session='01',
        task=task,
        run='1',
        root=output_path
        )
    ## 2.2 Write BIDS information
    write_raw_bids(
        raw=raw,
        bids_path=bids_path,
        events=events,
        event_id=event_id,
        overwrite=True
        )

# ## 2.3 Reading BIDS works with rwad_raw_bids
# raw = read_raw_bids(bids_path=bids_path)

# ## 2.3. If available, add calibration files to the dataset
# cal_fname = op.join(data_path, 'SSS', 'sss_cal_mgh.dat')
# ct_fname = op.join(data_path, 'SSS', 'ct_sparse_mgh.fif')

# write_meg_calibration(cal_fname, bids_path)
# write_meg_crosstalk(ct_fname, bids_path)

# # 3. Inspect data
# ## 3.1 Look at the sidecar file with all the information
# sidecar_json_bids_path = bids_path.copy().update(extension='.json')
# sidecar_json_content = sidecar_json_bids_path.fpath.read_text(
#     encoding='utf-8-sig'
#     )
# print(sidecar_json_content) 

# ## 3.2 Look at the events
# counts = count_events(output_path)
# counts

