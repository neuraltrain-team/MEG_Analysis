%% Example for Virtual Channel Projection
%% 0. Set basics 
clear
close all
clc
ft_defaults

% 0.1 Set Paths
headpath = 'C:\Users\JulianKeil\MEGSalzburg\ExpData3\Headmodel\OnMRI\';
datapath = 'C:\Users\JulianKeil\MEGSalzburg\ExpData3\FTData\';
outpath = 'D:\MEG experiments\MEGSalzburg\WithBaseline\SourceData\';%'C:\Users\JulianKeil\MEGSalzburg\ExpData3\SourceData\';

headdat = dir([headpath, '*.mat']);
indat = dir([datapath, '*.mat']);

% 0.2 Set parameters
lambda = 5;
latency = [0 1];

%% Loop participants
for p = 1:length(indat)
    %% 1. Load Data 
    load([datapath, indat(p).name]);

    % Get subject ID to load appropriate Headmodel
    id = indat(p).name(1:16);
    orig = load([headpath, id]);

    % Make a sparse headmodel
    sparsegrid = orig.grid;
    sparsetemplate = orig.template_grid;
    ind = 1:length(sparsegrid.inside);
    sub = reshape(ind,sparsegrid.dim);
    sparsesub = sub(1:2:sparsegrid.dim(1),1:2:sparsegrid.dim(2),1:2:sparsegrid.dim(3));
    sparseind = reshape(sparsesub,1,numel(sparsesub));
    
    sparsegrid.pos = sparsegrid.pos(sparseind,:);
    sparsegrid.inside = sparsegrid.inside(sparseind);
    sparsetemplate.pos = sparsetemplate.pos(sparseind,:);
    sparsetemplate.inside = sparsetemplate.inside(sparseind);
    
    % % get the frequency
    % if strcmpi(indat(p).name(19),'1')
    %     foi = str2double(indat(p).name(19:21));
    % else
    %     foi = str2double(indat(p).name(21:23));
    % end

    selmag  = strcmpi(meg.grad.chantype, 'megmag');

    cfg = [];
    cfg.channel = meg.label(selmag);
    cfg.bpfilter = 'yes'; % Filter on or off
    cfg.bpfreq = [80 200]; % SWR Band [foi-1 foi+1];
    cfg.hpfilttype = 'firws';
    
    dat4filt = ft_preprocessing(cfg,meg);

    cfg = [];
    cfg.channel = meg.label(selmag);
    
    dat_col = ft_preprocessing(cfg,meg);

    %% 2. Covariance
    cfg = [];
    cfg.covariance = 'yes';
    cfg.latency = latency;
    cfg.covariancewindow = cfg.latency;
    avgpost = ft_timelockanalysis(cfg,dat4filt);
    
    %% 3. Source Analysis to obtain spatial filter
    cfg=[];
    cfg.method = 'lcmv';
    cfg.sourcemodel = sparsegrid;%orig.grid;%template_fit_grid5;
    cfg.headmodel = orig.singleshell;%template_fit_singleshell;
    cfg.grad = avgpost.grad;
    cfg.lcmv.keepfilter = 'yes';
    cfg.lcmv.lambda = lambda;
    
    source = ft_sourceanalysis(cfg,avgpost);
    
    %% 4. Virtual Channel projection
    cfg = [];
    cfg.pos = sparsegrid.pos(sparsegrid.inside,:);

    sp = ft_virtualchannel(cfg,dat_col,source);
      
    %% 6. Save
    save([outpath,indat(p).name],'sp','sparsetemplate','-V7.3');
end