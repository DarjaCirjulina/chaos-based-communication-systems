close all, format compact, format longE
clear all,
%% Run skripts for data transmision system

SigalToNoise = -5:1:15;
points = length(SigalToNoise);
BER = zeros(1,points);
tic
for w = 1:1:points
    run('\Biti\generating_bit_sequence.m');
    t_end = sim_ilg;
    
    clearvars -except t_end BER points w SigalToNoise
    
    run('\TX\Ltspice_matlab_TX.m');
    
    clearvars -except t_end BER points w SigalToNoise
    SNR = SigalToNoise(w)
    
    run('FM_mod_demod_DK.m');
    clearvars -except t_end BER points w SigalToNoise
    
    run('\RX\Ltspice_matlab_RX.m');
    clearvars -except t_end BER points w SigalToNoise
    
    run('detector_info.m');
    
    BER(w) = sum(ber_number)/1000/10
    clearvars -except t_end BER points w SigalToNoise
    
end
toc
return
%% BER
V = [SigalToNoise; BER];
dlmwrite(['C:\Users\medvo\Desktop\Chaos\Vilnius_FM_CSK_simulacija\Vilnius_MATLAB_FMCSK\BER500.txt'],V','delimiter','\t','precision',12)
