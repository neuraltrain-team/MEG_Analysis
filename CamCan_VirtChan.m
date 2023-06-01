%% Example for Virtual Channel Projection
%% 0. Set basics 
clear
close all
clc
ft_defaults

% 0.1 Set Paths
headpath = 'C:\Users\JulianKeil\MEGData CamCan\MEG\HeadModel\';
datapath = 'C:\Users\JulianKeil\MEGData CamCan\MEG\FTData\';
outpath = 'C:\Users\JulianKeil\MEGData CamCan\MEG\SourceData\';

headdat = dir([headpath, '*.mat']);
indat = dir([datapath, '*.mat']);

% 0.2 Set parameters
taper = 'dpss';
foi = 10;
tapsmofrq = 2;
pad = 6;
lambda = 5;
latency = [0 .5];

%% Loop participants
for p = 1:length(indat)
    %% 1. Load Data 
    load([datapath, indat(p).name]);
    load([headpath, headdat(p).name]);
    
    %% 2. Copute Power and Cross-Spectral Density for the Frequency of Interest
%         % 2.1. Select Relevant Channels
%         selmag  = strcmpi(dataw_meg.grad.chantype, 'megmag');
%         selgrad = strcmpi(dataw_meg.grad.chantype, 'megplanar');
%     
%         cfg = [];
%         cfg.channel = dataw_meg.label(selmag);
%     
%         dataw_meg = ft_selectdata(cfg,dataw_meg);
%         dataw_meg.chantype = dataw_meg.chantype(selmag);
%         dataw_meg.chanunit = dataw_meg.chanunit(selmag);

    % Use the whole interval
    cfg=[];
    cfg.method = 'mtmfft';
    cfg.output = 'powandcsd';
    cfg.taper = taper;
    cfg.keeptrials = 'no';
    cfg.foi = foi;
    cfg.tapsmofrq = tapsmofrq;
    cfg.pad = pad;
    
    csd_all = ft_freqanalysis(cfg,dataw_meg); % All data
    
    %% 3. Source Analysis to obtain spatial filter
    cfg=[];
    cfg.method = 'dics';
    cfg.frequency = foi;
    cfg.sourcemodel = lf;
    cfg.headmodel = singleshell;
    cfg.dics.keepfilter = 'yes';
    cfg.dics.realfilter = 'yes';
    cfg.dics.lambda = lambda;
    cfg.latency = latency;
    cfg.dics.fixedori = 'yes';
    
    source = ft_sourceanalysis(cfg,csd_all);
    
    %% 4. Virtual Channel projection
    % First find out which sources are inside the brain
    lf.outside = find(lf.inside == 0);
    lf.inside = find(lf.inside == 1);
    
    % Then project the data to the channels inside the brain
    cfg = [];
    cfg.pos = lf.pos(lf.inside,:);

    sp = ft_virtualchannel(cfg,dataw_meg,source);
      
    %% 6. Save
    save([outpath,indat(p).name],'sp','-V7.3');
end