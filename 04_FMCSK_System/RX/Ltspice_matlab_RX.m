%% Clear variables
close all,
format long, format compact;
%=============================%
%% Setup
netlist=['V_RX.net'];

%% Matlad netlist modifications
% t_end = 2.001;
Signal = 10; %Bit signals

for n= 1:Signal % create 9 netlists and simulate them automatically
    % max time step for 500 us is 10us
    %               for 100 us is 1 us
    code=[
        '* V_RX.asc\r\n'...
        'V1 Vb 0 3\r\n'...
        'V2 Vcc 0 18\r\n'...
        'V3 0 Vee 18\r\n'...
        'C3 3a 1a 100nF\r\n'...
        'L2 1a 2a 100mH\r\n'...
        'R5 Vb 2a 20k\r\n'...
        'C4 2a N002 15nF\r\n'...
        'D2 2a N002 1N4148\r\n'...
        'R6 N001 0 10k\r\n'...
        'R7 3a 0 1k\r\n'...
        'R8 N002 N001 10k\r\n'...
        'XU2 3a N001 Vcc Vee N002 LT1001\r\n'...
        'V4 2a 0 PWL file=Sync_',num2str(n),'.txt\r\n'...
        '.model D D\r\n'...
        '.lib C:\\Users\\Documents\\LTspiceXVII\\lib\\cmp\\standard.dio\r\n'...
        '.tran 0 ',num2str(t_end),' 0 1u startup\r\n'...
        '.save v(1a) V(3a)\r\n'...
        '.lib LTC.lib\r\n'...
        '.backanno\r\n'...
        '.end\r\n'...
        ];
    
    %% Save netlist
    fid=fopen(netlist,'w+');
    fprintf(fid,code);
    fid=fclose(fid);
    
    %% Call batch files to simulate netlist and close Ltspice after pause
    
    dos('LTSpice_call.bat'); % Run LTspice netlist simulation
    pause(35) % Wait 3 min
    dos('LTSpice_end.bat'); % Close LTspice
    
    %% Read data from simulation ".raw" file
    
    raw_data=LTspice2Matlab('V_RX.raw');
    raw_data.variable_name_list % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    time=raw_data.time_vect;
    time=time-time(1);
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
    
    fileID = fopen(['V_RX',num2str(n),'.txt'],'wt');
    % fprintf(fileID,'%11s\t%11s\t%11s\n',...
    % 'time','Vl','V3');
    fprintf(fileID,'%11.8f\t%11.8f\t%11.8f\n',W);
    
    
end
