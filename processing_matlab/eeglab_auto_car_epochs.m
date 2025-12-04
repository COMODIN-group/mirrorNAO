%% PROYECTO ALPHAMINI

%% File parameters

participants = {'001' '002' '003' '004' '005' '006' '007' '009' '010' '012' '013' '014' '015'};

%'001' '002' '003' '004' '005' '006' '007' '008' '009' '010' '011' '012' '013' '014' '015'

protocols = {'video' 'robot' 'vr' 'control'};

% 'video' 'robot' 'vr' 'control'

results_folder = '../Results/';

upper_epoch = 3.75;
lower_epoch = 0.25;

rest_min = 5;
rest_max = 9.25;

for n = participants

    participant = char(n);

    part_folder = [results_folder participant '/'];

    %% Loop for protocols
    
    for k = protocols
    
        protocol = char(k);

        dataset_name = [participant '_' protocol];
        subject_name = participant;

        clean_fname = [participant '_' protocol '_clean.set'];

        car_fname = [participant '_' protocol '_clean_CAR.set'];

        rest_name = [participant '_' protocol '_clean_rest.set'];

        epoch_fname = [participant '_' protocol '_clean_epochs.set'];
        epochR_fname = [participant '_' protocol '_clean_epochs_right.set'];
        epochL_fname = [participant '_' protocol '_clean_epochs_left.set'];
        epochB_fname = [participant '_' protocol '_clean_epochs_both.set'];

        epochR_fname_rest = [participant '_' protocol '_clean_epochs_right_rest.set'];
        epochL_fname_rest = [participant '_' protocol '_clean_epochs_left_rest.set'];
        epochB_fname_rest = [participant '_' protocol '_clean_epochs_both_rest.set'];

        %% Epochs
        EEG = pop_loadset('filename',clean_fname,'filepath',part_folder);
        EEG = pop_reref( EEG, []);
        EEG = pop_saveset( EEG, 'filename',car_fname,'filepath',part_folder);

        EEG_rest = pop_select( EEG, 'time', [5 9.25]);
        EEG_rest = pop_saveset( EEG_rest, 'filename',rest_name,'filepath',part_folder);

        EEG = pop_epoch( EEG,  {  }, [-4         4], 'newname', [dataset_name ' epochs'], 'epochinfo', 'yes');
        EEG = pop_saveset( EEG, 'filename',epoch_fname,'filepath',part_folder);

        % EEG = pop_select( EEG, 'time',[-2 -1] ); Para los nuevos segmentos

        EEG_right = pop_selectevent( EEG, 'type',{'right'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        EEG_right_rest = pop_select( EEG_right, 'time',[-upper_epoch lower_epoch] );
        EEG_right_rest = pop_saveset( EEG_right_rest, 'filename', epochR_fname_rest,'filepath', part_folder);
        EEG_right = pop_select( EEG_right, 'time',[-lower_epoch upper_epoch] );
        EEG_right = pop_saveset( EEG_right, 'filename', epochR_fname,'filepath', part_folder);
        
        EEG_left = pop_selectevent( EEG, 'type',{'left'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        EEG_left_rest = pop_select( EEG_left, 'time',[upper_epoch lower_epoch] );
        EEG_left_rest = pop_saveset( EEG_left_rest, 'filename', epochL_fname_rest,'filepath', part_folder);
        EEG_left = pop_select( EEG_left, 'time',[-lower_epoch upper_epoch] );
        EEG_left = pop_saveset( EEG_left, 'filename', epochB_fname,'filepath', part_folder);
        
        EEG_both = pop_selectevent( EEG, 'type',{'both'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        EEG_both_rest = pop_select( EEG_both, 'time',[-upper_epoch lower_epoch] );
        EEG_both_rest = pop_saveset( EEG_both_rest, 'filename', epochB_fname_rest,'filepath', part_folder);
        EEG_both = pop_select( EEG_both, 'time',[-lower_epoch upper_epoch] );
        EEG_both = pop_saveset( EEG_both, 'filename', epochB_fname,'filepath', part_folder);

    end
end