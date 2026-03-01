%% Clear variables
% close all, format compact
% format long;
clc
%=============================%
%% Generate random bit sequence

% n = 1000; % number of bits
m = 100; % number of samples per bit
% t_delay = 10e-6; % bit stream delay
% T = 1/128e3; % bit length
tau = T/m; % sampling step

% iteration=10; % :1:10;

for o=1:iteration

Random_binary_sequence = randi([0, 1], 1,n);
%=============================%
X = Random_binary_sequence;
Y = ones(1,m);   % probably change to variable to play with sampling frequency
K = kron(X,Y);
%=============================%
%% Create time vector
t_zero = 0:tau:t_delay-tau;
time_del = t_delay:tau:T*n+t_delay;
time = [t_zero time_del];

zero_info = zeros(size(t_zero));
Information_signal=[0 zero_info K];

%% Check signal
%  figure(o)
%  plot(time*1e3, Information_signal, 'b'), , grid, grid minor,
%=============================%
%% Write signal to a file

M=[time',Information_signal']; % data to write to a file
dlmwrite(['bit_signal_for_',num2str(o),'_SNR.txt'],M,'delimiter','\t','precision','%.10f');
%=============================%
dlmwrite(['original_bit_sequence_for_',num2str(o),'_SNR.txt'],Random_binary_sequence,'delimiter','\t','precision','%.10f');

end
sim_ilg = n*T+t_delay;
fclose('all');