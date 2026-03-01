close all, format compact, format longE
clear all, clc
%% Run skripts for data transmision system
SigalToNoise = -10:1:5; % 22*ones(1,10);
points = length(SigalToNoise);
BER = zeros(1,points);
Incorrect_zeros_count = zeros(1,points);
Incorrect_ones_count = zeros(1,points);
t_delay = 20e-6; % bit stream delay
T = 1/128e3; % bit length
Ts = T/400;
Bits_N = 1000; % number of bits per iteration
iteration = 10;
% tic
QCSK_path = 'path';
v_SYNC = 'V1';
[matX, matY, matCross] = readCorrFiles(QCSK_path, SigalToNoise, v_SYNC);
% return
%=========================================================================%
n = Bits_N;
% run([QCSK_path '\Bits\generating_bit_sequence.m']);
t_end = n*T+t_delay;
% clearvars -except matX matY matCross PnoiseINFO PnoiseSYNC SigalToNoise points BER t_delay T Ts Bits_N iteration t_end w QCSK_path Incorrect_zeros_count Incorrect_ones_count
% return
%=========================================================================%
% run([QCSK_path '\TX\TX_Colpitts_LTsice_matlab.m']);
clearvars -except matX matY matCross PnoiseINFO PnoiseSYNC SigalToNoise points BER t_delay T Ts Bits_N iteration t_end w QCSK_path Incorrect_zeros_count Incorrect_ones_count 
%=========================================================================%
% return
clc
for w = 1:1:points
    %=====================================================================%
    SNR = SigalToNoise(w)
    %     return
    run([QCSK_path '\MAIN_CSK.m']);
%     PnoiseINFO = PfltInfo;
%     PnoiseSYNC = PfltSync;
    clearvars -except matX matY matCross PnoiseINFO PnoiseSYNC SigalToNoise points BER t_delay T Ts Bits_N iteration t_end w QCSK_path Incorrect_zeros_count Incorrect_ones_count 
    %=====================================================================%
    run([QCSK_path '\RX\RX_Colpitts_LTsice_matlab.m']);
    clearvars -except matX matY matCross PnoiseINFO PnoiseSYNC SigalToNoise points BER t_delay T Ts Bits_N iteration t_end w QCSK_path Incorrect_zeros_count Incorrect_ones_count 
    %=====================================================================%
    th = 0.5*(matY(w)-matX(w));
    run([QCSK_path '\detector_info.m']);
    %=====================================================================%
    BER(w) = sum(ber_number)/(Bits_N*iteration)
    Incorrect_zeros_count(w) = sum(incorrect_zeros);
    Incorrect_ones_count(w) = sum(incorrect_ones);
    clearvars -except matX matY matCross PnoiseINFO PnoiseSYNC SigalToNoise points BER t_delay T Ts Bits_N iteration t_end w QCSK_path Incorrect_zeros_count Incorrect_ones_count 
    %=====================================================================%
    V = [SigalToNoise; BER; Incorrect_zeros_count; Incorrect_ones_count]; V'
    dlmwrite([QCSK_path '\BER\BER_Count_wrong_bits_TH_SYNC_V2_SNR_N10_05_noDC.txt'],V','delimiter','\t','precision',12)
    clearvars -except matX matY matCross PnoiseINFO PnoiseSYNC SigalToNoise points BER t_delay T Ts Bits_N iteration t_end w QCSK_path Incorrect_zeros_count Incorrect_ones_count 
    %=====================================================================%
end
% toc
return