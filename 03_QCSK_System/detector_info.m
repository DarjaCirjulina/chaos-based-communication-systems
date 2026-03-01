%% Clear variables
close all, clc
format longE, format compact;
%=============================%
%% Read simulation results
delimiterIn = '\t'; % data separation
headerlinesIn=1; % number of header lines from the top in the .txt file

% iteration = 10;
ber_number=zeros(1,iteration);
ber_ratio=zeros(1,iteration);

% t_delay = 10e-6; % bit stream delay
% T = 1/128e3; % bit length
% Ts = T/400;
bit_length = T;
t_window = bit_length; % loga ilgums

incorrect_zeros = zeros(1,iteration); % Number of '0s' detected as '1s'
incorrect_ones = zeros(1,iteration);  % Number of '1s' detected as '0s'

for m = 1:iteration % read data for every noise level
    
%     m % Show iterration step
    
    saved_signals = importdata([QCSK_path '\RX\V_RX',num2str(m),'.txt'],delimiterIn,headerlinesIn); % read data
    saved_info_signal = importdata(['Info_decode',num2str(m),'.txt'],delimiterIn,headerlinesIn); % read data
    
    time = saved_signals.data(:, 1)';
    message_signal = saved_info_signal.data(:, 2)'; % From QAM code
    decode_signal_1 = saved_signals.data(:, 2)'; % From RX
    decode_signal_0 = saved_signals.data(:, 3)'; % From RX
    
    decode_signal_1 = decode_signal_1 - mean(decode_signal_1);
    decode_signal_1 = decode_signal_1 .* (-1);
    
    decode_signal_0 = decode_signal_0 - mean(decode_signal_0);
    decode_signal_0 = decode_signal_0 .* sqrt((mean(decode_signal_1.^2)/mean(decode_signal_0.^2)));
    %=====================================================================%
    % t_n correction
    [time, a_n] = unique(time);
    decode_signal_1 = decode_signal_1(a_n);
    decode_signal_0 = decode_signal_0(a_n);
    %=====================================================================%
    % Data interpolation 
    tau = Ts;
    t = 0:tau:time(end);
    decode_signal_1 = interp1(time, decode_signal_1(1:length(time)), t);
    decode_signal_0 = interp1(time, decode_signal_0(1:length(time)), t);
    
    message_signal = [0 message_signal(1:1:end)];
    
    % Start from t_delay
    satrt = uint64(t_delay/tau);
    t = t(satrt+1:1:length(t));
    message_signal =  message_signal(satrt+1:1:length(message_signal));
    decode_signal_1 = decode_signal_1(satrt+1:1:length(decode_signal_1));
    decode_signal_0 = decode_signal_0(satrt+1:1:length(decode_signal_0));
    
%     figure(), grid on, grid minor
%     plot(t, message_signal, 'b.-', t, decode_signal_1, 'r.-', t, decode_signal_0, 'g.-', t_info, 4.*info, 'k')
%     return
    
    %% Read original sequence
    original_bit_sequence = importdata([QCSK_path '\Bits\original_bit_sequence_for_',num2str(m),'_SNR.txt'],delimiterIn); % read data
    
    %% Create jumping window
    n_window = bit_length/tau; % window length in samples
    
    %% Calculate time needed to reach certain correlation coef.
    % For 1 and 0
    % Predefine vectors for correlation coefficient and time
    a = length(t)/n_window;
    beta_1 = zeros(1,uint64(a));
    beta_0 = zeros(1,uint64(a));
    
    % Calculte correlation coefficient using sliding window across all synchronizatio time interval
    j_win = uint64(0:n_window:(length(t) - n_window));
    for n = 1:1:length(j_win)
        
        x = message_signal((j_win(n) + 1):(j_win(n) + n_window));
        y_1 = decode_signal_1((j_win(n) + 1):(j_win(n) + n_window));
        y_0 = decode_signal_0((j_win(n) + 1):(j_win(n) + n_window));
        
        beta_1(n) = corr2(x,y_1);
        beta_0(n) = corr2(x,y_0);
        
    end
    
%     figure(), hold on
%     plot(original_bit_sequence, 'go'), grid on, grid minor,
%     plot(beta_1, 'b.-'), grid on, grid minor,
%     plot(beta_0, 'r.-'), grid on, grid minor,2
    
    
    %% Decoder comparator
    
    digital_comparator_out=zeros(1,length(beta_1));
    
    for k=1:length(beta_1)
        if beta_1(k)+th>beta_0(k)
            digital_comparator_out(k)=1;
        else
            digital_comparator_out(k)=0;
        end
    end
    
    % Loop through the bit sequences and count errors
    for i = 1:length(original_bit_sequence)
        if original_bit_sequence(i) == 0 && digital_comparator_out(i) == 1
            incorrect_zeros(m) = incorrect_zeros(m) + 1;
        elseif original_bit_sequence(i) == 1 && digital_comparator_out(i) == 0
            incorrect_ones(m) = incorrect_ones(m) + 1;
        end
    end
    %% BER calculation
    
    [number,ratio] = biterr(original_bit_sequence,digital_comparator_out);
    ber_number(m) = number;
    ber_ratio(m) = ratio;
    
    close all
end
sum(ber_number)
fclose('all');