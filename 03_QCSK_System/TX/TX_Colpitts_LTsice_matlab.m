%% Clear variables
% clc;clear all;
close all, clc
% format long, format compact;
%=============================%
%% Setup
netlist=[QCSK_path '\TX\C_TX.net'];

%% Matlad netlist modifications
% t_end = 0.0078225; % 500e-6 + 5e-6;
% iteration = 1;

for n= 1:iteration % create netlists and simulate them automatically
%     n
%     ',num2str(t_end),'
code=[
    '* C_TX.asc\r\n'...
    'L1 1 3 10e-6\r\n'...
    'C1 1 2 5.4nF\r\n'...
    'C2 2 0 5.4nF\r\n'...
    'RL 3 N002 35\r\n'...
    'R2 2 N001 400\r\n'...
    'V1 0 N001 5\r\n'...
    'V2 N002 0 5\r\n'...
    'Q1 1 0 2 0 2SC4083\r\n'...
    '.model NPN NPN\r\n'...
    '.model PNP PNP\r\n'...
    '.lib C:\\Users\\medvo\\AppData\\Local\\LTspice\\lib\\cmp\\standard.bjt\r\n'...
    '.tran 0 ',num2str(t_end),' 0 0.01us\r\n'...
    '.save V(1) V(2) V(3)\r\n'...
    '.backanno\r\n'...
    '.end\r\n'...
    ];

    %% Save netlist
    fid=fopen(netlist,'wt');
    fprintf(fid,code);
    fid=fclose(fid);
    
    %% Call batch files to simulate netlist and close Ltspice after pause
    
    path_of_exe='C:\Program Files\ADI\LTspice\LTspice.exe';
    netlist = [QCSK_path '\TX\C_TX.net'];
    system(sprintf('"%s" -Run -b "%s" -j12',path_of_exe,netlist));
    
    %% Read data from simulation ".raw" file
    
    raw_data=LTspice2Matlab([QCSK_path '\TX\C_TX.raw']);
    raw_data.variable_name_list; % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    time = raw_data.time_vect;  time = time - time(1);
    C1_LTspice = raw_data.variable_mat(1,:);
    C2_LTspice = raw_data.variable_mat(2,:);
    L1_LTspice = raw_data.variable_mat(3,:);
    %% Remove NaN values
    nan_check_vector=isnan(C1_LTspice);
    
    for k=length(nan_check_vector):-1:1
        
        if(1==nan_check_vector(k))
            C1_LTspice(k)=[];
            C2_LTspice(k)=[];
            L1_LTspice(k)=[];
            time(k)=[];
            fprintf(['found NaN at line',num2str(k),' \n'])
        end
    end
    
    %% Write experiment results to .txt file
    W=[time; C1_LTspice; C2_LTspice; L1_LTspice];
    
    fileID = fopen([QCSK_path '\TX\V_TX_',num2str(n),'.txt'],'wt');
    fprintf(fileID,'%11.8f\t%11.8f\t%11.8f\t%11.8f\n',W);
    
    close all
    fclose('all');
end
