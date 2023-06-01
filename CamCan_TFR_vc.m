%% FT MEG TFR Example
% Spurce-Level Analysis
% Use Prewhitened data

%% 0. set basics
clc
clear
close all
ft_defaults

inpath = 'C:\Users\JulianKeil\MEGData CamCan\MEG\SourceData_allchan\';
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

    %% 2. Compute TFR
    cfg=[];
    cfg.method='mtmconvol'; % Method: Multitaper Convolution
    cfg.output='pow'; % Output parameter
    cfg.foi=[1:2:20]; % Frequency resolution
    cfg.toi=[-2:.01: 2]; % Temporal resolution
    cfg.t_ftimwin = 0.2 * ones(numel(cfg.foi)); % Fixed 200ms Time Window
    cfg.tapsmofrq = 5 * ones(numel(cfg.foi)); % Fixed 10 Hz Smoothing
    cfg.taper = 'dpss'; % Adapt Slepian Tapers to the time-frequency window
    cfg.pad = 6;%'nextpow2';
    cfg.padtype = 'mirror';
    
    TFR_all = ft_freqanalysis(cfg,sp);
    
        % 2.1 Cut into baseline and activation window
        cfg = [];
        cfg.latency = [0 .5];
        
        TFR_act = ft_selectdata(cfg,TFR_all);
        
        cfg.latency = [-.5 0];
        
        TFR_bl = ft_selectdata(cfg,TFR_all);
    
    %% 3. Average across time to get stable power spectrum
    mean_act = mean(TFR_act.powspctrm,3,'omitnan');
    mean_bl = mean(TFR_bl.powspctrm,3,'omitnan');
    
        % 3.1 Baseline Correction
        TFR_act = rmfield(TFR_act,{'time'});
        TFR_act.dimord = 'chan_freq';
        TFR_act.powspctrm = mean_act;
        TFR_bl = rmfield(TFR_bl,{'time'});
        TFR_bl.dimord = 'chan_freq';
        TFR_bl.powspctrm = mean_bl;
        
        TFR_blc{p} = TFR_act;
        TFR_blc{p}.powspctrm = 10*log10(mean_act ./ mean_bl);
end

%% 4. Grand Average
GA_blc_vc = ft_freqgrandaverage([],TFR_blc{:});
GA_blc_vc.grad = TFR_blc{1}.grad;

    % 4.1. Update Labels
    for c = 1:length(GA_blc_vc.label)
        GA_blc_vc.label{c} = num2str(c);
    end

    for p = 1:length(TFR_blc)
        for c = 1:length(TFR_blc{p}.label)
            TFR_blc{p}.label{c} = num2str(c);
        end
    end

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

%% 6. Stats
    % 6.1 Build dummy data with zeros to test against
    for v = 1:length(TFR_blc) 
        TFR_zero{v} = TFR_blc{v};
        TFR_zero{v}.powspctrm = zeros(size(TFR_blc{v}.powspctrm));
    end

    % 6.3. Statistics
    cfg = [];
    cfg.parameter = 'powspctrm';
    cfg.method = 'montecarlo';
    cfg.numrandomization = 5000;%'all';
    cfg.correctm = 'none';
    cfg.neighbours = [];
    cfg.statistic = 'depsamplesT';
    cfg.correcttail = 'alpha';
    cfg.uvar = 1;
    cfg.ivar = 2;
    cfg.design = [1:length(TFR_blc),1:length(TFR_blc);...
                ones(1,length(TFR_blc)),ones(1,length(TFR_blc)).*2];
    
    % Restrict the data of interest
    cfg.avgoverchan = 'yes'; % Should we average actross a ROI?
    %cfg.latency = [0 .15]; % Post-Stimulus interval
    %cfg.avgovertime = 'yes';
    cfg.frequency = 5;
    cfg.avgoverfreq = 'no';
    
    cfg.channel = lf_V1.insidelabel; % all channels (you can also set the ROI here)
    stats_V1 = ft_freqstatistics(cfg,TFR_blc{:},TFR_zero{:});
    
    cfg.channel = lf_Hi.insidelabel; % all channels (you can also set the ROI here)
    stats_Hi = ft_freqstatistics(cfg,TFR_blc{:},TFR_zero{:});

%% 7. Plots
cfg = [];
cfg.channel = lf_V1.insidelabel;

ft_singleplotER(cfg,GA_blc_vc)

cfg = [];
cfg.channel = lf_Hi.insidelabel;

ft_singleplotER(cfg,GA_blc_vc)

standardvol.vol.bnd(3) = standardvol.vol.bnd(1);
lf.avg.pow = zeros(size(lf.inside));

cfg = [];
cfg.parameter = 'powspctrm';
cfg.dummy = lf;
cfg.vol = standardvol.vol;
cfg.freq = 5;
cfg.sourceplot = 'yes';
cfg.mri = standardmri;
cfg.islocation = 'yes';

vt_plot_wirebrain(cfg,GA_blc_vc);
