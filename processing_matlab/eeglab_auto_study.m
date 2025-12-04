%% PROYECTO ALPHAMINI

%% File parameters

participants = {'001' '002'};

%'001' '002' '003' '004' '005' '006' '007' '008' '009' '010' '011' '012' '013' '014' '015'

protocols = {'robot' 'video' 'vr' 'control'};

%'video' 'robot' 'vr' 'control'

results_folder = '../Results/';

commands = {};

for n = 1:length(participants)

    participant = char(participants{n});

    part_folder = [results_folder participant '\\'];
    output_folder = [results_folder participant '\\figures\\'];
    
    %% Prepare commands for STUDY
    
    control_fpath = [part_folder participant  '_control_clean_epochs.set' ];
    robot_fpath = [part_folder participant  '_robot_clean_epochs.set' ];
    video_fpath = [part_folder participant  '_video_clean_epochs.set' ];
    vr_fpath = [part_folder participant  '_vr_clean_epochs.set' ];

    % robot_fpath = [part_folder participant  '_robot_clean.set' ];
    % video_fpath = [part_folder participant  '_video_clean.set' ];
    % vr_fpath = [part_folder participant  '_vr_clean.set' ];
    % control_fpath = [part_folder participant  '_control_clean.set' ];

    commands = { commands{:} ...
        {'index',4*n-3,'load',control_fpath,'session', 1,'condition','control'} ...
        {'index',4*n-2,'load', robot_fpath,'session', 2, 'condition','robot'} ...
        {'index',4*n-1,'load',video_fpath,'session', 3,'condition','video'} ...
        {'index',4*n,'load',vr_fpath,'session', 4,'condition','vr'} };
 
end

[STUDY ALLEEG] = std_editset( STUDY, [], 'name', ['alphamini_study'],'commands',commands ,'updatedat','off','rmclust','on');
[STUDY ALLEEG] = std_checkset(STUDY, ALLEEG);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','STUDY.design 1','delfiles','off','defaultdesign','off','variable1','condition','values1',{'control','robot','video','vr'},'vartype1','categorical', ...
     'variable2','type','values2',{'both','left','right'},'vartype2','categorical'); 
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {},'savetrials','on','interp','on','recompute','on', ...
    'erp','on','erpparams',{'rmbase',[-4000 4000] }, ...
    'spec','on','specparams',{'specmode','fft','logtrials','off'}, ...
    'erpim','on','erpimparams',{'nlines',10,'smoothing',10}, ...
    'ersp','on','erspparams',{'cycles',[3 0.8] ,'nfreqs',100,'ntimesout',200,'baseline',[-2000 -500]});
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'filename',['alphamini_full.study'],'filepath',results_folder);

%STUDY = pop_statparams(STUDY, 'groupstats','on','condstats','on','method','perm','mcorrect','fdr','alpha',0.5);
%STUDY = std_erspplot(STUDY,ALLEEG,'channels',{'FC1','FCz','FC2','C3','C4','CP1','CPZ','CP2'}, 'design', 1);
%STUDY = std_erspplot(STUDY,ALLEEG,'channels',{'C4'}, 'plotsubjects', 'on', 'design', 1 );
%STUDY = pop_erspparams(STUDY, 'freqrange',[1 30] );
%STUDY = std_erspplot(STUDY,ALLEEG,'channels',{'C4'}, 'design', 1);

%STUDY = pop_specparams(STUDY, 'freqrange',[1 40] );
%STUDY = std_specplot(STUDY,ALLEEG,'channels',{'FC1','FCz','FC2','C3','C4','CP1','CPZ','CP2'}, 'design', 1);
%STUDY = pop_specparams(STUDY, 'averagechan','on');
%STUDY = std_specplot(STUDY,ALLEEG,'channels',{'FC1','FCz','FC2','C3','C4','CP1','CPZ','CP2'}, 'design', 1);

eeglab redraw;
