%% PROYECTO ALPHAMINI

%% File parameters

participants = {'001' '002' '003' '004' '005' '006' '007' '008' '009' '010' '012' '013' '014' '015'};

%'001' '002' '003' '004' '005' '006' '007' '008' '009' '010' '011' '012' '013' '014' '015'

protocols = {'robot' 'video' 'vr' 'control'};

% 'video' 'robot' 'vr' 'control'

results_folder = '../Results/';

for n = participants

    participant = char(n);
    part_folder = [results_folder participant];

    if strcmp(participant,'011')
        protocols = {'robot' 'video' 'control'};
    else
        protocols = {'robot' 'video' 'vr' 'control'};
    end
    

%% EEGLAB data options

    save_datasets  = 1;
    
    save_PDFs = 1;

    make_epochs = 0;

    make_study = 0;
    
    %% Loop for protocols
    
    for k = protocols
    
        protocol = char(k);
        dataset_name = [participant '_' protocol];
        subject_name = participant;

        fname = [participant '_' protocol '.csv'];
    
        labready_fname = [participant '_' protocol '_READY.set']; %Loaded data, events and channels
        filtered_fname = [participant '_' protocol '_filt.set'];
        processed_fname = [participant '_' protocol '_processed.set'];
        epoch_fname = [participant '_' protocol '_processed_epochs.set'];
        epochR_fname = [participant '_' protocol '_processed_epochs_right.set'];
        epochL_fname = [participant '_' protocol '_processed_epochs_left.set'];
        epochB_fname = [participant '_' protocol '_processed_epochs_both.set'];
        
        % Create fully-formed filename as a string
        filename = fullfile(part_folder, fname);
        
        % Check that file exists
        assert(exist(filename, 'file') == 2, '%s does not exist.', filename);
        
        % Read in the data, skipping the 5 first rows
        data = readmatrix(filename);
               
        %% Array processing
        
        % Separate EEG data and auxiliary data         
        eegdata = data(:,2:9);          % EEG data
        auxdata = data(:,10:18);   % Aux data
        eventdata = data(:,19);   % Event Data 
    
        % General variables
        time = (0:4:length(eegdata)*4-1)';  % Time vector
        N_ch = 8;                           % Number of channels
        
        % Band-pass Filtering Paramaters
        fsamp = 250;                    % Sampling frequency
        tsample = 1/fsamp;              % Period of samples
        f_low = 30;                 % Cut frequency for high-pass filter
        f_high = 1;                   % Cut frequency for low-pass filter
        
        %% EEGLAB 
    
        %% Load data, events and channel locations

        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        EEG = pop_importdata('dataformat','matlab','nbchan',0,'data',raw_fname,'setname',dataset_name,'srate',250,'subject',subject_name,'pnts',0,'xmin',0);
        EEG = pop_chanevent(EEG, 9,'edge','leading','edgelen',0);
        EEG = pop_selectevent( EEG, 'type',1,'renametype','right','deleteevents','off');
        EEG = pop_selectevent( EEG, 'type',2,'renametype','left','deleteevents','off');
        EEG = pop_selectevent( EEG, 'type',3,'renametype','both','deleteevents','off');
        EEG=pop_chanedit(EEG, 'load',{'./Standard-10-20-UHybridBlack.ced','filetype','autodetect'},'lookup','../python-nao/Results/standard_1005.elc');
        if (save_datasets)
            EEG = pop_saveset( EEG, 'filename',labready_fname,'filepath', part_folder);
        end
    
        %% Cleaning

        EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass',[0.5 1] ,'BurstCriterion',20,'WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
        EEG.setname= [dataset_name ' filtered ASR20'];
        EEG = pop_eegfiltnew(EEG, 'locutoff',3,'hicutoff',30,'plotfreqz',0);
        EEG.setname= [dataset_name ' 3-30'];
        EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',[1:8] ,'computepower',1,'linefreqs',50,'newversion',0,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',0,'sigtype','Channels','taperbandwidth',2,'tau',100,'verb',1,'winsize',4,'winstep',1);
        EEG.setname= [dataset_name ' filtered'];
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'rndreset','yes','interrupt','on');
        % pop_processMARA ( ALLEEG,EEG,CURRENTSET )
        EEG = pop_iclabel(EEG, 'default');
        %EEG = pop_reref( EEG, []);
        EEG.setname= [dataset_name ' filtered ASR20 ICA'];
        if (save_datasets)
            EEG = pop_saveset( EEG, 'filename',processed_fname,'filepath',part_folder);
        end
        
        if (make_epochs)

        %% Epochs
        EEG = pop_epoch( EEG, { 'right' 'left' 'both'  }, [-4  4], 'newname', [dataset_name ' ASR filtered ICA CAR epochs'], 'epochinfo', 'yes');
        EEG = pop_saveset( EEG, 'filename',epoch_fname,'filepath',part_folder);

        EEG = pop_epoch( EEG, {  'right' }, [-4  4], 'newname', [dataset_name ' ASR filtered ICA CAR epochs R'], 'epochinfo', 'yes');
        EEG = pop_saveset( EEG, 'filename',epochR_fname,'filepath',part_folder);
        
        EEG = pop_loadset('filename',epoch_fname,'filepath',part_folder);
        EEG = pop_epoch( EEG, { 'left' }, [-4  4], 'newname', [dataset_name ' ASR filtered ICA CAR epochs L'], 'epochinfo', 'yes');
        EEG = pop_saveset( EEG, 'filename',epochL_fname,'filepath',part_folder);

        EEG = pop_loadset('filename',epoch_fname,'filepath',part_folder);
        EEG = pop_epoch( EEG, {  'both'  }, [-4  4], 'newname', [dataset_name ' ASR filtered ICA CAR epochs B'], 'epochinfo', 'yes');
        EEG = pop_saveset( EEG, 'filename',epochB_fname,'filepath',part_folder);

        end
        
    end
        
        if (make_study)
    
        %% Study
        
        robot_fpath = [part_folder participant  '_robot_ASR_filt_ICA_CAR_epochs.set' ];
        video_fpath = [part_folder participant  '_video_ASR_filt_ICA_CAR_epochs.set' ];
        vr_fpath = [part_folder participant  '_vr_ASR_filt_ICA_CAR_epochs.set' ];
        control_fpath = [part_folder participant  '_control_ASR_filt_ICA_CAR_epochs.set' ];
    
        [STUDY ALLEEG] = std_editset( STUDY, [], 'name', [subject_name '_study'],'commands',{ ...
            {'index',1,'load', robot_fpath,'session',1,'condition','robot'}, ...
            {'index',2,'load',video_fpath,'session',2,'condition','video'}, ...
            {'index',3,'load',vr_fpath,'session',3,'condition','vr'}}, ...
            'updatedat','off','rmclust','on');
        [STUDY ALLEEG] = std_checkset(STUDY, ALLEEG);
        CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
        STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','STUDY.design 1','delfiles','off','defaultdesign','off','variable1','condition','values1',{'robot','video','vr'},'vartype1','categorical', ...
            'variable2','type','values2',{'both','left','right'},'vartype2','categorical','subjselect',{subject_name});
        [STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {},'savetrials','on','interp','on','recompute','on', ...
            'erp','on','erpparams',{'rmbase',[-4000 4000] }, ...
            'spec','on','specparams',{'specmode','fft','logtrials','off'}, ...
            'erpim','on','erpimparams',{'nlines',10,'smoothing',10}, ...
            'ersp','on','erspparams',{'cycles',[3 0.8] ,'nfreqs',100,'ntimesout',200,'baseline',[-2000 -500]});
        [STUDY EEG] = pop_savestudy( STUDY, EEG, 'filename',[participant '.study'],'filepath',part_folder);
        
        STUDY = pop_statparams(STUDY, 'groupstats','on','condstats','on','method','perm','mcorrect','fdr','alpha',0.5);
        %STUDY = std_erspplot(STUDY,ALLEEG,'channels',{'FC1','FCz','FC2','C3','C4','CP1','CPZ','CP2'}, 'design', 1);
        %STUDY = std_erspplot(STUDY,ALLEEG,'channels',{'C4'}, 'plotsubjects', 'on', 'design', 1 );
        %STUDY = pop_erspparams(STUDY, 'freqrange',[1 30] );
        %STUDY = std_erspplot(STUDY,ALLEEG,'channels',{'C4'}, 'design', 1);

        %STUDY = pop_specparams(STUDY, 'freqrange',[1 40] );
        %STUDY = std_specplot(STUDY,ALLEEG,'channels',{'FC1','FCz','FC2','C3','C4','CP1','CPZ','CP2'}, 'design', 1);
        %STUDY = pop_specparams(STUDY, 'averagechan','on');
        %STUDY = std_specplot(STUDY,ALLEEG,'channels',{'FC1','FCz','FC2','C3','C4','CP1','CPZ','CP2'}, 'design', 1);

        end

        eeglab redraw;
   
end
