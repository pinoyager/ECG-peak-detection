import scipy.io as sio
import glob
import os
import numpy as np
import csv

base_path = './MIT_database'
easy_list = glob.glob(os.path.join(base_path,'easy/'+'*.txt'))
mid_list = glob.glob(os.path.join(base_path,'mid/'+'*.txt'))
hard_list = glob.glob(os.path.join(base_path,'hard/'+'*.txt'))
flist = easy_list + mid_list + hard_list

for path in flist:
	f = open(path,'r')
	peak = []
	csvread = csv.reader(f,delimiter = '\t',skipinitialspace = True)
	for row in csvread:
		# print(row[0])
		time = row[0].split(':')
		minute = int(time[0])
		# print(minute)
		second = float(time[1])
		# print(second)
		peak.append(round((minute*60+second)*360))
	
	peak_vec = np.asarray(peak)
	s_path=path.split('.txt')[0]+'peak.mat'
	sio.savemat(s_path,{'ref_peak':peak_vec})

