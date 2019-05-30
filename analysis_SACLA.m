clear all;close all;clc
exppath = '/work/fuchs/Data';%change as per SACLA
cd (exppath);
% runnumlist=[736940,736942];
runnumlist=736940;
dark_laser_off=[736939,736941,736943];
roi_x=[188:200];
roi_y=[260:268];
dark_image_3d=zeros(256,512,length(dark_laser_off));
image_dark=zeros(256,512);
avg_image=zeros(256,512);
% create average of dark image
for i =1:length(dark_laser_off)
    filename=[exppath '/'  sprintf('%d.h5',dark_laser_off(i))];
    basename = ['/run_' sprintf('%d',dark_laser_off(i)) '/'];
    H5TagNo_List = h5read(filename, [basename '/event_info/tag_number_list'])';
    length_of_dark_run(i)=length(H5TagNo_list);
    for j=1:length(H5TagNo_List)
        name=[basename 'detector_2d_1/tag_' num2str(H5TagNo_List(i)) '/detector_data'];
        image=hdf5read(filename,name);
        avg_image=avg_image+image;
    end
    dark_image_3d(:,:,i)=avg_image;
end    
% average over sum of dark images
image_dark=sum(dark_image_3d,3)./sum(length_of_dark_run);
avg_image=zeros(256,512);
for i=1:length(runnumlist)
    filename=[exppath '/'  sprintf('%d.h5',runnumlist(i))];
    basename = ['/run_' sprintf('%d',runnumlist(i)) '/'];
    H5TagNo_List = h5read(filename, [basename '/event_info/tag_number_list'])';
    length_of_run(i)=length(H5TagNo_list);
    for j=1:length(H5TagNo_List)
        name=[basename 'detector_2d_1/tag_' num2str(H5TagNo_List(i)) '/detector_data'];
        image=hdf5read(filename,name)-image_dark;
        image(image<threshold)=0;
        avg_image=avg_image+image;  
        temp=image(188:200,260:268);
        adu_sum(i,j)=sum(sum(temp));
        
    end
    image_3d(:,:,i)=avg_image;
    image_3d_avg{i}=image_3d(:,:,i)./length_of_run(i);
end
filename=[exppath '/'  sprintf('%d.h5',runnumlist(1))];
basename = ['/run_' sprintf('%d',runnumlist(1)) '/'];
H5BeamPulseEnergy = ...
    h5read(filename, ...
    [basename '/event_info/bl_3/eh_2/photodiode/photodiode_user_1_in_volt'])';
H5scanvar=h5read(filename,[basename '/event_info/xfel_bl_3_st_2_motor_38/position'])';
SP=unique(H5scanvar);
adu_sum_all_events=sum(adu_sum,1);
for j=1:length(SP)
    temp2=adu_sum_all_events(H5scanvar==SP(j));
    temp3=H5BeamPulseEnergy(H5scanvar==SP(j));
  %  
    adu_sum_norm(j)=sum(temp2)/sum(temp3);
end 
figure()
plot(H5TagNo_List,Sample_Z_motor);
figure()
plot(SP,adu_sum_norm_per_shot)
title('Sum of Adu in roi/event')
xlabel('scan variable (arbunits)');
ylabel('Adu norm intensity');
%     set(gca,'yscale','log')
 xlim([2.76372*10^(5),max(H5scanvar)])
        
        
        
        
    
  
    
    
    
    
    