close all, format compact, format long
clear all
%% Datu interpolacija
iteration = 1;
SNR = 100;
T = 1/128e3; % bit length
Ts = T/400;
Fs = 1/Ts;      % Sampling freq
% tic
for n = 1:1:iteration
    n
    %=====================================================================%
    dati1 = dlmread(['path\V_TX_',num2str(n),'.txt']);
    t_n = dati1(:,1)';
    V1_n = dati1 (:, 2)';
    V2_n = dati1 (:, 4)';
    V3_n = dati1 (:, 3)';
    %=====================================================================%
    % t_n correction
    [t_n, a_n] = unique(t_n);
    V1_n = V1_n(a_n);
    V2_n = V2_n(a_n);
    V3_n = V3_n(a_n);        
    %=====================================================================%
    t = 0:(1/Fs):t_n(end);
    V1 = interp1(t_n, V1_n(1:length(t_n)), t);
    V2 = interp1(t_n, V2_n(1:length(t_n)), t);
    V3 = interp1(t_n, V3_n(1:length(t_n)), t);
    %=====================================================================%
    % DC block
    rmsV1 = mean(V1); rmsV2 = mean(V2); rmsV3 = mean(V3);
    V1 = V1 - rmsV1;
    V2 = V2 - rmsV2;
    V3 = V3 - rmsV3;
    %=====================================================================%
    % low-pass filter
    wp_V1 = 4.55e6/(Fs/2);
    wp_V2 = 1.7e6/(Fs/2); % Sync V1
    wp_V3 = 2.67e6/(Fs/2);

    % wp_Info = 4.5e6/(Fs/2); % Sync V2
    % wp_Sync = 1.8e6/(Fs/2);

    FIR_n = 100;
    bFIR_V1 = fir1(FIR_n, wp_V1);
    bFIR_V2 = fir1(FIR_n, wp_V2);
    bFIR_V3 = fir1(FIR_n, wp_V3);
    
    V1_fir = filter(bFIR_V1, 1, V1);
    V2_fir = filter(bFIR_V2, 1, V2);
    V3_fir = filter(bFIR_V3, 1, V3);

    V1_corr = corr2(V1(1:end-(FIR_n/2)), V1_fir((FIR_n/2+1):end))
    V2_corr = corr2(V2(1:end-(FIR_n/2)), V2_fir((FIR_n/2+1):end))
    V3_corr = corr2(V3(1:end-(FIR_n/2)), V3_fir((FIR_n/2+1):end))
    %=====================================================================%
    % Mean-squared error
    msrV1_info = 10*log10(immse(V1(1:end-(FIR_n/2)), V1_fir((FIR_n/2+1):end))/mean(V1(1:end-(FIR_n/2)).^2))
    msrV2_sync = 10*log10(immse(V2(1:end-(FIR_n/2)), V2_fir((FIR_n/2+1):end))/mean(V2(1:end-(FIR_n/2)).^2))
    msrV3_sync = 10*log10(immse(V3(1:end-(FIR_n/2)), V3_fir((FIR_n/2+1):end))/mean(V3(1:end-(FIR_n/2)).^2))
end
% return


