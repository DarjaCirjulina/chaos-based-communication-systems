close all, format compact, format long
%% Datu interpolacija
iteration = 1;
Gref = sqrt(0);          % reflected
SNR = 100;
% tic
for n = 1:1:iteration
    n
    dati1 = dlmread(['\TX\V_TX',num2str(n),'.txt']);
    % dati1 = dlmread(['C_TX.txt']);
    t_n = dati1(:,1)';
    V1_n = dati1 (:, 3)';
    V2_n = dati1 (:, 4)';
    V3_n = dati1 (:, 2)';
    Ts = 1e-5;
    Fs = 1/Ts;      % Sampling freq
    Fc = 800e3;     % Central freq
    freqdevSync = 8e3;        % Freq deviation
    freqdevInfo = 1e3;        % Freq deviation
    
    % biti
    biti = dlmread(['\Biti\bit_signal_for_',num2str(n),'_SNR.txt']);
    time_info = biti(:,1)';
    info_in = biti(:,2)';
    t_n = unique(t_n);
    % Interpolacija
    t = 0:(1/Fs):t_n(end);
    V1 = interp1(t_n, V1_n(1:length(t_n)), t);
    V2 = interp1(t_n, V2_n(1:length(t_n)), t);
    V3 = interp1(t_n, V3_n(1:length(t_n)), t);
    info = interp1(time_info, info_in, t);
    V2plot = V2;
    % DC block
    rmsV1 = mean(V1); rmsV2 = mean(V2); rmsV3 = mean(V3);
    V1 = V1 - rmsV1;
    V2 = V2 - rmsV2;
    V3 = V3 - rmsV3;
    
    % Bit generation
    V1 = V1 + 0.075;
    V3 = -1 * V3 * peak2peak(V1)/peak2peak(V3);
    infoV1 = V1 .* info;
    infoV3 = V3 .* (1 - info);
    infoV1V3 = infoV1 + infoV3;
    infoV1V3 = infoV1V3 - mean(infoV1V3);
    
    V2 = V2/max(V2);
    infoV1V3 = infoV1V3/max(infoV1V3);
    
%     return
    % figure(),
    % plot(t, infoV1V3, 'b.-', t, infoV1, 'r.-')
    % xlim([0 0.011])
    % return
    
    % HPF pre-kompensation Sync
    bSyncHPF = [1.147120458e21, -1.146543997e21]; % f2 = 100e3
    aSyncHPF = [1.507120198e21, -7.865442577e20];
    % Making a0 to be 1:
    bSyncHPF = bSyncHPF / aSyncHPF(1);
    aSyncHPF = aSyncHPF / aSyncHPF(1);
    % fvtool(bSyncHPF,aSyncHPF)
    % return
    syncV2Flt = filter(bSyncHPF, aSyncHPF, V2);
    
    % HPF pre-kompensation Info
    bInfoHPF = [9.177540127e20, -9.171775519e20]; % f2 = 100e3
    aInfoHPF = [1.205696158e21, -6.292354061e20];
    % Making a0 to be 1:
    bInfoHPF = bInfoHPF / aInfoHPF(1);
    aInfoHPF = aInfoHPF / aInfoHPF(1);
    % fvtool(bInfoHPF,aInfoHPF)
    % return
    infoV1V3Flt = filter(bInfoHPF, aInfoHPF, infoV1V3);
    
    % Upsampling
    Upsap_k = 100;
    tRsm = resample(t,Upsap_k,1);
    V2Rsm = resample(syncV2Flt,Upsap_k,1);
    InfoRsm = resample(infoV1V3Flt,Upsap_k,1);
    
    
    % FM modulacija
    V2FM = fmmod(V2Rsm,Fc,Fs*Upsap_k,freqdevSync);
    InfoFM = fmmod(InfoRsm,Fc,Fs*Upsap_k,freqdevInfo);
    
    FMinfo = InfoFM;
    
    % Multipath
    % Gain
    % Gref = sqrt(0);          % reflected
    Gst = sqrt(1-(Gref)^2);     % straight
    % G = sqrt(Gst^2 + Gref^2)
    % Delay
    dt = Ts/Upsap_k;
    fN=0.160; dN=(2*30-1)/fN; 
    Ch=[zeros(1,8) Gst zeros(1,9+floor(dN))]+[zeros(1,floor(dN)) Gref*lpntrp(17,mod(dN,1))];

    multV2FM = filter(Ch, 1, V2FM);
    multInfoFM = filter(Ch, 1, InfoFM);
        
    % AWGN kanals
    noiseSync = randn(size(multV2FM));
    noiseInfo = randn(size(multInfoFM));
    
    % band pass filter
    wo = 800e3/(Fs*Upsap_k/2);
    bwSync = 21e3/(Fs*Upsap_k/2);
    bwInfo = 19e3/(Fs*Upsap_k/2);
    
    [bSyncBPF, aSyncBPF] = iirpeak(wo, bwSync);
    [bInfoBPF, aInfoBPF] = iirpeak(wo, bwInfo);
    % fvtool(bSyncBPF, aSyncBPF)
    % fvtool(bInfoBPF, aInfoBPF)
    
    noiseSyncFlt = filter(bSyncBPF, aSyncBPF, noiseSync);
    noiseInfoFlt = filter(bInfoBPF, aInfoBPF, noiseInfo);
    
    noiseSyncFlt = [noiseSyncFlt(4:end) 0 0 0];
    noiseInfoFlt = [noiseInfoFlt(4:end) 0 0 0];
    
    PsyncRef = rms(multV2FM)^2;
    Psync = rms(noiseSyncFlt)^2;
    
    PinfoRef = rms(multInfoFM)^2;
    Pinfo = rms(noiseInfoFlt)^2;
    
    kSync = PsyncRef/(10^(SNR/10)*Psync);
    kInfo = PinfoRef/(10^(SNR/10)*Pinfo);
    
    kNoiseSync = sqrt(Psync/rms(noiseSync)^2);
    kNoiseInfo = sqrt(Pinfo/rms(noiseInfo)^2);
    
    noiseFltSync = noiseSyncFlt*sqrt(kSync);
    noiseFltInfo = noiseInfoFlt*sqrt(kInfo);

    % FM signal + noise * k
    noiseV2FM = multV2FM + noiseSync * kNoiseSync * kSync;
    noiseInfoFM = multInfoFM + noiseInfo * kNoiseInfo * kInfo;
    
    % BPF
    SyncNoiseBPF = filter(bSyncBPF, aSyncBPF, noiseV2FM);
    InfoNoiseBPF = filter(bInfoBPF, aInfoBPF, noiseInfoFM);
    
    % FM demodulacija
    V2FMdem = fmdemod(SyncNoiseBPF, Fc, Fs*Upsap_k, freqdevSync);
    InfoFMdem = fmdemod(InfoNoiseBPF, Fc, Fs*Upsap_k, freqdevInfo);
    
    % Dowmsampling
    V2dRsm = resample(V2FMdem,1,Upsap_k);
    InfodRsm = resample(InfoFMdem,1,Upsap_k);
    
    % Low-pass filter Sync
    bSync = [1.01412048e31,   1.01412048e31]; % f1 = 0.08e3;
    aSync = [4.045198388e33, -4.024915978e33];
    % Making a0 to be 1:
    bSync = bSync / aSync(1);
    aSync = aSync / aSync(1);
    % fvtool(bSync,aSync)
    % return
    SyncdRsmFlt = filter(bSync, aSync, V2dRsm);
    
    % LPF post-compensation Info
    bInfo = [5.070602401e30,  5.070602401e30]; % f1  = 0.1e3;
    aInfo = [1.619093476e33, -1.608952271e33];
    % Making a0 to be 1:
    bInfo = bInfo / aInfo(1);
    aInfo = aInfo / aInfo(1);
    % fvtool(bInfo,aInfo)
    % return
    InfodRsmFlt = filter(bInfo, aInfo, InfodRsm);
    
    % AGC
    SyncAGC = SyncdRsmFlt * peak2peak(V2) / peak2peak(SyncdRsmFlt(1000:end));
    InfoAGC = InfodRsmFlt * peak2peak(infoV1V3) / peak2peak(InfodRsmFlt(1000:end));
    
    % figure()
    % plot(t, infoV1V3,'b.-', t, InfoAGC,'r.-')
    
    % DC add
    V2dcAdd = SyncAGC + rmsV2;
    
    %         figure(), hold on, grid on, grid minor
    %         plot(V2plot, 'b.-')
    %         plot(V2dcAdd, 'r.-')
    %
    %         figure(), hold on, grid on, grid minor
    %         plot(infoV1V3(10:end), 'b.-')
    %         plot(InfoAGC(10:end), 'r.-')
    
%     Sync_corr = corr2(V2plot, V2dcAdd)
%     Info_corr = corr2(infoV1V3, InfoAGC)
    %         return
    
    V = [t; V2dcAdd];
    dlmwrite(['\RX\Sync_',num2str(n),'.txt'],V','delimiter','\t','precision',12)
    
    V1 = [t; InfoAGC];
    dlmwrite(['Info_decode',num2str(n),'.txt'],V1','delimiter','\t','precision',12)
%     fn = n
    % return
end
% return
% toc
