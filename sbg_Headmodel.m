%% Example to make MEG Headmodel
%
% 1. Read in the Template Grid
% 2. Read in the individual MRI and associated files
% 3. Segment MRI
% 4. Prepare Singleshell Head Model
% 3. Morph the tenplate grid to the head model

%% 0. Set basics 
clear
close all
clc
ft_defaults

% 0.1 Set Paths
mripath = 'C:\Users\JulianKeil\MEGSalzburg\ExpData3\MRI\';
hspath = 'C:\Users\JulianKeil\MEGSalzburg\ExpData3\CleanData\';
gradpath = 'C:\Users\JulianKeil\MEGSalzburg\ExpData3\FTData\';
outpath = 'C:\Users\JulianKeil\MEGSalzburg\ExpData3\Headmodel\OnMRI\';

procdat = dir([gradpath, '*BW180_proc-clean_rej_epo.mat']);

%% 1. Read in template source grid
load('C:\Users\JulianKeil\Github\fieldtrip\template\sourcemodel\standard_sourcemodel3d5mm.mat');
template_grid = sourcemodel;
template_grid = ft_convert_units(template_grid, 'mm');
clear sourcemodel

%% Loop Participants
for p = 1%:length(procdat)
    %% 2. Read in individual mri data   
        % 2.1. Read in headshape
        rawdat = dir([hspath,'*BW180_proc-clean_rej_epo.fif']);
        hs = ft_read_headshape([hspath,rawdat(p).name]);
        
            % 2.1.1 Change cm to mm
            hs = ft_convert_units(hs,'mm');
        
        % 2.2 Read in header
        load([gradpath procdat(p).name],'meg');
        grad = meg.grad;
        grad = ft_convert_units(grad, 'mm');

        % 2.1 Read MRI
        mrinames = dir([mripath, '*.nii']);
        if ~isempty(mrinames)
            if any(strcmpi(mrinames(:).name(1:5),procdat(p).name(1:5)))     
                %mridat = dir([mripath,rawnames(p).name,'\anat\',rawnames(p).name,'_T1w.nii\','*T1.nii']);
                %mri = ft_read_mri([mripath,rawnames(p).name,'\anat\',rawnames(p).name,'_T1w.nii\', mridat.name]);
                mri = ft_read_mri([mripath, procdat(p).name(1:5),'.nii']);
                mri.coordsys = 'mni';
            else % Fake the MRI
                mri = mrifaker([hspath,rawdat(p).name], 'fif');
                mri.unit = 'mm';
                mri.coordsys = 'mni';
            end
        else % Fake the MRI
            mri = mrifaker([hspath,rawdat(p).name], 'fif');
            mri.unit = 'mm';
            mri.coordsys = 'mni';
        end
    %% 3. Realign MRI and MEG
    cfg = [];
    cfg.method = 'headshape';
    cfg.headshape.headshape = hs;
    cfg.headshape.icp = 'yes';

    mris = ft_volumerealign(cfg,mri);

    %% 3. Segment MRI
    cfg = [];
    cfg.name = 'segment';
    mri_s = ft_volumesegment(cfg, mris);
    
        % 3.1 check segmented volume against mri
        mri_s.brainmask = mri_s.gray+mri_s.white+mri_s.csf;
        
        cfg = [];
        cfg.interactive = 'yes';
        cfg.funparameter = 'brainmask';
 
        %ft_sourceplot(cfg, mri_s);

    %% 4. Prepare Head Model
    close all

    cfg = [];
    cfg.grad = grad; % Gradiometer definition from MEG data
    cfg.method = 'singleshell';
    cfg.tissue = 'brain'; % will be constructed on the fly from white+grey+csf
    singleshell = ft_prepare_headmodel(cfg, mri_s);
    singleshell = ft_convert_units(singleshell, 'mm');
    
    plot3(grad.chanpos(:,1),grad.chanpos(:,2),grad.chanpos(:,3),'*');
    ft_plot_headmodel(singleshell, 'facecolor', 'cortex');

    %% 5. Morph the template grid to the individual head model
    % Attention! Replace grid.pos with template_grid.pos when doing group analyses
    close all

    cfg = [];
    cfg.method = 'basedonmni';
    cfg.template = template_grid;
    cfg.nonlinear = 'yes';
    cfg.mri = mris; % Watch out! Use the realiged & resliced MRI!
    cfg.headmodel = singleshell;
    cfg.unit ='mm';

    grid = ft_prepare_sourcemodel(cfg); 
    
    % make a figure of the single subject headmodel, and grid positions
    plot3(grad.chanpos(:,1),grad.chanpos(:,2),grad.chanpos(:,3),'*');
    ft_plot_headmodel(singleshell, 'facecolor', 'none');
    ft_plot_mesh(grid.pos(grid.inside,:));

%     %% 6. Compute Forward Solution Leadfield
%     cfg = [];
%     cfg.grad = grad;
%     cfg.sourcemodel = grid;
%     cfg.headmodel = singleshell;
%     cfg.reducerank = 2;
%     
%     lf = ft_prepare_leadfield(cfg);

    %% 7. Save
    save([outpath,procdat(p).name(1:16)],'grad','grid','template_grid','singleshell','-V7.3');

end