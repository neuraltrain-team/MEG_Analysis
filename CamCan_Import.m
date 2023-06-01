%% MEG Processing Pipeline
% 1. Preprocess Data in MNE Python using BIDS automatic processing pipeline
% * Identify bad channels
% * ICA
% * Epoch
% * Selection of conditions
% 2. Read in preprocessed MEG data
% * Compute the covariance across sensors
% * Pre-Whiten sensor activity to get rid of difference between
% magnetometers and gradiometers

% Focus on Magnetometers: https://mailman.science.ru.nl/pipermail/fieldtrip/2019-November/039675.html
%% 0. set basics
clc
clear
close all
ft_defaults

inpath = 'C:\Users\JulianKeil\MEGData CamCan\MEG\CleanData\';
indat = dir([inpath,'*_proc-clean_rej_epo.fif']);
outpath = 'C:\Users\JulianKeil\MEGData CamCan\MEG\FTData\';

%% Loop Participants
for p = 1:length(indat)
    %% 1. Read in Data
    
    cfg = [];
    cfg.dataset = [inpath,indat(p).name];
    
    epo = ft_preprocessing(cfg);
    
    %% 2. Read in Events
    
    % ev = ft_read_event([inpath,indat(p).name]);
    % for i = 1:length(ev)
    %     epo.trialinfo(i) = numel(ev(p).value); 
    % end
    % 
    % epo.trialinfo = epo.trialinfo';
    
    trigchan = find(strcmp(epo.label,'STI101'));
    zeropos = nearest(epo.time{1},0);
    
    for t = 1:length(epo.trial)
        epo.trialinfo(t) = epo.trial{t}(trigchan,zeropos);
    end
    
    epo.trialinfo = epo.trialinfo';

        % 3.1. IF needed:Change channel names to exclude spaces if needed
        if ~strcmpi(epo.label{1}(4),'0')
            % Labels
            for c = 1:length(epo.label)
                tmp = strsplit(epo.label{c});
                epo.label{c} = [tmp{1}, tmp{2}];
            end
            % Gradiometer Labels
            for c = 1:length(epo.grad.label)
                tmp = strsplit(epo.grad.label{c});
                epo.grad.label{c} = [tmp{1}, tmp{2}];
            end
            % Electrode Labels
            for c = 1:length(epo.elec.label)
                tmp = strsplit(epo.elec.label{c});
                epo.elec.label{c} = [tmp{1}, tmp{2}];
            end
        end

    %% 4. Select only the MEG data
    cfg         = [];
    cfg.channel = {'MEG'};
    meg        = ft_selectdata(cfg, epo);
    
    %% 5. Pre-Whitening 
    % 5.1 Extract the Baseline for pre-whitening
    cfg         = [];
    cfg.latency = [-2 -.5];
    baseline    = ft_selectdata(cfg, meg);
    
    % 5.2 Compute the Covariance of the Baseline and visualize
    cfg            = [];
    cfg.covariance = 'yes';
    baseline_avg   = ft_timelockanalysis(cfg, baseline);
    
    selmag  = strcmpi(baseline_avg.grad.chantype, 'megmag');
    selgrad = strcmpi(baseline_avg.grad.chantype, 'megplanar');
    % 
    % C = baseline_avg.cov([find(selmag);find(selgrad)],[find(selmag);find(selgrad)]);
    % figure;imagesc(C);hold on;plot(102.5.*[1 1],[0 306],'w','linewidth',2);plot([0 306],102.5.*[1 1],'w','linewidth',2);
    % 
    % %% Single Value Decomposition to visualize difference in signal strength
    % [u,s,v] = svd(baseline_avg.cov);
    % figure;plot(log10(diag(s)),'o');
    
    % 5.3. Find the "cliff" in the SVD-Spectrum
    % the following lines detect the location of the first large 'cliff' in the singular value spectrum of the grads and mags
        % 5.3.1 Magnetometers
        s_mag = svd(baseline_avg.cov(selmag,  selmag)); % SVD
        d_mag = -diff(log10(diag(s_mag))); % Compute first derivative
        d_mag = d_mag./std(d_mag); % Normalize
        kappa_mag = find(d_mag>4,1,'first'); % Find Cliff

        % 5.3.2 Gradiometers
        s_grad = svd(baseline_avg.cov(selgrad, selgrad));
        d_grad = -diff(log10(diag(s_grad))); 
        d_grad = d_grad./std(d_grad);
        kappa_grad = find(d_grad>4,1,'first');
    
    % 5.4. Prewhiten
    cfg            = [];
    cfg.channel    = 'meg';
    cfg.kappa      = min(kappa_mag,kappa_grad);
    dataw_meg      = ft_denoise_prewhiten(cfg, meg, baseline_avg);
    
    %% 6. Save Data
    save([outpath,indat(p).name(1:end-4)],'dataw_meg','-V7.3');
end