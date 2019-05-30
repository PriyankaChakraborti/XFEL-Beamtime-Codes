#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 26 11:27:52 2018

@author: priyanka
"""
import h5py
import sys
import os 
import numpy as np
import time
import pylab as pyl
pyl.interactive(True)
import matplotlib
import matplotlib.pyplot as plt
import argparse
import sys
import shutil
import multiprocessing as mproc
#
#
from argparse import ArgumentParser
#
#
#comm = MPI.COMM_WORLD
#rank = comm.Get_rank()
#size = comm.Get_size()
# This script retrieves all data for runs from a start run number up to the latest one
# If a the data file of a run exist the download will skip this file

# To be executed on some hpc node
# Use: qsub -I to get an interactive shell on a node
# assign a few file labels#
data_directory="/work/priyanka"
tmp_data_directory='%s/tmp' % data_directory
taglist_directory='%s/taglists' % data_directory
maketaglist_condition_file='%s/config/maketaglist.conf' % data_directory
dataconvert_config_file='%s/config/dataconvert.conf' % data_directory
#set parameters here
beamline=3
run_url="http://xqaccdaq01.daq.xfel.cntl.local/cgi-bin/storage/run.cgi?bl=%d" % beamline
VERBOSE = False
def get_last_run():
    """Gets the last run from sacla webpage"""
    import urllib.request, urllib.error, urllib.parse
    # get the html document
    doc = urllib.request.urlopen(run_url).readlines()
    for i,l in enumerate(doc):
        if l.find("detectors")!=-1:
            try:
                return int(doc[i+4].strip().strip("</td>"))
            except:
                # We return 0 as we are shure that there are no negative runs
                return None
def download_run_function(current_run, nompccd, result_queue):
    try:
        download_run(current_run, nompccd)
        result_queue.put(0)
    except:
        print(sys.exc_info()[0])
        result_queue.put(current_run)
def download_run(current_run,nompccd):
    tmp_data_file = '%s/%06d.h5' % (tmp_data_directory, current_run)
    data_file = '%s/%06d.h5' % (data_directory, current_run) 
    if nompccd:
        tmp_data_file = '%s/%06d_nompccd.h5' % (tmp_data_directory, current_run)
        data_file = '%s/%06d_nompccd.h5' % (data_directory, current_run)
    # Check whether run was already downloaded
    if os.path.isfile(data_file):
       print(('Datafile for run %s already exists' % current_run)) 
    else:
        print(('Downloading datafile for run: %s' % current_run))
    # Make tag list
    taglist_file='%s/%06d_taglist.txt' % (taglist_directory, current_run)  
    if nompccd:
       taglist_file = '%s/%06d_taglist_nompccd.txt' % (taglist_directory, current_run)
    if os.path.isfile(maketaglist_condition_file):
            command = 'MakeTagList -b %d -r %06d -inp %s -out %s' % (beamline, current_run, maketaglist_condition_file, taglist_file)
    else:
        print("[WARNING] MakeTagList cfg file %s could not be found, proceeding with no conditions" % maketaglist_condition_file)
        command = 'MakeTagList -b %d -r %06d -out %s' % (beamline, current_run,  taglist_file)
    print(command)  
    try:
        os.system(command)
    except:
        print("Cannot run Make taglist because:")
        print(sys.exc_info()[0])
        raise RuntimeError
    had_mpccd=fix_taglist(taglist_file,nompccd)
    if nompccd and not had_mpccd:
        print('skipping run as it had no mpccd')
        os.remove(tagfile_list)
        return
      # Call DataConvert4
    command = 'DataConvert4 -f %s -l %s -dir %s -o %06d.h5' % (dataconvert_config_file, taglist_file, tmp_data_directory, current_run)
    if nompccd:
        command = 'DataConvert4 -f %s -l %s -dir %s -o %06d_nompccd.h5' % (dataconvert_config_file, taglist_file, tmp_data_directory, current_run)
        
    print(command)
    try:
        os.system(command)
    except:
        print(sys.exc_info())
    print('Move datafile')
    time.sleep(5)
    shutil.move(tmp_data_file,data_file)
    return
def fix_taglist(txt_file,nompccd):
    import re
    had_mpccd = False
    with open(txt_file,'r') as file:
        data=file.readlines()
        file.close()
    with open(txt_file,'w') as file:
        for line in data:
            if re.match('^det,$', line) and not nompccd:
                print('fix it ...')
            elif re.match('^det,.*', line) and nompccd:
                print('remove detectors ...')
                had_mpccd = True
            else:
                file.write(line)
    return had_mpccd
def download_run_to_latest(start_run,keepPolling,nompccd,max_jobs=1):
    if not os.path.exists(tmp_data_directory):
        print('Create temporary directory %s' % tmp_data_directory)
        os.makedirs(tmp_data_directory)
     last_run=get_last_run()
     current_run=start_run
     results_queue=mproc.Queue()
     while last_run is None or current_run<=last_run:
         if last_run is not None:
             while current_run<=last_run:
                 while len(mproc.active_children()) < max_jobs:
                    try:
                        if current_run > last_run:
                            last_run = get_last_run()
                            print('No more jobs left, checking for new runs')
                            break
                        p = mproc.Process(target=download_run_function, args=(current_run, nompccd, results_queue))
                        p.start()
                        #download_run(current_run, nompccd)
                        current_run += 1
                    except KeyboardInterrupt:
                        raise KeyboardInterrupt
                    except:
                        print("Failed to get %s because..." % str(current_run))
                        print(sys.exc_info())
                while not results_queue.empty():
                    res = results_queue.get()
                    if res != 0:
                        print("Failed to get %s because..." % str(current_run))
                        print("Trying again...")
                        current_run = res
                        break
                if len(mproc.active_children()) == 0:
                    print('No more jobs left, checking for new runs')
                last_run = get_last_run()

        if current_run > get_last_run():
            current_run = get_last_run()
        if (last_run is None or current_run > last_run) and keepPolling:
            while last_run is None or current_run > last_run:
                print('no new runs - sleep ...')
                time.sleep(5)
last_run = get_last_run()
             
        
        
    
            
            
        
      
      
         
         
       
              
                
    
    
    























