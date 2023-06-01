%% FT MEG TFR Example
% Sensor-Level Analysis
% Use Prewhitened data

%% 0. set basics
clc
clear
close all
ft_defaults

inpath = 'C:\Users\JulianKeil\MEGData CamCan\MEG\FTData\';
indat = dir([inpath,'*_proc-clean_rej_epo.mat']);

%% Loop Participants
for p = 1:length(indat)
    %% 1. Load Data
    load([inpath, indat(p).name]);

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
    
    TFR_all = ft_freqanalysis(cfg,dataw_meg);
    
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

    %% 4. Combine Planar for visualization purposes!
    cfg = [];
    cfg.updatesens = 'yes';
    TFR_blc_comb{p} = ft_combineplanar(cfg,TFR_blc{p});

    % Set Cmbined channel type
    for c = 1:length(TFR_blc_comb{p}.grad.chantype)
        if strcmpi(TFR_blc_comb{p}.grad.chantype(c),'unknown')
            TFR_blc_comb{p}.grad.chantype{c} = 'megplanar';
        end
    end

end

%% 5. Grad Average
GA_blc_comb = ft_freqgrandaverage([],TFR_blc_comb{:});
GA_blc_comb.grad = TFR_blc_comb{1}.grad;

%% 6. Stats
    % 6.1 Build dummy data with zeros to test against
    for v = 1:length(TFR_blc_comb) 
        TFR_zero{v} = TFR_blc_comb{v};
        TFR_zero{v}.powspctrm = zeros(size(TFR_blc_comb{v}.powspctrm));
    end

    % 6.2. Define Neighbours
    selmag  = strcmpi(GA_blc_comb.grad.chantype, 'megmag');
    selgrad = strcmpi(GA_blc_comb.grad.chantype, 'megplanar');

    cfg = []; 
    cfg.channel = GA_blc_comb.label(selmag);
    cfg.method = 'distance'; % how should the neighbors be selected?
    cfg.neighbourdist = 5; % I have no Idea what range this has, just make sure, that you get meaningful neighbors
    cfg.grad = GA_blc_comb.grad; % Here we need the 3d-positions!
    
    neigh_mag = ft_prepare_neighbours(cfg); % between 5 and 10 neighbors is a good value, always good to check!

    cfg.channel = GA_blc_comb.label(selgrad);
    
    neigh_grad = ft_prepare_neighbours(cfg); % between 5 and 10 neighbors is a good value, always good to check!


    % 6.3. Statistics
    cfg = [];
    cfg.parameter = 'powspctrm';
    cfg.method = 'montecarlo';
    cfg.numrandomization = 5000;%'all';
    cfg.correctm = 'none';
    cfg.neighbours = neigh;
    cfg.statistic = 'depsamplesT';
    cfg.correcttail = 'alpha';
    cfg.uvar = 1;
    cfg.ivar = 2;
    cfg.design = [1:length(TFR_blc_comb),1:length(TFR_blc_comb);...
                ones(1,length(TFR_blc_comb)),ones(1,length(TFR_blc_comb)).*2];
    
    % Restrict the data of interest
    cfg.avgoverchan = 'no'; % Should we average actross a ROI?
    %cfg.latency = [0 .15]; % Post-Stimulus interval
    %cfg.avgovertime = 'yes';
    cfg.frequency = 5;
    cfg.avgoverfreq = 'no';
    
    cfg.channel = {'MEG2121'}; % all channels (you can also set the ROI here)
    stats_mag = ft_freqstatistics(cfg,TFR_blc_comb{:},TFR_zero{:});
    
    cfg.channel = {'MEG2112+2113'}; % all channels (you can also set the ROI here)
    stats_grad = ft_freqstatistics(cfg,TFR_blc_comb{:},TFR_zero{:});

%% 7. Plots
GA_blc_comb.grad = TFR_blc_comb{1}.grad;

selmag  = strcmpi(GA_blc_comb.grad.chantype, 'megmag');
selgrad = strcmpi(GA_blc_comb.grad.chantype, 'megplanar');

cfg        = [];
cfg.channel = GA_blc_comb.label(selmag);
cfg.layout = 'neuromag306mag_helmet.mat';
figure; ft_multiplotER(cfg,GA_blc_comb)

cfg        = [];
cfg.channel = GA_blc_comb.label(selgrad);
cfg.layout = 'neuromag306cmb_helmet.mat';
figure; ft_multiplotER(cfg,GA_blc_comb)
