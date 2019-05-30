#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Nov 27 15:46:56 2018

@author: priyanka
"""
import h5py
from time import time
import sys
import os
import matplotlib.pyplot as plt
import numpy as np
from math import asin, sin, pi
#below is specific to the experiment:calibration parameter
from utilities import beamtime_converter_201411XX as btc
# loading some utils
TOOLS_DIR=(os.environ["PWD"] + "/../")
import utilities as sacla_ut
print('Imported sacla utils')
#Loading Images Processor
#Comment out if not needed
try:
    from photon_tools.images_processor import ImagesProcessor
    from photon_tools.plot_utilities import plot_utilities as pu
    import photon_tools.hdf5_utilities as h5u
    print "Imported ImagesProcessor"
    print "Imported plot_utilities as pu"
    print "Imported hdf5_utilities as h5u"
except:
    try:
        sys.path.append(TOOLS_DIR)
        from photon_tools.images_processor import ImagesProcessor
        from photon_tools.plot_utilities import plot_utilities as pu
        import photon_tools.hdf5_utilities as h5u
        print "Imported ImagesProcessor"
        print "Imported plot_utilities as pu"
        print "Imported hdf5_utilities as h5u"
    except:
        print "[ERROR] cannot load ImagesProcessor library"
#DAQ labels:They can change from run to run
# Define SACLA quantities - they can change from beamtime to beamtime
daq_labels = {}
daq_labels["I0_down"] = "event_info/bl_3/eh_4/photodiode/photodiode_I0_lower_user_7_in_volt"
daq_labels["I0_up"] = "event_info/bl_3/eh_4/photodiode/photodiode_I0_upper_user_8_in_volt"
daq_labels["TFY"] = "event_info/bl_3/eh_4/photodiode/photodiode_sample_PD_user_9_in_volt"
daq_labels["photon_mono_energy"] = "event_info/bl_3/tc/mono_1_position_theta"
daq_labels["delay"] = "event_info/bl_3/eh_4/laser/delay_line_motor_29"
daq_labels["ND"] = "event_info/bl_3/eh_4/laser/nd_filter_motor_26"
daq_labels["photon_sase_energy"] = "event_info/bl_3/oh_2/photon_energy_in_eV"
daq_labels["x_status"] = "event_info/bl_3/eh_1/xfel_pulse_selector_status"
daq_labels["x_shut"] = "event_info/bl_3/shutter_1_open_valid_status"
daq_labels["laser_status"] = "event_info/bl_3/lh_1/laser_pulse_selector_status"
daq_labels["tags"] = "event_info/tag_number_list"
run=23668#change as needed
adu_thresh=75
file_folder='/UserData/priyanka/'
file_name = '%d.h5'%(run_num)
file_path = file_folder+file_name
f= h5py.File(file_path, 'r')
tag_list = f["/run_" + run + "/event_info/tag_number_list"][:]
is_laser = f["/run_" + run + "/event_info/bl_3/lh_1/laser_pulse_selector_status"][:]
photon_energy = f["/run_" + run + "/event_info/bl_3/oh_2/photon_energy_in_eV"][:]
is_xray = f["/run_" + run + "/event_info/bl_3/eh_1/xfel_pulse_selector_status"][:]
is_laser_off = is_laser == 0
is_laser_on = is_laser == 1
init = time()
init = time()
roi = []
spectra_off = []
spectra_on = []
ax = []
fig = plt.figure(figsize=(10, 10))
#convert all key lists to np arrays
iol = np.array(f["/run_" + run + daq_labels["IO_down"]][:])
iou = np.array(f["/run_" + run + daq_labels["IO_up"]][:])
spd = np.array(f["/run_" + run + PDSample][:])
mono = btc.convert("energy", np.array(f["/run_" + run + Mono][:]))
nd = np.array(f["/run_" + run + ND])
delay = np.array(f["/run_" + run + "/event_info/bl_3/eh_4/laser/delay_line_motor_29"][:])        
is_data = (is_xray == 1) * (photon_energy > 9651) * (photon_energy < 9700) * (iol < 0.5) * (iou < 0.5) * (iol > 0.) * (iou > 0.) * (nd > -1)
itot = iol[is_data] + iou[is_data]
spd = spd[is_data][itot > 0]
new_tag=np.array(tag_list[is_data])
#
#plot iol vs iou
fig1=plt.figure(1)
fig1.clear()
ax = fig1.add_axes((.07,.1,.8,.8)
ax.plot(iol[isdata],iou[isdata])
ax.set(xlabel='iol', ylabel='iou',
       title='Calibration');
#image_generator
img_gen = ( f["run_"+run+'/detector_2d_assembled_1/%d/detector_data'%(item) ].value for item in np.nditer(new_tag,op_flags=['read-write'] ) 
num_images=new_tag.shape[0]
mean_int = np.zeros(num_images)
# -- sum adu image
im_avg = img_gen.next()
temp1=im_avg.flatten()
#
mean_int[0] = np.average(temp1[temp1>adu_thresh])
i=1
for im_next in img_gen:
    t1 = time.time()
    im_avg += im_next
    temp1=img_avg.flatten()
    mean_int[i] = np.sum(temp1[temp1>adu_thresh])
 #   print 'R.%d | M.%.1f ADU | S.%d/%d | %.1f Hz'%(run,mean_int[i],i,num_images,1.0/(time.time() - t1))
    i += 1
#im_avg /= num_im
hist_bins = np.arange(np.floor(itot.min()), np.ceil(itot.max()) + 2, 2) - 1
hist, hist_bins = np.histogram(itot, bins=hist_bins)
hist_bins_center = [(hist_bins[i] + hist_bins[i+1])/2.0 for i in range(len(hist_bins) - 1)]
bin_idx=np.digitize(itot,hist_bins)
adu_sum=0
#count=0
for i in range(len(hist_bins)-1):
    for item in np.nditer(bin_idx,op_flags=['read-write'] ) :
        if item==i:
           idx=item
           adu_sum+=mean_int[idx]           
    img_adu_sum_norm[i]=adu_sum/hist
fig2=plt.figure(2)
fig2.clear()
ax = fig2.add_axes((.07,.1,.8,.8)
ax.plot(itot,img_adu_sum_norm)
ax.set(xlabel='senergy', ylabel='sum_adu',
       title='Calibration');           
            
     
       
       



      