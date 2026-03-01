% close all, format compact, format long
clc

Fs = 1/Ts;      % Sampling freq

% tic
for n = 1:1:iteration
%     n
    %=====================================================================%
    dati1 = dlmread([QCSK_path '\TX\V_TX_',num2str(n),'.txt']);
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
    % Interpolacija
    t = 0:(1/Fs):t_n(end);
    V1 = interp1(t_n, V1_n(1:length(t_n)), t);
    V2 = interp1(t_n, V2_n(1:length(t_n)), t);
    V3 = interp1(t_n, V3_n(1:length(t_n)), t);
    %=====================================================================%
    % DC block
    meanV1 = mean(V1); meanV2 = mean(V2); meanV3 = mean(V3);
    V1 = V1 - meanV1;
    V2 = V2 - meanV2;
    V3 = V3 - meanV3;
    %=====================================================================%
    % low-pass filter
    wp_V1 = 4.55e6/(Fs/2);
    wp_V2 = 1.7e6/(Fs/2);
    wp_V3 = 2.67e6/(Fs/2);
    
    FIR_n = 100;
    
    bFIR_V1 = fir1(FIR_n, wp_V1);
    bFIR_V2 = fir1(FIR_n, wp_V2);
    bFIR_V3 = fir1(FIR_n, wp_V3);
    %=====================================================================%
    % SNR calculation & Noise signal generation
    noiseV1 = randn(size(V1));
    noiseV2 = randn(size(V2));
    noiseV3 = randn(size(V3));
    
    noiseV1Flt = filter(bFIR_V1, 1, noiseV1);
    noiseV2Flt = filter(bFIR_V2, 1, noiseV2);
    noiseV3Flt = filter(bFIR_V3, 1, noiseV3);
    
    noiseV1Flt = [noiseV1Flt((FIR_n/2+1):end) zeros(1, FIR_n/2)];
    noiseV2Flt = [noiseV2Flt((FIR_n/2+1):end) zeros(1, FIR_n/2)];
    noiseV3Flt = [noiseV3Flt((FIR_n/2+1):end) zeros(1, FIR_n/2)];
    
    PV1Ref = rms(V1)^2;
    PV1 = rms(noiseV1Flt)^2;
    
    PV2Ref = rms(V2)^2;
    PV2 = rms(noiseV2Flt)^2;

    kV1 = rms(V1)./rms(noiseV1Flt)./sqrt(10^(SNR/10));
    kV2 = rms(V2)./rms(noiseV2Flt)./sqrt(10^(SNR/10));
    kV3 = rms(V3)./rms(noiseV3Flt)./sqrt(10^(SNR/10));
    
    NoiseV1 = noiseV1 * kV1;
    NoiseV2 = noiseV2 * kV2;
    NoiseV3 = noiseV3 * kV3;
           
    % SNR check
%     noiseFltV1 = noiseV1Flt*kV1;
%     noiseFltV2 = noiseV2Flt*kV2;
%     PfltV1 = rms(noiseFltV1)^2;
%     PfltV2 = rms(noiseFltV2)^2;
%     SNRcheckV1 = 10*log10(PV1Ref/PfltV1)
%     SNRcheckV2 = 10*log10(PV2Ref/PfltV2)
%     return
    %=====================================================================%
    % AWGN kanals
    V1_AWGN = V1 + NoiseV1;
    V2_AWGN = V2 + NoiseV2;
    V3_AWGN = V3 + NoiseV3;
    %=====================================================================%
    % LPF
    V1noiseLPF = filter(bFIR_V1, 1, V1_AWGN);
    V2noiseLPF = filter(bFIR_V2, 1, V2_AWGN);
    V3noiseLPF = filter(bFIR_V3, 1, V3_AWGN);
    %=====================================================================%
    % AGC
    V1AGC = V1noiseLPF - mean(V1noiseLPF);
    V2AGC = V2noiseLPF - mean(V2noiseLPF);
    V3AGC = V3noiseLPF - mean(V3noiseLPF);
    
    V1AGC = V1AGC * sqrt(mean(V1.^2) / mean(V1AGC.^2));
    V2AGC = V2AGC * sqrt(mean(V2.^2) / mean(V2AGC.^2));
    V3AGC = V3AGC * sqrt(mean(V3.^2) / mean(V3AGC.^2));
    %=====================================================================%
    % DC add
    V1dcAdd = V1AGC + meanV1;
    V2dcAdd = V2AGC + meanV2;
    V3dcAdd = V3AGC + meanV3;
    %=====================================================================%
    V_Sync_txt = [t; V3dcAdd];
    dlmwrite([QCSK_path '\RX\Sync_',num2str(n),'.txt'],V_Sync_txt','delimiter','\t','precision',12)
    
    V_Info_txt = [t; V1dcAdd; V2dcAdd];
    dlmwrite(['Info_decode',num2str(n),'.txt'],V_Info_txt','delimiter','\t','precision',12)
    close all
    fclose('all');
end

