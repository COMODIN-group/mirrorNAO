clc;
clear;

participants = {'001' '002'};

% '001' '002' '003' '004' '005' '006' '007' '008' '009' '010' '011' '012' '013' '014' '015'

protocols = {'control' 'robot' 'video' 'vr'};

%'control' 'video' 'robot' 'vr'

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
bp_folder = '../Results/_ERD_cbase/';
true_folder = '../Results/_ERD_cbase_true/';

row_counter = 0;


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

                [rest_spectra,freqs] = spectopo(rest_EEG.data(j,:,:), 0, rest_EEG.srate, 'plot', 'off');

                for k = 1:5 % five trials for each subject

                    [spectra,freqs] = spectopo(EEG.data(j,:,k), 0, EEG.srate, 'plot', 'off');

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
averages_pos = zeros(24,12);
std_pos = zeros(24,12);
averages_norm = zeros(24,12);
positives = zeros(24,12);
pos_ratio = zeros(24,12);
row_counter = 1;

for i = 1:length(dataChs)
    ChName = dataChs{i};
    ChData = data.(ChName);
    
    WaveNames = fieldnames(ChData); 
    
    for j = 1:length(WaveNames)
        WName = WaveNames{j};
        matrix = ChData.(WName);
        pos_matrix = max(matrix,0);
        norm_matrix = max(log(pos_matrix),0);

        % Get number and ratio of ERD
        s = sign(matrix);
        positives(row_counter,:) = sum(s(:,2:13)==1);
        pos_ratio(row_counter,:) = (sum(s(:,2:13)==1)/65)*100;
        
        % Averages for tables
        averages(row_counter,:) = mean(matrix(:,2:13));
        averages_pos(row_counter,:) = mean(pos_matrix(:,2:13));
        std_pos(row_counter,:) = std(pos_matrix(:,2:13));
        averages_norm(row_counter,:) = mean(norm_matrix(:,2:13));
        row_counter = row_counter + 1;
        
        % Transform participants cell to fit the table
        extendedParticipants = repmat(participants, 5, 1);
        extendedParticipants = reshape(extendedParticipants,1,[]);
        extendedParticipants_t = extendedParticipants';

        % Convert the matrix to a table
        T_extended = array2table(matrix, 'VariableNames',{'Participants','Control_Right','Control_Left','Control_Both', 'Robot_Right','Robot_Left', 'Robot_Both','Video_Right','Video_Left', 'Video_Both' 'VR_Right', 'VR_Left', 'VR_Both'});
        T_extended.Participants = extendedParticipants_t;
        
        % Define filename: SubStructName_MatrixName.csv
        filename = sprintf('%s_%s_erd.csv', ChName, WName);
        fullPath = fullfile(bp_folder, filename);
        
        % Save table as CSV
        writetable(T_extended, fullPath);

        % Convert the matrix to a table
        T_extended_pos = array2table(pos_matrix, 'VariableNames',{'Participants','Control_Right','Control_Left','Control_Both', 'Robot_Right','Robot_Left', 'Robot_Both','Video_Right','Video_Left', 'Video_Both', 'VR_Right', 'VR_Left', 'VR_Both'});
        T_extended_pos.Participants = extendedParticipants_t;
        
        % Define filename: SubStructName_MatrixName.csv
        filename_pos = sprintf('%s_%s_erd_true.csv', ChName, WName);
        fullPath_pos = fullfile(bp_folder, filename_pos);
        true_fullPath_pos = fullfile(true_folder, filename_pos);
        
        % Save table as CSV
        writetable(T_extended_pos, fullPath_pos);
        writetable(T_extended_pos, true_fullPath_pos);

        % Convert the matrix to a table
        T_extended_norm = array2table(norm_matrix, 'VariableNames',{'Participants','Control_Right','Control_Left','Control_Both', 'Robot_Right','Robot_Left', 'Robot_Both','Video_Right','Video_Left', 'Video_Both', 'VR_Right', 'VR_Left', 'VR_Both'});
        T_extended_norm.Participants = extendedParticipants_t;
        
        % Define filename: SubStructName_MatrixName.csv
        filename_norm = sprintf('%s_%s_erd_norm.csv', ChName, WName);
        fullPath_norm = fullfile(bp_folder, filename_norm);
        
        % Save table as CSV
        writetable(T_extended_norm, fullPath_norm);
    end
end

T_averages = array2table(averages, 'VariableNames',{'Control_Right','Control_Left','Control_Both', 'Robot_Right','Robot_Left', 'Robot_Both','Video_Right','Video_Left', 'Video_Both', 'VR_Right', 'VR_Left', 'VR_Both'}, ...
    'RowNames', {'FC1_theta','FC1_alpha','FC1_beta','FCz_theta','FCz_alpha','FCz_beta','FC2_theta','FC2_alpha','FC2_beta','C3_theta','C3_alpha','C3_beta','C4_theta','C4_alpha','C4_beta', ...
    'CP1_theta','CP1_alpha','CP1_beta','CPz_theta','CPz_alpha','CPz_beta','CP2_theta','CP2_alpha','CP2_beta'});

filename = 'averages.xlsx'; % .xls
fullPath = fullfile(bp_folder, filename);

writetable(T_averages, fullPath);

T_averages = array2table(averages_pos, 'VariableNames',{'Control_Right','Control_Left','Control_Both', 'Robot_Right','Robot_Left', 'Robot_Both', 'Video_Right','Video_Left', 'Video_Both', 'VR_Right', 'VR_Left', 'VR_Both'}, ...
    'RowNames', {'FC1_theta','FC1_alpha','FC1_beta','FCz_theta','FCz_alpha','FCz_beta','FC2_theta','FC2_alpha','FC2_beta','C3_theta','C3_alpha','C3_beta','C4_theta','C4_alpha','C4_beta', ...
    'CP1_theta','CP1_alpha','CP1_beta','CPz_theta','CPz_alpha','CPz_beta','CP2_theta','CP2_alpha','CP2_beta'});

filename = 'averages_true.xlsx'; % .xls
fullPath = fullfile(bp_folder, filename);
true_fullPath = fullfile(true_folder, filename);

writetable(T_averages, fullPath);
writetable(T_averages, true_fullPath);

T_averages = array2table(std_pos, 'VariableNames',{'Control_Right','Control_Left','Control_Both', 'Robot_Right','Robot_Left', 'Robot_Both', 'Video_Right','Video_Left', 'Video_Both', 'VR_Right', 'VR_Left', 'VR_Both'}, ...
    'RowNames', {'FC1_theta','FC1_alpha','FC1_beta','FCz_theta','FCz_alpha','FCz_beta','FC2_theta','FC2_alpha','FC2_beta','C3_theta','C3_alpha','C3_beta','C4_theta','C4_alpha','C4_beta', ...
    'CP1_theta','CP1_alpha','CP1_beta','CPz_theta','CPz_alpha','CPz_beta','CP2_theta','CP2_alpha','CP2_beta'});

filename = 'standard_desviation.xlsx'; % .xls
fullPath = fullfile(bp_folder, filename);
true_fullPath = fullfile(true_folder, filename);

writetable(T_averages, fullPath);
writetable(T_averages, true_fullPath);

T_averages = array2table(averages_norm, 'VariableNames',{'Control_Right','Control_Left','Control_Both', 'Robot_Right','Robot_Left', 'Robot_Both', 'Video_Right','Video_Left', 'Video_Both','VR_Right', 'VR_Left', 'VR_Both'}, ...
    'RowNames', {'FC1_theta','FC1_alpha','FC1_beta','FCz_theta','FCz_alpha','FCz_beta','FC2_theta','FC2_alpha','FC2_beta','C3_theta','C3_alpha','C3_beta','C4_theta','C4_alpha','C4_beta', ...
    'CP1_theta','CP1_alpha','CP1_beta','CPz_theta','CPz_alpha','CPz_beta','CP2_theta','CP2_alpha','CP2_beta'});

filename = 'averages_norm.xlsx'; % .xls
fullPath = fullfile(bp_folder, filename);

writetable(T_averages, fullPath);

T_erdratio = array2table(pos_ratio, 'VariableNames',{'Control_Right','Control_Left','Control_Both', 'Robot_Right','Robot_Left', 'Robot_Both', 'Video_Right','Video_Left', 'Video_Both','VR_Right', 'VR_Left', 'VR_Both'}, ...
    'RowNames', {'FC1_theta','FC1_alpha','FC1_beta','FCz_theta','FCz_alpha','FCz_beta','FC2_theta','FC2_alpha','FC2_beta','C3_theta','C3_alpha','C3_beta','C4_theta','C4_alpha','C4_beta', ...
    'CP1_theta','CP1_alpha','CP1_beta','CPz_theta','CPz_alpha','CPz_beta','CP2_theta','CP2_alpha','CP2_beta'});

filename = '_erd_ratio.xlsx'; % .xls
fullPath = fullfile(bp_folder, filename);
true_fullPath = fullfile(true_folder, filename);

writetable(T_erdratio, fullPath);
writetable(T_averages, true_fullPath);