clear all;
fclose('all');

serialobj=instrfind;
if ~isempty(serialobj)
    delete(serialobj)
end
clc;clear all;
close all;
s1 = serial('/dev/cu.usbmodemFA131');  %define serial port
s1.BaudRate=115200;     %define baud rate

buff_len = 1500;
disbuff=nan(1,buff_len);

fopen(s1);
clear data;
signal_len = 2000;
fs=480;   %sample rate
time=[1:buff_len];
time = time/fs;
zma = zeros(1,signal_len);
z = zeros(1,signal_len);
peak = zeros(1,buff_len);
figure
h_plot=plot(nan,nan);
hold off 

q = 12;

notch_freq = 60/(fs/2);
[b_60,a_60] = iirnotch(notch_freq,notch_freq/q);
[b_120,a_120] = iirnotch(notch_freq*2,notch_freq/q);
[b_1,a_1] = butter(3,0.8*2/fs,'high');
% [b_low,a_low] = cheby2(6,60,5*2/fs,'low');
ma_len = fs/10;
ma = ones(1,ma_len)/ma_len;


a_temp = conv(a_60,a_1);
b_temp = conv(b_60,b_1);
a = conv(a_temp,a_120);
b = conv(b_temp,b_120);
b = fliplr(b);
a = fliplr(a);

%dis_fil = filter(b,a,disbuff);

%dis_fil_square = dis_fil.^2;
%dis_flat = conv(dis_fil_square,ma,'same');

tic
for i= 1:signal_len
    data=fscanf(s1);%read sensor
    y(i) = str2double(data);

    if i<=buff_len
    disbuff(i)=y(i);
    
    else

    disbuff=[disbuff(2:end) y(i)];
    peak = [peak(2:end) 0]
    end
   
    if i > length(b),
        z(i) = sum(b.* disbuff(i-length(b)+1:i))-sum(a(2:end).*z(i-length(a)+1:i-1));
        if i > 48
            z(i) = z(i).^2;
            zma(i) = sum(z(i-47:i))/48;
            if zma(i) -  zma(i-1) > -1000,
                [~,p] = max(zma(i-47:i));
                p = p + i -48;
                peak(p) = 1;
            end
        end
    end

    


    if i>1
    set(h_plot,'xdata',time,'ydata',disbuff)
    hold on;
    cir1 = time(peak ==1);
    cir2 = disbuff(peak ==1);
    scatter(cir1,cir2,'ro');

    title('ECG sampling');
    xlabel('Time');
    ylabel('Quantization value');
    hold off;
    drawnow;
    end
end
toc
% close the serial port
fclose(s1);  
% disbuff = disbuff - mean(disbuff);
disbuff = disbuff - mean(disbuff);
y = y - mean(y);
% % fir design
% cutoff = [55*2/fs 65*2/fs];
% filter_len = 148;
% FIR_h = fir1(filter_len,cutoff,'stop');
% z_fir = conv(disbuff,FIR_h,'same');

% ma design
% filter_len = floor(fs/60);
% MA_h = ones(1,filter_len)/filter_len;
% z_ma = conv(disbuff,MA_h,'same');

% IIR notch design
notch_freq = 60/(fs/2);
q = 12;
[b,a] = iirnotch(notch_freq,notch_freq/q);
z_iirnotch =filter(b,a,disbuff);

% IIR comb design,n shound be int
% notch_freq = 60/(fs/2);
% n = fs / 60;
% q = 60;
% [b,a] = iircomb(n,notch_freq/q);
% z_iircomb = filter(b,a,disbuff);
% cheby2 filter 
% order = 0;
[b,a] = cheby2(6,60,0.8/fs*2,'high');
% input z for filter you want
z_rmbw = filter(b,a,z_iirnotch);
figure;

plot(time,z_iirnotch)
title('ECG sampling after filtering');
xlabel('Time');
ylabel('Quantization value');

figure;

plot(time,z_rmbw)
title('ECG sampling after filtering(base wander)');
xlabel('Time');
ylabel('Quantization value');

% y = y - mean(y);

% figure;
% mag = fftshift(abs(fft(disbuff)));
% f_axis = 0:1:(buff_len-1);
% f_axis = f_axis - (buff_len/2);
% f_axis = f_axis*fs/buff_len;


figure;
mag = fftshift(abs(fft(disbuff)));
f_axis = 0:1:(buff_len-1);
f_axis = f_axis - (buff_len/2);
f_axis = f_axis*fs/buff_len;

plot(f_axis,mag);
xlabel('freq');
xlim([-fs/2 fs/2]);
ylabel('Magnitude');
title('ECG Spectrum');

figure;
mag = fftshift(abs(fft(z_iirnotch)));
f_axis = 0:1:(buff_len-1);
f_axis = f_axis - (buff_len/2);
f_axis = f_axis*fs/buff_len;

plot(f_axis,mag);
xlabel('freq');
xlim([-fs/2 fs/2]);
ylabel('Magnitude');
title('ECG Spectrum');

figure;
mag = fftshift(abs(fft(z_rmbw)));
f_axis = 0:1:(buff_len-1);
f_axis = f_axis - (buff_len/2);
f_axis = f_axis*fs/buff_len;

plot(f_axis,mag);
xlabel('freq');
xlim([-fs/2 fs/2]);
ylabel('Magnitude');
title('ECG Spectrum');

















