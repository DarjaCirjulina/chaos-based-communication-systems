%% Clear variables
close all,
format long, format compact;
%=============================%
%% Setup
netlist=['V_TX.net'];

%% Matlad netlist modifications
% t_end = 2.001;
Signal = 10; %:1:10; %Bit signals

for n=1:Signal % create 9 netlists and simulate them automatically
    
    n
    % max time step for 500 us is 10us
    %               for 100 us is 1 us
    code=[
        '* V_TX.asc\r\n'...
        'C1 3 1 100nF\r\n'...
        'L1 1 2 100mH\r\n'...
        'R1 Vb 2 20k\r\n'...
        'C2 2 N002 15n\r\n'...
        'D1 2 N002 1N4148\r\n'...
        'R2 N001 0 10k\r\n'...
        'R3 3 0 1k\r\n'...
        'R4 N002 N001 10k\r\n'...
        'V1 Vb 0 3\r\n'...
        'V2 Vcc 0 18\r\n'...
        'V3 0 Vee 18\r\n'...
        'XU1 3 N001 Vcc Vee N002 LT1001\r\n'...
        '.model D D\r\n'...
        '.lib C:\\Users\\Documents\\LTspiceXVII\\lib\\cmp\\standard.dio\r\n'...
        '.tran 0 ',num2str(t_end),' 0 1u startup\r\n'...
        '.save v(1) V(2) V(3)\r\n'...
        '.lib LTC.lib\r\n'...
        '.backanno\r\n'...
        '.end\r\n'...
        ];
    
    %% Save netlist
    fid=fopen(netlist,'w+');
    fprintf(fid,code);
    fid=fclose(fid);
    
    %% Call batch files to simulate netlist and close Ltspice after pause
    
    path_of_exe='C:\Program Files\LTC\LTspiceXVII\XVIIx64.exe';
    netlist = 'RX_oscillator.net';
    system(sprintf('"%s" -Run -b "%s" -j12',path_of_exe,netlist));
    
    %% Read data from simulation ".raw" file
    
    raw_data=LTspice2Matlab('V_TX.raw');
    raw_data.variable_name_list % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    time=raw_data.time_vect;
    % time=time-time(1);
    message_signal=raw_data.variable_mat(1,:);
    decode_signal_1=raw_data.variable_mat(2,:);
    decode_signal_0=raw_data.variable_mat(3,:);
    
    %% Remove NaN values
    nan_check_vector=isnan(message_signal);
    
    for k=length(nan_check_vector):-1:1
        
        if(1==nan_check_vector(k))
            message_signal(k)=[];
            decode_signal_1(k)=[];
            decode_signal_0(k)=[];
            time(k)=[];
            fprintf(['found NaN at line',num2str(k),' \n'])
        end
    end
    
    %% Write experiment results to .txt file
    W=[time; message_signal; decode_signal_1; decode_signal_0];
    
    fileID = fopen(['V_TX',num2str(n),'.txt'],'wt');
    % fprintf(fileID,'%11s\t%11s\t%11s\t%11s\n',...
    % 'time','Vl','V2','V3');
    fprintf(fileID,'%11.8f\t%11.8f\t%11.8f\t%11.8f\n',W);
    
    
end
