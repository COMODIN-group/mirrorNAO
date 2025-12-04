clc;
clear;

participants = {'001' '002' '003' '004' '005' '006' '007' '009' '010' '012' '013' '014' '015'};

% '001' '002' '003' '004' '005' '006' '007' '008' '009' '010' '011' '012' '013' '014' '015'

protocols = {'control' 'robot' 'video' 'vr'};

%'control' 'video' 'robot' 'vr'

moves =  {'right' 'left' 'both'};

% 'R' 'L' 'B'

channels = {'FC1', 'FCz', 'FC2', 'C3', 'C4', 'CP1', 'CPz', 'CP2'};

nparticipants = length(participants) * 1;  % 1 porque usamos la media de los trials
nsettings = 13; % número de combinaciones de settings + movimientos + columna tiempo
npoints = 200; % número de muestras

data = struct;

data.FC1 = struct('theta', zeros(npoints,nsettings,nparticipants), 'alpha', zeros(npoints,nsettings,nparticipants), 'beta', zeros(npoints,nsettings,nparticipants));
data.FCz = struct('theta', zeros(npoints,nsettings,nparticipants), 'alpha', zeros(npoints,nsettings,nparticipants), 'beta', zeros(npoints,nsettings,nparticipants));
data.FC2 = struct('theta', zeros(npoints,nsettings,nparticipants), 'alpha', zeros(npoints,nsettings,nparticipants), 'beta', zeros(npoints,nsettings,nparticipants));
data.C3 = struct('theta', zeros(npoints,nsettings,nparticipants), 'alpha', zeros(npoints,nsettings,nparticipants), 'beta', zeros(npoints,nsettings,nparticipants));
data.C4 = struct('theta', zeros(npoints,nsettings,nparticipants), 'alpha', zeros(npoints,nsettings,nparticipants), 'beta', zeros(npoints,nsettings,nparticipants));
data.CP1 = struct('theta', zeros(npoints,nsettings,nparticipants), 'alpha', zeros(npoints,nsettings,nparticipants), 'beta', zeros(npoints,nsettings,nparticipants));
data.CPz = struct('theta', zeros(npoints,nsettings,nparticipants), 'alpha', zeros(npoints,nsettings,nparticipants), 'beta', zeros(npoints,nsettings,nparticipants));
data.CP2 = struct('theta', zeros(npoints,nsettings,nparticipants), 'alpha', zeros(npoints,nsettings,nparticipants), 'beta', zeros(npoints,nsettings,nparticipants));

results_folder = '../Results/';
bp_folder = '../Results/_ERD_cbase_plot/';

wave_cycles = 0;
part_counter = 1;

for n = 1:length(participants)
    
    participant = char(participants{n});

    part_folder = [results_folder participant '/'];

    col_counter = 2;

    for i = 1:length(protocols)

        protocol = char(protocols{i});

        rest_dataset_name = [participant '_' protocol '_clean_rest.set'];
        rest_EEG = pop_loadset('filename', rest_dataset_name, 'filepath', part_folder);

        for m = 1:length(moves)
        
            move = char(moves{m});

            dataset_name = [participant '_' protocol '_clean_epochs_' move '.set'];
            EEG = pop_loadset('filename', dataset_name, 'filepath', part_folder);

            nchannels = EEG.nbchan;

            for j = 1:nchannels

                % compute ersp

                [ersp, ~, ~, times, freqs] = newtimef( EEG.data(j,:,:), EEG.pnts,...
                [EEG.xmin EEG.xmax]*1000, EEG.srate, wave_cycles , 'elocs', EEG.chanlocs,...
                'chaninfo', EEG.chaninfo,'baseline',NaN, 'freqs', [1 40], 'plotersp',...
                'off', 'plotitc' , 'off', 'plotphase', 'off', 'padratio', 1);

                [ersp_rest, ~, ~, times_rest, freqs_rest] = newtimef( rest_EEG.data(j,:,:), rest_EEG.pnts,...
                [rest_EEG.xmin rest_EEG.xmax]*1000, rest_EEG.srate, wave_cycles , 'elocs', rest_EEG.chanlocs,...
                'chaninfo', rest_EEG.chaninfo,'baseline', NaN, 'freqs', [1 40], 'plotersp',...
                'off', 'plotitc' , 'off', 'plotphase', 'off', 'padratio', 1);

                % theta=4-8, alpha=8-13, beta=13-30
                thetaFreq = find(freqs>=4 & freqs<=8);
                alphaFreq = find(freqs>=8 & freqs<=13);
                betaFreq  = find(freqs>=13 & freqs<=30);
         
                % ersp by band
                rest_theta_timef = mean(10.^(ersp_rest(thetaFreq,:)/10)).';
                rest_alpha_timef = mean(10.^(ersp_rest(alphaFreq,:)/10)).';
                rest_beta_timef = mean(10.^(ersp_rest(betaFreq,:)/10)).';

                theta_timef = mean(10.^(ersp(thetaFreq,:)/10)).';
                alpha_timef = mean(10.^(ersp(alphaFreq,:)/10)).';
                beta_timef = mean(10.^(ersp(betaFreq,:)/10)).';

                data.(channels{j}).theta(:,col_counter,part_counter) = ((rest_theta_timef - theta_timef)./rest_theta_timef)*100;
                data.(channels{j}).alpha(:,col_counter,part_counter) = ((rest_alpha_timef - alpha_timef)./rest_alpha_timef)*100;
                data.(channels{j}).beta(:,col_counter,part_counter) = ((rest_beta_timef - beta_timef)./rest_beta_timef)*100;

                data.(channels{j}).theta(:,1,part_counter) = times.';
                data.(channels{j}).alpha(:,1,part_counter) = times.';
                data.(channels{j}).beta(:,1,part_counter) = times.';

            end
            col_counter = col_counter + 1;
        end
    end

    part_counter = part_counter + 1;
end



dataChs = fieldnames(data);

for i = 1:length(dataChs)
    ChName = dataChs{i};
    ChData = data.(ChName);
    
    WaveNames = fieldnames(ChData); 
    
    for j = 1:length(WaveNames)
        WName = WaveNames{j};
        matrix = ChData.(WName);
        pos_matrix = max(matrix,0);
        
        % Averages for tables
        averages = mean(pos_matrix,3);
        desviation = std(pos_matrix,0,3);
        desviation(:,1) = averages(:,1);

        % Convert the matrix to a table
        table_avg = array2table(averages, 'VariableNames',{'Time','Control_Right','Control_Left','Control_Both', 'Robot_Right','Robot_Left', 'Robot_Both','Video_Right','Video_Left', 'Video_Both' 'VR_Right', 'VR_Left', 'VR_Both'});
        table_std = array2table(desviation, 'VariableNames',{'Time','Control_Right','Control_Left','Control_Both', 'Robot_Right','Robot_Left', 'Robot_Both','Video_Right','Video_Left', 'Video_Both' 'VR_Right', 'VR_Left', 'VR_Both'});
        
        % Define filename: SubStructName_MatrixName.csv
        filename_avg = sprintf('%s_%s_avg.csv', ChName, WName);
        fullPath_avg = fullfile(bp_folder, filename_avg);

        filename_std = sprintf('%s_%s_std.csv', ChName, WName);
        fullPath_std = fullfile(bp_folder, filename_std);
        
        % Save table as CSV
        writetable(table_avg, fullPath_avg);
        writetable(table_std, fullPath_std);

    end
end
