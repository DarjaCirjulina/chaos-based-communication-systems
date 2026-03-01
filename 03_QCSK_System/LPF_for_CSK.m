close all, format compact, format long
clear all
%% Datu interpolacija
iteration = 1;
SNR = 100;
T = 1/128e3; % bit length
Ts = T/400;
Fs = 1/Ts;      % Sampling freq
% tic
QCSK_path = 'path';

for n = 1:1:iteration
    n
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
    % V2 sync
    V1 = -1 .* V1;
    V3 = (V3) .* sqrt((mean(V1.^2)/mean(V3.^2))); % * peak2peak(V2)/peak2peak(V3);
    infoV1 = (V1) .* info;
    infoV3 = (V3) .* (1 - info);
    infoV1V3 = infoV1 + infoV3;
    infoV1V3 = infoV1V3 - mean(infoV1V3);
    
%     figure()
%     plot(t, infoV1V3, 'b.-', t, info, 'r.-')
%     grid on, grid minor
%     return
    %=====================================================================%
    % QAM signal in baseband
    V2_Peq = V2 .* sqrt((mean(infoV1V3.^2)/mean(V2.^2))); % equal power signal
    Info_Sync_QAM = infoV1V3 + 1i .* V2_Peq;
    %=====================================================================%
    % low-pass filter -25 dB !!!
%     wp_Info = 2.6e6/(Fs/2);
%     wp_Sync = 4.5e6/(Fs/2); % Sync V1

    wp_Info = 4.5e6/(Fs/2); % Sync V2
    wp_Sync = 2.5e6/(Fs/2);

    FIR_n = 100;
    bFIR_Info = fir1(FIR_n, wp_Info);
    bFIR_Sync = fir1(FIR_n, wp_Sync);
    
    % fvtool(bFIR_Info, 1)
    % fvtool(bFIR_Sync, 1)
    
    Info_QAM_fir = filter(bFIR_Info, 1, real(Info_Sync_QAM));
    Sync_QAM_fir = filter(bFIR_Sync, 1, imag(Info_Sync_QAM));
    
    % figure(), hold on, grid on, grid minor, title('Information-carrying signal')
    % plot(real(Info_Sync_QAM(1:end-(FIR_n/2))), 'b.-')
    % plot(Info_QAM_fir((FIR_n/2+1):end), 'r.-')
    % xlim([500 1000])
    % hold off

    figure(), hold on, grid on, grid minor, title('Synchronization signal')
    plot(imag(Info_Sync_QAM(1:end-(FIR_n/2))), 'b.-')
    plot(Sync_QAM_fir((FIR_n/2+1):end), 'r.-')
    xlim([500 1000])
    hold off
    % return
    Sync_corr = corr2(V2_Peq(1:end-(FIR_n/2)), Sync_QAM_fir((FIR_n/2+1):end))
    Info_corr = corr2(infoV1V3(1:end-(FIR_n/2)), Info_QAM_fir((FIR_n/2+1):end))
    %=====================================================================%
    % Mean-squared error
    msrQAM_info = 10*log10(immse(real(Info_Sync_QAM(1:end-(FIR_n/2))), Info_QAM_fir((FIR_n/2+1):end))/mean(real(Info_Sync_QAM(1:end-(FIR_n/2))).^2))
    msrQAM_sync = 10*log10(immse(imag(Info_Sync_QAM(1:end-(FIR_n/2))), Sync_QAM_fir((FIR_n/2+1):end))/mean(imag(Info_Sync_QAM(1:end-(FIR_n/2))).^2))
end
