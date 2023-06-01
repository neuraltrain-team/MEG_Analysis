%% FT MEG TFR Example
% Spurce-Level Analysis
% Use Prewhitened data

%% 0. set basics
clc
clear
close all
ft_defaults

inpath = 'C:\Users\JulianKeil\MEGData CamCan\MEG\SourceData\';
headpath = 'C:\Users\JulianKeil\MEGData CamCan\MEG\HeadModel\';

indat = dir([inpath,'*_proc-clean_rej_epo.mat']);
headdat = dir([headpath, '*.mat']);

% 0.1 Read in Standard MRI and Headmodel for Plotting
standardmri = ft_read_mri('single_subj_T1.nii');
standardmri.coordsys = 'mni';
standardvol = load('standard_singleshell.mat');
standardvol.vol = ft_convert_units(standardvol.vol,'mm');

%% Loop Participants
for p = 1:length(indat)
    %% 1. Load Data
    load([inpath, indat(p).name]);
    load([headpath, headdat(p).name]);

    %% 5. Select Virtual Channels for ROIs
    % 5.1 Make sure that the leadfield is in the same space as the template
    lf.outside = find(lf.inside == 0);
    lf.inside = find(lf.inside == 1);
    lf.pos = template_grid.pos;

    % 5.2 Select the ROIs
    cfg=[];
    cfg.mri = standardmri;
    cfg.vol = singleshell;
    cfg.standardvol = standardvol.vol;
    cfg.lf = lf;
    cfg.atlas = 'C:\Users\JulianKeil\Github\fieldtrip\template\atlas\aal\ROI_MNI_V4.nii';
    
    cfg.roi = {'Occipital_Mid_L', 'Occipital_Mid_R'};
    cfg.hemisphere = 'both';
    lf_V1 = vt_make_roifield(cfg);

    cfg.roi = {'Hippocampus_L', 'Hippocampus_R'};
    cfg.hemisphere = 'both';
    lf_Hi = vt_make_roifield(cfg);

        % 5.2.1 Update the Labels
        % change inside labels (refer to all lf points) to str for label names
        for i = 1:length(lf_V1.inside)
            lf_V1.insidelabel{i} = num2str(lf_V1.inside(i));
        end
    
        % change inside labels (refer to all lf points) to str for label names
        for i = 1:length(lf_Hi.inside)
            lf_Hi.insidelabel{i} = num2str(lf_Hi.inside(i));
        end

    %% 2. Compute TFR
    for c = 1:length(sp.label)
        sp.label{c} = num2str(c);
        sp.label{c} = num2str(c);
    end

        % 2.1 Cut into baseline and activation window
        cfg = [];
        cfg.latency = [0 1];
        
        act = ft_selectdata(cfg,sp);
        
        cfg.latency = [-1 0];
        
        bl = ft_selectdata(cfg,sp);

    cfg=[];
    cfg.channel = [lf_V1.insidelabel lf_Hi.insidelabel];
    cfg.method='mtmfft'; % Method: Multitaper Convolution
    cfg.output='fourier'; % Output parameter
    cfg.foi=[0:2:20]; % Frequency resolution
    cfg.t_ftimwin = 0.2 * ones(numel(cfg.foi)); % Fixed 200ms Time Window
    cfg.tapsmofrq = 5 * ones(numel(cfg.foi)); % Fixed 10 Hz Smoothing
    cfg.taper = 'dpss'; % Adapt Slepian Tapers to the time-frequency window
    cfg.pad = 6;%'nextpow2';
    cfg.padtype = 'mirror';
    
    FFT_act{p} = ft_freqanalysis(cfg,act);
    FFT_bl{p} = ft_freqanalysis(cfg,bl);
    
    

    cfg         = [];
    cfg.channel = [lf_V1.insidelabel lf_Hi.insidelabel];
    cfg.method  = 'psi';
    cfg.bandwidth = 5;
    %cfg.complex = 'absimag';
    conn_act{p} = ft_connectivityanalysis(cfg, FFT_act{p});
    conn_bl{p} = ft_connectivityanalysis(cfg, FFT_bl{p});

    conn_blc{p} = conn_act{p};
    conn_blc{p}.psispctrm = (conn_act{p}.psispctrm - conn_bl{p}.psispctrm);% ./ conn_bl.psispctrm;

end

%%
cfg = [];
cfg.parameter = 'psispctrm';
GA_conn = vt_conngrandaverage(cfg,conn_blc{:});
GA_conn.grad = conn_blc{1}.grad;

%%

cfg = [];
cfg.parameter = 'psispctrm';

ft_connectivityplot(cfg,GA_conn);

%%

standardvol.vol.bnd(3) = standardvol.vol.bnd(1);
lf.avg.pow = zeros(size(lf.inside));

cfg = [];
cfg.parameter = 'psispctrm';
cfg.dummy = lf;
cfg.vol = standardvol.vol;
cfg.freq = 5;
cfg.source = {'3090'};
cfg.sink = lf_Hi.insidelabel;
cfg.sourceplot = 'yes';
cfg.mri = standardmri;
cfg.islocation = 'yes';

vt_plot_wireconn(cfg,GA_conn);
%% Stats
% Reshape to channel combinations
% Then treat as Freq data

for v = 1:length(conn_blc) 
    conn_zero{v} = conn_blc{v};
    conn_zero{v}.psispctrm = zeros(size(conn_blc{v}.psispctrm));
end

% 6.3. Statistics
cfg = [];
cfg.parameter = 'psispctrm';
cfg.method = 'montecarlo';
cfg.numrandomization = 5000;%'all';
cfg.correctm = 'none';
cfg.neighbours = [];
cfg.statistic = 'depsamplesT';
cfg.correcttail = 'alpha';
cfg.uvar = 1;
cfg.ivar = 2;
cfg.design = [1:length(conn_blc),1:length(conn_blc);...
            ones(1,length(conn_blc)),ones(1,length(conn_blc)).*2];

% Restrict the data of interest
cfg.avgoverchan = 'no'; % Should we average actross a ROI?
%cfg.latency = [0 .15]; % Post-Stimulus interval
%cfg.avgovertime = 'yes';
cfg.frequency = 5;
cfg.avgoverfreq = 'no';

%cfg.channel = lf_V1.insidelabel; % all channels (you can also set the ROI here)
stats_conn = ft_freqstatistics(cfg,conn_blc{:},conn_zero{:});
