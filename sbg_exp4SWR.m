%% Export MEG Data projected to the Hippocampus for SWR detection
%% 0. set basics
clc
clear
close all
ft_defaults

% inpath{1} = 'C:\Users\JulianKeil\MEGSalzburg\ExpData\SourceData\';
% outpath{1} = 'C:\Users\JulianKeil\MEGSalzburg\ExpData\SWR4Exp\';
% inpath{2} = 'C:\Users\JulianKeil\MEGSalzburg\ExpData2\SourceData\';
% outpath{2} = 'C:\Users\JulianKeil\MEGSalzburg\ExpData2\SWR4Exp\';

inpath{1} = 'D:\MEG experiments\MEGSalzburg\WithBaseline\SourceData\';
outpath{1} = 'D:\MEG experiments\MEGSalzburg\WithBaseline\SWR4Exp\';
%% 1. Select Hippocampus Channels
headpath = 'D:\MEG experiments\MEGSalzburg\WithBaseline\SourceData\';
load([headpath, 'sub-19600622zyny_ses-01_task-BW120_proc-clean_rej_epo.mat'],'sparsetemplate');
template_grid = sparsetemplate;
standardmri = ft_read_mri('single_subj_T1.nii');
standardmri.coordsys = 'mni';
standardvol = ft_read_headmodel('standard_singleshell.mat');
standardvol = ft_convert_units(standardvol, 'mm');

    % 1.1 Make sure that the leadfield is in the same space as the template
    template_grid.outside = find(template_grid.inside == 0);
    template_grid.inside = find(template_grid.inside == 1);

    % 1.2 Select the ROIs
    cfg=[];
    cfg.mri = standardmri;
    cfg.vol = standardvol;
    cfg.standardvol = standardvol;
    cfg.lf = template_grid;
    cfg.atlas = 'C:\Users\JulianKeil\Github\fieldtrip\template\atlas\aal\ROI_MNI_V4.nii';
    cfg.plot = 'no';

    cfg.roi = {'Hippocampus_R'};
    cfg.hemisphere = 'right';
    lf_Hir = vt_make_roifield(cfg);

    cfg.roi = {'Hippocampus_L'};
    cfg.hemisphere = 'left';
    lf_Hil = vt_make_roifield(cfg);

        % 5.2.1 Update the Labels   
        % change inside labels (refer to all lf points) to str for label names
        for i = 1:length(lf_Hir.inside)
            lf_Hir.insidelabel{i} = num2str(lf_Hir.inside(i));
        end

        for i = 1:length(lf_Hil.inside)
            lf_Hil.insidelabel{i} = num2str(lf_Hil.inside(i));
        end
        

%% Loop Experiments
for i = 1:length(inpath) 
    indat = dir([inpath{i},'*_proc-clean_rej_epo.mat']);

    %% Loop Participants
    for p = 1:length(indat)
        %% 2. Load Data
        load([inpath{i}, indat(p).name],'sp');
    
        %% 3. Select Channels
        % Change labels
        for l = 1:length(template_grid.inside)
            sp.label{l} = num2str(template_grid.inside(l));
        end
        sp = rmfield(sp,{'brainordinate','grad'});
        
        % Select Left Hippocampus
        cfg = [];
        cfg.channel = lf_Hil.insidelabel;

        HippLeft = ft_selectdata(cfg,sp);

        % Select Right Hippocampus
        cfg = [];
        cfg.channel = lf_Hir.insidelabel;

        HippRight = ft_selectdata(cfg,sp);

        %% 4. Recode into trial by chan by time matrix
        time = HippLeft.time{1};
        Hipp_l = [];
        Hipp_r = [];
        for t = 1:length(HippLeft.trial)
            Hipp_l(t,:,:) = HippLeft.trial{t};
            Hipp_r(t,:,:) = HippRight.trial{t};
        end
        
        %% Save Data
        save([outpath{i},'sub_',indat(p).name(5:16),'_',indat(p).name(30:34),'_left.mat'],'Hipp_l','time','-V7.3');
        save([outpath{i},'sub_',indat(p).name(5:16),'_',indat(p).name(30:34),'_right.mat'],'Hipp_r','time','-V7.3');

    end
end
