# -*- coding: utf-8 -*-
"""
Created on Fri May 19 16:54:16 2023

@author: JulianKeil
"""

study_name = "audiovisual"
bids_root = "BIDSData"
mf_cal_fname = "C:/Users/neuraltrainlab/Documents/CamCan/MEG/Calibration/sss_cal.dat"
mf_ctc_fname = "C:/Users/neuraltrainlab/Documents/CamCan/MEG/Calibration/ct_sparse.fif"

subjects = ["1", "2", "3"]

task = "audiovisual"
find_flat_channels_meg = True
find_noisy_channels_meg = True
use_maxwell_filter = True # UPDATE!
ch_types = ["meg"]

l_freq = 1.0
h_freq = 150.0
notch_freq = [25, 50, 100, 150]
raw_resample_sfreq = 600
crop_runs = None

# Artifact correction.
spatial_filter = "ica"
ica_max_iterations = 500
ica_l_freq = 1.0
ica_n_components = 0.99
ica_reject_components = "auto"

# Epochs
epochs_tmin = -2
epochs_tmax = 2
baseline = (None, 0)

# Conditions / events to consider when epoching
conditions = ["Visual"]