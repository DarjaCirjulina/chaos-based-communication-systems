% Chaos correlator decoder for the BER estimation in AWGN channel
% Ruslans Babajans Darja Cirjulina
% 16.01.2024
%
% Features:
% Can estimate time shift between readings of the two Analog Discovery 2
% oscilloscopes

%=========================================================================%
clc,clear all, close all, format longE, format compact;
%=========================================================================%
% Parameters
tic
Fs_scope = 125e5; % Sample rate of the oscilloscope
bit_length = 1/125e3; % Length of one bit in s
number_of_bits = 1024; % Number of bits used per measurements iterration
number_of_bits_to_cut = 24; % 12 from either side
t_end = bit_length*number_of_bits; % Length of the message signal

time_original = 0:1/Fs_scope:t_end-1/Fs_scope; % Time vector

attenuation = 39; % 0, 5, 10, 15, 20
iteration = 1:1:100; %:1:1000; %:1:10; % Number of measurements per position

% BER holders
ber_number=zeros(length(iteration),length(attenuation));
ber_ratio=zeros(length(iteration),length(attenuation));
%=========================================================================%
% Calculate BER for every experiment iterration

for m = 1:1:length(attenuation) % For every position
    for num = 1:length(iteration) % For every number of measurements per position
        %         tic
        %-----------------------------------------------------------------%
        %Print iterration
        fprintf('Attenuation = %d, Iteration = %d \n',attenuation(m),num)
        fprintf('==============================================\n')
        %-----------------------------------------------------------------%
        % Read saved scope signals
        cd ..
        cd Generated_bit_signals_and_measurement_data % Directory for data
        
        Chaos_info_signal_AD_X = csvread([...
            'Chaos_info_signal_master','_attenuation_',...
            num2str(attenuation(m)),'_iteration_',num2str(iteration(num)),'.csv']);
        Chaos_info_signal_AD_X=Chaos_info_signal_AD_X-mean(Chaos_info_signal_AD_X);
        Chaos_info_signal_AD_X=Chaos_info_signal_AD_X/sqrt(mean(Chaos_info_signal_AD_X.^2));
        
        Chaos_info_signal_AD_Y = csvread([...
            'Chaos_info_signal_master','_attenuation_',...
            num2str(attenuation(m)),'_iteration_',num2str(iteration(num)),'.csv']);
        Chaos_info_signal_AD_Y=Chaos_info_signal_AD_Y-mean(Chaos_info_signal_AD_Y);
        Chaos_info_signal_AD_Y=Chaos_info_signal_AD_Y/sqrt(mean(Chaos_info_signal_AD_Y.^2));
        
        Chaos_info_signal_1_bit = csvread([...
            'Chaos_ones_slave','_attenuation_',...
            num2str(attenuation(m)),'_iteration_',num2str(iteration(num)),'.csv']);
        Chaos_info_signal_1_bit=Chaos_info_signal_1_bit-mean(Chaos_info_signal_1_bit);
        Chaos_info_signal_1_bit=Chaos_info_signal_1_bit/sqrt(mean(Chaos_info_signal_1_bit.^2));
        
        Chaos_info_signal_0_bit = csvread([...
            'Chaos_zeros_slave','_attenuation_',...
            num2str(attenuation(m)),'_iteration_',num2str(iteration(num)),'.csv']);
        Chaos_info_signal_0_bit=Chaos_info_signal_0_bit-mean(Chaos_info_signal_0_bit);
        Chaos_info_signal_0_bit=Chaos_info_signal_0_bit/sqrt(mean(Chaos_info_signal_0_bit.^2));
        %-----------------------------------------------------------------%
        time_original = 0:1/Fs_scope:t_end-1/Fs_scope; % Time vector
        % Read the original binary info signal
        
        original_bit_sequence = csvread([...
            'Colpitts_original_bit_sequence','_attenuation_',...
            num2str(attenuation(m)),'_iteration_',num2str(iteration(num)),'.csv']);
        
        samples_per_bit = length(time_original)/number_of_bits;
        original_info_signal = kron(original_bit_sequence,...
            ones(1,samples_per_bit));
        
        t_sample=bit_length/2:bit_length:bit_length*length(original_bit_sequence);
        
        
%         figure(), hold on
%         plot(time_original, Chaos_info_signal_AD_X, 'b.-', time_original, Chaos_info_signal_1_bit, 'r.-')
%         plot(time_original, original_info_signal, 'k.-')
%         grid on, grid minor
%         hold off
%         
%         figure(), hold on
%         %         plot(time_original, Chaos_info_signal_AD_X, 'b.-', time_original, Chaos_info_signal_0_bit, 'r.-')
%         plot(time_original, Chaos_info_signal_0_bit, 'r.-')
%         plot(time_original, original_info_signal, 'k.-')
%         grid on, grid minor
%         hold off
%         
%         figure(), hold on
%         plot(Chaos_info_signal_0_bit(82692:end), 'r.-')
%         plot(original_info_signal(2501:end), 'k.-')
%         grid on, grid minor
%         hold off
        %         return
        %-----------------------------------------------------------------%
        % Create window
        %         toc
        window=1; % start address
        t_window=bit_length/4;
        while time_original(window)<t_window
            window=window+1;
        end
        window = 20;
        %-----------------------------------------------------------------%
        % Predefine vectors for correlation coefficient and time
        
        time_decoded_1=zeros(1,length(time_original)-window);
        time_decoded_0=zeros(1,length(time_original)-window);
        %-----------------------------------------------------------------%
        % Calculte correlation coefficient using sliding window across all
        % synchronization time interval
        mean_filt=ones(1,window)/window;
        % Correlation coefficient with sliding window 'window'
        
        Xm=filter(mean_filt,1,Chaos_info_signal_AD_X);
        Om=filter(mean_filt,1,Chaos_info_signal_1_bit);
        XOm=filter(mean_filt,1,Chaos_info_signal_AD_X.*Chaos_info_signal_1_bit);
        Xa=sqrt(filter(mean_filt,1,Chaos_info_signal_AD_X.^2)-Xm.^2);
        Oa=sqrt(filter(mean_filt,1,Chaos_info_signal_1_bit.^2)-Om.^2);
        
        Ym=filter(mean_filt,1,Chaos_info_signal_AD_Y);
        Zm=filter(mean_filt,1,Chaos_info_signal_0_bit);
        YZm=filter(mean_filt,1,Chaos_info_signal_AD_Y.*Chaos_info_signal_0_bit);
        Ya=sqrt(filter(mean_filt,1,Chaos_info_signal_AD_Y.^2)-Ym.^2);
        Za=sqrt(filter(mean_filt,1,Chaos_info_signal_0_bit.^2)-Zm.^2);
        
        beta_1=(XOm-Xm.*Om)./real((Xa.*Oa));
        beta_0=(YZm-Ym.*Zm)./real((Ya.*Za));
        
        beta_1(isinf(beta_1))=sign(beta_1(isinf(beta_1)));
        beta_0(isinf(beta_0))=sign(beta_0(isinf(beta_0)));
        
        beta_1 = beta_1(window+1:end);
        beta_0 = beta_0(window+1:end);
        
        time_decoded_0=time_original(1:length(beta_0));
        time_decoded_1=time_original(1:length(beta_1));        
        
%         figure(), hold on
%         plot(time_original, Chaos_info_signal_AD_X, 'b.-', time_original, Chaos_info_signal_1_bit, 'r.-')
%         plot(time_decoded_0, beta_0, 'k.-')
%         plot(time_decoded_1, beta_1, 'm.-')
%         % plot(time_original, original_info_signal, 'c.-')
%         grid on, grid minor
%         hold off
%         return
        %-----------------------------------------------------------------%
        % Decoder comparator
        
        Threshold_1 = mean(beta_1);
        Threshold_0 = mean(beta_0);
        digital_comparator_out_1=zeros(1,length(beta_1));
        digital_comparator_out_0=zeros(1,length(beta_0));
        
        for k=1:length(beta_1)
            if beta_1(k)>Threshold_1
                digital_comparator_out_1(k)=1;
            else
                digital_comparator_out_1(k)=0;
            end
        end
        
        % -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -%
        
        for k=1:length(beta_0)
            if beta_0(k)<Threshold_0
                digital_comparator_out_0(k)=1;
            else
                digital_comparator_out_0(k)=0;
            end
        end
        
%         figure(), hold on
%         plot(digital_comparator_out_1, 'b.-'),
%         plot(digital_comparator_out_0, 'r.-')
%         grid on, grid minor
%         return
        %-----------------------------------------------------------------%
        % Time allignment
        % !!! ENSURE: beta_0 and beta_1 of the same size
        
        % Doubled original vector
        original_info_double=repmat(original_info_signal,1,2); % [x x]
        
        % Aligning '0' sequence and original signal
        Cross_corr_0=conv(original_info_double, fliplr(digital_comparator_out_0));
        K_0=find(max(Cross_corr_0)==Cross_corr_0);
        original_info_signal_0=original_info_double(K_0-length(digital_comparator_out_0)+1:K_0);
        
        % Truncate leading samples of first incomlete bit
        original_info_signal_0=original_info_signal_0(mod(-K_0,samples_per_bit)+1:end);
        beta_0=beta_0(mod(-K_0,samples_per_bit)+1:end);
        beta_1=beta_1(mod(-K_0,samples_per_bit)+1:end);
        
        % Truncate trailing samples of last incomlete bit
        original_info_signal_0=original_info_signal_0(1:end-mod(length(original_info_signal_0),samples_per_bit));
        beta_0=beta_0(1:end-mod(length(beta_0),samples_per_bit));
        beta_1=beta_1(1:end-mod(length(beta_1),samples_per_bit));
        
        % Truncate leading 11 leading bits and 12 trailing bits
        samples_2_cut_from_start=(length(original_info_signal_0)/samples_per_bit-1000-12)*samples_per_bit;
        original_info_signal_0=original_info_signal_0(samples_2_cut_from_start+1:end-12*samples_per_bit);
        beta_0=beta_0(samples_2_cut_from_start+1:end-12*samples_per_bit);
        beta_1=beta_1(samples_2_cut_from_start+1:end-12*samples_per_bit);

        % Equalize power of beta
        beta_0=beta_0-mean(beta_0);
        beta_1=beta_1-mean(beta_1);
        beta_0=beta_0/sqrt(mean(beta_0.^2));
        beta_1=beta_1/sqrt(mean(beta_1.^2));
        
        % Make decision
        integrator=filter(ones(1,samples_per_bit),1,beta_1-beta_0);
        detector=integrator(100:samples_per_bit:end)'>0;
        orig_bits=original_info_signal_0(50:samples_per_bit:end); % take any sample in bit: 50 just to be sure that

%         figure(1); hold on
%         plot(orig_bits,'b.-')
%         stem(detector,'r')
% 
%         figure(2); hold on
%         plot(original_info_signal_0(1:10000),'b.-')
%         plot(beta_0(1:10000),'k.-')
%         plot(beta_1(1:10000),'m.-')
%         plot(integrator(1:10000)/100,'c.-')
        
%         figure()
%         plot(abs(detector-orig_bits), 'b.-')
        
        % !!! ENSURE: In all four signals, there are integer number of bits,
        % aligned to the beginning of vectors
        %-----------------------------------------------------------------%
        % BER calculation
%         BER=sum(abs(detector-orig_bits))/length(orig_bits)
        ber_number(num,m)=sum(abs(detector-orig_bits));
        ber_ratio(num,m)=ber_number(num,m)/length(orig_bits);
        %-----------------------------------------------------------------%
        length_bits=length(orig_bits);
    end

    toc
    %---------------------------------------------------------------------%
    % Save BER numbers
    
    cd ..
    cd Decoder
    
end
ber_res = sum(ber_number')
fileID = fopen(['Colpitts_BER_numbers_sum_attenuation_',num2str(attenuation),'.txt'],'wt');
fprintf(fileID,'%11s\n','ber_numbers');
fprintf(fileID,'%11.8f\n',sum(ber_number));

fileID = fopen(['Colpitts_BER_number_attenuation_',num2str(attenuation),'.txt'],'wt');
fprintf(fileID,'%11s\n','ber_numbers');
fprintf(fileID,'%11.8f\n',ber_number);


%=========================================================================%
% Plots

% figure(1)
% plot(time_original,original_info_signal_from_hardware)
%
% figure(2)
% hold on
% plot(T,digital_comparator_out,'Color','#D95319','LineWidth',2)
% plot(time_original, info_signal_from_hardware,'Color','#77AC30','LineWidth',2)
%
% figure(3)
% hold on
% plot(time_decoded_0,digital_comparator_out_1,'o-','Color','#D95319','LineWidth',2) % red
% plot(time_decoded_1,digital_comparator_out_1,'bo-','LineWidth',2) % red
% plot(time_original, original_info_signal,'Color','#77AC30','LineWidth',2) % green
% return

% plot(time_holder,decoded_bit_sequence,'o','Color','#D95319','LineWidth',2)
% plot(t_sample,original_bit_sequence,'o','Color','#77AC30','LineWidth',2)
%
% figure(4)
% subplot(2,1,1)
% plot(time_decoded_0,digital_comparator_out_1,'Color','#D95319','LineWidth',2) % red
% subplot(2,1,2)
% plot(time_original, original_info_signal,'Color','#77AC30','LineWidth',2) % green

%=========================================================================%
toc