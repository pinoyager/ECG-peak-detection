close all;
clear all;
load('./MIT_database/hard/108m.mat');
fs = 360; %set the sample rate
q = 3;
%buff_len = 1500;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%filter design
%[b_60,a_60] remove 60Hz power-line noise
%[b_120,a_120] remove 120Hz
%[b_0,a_0] remove baseline wonder
% ma is moving average filter to remove two peaks
% a, b are filter coefficient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
notch_freq = 60/(fs/2);
[b_60,a_60] = iirnotch(notch_freq,notch_freq/q);
[b_120,a_120] = iirnotch(notch_freq*2,notch_freq/q);
%[b_180,a_180] = iirnotch(notch_freq*3,notch_freq/q);
[b_0,a_0] = iirnotch(notch_freq/fs,notch_freq/60);
%[b_1,a_1] = butter(6,0.2/fs,'high');
%[b_low,a_low] = cheby2(6,60,5*2/fs,'low');
ma_len = fs/10;
ma = ones(1,ma_len)/ma_len;
a_temp = conv(a_60,a_120);
b_temp = conv(b_60,b_120);
%a_temp = conv(a_temp,a_180);
%b_temp = conv(b_temp,b_180);
a = conv(a_temp,a_0);
b = conv(b_temp,b_0);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Get data from sheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
val_offset = val(1,:) - mean(val(1,:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Filter the original signal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dis_fil = filter(b,a,val_offset);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Filter two peaks into one peak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dis_fil_square = dis_fil.^2;
dis_flat = conv(dis_fil_square,ma,'same');

%dis_fil_square_filtered = filter(b_low,a_low,dis_fil_square);

%
%figure;
%mag = fftshift(abs(fft(disbuff)));
%f_axis = 0:1:(buff_len-1);
%f_axis = f_axis - (buff_len/2);
%f_axis = f_axis*fs/buff_len;
%plot(f_axis,mag);
%xlabel('freq');
%xlim([-fs/2 fs/2]);
%ylabel('Magnitude');
%title('ECG Spectrum');%
%

%figure;
%mag = fftshift(abs(fft(dis_fil)));
%f_axis = 0:1:(buff_len-1);
%f_axis = f_axis - (buff_len/2);
%f_axis = f_axis*fs/buff_len;%

%plot(f_axis,mag);
%xlim([-fs/2 fs/2]);
%ylabel('Magnitude');
%title('ECG Spectrum');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Find peak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
peak = zeros(1,length(dis_flat));
dis_flat = 10*dis_flat;
for i=1:length(dis_flat)-1
	
	if dis_flat(i+1) - dis_flat(i) < -2000 && i>100
		[~,i_max] = max(dis_flat(i+1-100:i+1));
		i_max = i_max + i - 100;
		peak(i_max) = 1;
	end
end

peak_shift = [peak(5:end) zeros(1,4)];


figure;
hold on
plot(dis_flat(6000:12000));
plot(300000*peak(6000:12000));
plot(200*val(1,6000:12000));
hold off
%figure;
%plot(dis_fil_square);
%
%figure;
%mag = fftshift(abs(fft(dis_fil_square)));
%f_axis = 0:1:(buff_len-1);
%f_axis = f_axis - (buff_len/2);
%f_axis = f_axis*fs/buff_len;
%
%plot(f_axis,mag);
%xlabel('freq');
%xlim([-fs/2 fs/2]);
%ylabel('Magnitude');
%title('ECG Spectrum');
%
%figure;
%plot(dis_fil_square_filtered);
%
%figure;
%mag = fftshift(abs(fft(dis_fil_square_filtered)));
%f_axis = 0:1:(buff_len-1);
%f_axis = f_axis - (buff_len/2);
%f_axis = f_axis*fs/buff_len;
%
%plot(f_axis,mag);
%xlabel('freq');
%xlim([-fs/2 fs/2]);
%ylabel('Magnitude');
%title('ECG Spectrum');
%
%figure;
%mag = fftshift(abs(fft(dis_flat)));
%f_axis = 0:1:(buff_len-1);
%f_axis = f_axis - (buff_len/2);
%f_axis = f_axis*fs/buff_len;
%
%plot(f_axis,mag);
%xlabel('freq');
%xlim([-fs/2 fs/2]);
%ylabel('Magnitude');
%title('ECG Spectrum');
%
%figure;
%plot(dis_flat);
