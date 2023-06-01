# MEG_Analysis
Collection of Python and Matlab Scripts to run the MEG data analysis for Mars2

# MEG Data Analysis Pipeline

All scripts are on GitHub under: https://github.com/neuraltrain-team/MEG_Analysis

Pipeline requires:

- MNE Python: https://mne.tools/stable/index.html
- FieldTrip: https://www.fieldtriptoolbox.org/
- VirtualTools: https://github.com/juliankeil/VirtualTools

## Preprocessing: MNE Python

1. Step 1: Convert Raw MEG files to BIDS format:
    1. Run **MNE_Raw2Bids.py** to read in the raw MEG data and format for the automatic processing
2. Step 2: Run the automatic BIDS pipeline: Attention, need the fine MEG configuration files
    1. Go to the command line, go to the root folder of the BIDS data and run (watch out, this needs the fine configuration files for the MEG system!): **mne_bids_pipeline --config=MNE_BIDS_config.py --steps=preprocessing**
        1. Find Noisy or Flat Channels
        2. Maxwell Filter
        3. Bandpass and Notch Filter
        4. ICA
        5. Epoch
        6. Condition Selection
3. Step 3: Automatic rejection of bad channels and epochs
    1. **Run MNE_BIDS_autoreject.py**

## TFR and Source Analysis: FieldTrip

1. Step 1: Read in MNE BIDS Data
    1. Run **CamCan_Import.m** to select MEG channels and prewhiten the MEG data to have the same scale between magnetometers and gradiometers 
2. Step 2: Create Headmodel
    1. Read in the Headmodel in MRIcoGL to double check orientation
    2. Run **CamCan_Headmodel.m** to build headmodel and sourcemodel. Watch out, this requires some user input to re-orient the MRI and MEG data in space
3. Compute TFR in Sensor Space
    1. Run **CamCan_TFR.m** to compute TFR
    2. Stats and Plotting in the same script
4. Project data to virtual channels in source space
    1. Run **CamCan_VirtChan.m** for Virtual Sensor Projection
5. Compute TFR in Source Space
    1. Run **CamCan_TFR_vc.m** to compute TFR
    2. Stats and Plotting in the same script
6. Compute Connectivity in Source Space
    1. Run CamCan_Connectivity.m to compute Functional Connectivity
    2. Stats and Plotting in the same script
