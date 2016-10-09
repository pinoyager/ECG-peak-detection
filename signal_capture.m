clear all;
fclose('all');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finding serial port and setting uart parameter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
serialobj=instrfind;
if ~isempty(serialobj)
    delete(serialobj)
end
clc;clear all;
close all;
s1 = serial('/dev/cu.usbmodemFA131');  %define serial port
s1.BaudRate=115200;     %define baud rate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setting 
% sampling rate 
% real-time figure
% buffer length and signal length
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
buff_len = 1500;
disbuff=nan(1,buff_len);
y = nan(1,buff_len);
fopen(s1);
clear data;
signal_len = 2000;
fs=480;   %sample rate
time=[1:buff_len];
time = time/fs;
dis_fil = zeros(1,signal_len);
dis_flat = zeros(1,signal_len);
dis_flat_ma = zeros(1,signal_len);
peak = zeros(1,buff_len);
figure
sig_plot=plot(nan,nan);
hold on 
scat_plot=scatter(nan,nan);
hold off 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%filter design
%q is quality factor
%[b_60,a_60] remove 60Hz power-line noise
%[b_120,a_120] remove 120Hz
%[b_0,a_0] remove baseline wonder
% ma is moving average filter to remove two peaks
% a, b are filter coefficient
% We should flip a,b to multiply filter to signal
% more easily
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
q = 3;

notch_freq = 60/(fs/2);
[b_60,a_60] = iirnotch(notch_freq,notch_freq/q);
[b_120,a_120] = iirnotch(notch_freq*2,notch_freq/q);
[b_0,a_0] = iirnotch(notch_freq/fs,notch_freq/60);
ma_len = fs/10;
ma = ones(1,ma_len)/ma_len;
a_temp = conv(a_60,a_120);
b_temp = conv(b_60,b_120);
a = conv(a_temp,a_0);
b = conv(b_temp,b_0);
%b = fliplr(b);
%a = fliplr(a);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% start to find peak and read data
% preset the threhold and backtracking sample
% You should becareful the realtionship between 
% tracking points and sampling rate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disbuff_mean = zeros(1,signal_len);
p_tracking = round(10*fs/360);
threhold = -2000;
tic
for i= 1:signal_len
    data=fscanf(s1);%read sensor
    y(i) = str2double(data);
    if ~isnan(y(i))
        if i<=buff_len

        disbuff(i)=y(i);
        
        else

        disbuff=[disbuff(2:end) y(i)];
        peak = [peak(2:end) 0];
        end
       
        if i > length(b),
            % filter and square
            % ***************becareful
            % the mean hasn't been subtracted
            % ***************
            %dis_fil(i) = (sum(b.*y(i-length(b)+1:i))-sum(a(2:end).*dis_fil(i-length(a)+1:i-1)))./a(1)
            disbuff_mean(i) = y(i) - mean(y(1:i-1));
            dis_fil(i) = b(1)*disbuff_mean(i)+b(2)*disbuff_mean(i-1)+b(3)*disbuff_mean(i-2)+b(4)*disbuff_mean(i-3)+b(5)*disbuff_mean(i-4)+b(6)*disbuff_mean(i-5)+b(7)*disbuff_mean(i-6);
            dis_fil(i) = dis_fil(i) - a(2)*dis_fil(i-1) - a(3)*dis_fil(i-2) - a(4)*dis_fil(i-3) - a(5)*dis_fil(i-4) -a(6)*dis_fil(i-5) - a(7)*dis_fil(i-6);
            dis_fil(i) = dis_fil(i)/a(1);
            %dis_fil(i) = dis_fil(i)-mean(y(1:i));

            dis_flat(i) = dis_fil(i).^2;
            if i > ma_len
                dis_flat_ma(i) = mean(dis_flat(i-ma_len+1:i));
            else
                dis_flat_ma(i) = mean(dis_flat(1:i));
            end
            % if i > the number we trace back and the slope is enough larger
            if i > p_tracking && dis_flat_ma(i) - dis_flat_ma(i-1) < threhold
                [~,p] = max(dis_flat_ma(i-p_tracking:i));
                p = p + i - (p_tracking+1);
                peak(p-4) = 1;
            end
        end
        if i>1
            cir1 = time(peak ==1);
            cir2 = disbuff(peak ==1);
            set(sig_plot,'xdata',time,'ydata',disbuff)
            hold on;
            set(scat_plot,'xdata',time,'ydata',peak)
            title('ECG peak detection');
            xlabel('Time');
            ylabel('Quantization value');
            hold off;
            drawnow;
        end
    else
        i = i - 1;
    end
end
toc
% close the serial port
fclose(s1);  

