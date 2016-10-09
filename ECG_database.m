clear;
close all;


% This only works on MS Windows platform, 
% if you need for linux,Mac Version, Plz contact me
easy_list = ls('./MIT_database/easy/*m.mat');
easy_peak = ls('./MIT_database/easy/*peak.mat');
mid_list = ls('./MIT_database/mid/*m.mat');
mid_peak = ls('./MIT_database/mid/*peak.mat');
hard_list = ls('./MIT_database/hard/*m.mat');
hard_peak = ls('./MIT_database/hard/*peak.mat');
data_list = [easy_list;mid_list;hard_list];
peak_list = [easy_peak;mid_peak;hard_peak];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%filter design
%[b_60,a_60] remove 60Hz power-line noise
%[b_120,a_120] remove 120Hz
%[b_0,a_0] remove baseline wonder
% ma is moving average filter to remove two peaks
% a, b are filter coefficient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fs = 360; %set the sample rate
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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:length(data_list),
	clear val;
	dis_flat = 0;
	dis_fil = 0;
	dis_fil_square =0;
	% load data file and peak file
	if i/5<=1,
		load(strcat('./MIT_database/easy/',data_list(i,:)));
		load(strcat('./MIT_database/easy/',peak_list(i,:)));
		% data_list(i,:)
		% peak_list(i,:)
		fprintf('current use data set easy/%s\n',data_list(i,:));
	elseif i/5 <=2,
		load(strcat('./MIT_database/mid/',data_list(i,:)));
		load(strcat('./MIT_database/mid/',peak_list(i,:)));
		fprintf('current use data set mid/%s\n',data_list(i,:));
	else
		load(strcat('./MIT_database/hard/',data_list(i,:)));
		load(strcat('./MIT_database/hard/',peak_list(i,:)));
		fprintf('current use data set hard/%s\n',data_list(i,:));
	end

	% start realtime signal processing
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


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%Find peak
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	peak = zeros(1,length(dis_flat));
	dis_flat = 10*dis_flat;
	for i=1:length(dis_flat)-1
		
		if dis_flat(i+1) - dis_flat(i) < -2000 && i>200
			[~,i_max] = max(dis_flat(i+1-200:i+1));
			i_max = i_max + i - 200;
			peak(i_max) = 1;
		end
	end

	peak_shift = [peak(7:end) zeros(1,6)];

	peak_index = find(peak_shift==1);
	j = 2;
	tol = 10;
	i = 1;
	TP = 0;
	FP = 0;
	FN = 0;
	while i <= length(peak_index) && j <=length(ref_peak),
		if  abs(peak_index(i) - double(ref_peak(j))) < tol,
			TP = TP + 1;
			i = i+1;
			j = j+1;
		elseif peak_index(i) < double(ref_peak(j)),
			FP = FP + 1;
			i = i+1;
		else
			FN = FN +1;
			j = j+1;
		end
	end
	if i>length(peak_index),
		FN = FN +length(ref_peak) - (j-1);
	else,
		FP = FP + length(peak_index) - (i-1);
	end
	fprintf('Correct identify rate(TP/reference peak number): %f\n',TP/length(ref_peak)*100);
	fprintf('Peak lost rate(FN/reference peak number): %f\n',FN/length(ref_peak)*100);
	fprintf('Mis classify rate(FP/our peak number): %f\n',FP/length(peak_index)*100);

end







