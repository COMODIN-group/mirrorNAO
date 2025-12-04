clc;
clear;

participants = {'001' '002' '003' '004' '005' '006' '007' '009' '010' '012' '013' '014' '015'};

% '001' '002' '003' '004' '005' '006' '007' '008' '009' '010' '011' '012' '013' '014' '015'

protocols = {'control' 'video' 'robot' 'vr'};

%'video' 'robot' 'vr' 'control'

moves =  {'right' 'left' 'both'};

% 'R' 'L' 'B'

channels = {'FC1', 'FCz', 'FC2', 'C3', 'C4', 'CP1', 'CPz', 'CP2'};

nrows = length(participants) * 5;

data = struct;

data.FC1 = struct('theta', zeros(nrows,13), 'alpha', zeros(nrows,13), 'beta', zeros(nrows,13));
data.FCz = struct('theta', zeros(nrows,13), 'alpha', zeros(nrows,13), 'beta', zeros(nrows,13));
data.FC2 = struct('theta', zeros(nrows,13), 'alpha', zeros(nrows,13), 'beta', zeros(nrows,13));
data.C3 = struct('theta', zeros(nrows,13), 'alpha', zeros(nrows,13), 'beta', zeros(nrows,13));
data.C4 = struct('theta', zeros(nrows,13), 'alpha', zeros(nrows,13), 'beta', zeros(nrows,13));
data.CP1 = struct('theta', zeros(nrows,13), 'alpha', zeros(nrows,13), 'beta', zeros(nrows,13));
data.CPz = struct('theta', zeros(nrows,13), 'alpha', zeros(nrows,13), 'beta', zeros(nrows,13));
data.CP2 = struct('theta', zeros(nrows,13), 'alpha', zeros(nrows,13), 'beta', zeros(nrows,13));

results_folder = '../Results/';
bp_folder = '../Results/';

row_counter = 0;

for n = 1:length(participants)

    participant = char(participants{n});

    part_folder = [results_folder participant '\\'];

    col_counter = 2;
        
    for i = 1:length(protocols)

        protocol = char(protocols{i});

        for m = 1:length(moves)
        
            move = char(moves{m});

            dataset_name = [participant '_' protocol '_clean_epochs_' move '.set'];

            rest_dataset_name = [participant '_' protocol '_clean_epochs_' move '_rest.set'];

            EEG = pop_loadset('filename', dataset_name, 'filepath', part_folder);

            rest_EEG = pop_loadset('filename', rest_dataset_name, 'filepath', part_folder);

            nchannels = EEG.nbchan;

            for j = 1:nchannels

                for k = 1:5 % five trials for each subject

                    [spectra,freqs] = spectopo(EEG.data(j,:,k), 0, EEG.srate, 'plot', 'off');
                    [rest_spectra,freqs] = spectopo(rest_EEG.data(j,:,k), 0, EEG.srate, 'plot', 'off');

                    % theta=4-8, alpha=8-13, beta=13-30
                    thetaFreq = find(freqs>=4 & freqs<=8);
                    alphaFreq = find(freqs>=8 & freqs<=13);
                    betaFreq  = find(freqs>=13 & freqs<=30);

                    % compute single spectral power
                    data.(channels{j}).theta(row_counter+k,col_counter) = ((mean(10.^(rest_spectra(thetaFreq)/10)) - mean(10.^(spectra(thetaFreq)/10)))/mean(10.^(rest_spectra(thetaFreq)/10)))*100;
                    data.(channels{j}).alpha(row_counter+k,col_counter) = ((mean(10.^(rest_spectra(alphaFreq)/10)) - mean(10.^(spectra(alphaFreq)/10)))/mean(10.^(rest_spectra(alphaFreq)/10)))*100;
                    data.(channels{j}).beta(row_counter+k,col_counter) = ((mean(10.^(rest_spectra(betaFreq)/10)) - mean(10.^(spectra(betaFreq)/10)))/mean(10.^(rest_spectra(betaFreq)/10)))*100;
                    
                end
            end

            col_counter = col_counter + 1;
       end
    end

    row_counter = row_counter + 5;
end


dataChs = fieldnames(data);
averages = zeros(24,12);
row_counter = 1;

for i = 1:length(dataChs)
    ChName = dataChs{i};
    Chdata = data.(ChName);

    WaveNames = fieldnames(Chdata); 
    
    for j = 1:length(WaveNames)
        WName = WaveNames{j};
        matrix = Chdata.(WName);

        averages(row_counter,:) = mean(matrix(:,2:13));
        row_counter = row_counter + 1;

        % Transform participants cell to fit the table
        extendedParticipants = repmat(participants, 5, 1);
        extendedParticipants = reshape(extendedParticipants,1,[]);
        extendedParticipants_t = extendedParticipants';

        % Convert the matrix to a table
        T_extended = array2table(matrix, 'VariableNames',{'Participants','Control_Right','Control_Left','Control_Both','Video_Right','Video_Left', 'Video_Both', 'Robot_Right','Robot_Left', 'Robot_Both', 'VR_Right', 'VR_Left', 'VR_Both'});
        T_extended.Participants = extendedParticipants_t;

        % Define filename: SubStructName_MatrixName.csv
        filename = sprintf('%s_%s_erd.csv', ChName, WName);
        fullPath = fullfile(bp_folder, filename);

        % Save table as CSV
        writetable(T_extended, fullPath);
    end
end

T_averages = array2table(averages, 'VariableNames',{'Control_Right','Control_Left','Control_Both','Video_Right','Video_Left', 'Video_Both', 'Robot_Right','Robot_Left', 'Robot_Both', 'VR_Right', 'VR_Left', 'VR_Both'}, ...
    'RowNames', {'FC1_theta','FC1_alpha','FC1_beta','FCz_theta','FCz_alpha','FCz_beta','FC2_theta','FC2_alpha','FC2_beta','C3_theta','C3_alpha','C3_beta','C4_theta','C4_alpha','C4_beta', ...
    'CP1_theta','CP1_alpha','CP1_beta','CPz_theta','CPz_alpha','CPz_beta','CP2_theta','CP2_alpha','CP2_beta'});

filename = 'averages.xlsx'; % .xls
fullPath = fullfile(bp_folder, filename);

writetable(T_averages, fullPath);
