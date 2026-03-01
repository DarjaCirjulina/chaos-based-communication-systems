%% Generate random bit sequences and signals for the experiment

%% Clear variables
close all; clear variables; format long;
%=========================================================================%
%% Parameters
n= 1024; % number of bits
m=round(32768/n); % number of samples per bit
f=125e3; % data rate
T=1/f; % bit length
tau=T/m; % sampling step
Fs=round(1/tau);

cd Generated_bit_signals_and_measurement_data % Directory for data

attenuation=39; % Attenuations in dB for the experiments
iteration=100; 

for o=1:length(attenuation)
    for num=1:1:iteration
        Random_binary_sequence = randi([0, 1], 1,n);
        % Random_binary_sequence(1:24) = zeros(1,24);
        Information_signal=kron(Random_binary_sequence,ones(1,m));
        
        csvwrite([...
            'Colpitts_original_bit_sequence','_attenuation_',num2str(attenuation(o)),...
            '_iteration_',num2str(num),'.csv'], Random_binary_sequence)
        csvwrite([...
            'Colpitts_info_signal_','attenuation_',num2str(attenuation(o)),...
            '_iteration_',num2str(num),'.csv'],Information_signal)
    end
end

cd ..