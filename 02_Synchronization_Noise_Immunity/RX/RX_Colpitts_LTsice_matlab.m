%% Clear variables
% clc;clear all;
close all, clc
% format long, format compact;
%=============================%
%% Setup
netlist=[QCSK_path '\RX\C_RX.net'];

%% Matlad netlist modifications
% t_end = 0.0078225; % 500e-6 + 5e-6;
% iteration = 1;

for n= 1:iteration % create netlists and simulate them automatically
    %     n
    %     ',num2str(t_end),'
    code=[
        '* path \r\n'...
        'L1 1A 3A 10e-6\r\n'...
        'C1 1A 2A 5.4nF\r\n'...
        'RL2 3A N002 35\r\n'...
        'R2 2A N001 400\r\n'...
        'V1 0 N001 5\r\n'...
        'V2 N002 0 5\r\n'...
        'Q1 1A 0 2A 0 2SC4083\r\n'...
        'V3 3A 0 PWL file=Sync_',num2str(n),'.txt\r\n'...
        'C2 2A 0 5.4nF\r\n'...
        '.model NPN NPN\r\n'...
        '.model PNP PNP\r\n'...
        '.lib C:\\Users\\medvo\\AppData\\Local\\LTspice\\lib\\cmp\\standard.bjt\r\n'...
        '.tran 0 ',num2str(t_end),' 0 0.1us\r\n'...
        '.save V(1A) V(2A)\r\n'...
        '.backanno\r\n'...
        '.end\r\n'...
        ];

    %% Save netlist
    fid=fopen(netlist,'wt');
    fprintf(fid,code);
    fid=fclose(fid);

    %% Call batch files to simulate netlist and close Ltspice after pause
    
    path_of_exe='C:\Program Files\ADI\LTspice\LTspice.exe';
    netlist = [QCSK_path '\RX\C_RX.net'];
    system(sprintf('"%s" -Run -b "%s" -j12',path_of_exe,netlist));
    
    %% Read data from simulation ".raw" file
    
    raw_data=LTspice2Matlab([QCSK_path '\RX\C_RX.raw']);
    raw_data.variable_name_list; % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    time = raw_data.time_vect;
    decode_signal_1=raw_data.variable_mat(1,:);
    decode_signal_0=raw_data.variable_mat(2,:);
    %% Remove NaN values
    nan_check_vector=isnan(decode_signal_1);
    
    for k=length(nan_check_vector):-1:1
        
        if(1==nan_check_vector(k))
            decode_signal_1(k)=[];
            decode_signal_0(k)=[];
            time(k)=[];
            fprintf(['found NaN at line',num2str(k),' \n'])
        end
    end
    
    %% Write experiment results to .txt file
    W=[time; decode_signal_1; decode_signal_0];
    
    fileID = fopen([QCSK_path '\RX\V_RX',num2str(n),'.txt'],'wt');
    % fprintf(fileID,'%11s\t%11s\t%11s\n',...
    % 'time','Vl','V3');
    fprintf(fileID,'%11.8f\t%11.8f\t%11.8f\n',W);
    
    close all
    fclose('all');
end
