close all, format compact, format longE
clear all, clc
%% Run skripts for data transmision system
SigalToNoise = -20:1:30;
points = length(SigalToNoise);
CORR_1 = zeros(1,points);
CORR_2 = zeros(1,points);
CORR_X = zeros(1,points);
t_delay = 30e-6; % bit stream delay
T = 1/128e3; % bit length
Ts = T/400;
Bits_N = 1000; % number of bits per iteration
t_end = T*Bits_N+t_delay;
iteration = 10;
tic
QCSK_path = 'path';
% return
%=========================================================================%
run([QCSK_path '\TX\TX_Colpitts_LTsice_matlab.m']);
clearvars -except SigalToNoise points CORR_1 CORR_2 t_delay T Ts Bits_N iteration t_end w QCSK_path CORR_X
%=========================================================================%
% return
clc
for w = 1:1:points 
    %=====================================================================%
    SNR = SigalToNoise(w)
    run([QCSK_path '\MAIN_CSK.m']);
    clearvars -except SigalToNoise points CORR_1 CORR_2 t_delay T Ts Bits_N iteration t_end w QCSK_path CORR_X
    %=====================================================================%
    run([QCSK_path '\RX\RX_Colpitts_LTsice_matlab.m']);
    clearvars -except SigalToNoise points CORR_1 CORR_2 t_delay T Ts Bits_N iteration t_end w QCSK_path CORR_X
    %=====================================================================%
    run([QCSK_path '\detector_info.m']);
    %=====================================================================%
    CORR_1(w) = mean(beta_mean_1)
    CORR_2(w) = mean(beta_mean_2)
    CORR_X(w) = mean(beta_mean_X)
    %---------------------------------------------------------------------%
    V_1 = [SigalToNoise; CORR_1]; V_1'
    dlmwrite([QCSK_path '\BER\FOR_XTH_CORR_1_SYNC_V3_SNR_N20_30.txt'],V_1','delimiter','\t','precision',12)
    %---------------------------------------------------------------------%
    V_2 = [SigalToNoise; CORR_2]; V_2'
    dlmwrite([QCSK_path '\BER\FOR_XTH_CORR_2_SYNC_V3_SNR_N20_30.txt'],V_2','delimiter','\t','precision',12)
    %---------------------------------------------------------------------%
    V_X = [SigalToNoise; CORR_X]; V_X'
    dlmwrite([QCSK_path '\BER\FOR_XTH_CORR_X_SYNC_V3_SNR_N20_30.txt'],V_X','delimiter','\t','precision',12)
    %---------------------------------------------------------------------%
    clearvars -except SigalToNoise points CORR_1 CORR_2 t_delay T Ts Bits_N iteration t_end w QCSK_path CORR_X
    %=====================================================================%
end
toc
return