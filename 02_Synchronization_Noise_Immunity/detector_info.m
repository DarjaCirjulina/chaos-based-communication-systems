%% Clear variables
close all, clc
format longE, format compact;
%=============================%
%% Read simulation results
delimiterIn = '\t'; % data separation
headerlinesIn=1; % number of header lines from the top in the .txt file

% iteration = 10;
beta_mean_1 =zeros(1,iteration);
beta_mean_2 =zeros(1,iteration);
beta_mean_X =zeros(1,iteration);


for m = 1:iteration % read data for every noise level
    
%     m % Show iterration step
    
    saved_signals = importdata([QCSK_path '\RX\V_RX',num2str(m),'.txt'],delimiterIn,headerlinesIn); % read data
    saved_info_signal = importdata(['Info_decode',num2str(m),'.txt'],delimiterIn,headerlinesIn); % read data
    
    time = saved_signals.data(:, 1)';
    signal_with_noise_1 = saved_info_signal.data(:, 2)'; % From QAM code
    signal_with_noise_2 = saved_info_signal.data(:, 3)'; % From QAM code
    slave_signal_1 = saved_signals.data(:, 2)'; % From RX
    slave_signal_2 = saved_signals.data(:, 3)'; % From RX
    %=====================================================================%
    % t_n correction
    [time, a_n] = unique(time);
    slave_signal_1 = slave_signal_1(a_n);
    slave_signal_2 = slave_signal_2(a_n);
    %=====================================================================%
    % Data interpolation 
    tau = Ts;
    t = 0:tau:time(end);
    slave_signal_1 = interp1(time, slave_signal_1(1:length(time)), t);
    slave_signal_2 = interp1(time, slave_signal_2(1:length(time)), t);
    
    signal_with_noise_1 = [0 signal_with_noise_1(1:1:end)];
    signal_with_noise_2 = [0 signal_with_noise_2(1:1:end)];
    %=====================================================================%
    % Start from t_delay
    satrt = uint64(t_delay/tau);
    t = t(satrt+1:1:length(t));
    signal_with_noise_1 =  signal_with_noise_1(satrt+1:1:length(signal_with_noise_1));
    signal_with_noise_2 =  signal_with_noise_2(satrt+1:1:length(signal_with_noise_2));
    slave_signal_1 = slave_signal_1(satrt+1:1:length(slave_signal_1));
    slave_signal_2 = slave_signal_2(satrt+1:1:length(slave_signal_2));
    
%     figure(), grid on, grid minor
%     plot(t, message_signal, 'b.-', t, decode_signal_1, 'r.-', t, decode_signal_0, 'g.-', t_info, 4.*info, 'k')
%     return
    %=====================================================================%
    %% Create jumping window
    n_window = t_window/tau; % window length in samples
    %=====================================================================%
    %% Calculate time needed to reach certain correlation coef.
    % For 1 and 0
    % Predefine vectors for correlation coefficient and time
    a = length(t)/n_window;
    beta_1 = zeros(1,uint64(a));
    beta_2 = zeros(1,uint64(a));
    beta_X = zeros(1,uint64(a));
    
    % Calculte correlation coefficient using sliding window across all synchronizatio time interval
    j_win = uint64(0:n_window:(length(t) - n_window));
    for n = 1:1:length(j_win)
        
        x_1 = signal_with_noise_1((j_win(n) + 1):(j_win(n) + n_window));
        x_2 = signal_with_noise_2((j_win(n) + 1):(j_win(n) + n_window));
        y_1 = slave_signal_1((j_win(n) + 1):(j_win(n) + n_window));
        y_2 = slave_signal_2((j_win(n) + 1):(j_win(n) + n_window));
        
        beta_1(n) = corr2(x_1,y_1);
        beta_2(n) = corr2(x_2,y_2);
        beta_X(n) = corr2(y_1,y_2);
        
    end
    
%     figure(), hold on
%     plot(original_bit_sequence, 'go'), grid on, grid minor,
%     plot(beta_1, 'b.-'), grid on, grid minor,
%     plot(beta_2, 'r.-'), grid on, grid minor,
%     return
    %=====================================================================%
    %% Mean correlation coefficient
    beta_mean_1(m) = mean(beta_1);
    beta_mean_2(m) = mean(beta_2);
    beta_mean_X(m) = mean(beta_X);
    
    close all
end

fclose('all');