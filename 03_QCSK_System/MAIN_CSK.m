% close all, format compact, format long
clc
%% Datu interpolacija
% iteration = 1;
% SNR = 100;
% T = 1/128e3; % bit length
% Ts = T/400;
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
    % biti
    biti = dlmread([QCSK_path '\Bits\bit_signal_for_',num2str(n),'_SNR.txt']);
    time_info = biti(:,1)';
    info_in = biti(:,2)';
%     t_n = unique(t_n);
    % Interpolacija
    t = 0:(1/Fs):t_n(end);
    V1 = interp1(t_n, V1_n(1:length(t_n)), t);
    V2 = interp1(t_n, V2_n(1:length(t_n)), t);
    V3 = interp1(t_n, V3_n(1:length(t_n)), t);
    info = interp1(time_info, info_in, t);
    %=====================================================================%
    % DC block
    rmsV1 = mean(V1); rmsV2 = mean(V2); rmsV3 = mean(V3);
    V1 = V1 - rmsV1;
    V2 = V2 - rmsV2;
    V3 = V3 - rmsV3;
    %=====================================================================%
    % Bit generation
    % V1 sync
%     V2 = 1 .* V2;
%     V3 = V3 .* sqrt((mean(V2.^2)/mean(V3.^2))); % * peak2peak(V2)/peak2peak(V3);
%     infoV2 = (V2) .* info;
%     infoV3 = (V3) .* (1 - info);
%     infoV2V3 = infoV2 + infoV3;
%     infoV2V3 = infoV2V3 - mean(infoV2V3);
    %---------------------------------------------------------------------%
    % V2 sync
    V1 = -1 .* V1;
    V3 = (V3) .* sqrt((mean(V1.^2)/mean(V3.^2))); % * peak2peak(V2)/peak2peak(V3);
    infoV1 = (V1) .* info;
    infoV3 = (V3) .* (1 - info);
    infoV1V3 = infoV1 + infoV3;
    infoV1V3 = infoV1V3 - mean(infoV1V3);
    %=====================================================================%
    % QAM signal in baseband
    V2_Peq = V2 .* sqrt((mean(infoV1V3.^2)/mean(V2.^2))); % equal power signal
    Info_Sync_QAM = infoV1V3 + 1i .* V2_Peq;
    %=====================================================================%
    % low-pass filter
    wp_Info = 4.5e6/(Fs/2); % Sync V2
    wp_Sync = 2e6/(Fs/2); % 1.7e6 ir robeza - mazak nevar!!!

%     wp_Info = 2.6e6/(Fs/2);
%     wp_Sync = 4.5e6/(Fs/2); % Sync V1
    
    FIR_n = 100;
    
    bFIR_Info = fir1(FIR_n, wp_Info);
    bFIR_Sync = fir1(FIR_n, wp_Sync);
    %=====================================================================%
    % SNR calculation & Noise signal generation
    noiseSync = randn(size(V2_Peq));
    noiseInfo = randn(size(infoV1V3));
    
    noiseSyncFlt = filter(bFIR_Sync, 1, noiseSync);
    noiseInfoFlt = filter(bFIR_Info, 1, noiseInfo);
    
    noiseSyncFlt = [noiseSyncFlt((FIR_n/2+1):end) zeros(1, FIR_n/2)];
    noiseInfoFlt = [noiseInfoFlt((FIR_n/2+1):end) zeros(1, FIR_n/2)];
    
    PsyncRef = rms(V2_Peq)^2;
    Psync = rms(noiseSyncFlt)^2;
    
    PinfoRef = rms(infoV1V3)^2;
    Pinfo = rms(noiseInfoFlt)^2;

    kSync = rms(V2_Peq)./rms(noiseSyncFlt)./sqrt(10^(SNR/10));
    kInfo = rms(infoV1V3)./rms(noiseInfoFlt)./sqrt(10^(SNR/10));
    
    Noise = noiseInfo * kInfo + 1i * noiseSync * kSync;
           
    % SNR check
%     noiseFltSync = noiseSyncFlt*kSync;
%     noiseFltInfo = noiseInfoFlt*kInfo;
%     PfltSync = rms(noiseFltSync)^2;
%     PfltInfo = rms(noiseFltInfo)^2;
%     SNRcheckSync = 10*log10(PsyncRef/PfltSync)
%     SNRcheckInfo = 10*log10(PinfoRef/PfltInfo)
    %=====================================================================%
    % AWGN kanals
     Info_Sync_QAM_Noise = Info_Sync_QAM + Noise;
    %=====================================================================%
    % Demodulation
    InfoDemod = real(Info_Sync_QAM_Noise);
    SyncDemod = imag(Info_Sync_QAM_Noise);    
    %=====================================================================%
    % LPF
    InfoDemodLPF = filter(bFIR_Info, 1, InfoDemod);
    SyncDemodLPF = filter(bFIR_Sync, 1, SyncDemod);
    %=====================================================================%
    % AGC
    InfoAGC = InfoDemodLPF - mean(InfoDemodLPF);
    SyncAGC = SyncDemodLPF - mean(SyncDemodLPF);
    InfoAGC = InfoAGC * sqrt(mean(infoV1V3.^2) / mean(InfoAGC.^2));
    SyncAGC = SyncAGC * sqrt(mean(V2.^2) / mean(SyncAGC.^2));
%     figure()
%     plot(t, infoV2V3,'b.-', t(1:end-(FIR_n/2)), InfoAGC((FIR_n/2+1):end),'r.-')
    %=====================================================================%
    % DC add
    V2dcAdd = SyncAGC + rmsV2;
    
    % Sync_corr = corr2(V2(1:end-(FIR_n/2)), V2dcAdd((FIR_n/2+1):end))
    % Info_corr = corr2(infoV1V3(1:end-(FIR_n/2)), InfoAGC((FIR_n/2+1):end))
    %=====================================================================%
    V_Sync_txt = [t; V2dcAdd];
    dlmwrite([QCSK_path '\RX\Sync_',num2str(n),'.txt'],V_Sync_txt','delimiter','\t','precision',12)
    
    V_Info_txt = [t; InfoAGC];
    dlmwrite(['Info_decode',num2str(n),'.txt'],V_Info_txt','delimiter','\t','precision',12)
    close all
    fclose('all');
end
% toc
