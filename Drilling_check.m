%% Droplet Method **use this plz
% Make average image and histogram

% check for hole drilling

datadir = '/work/johann/'; % where the hdf5 files are
matfilesdir = '~/SACLA-MB-July2018/'; % where the matlab files are

% 711385 is DAQ test
runnum = 711459; % run number change as needed
datafile = [datadir num2str(runnum) '.h5'];
    basename = ['/run_' num2str(runnum)];
% Get list of tags, accelerator status, and electron pulse energy

H5Accelerator_Status = ...
    h5read(datafile, [basename '/event_info/acc/accelerator_status'])';

H5BeamPulseEnergy = ...
    h5read(datafile, ...
    [basename '/event_info/bm_1_signal_in_coulomb'])';

H5TagNo_List = h5read(datafile, [basename '/event_info/tag_number_list'])';

N_shots = length(H5TagNo_List);



% Choose detector
det_name = 'detector_2d_3'; % change
    % detector list
    
    
   
    if strcmpi(det_name,'detector_2d_1');
        % Upstream Mono.
        siz = [512 1024]; % image size change as needed...
%         load('/home/johann/SACLA-MB-July2018/MAT_files/detector_2d_1_dark_R711388.mat')
        dark_img = zeros(siz); % dark image for now
    elseif strcmpi(det_name,'detector_2d_2');
        % Side MPCCD.
        siz = [256 512]; % image size change as needed...
        load('/home/johann/SACLA-MB-July2018/MAT_files/detector_2d_2_dark_R711388.mat')
        display(det_name);
    %     dark_img = zeros(siz); % uncomment to get rid of old darks
    elseif strcmpi(det_name,'detector_2d_3');
        % Analyzer MPCCD.
        siz = [512 1024]; % image size change as needed...
        load('/home/johann/SACLA-MB-July2018/MAT_files/detector_2d_3_dark_R711388.mat')
        display(det_name);
    % dark_img = zeros(siz); % dark image for now
    else
        display('specify a detector');
    end

%int  = H5TagNo_List(i);
%name = [basename '/detector_2d_2/tag_' num2str(int) '/detector_data'];

% Set paramaters for histogram, thresholds
adubins = linspace(-100,2000,300); % 10 keV ~ 100 adu.  This will go to 20 keV
threshold = 50; % conservative thresolding on MPCCD 2
% threshold = 65; % conservative thresolding on MPCCD 2
threshold = 195; % conservative thresolding on MPCCD 2
adu_to_energy = 10.3604; % detector-dependent

% ROI for histogram
xmin = 1;
xmax = siz(2);
ymin = 1;
ymax = siz(1); 

% 
% % % % ROI for histogram
xmin = 50;
xmax = 500;
ymin = 50;
ymax = 200;

%
N_shots_to_average = N_shots; % average all shots in run
% % N_shots_to_average = 1000; %for testing

aduhist_all = zeros(size(adubins));
total_realtime_counts = zeros(1,N_shots_to_average);
image = zeros(siz);
tmp = zeros(siz);
avg_img =  zeros(siz);

disp(['reading data, ' int2str(N_shots_to_average) ' shots'])
fprintf('\n\n\n\n');


fh = H5F.open(datafile); % open file
for nn=1:N_shots_to_average 
    %%
    tag = H5TagNo_List(nn); % tag
    % load image from h5 file
    
    % comment for different detectors
    
%     name = [basename '/'' /tag_' num2str(tag) '/detector_data'];
    name = [basename '/' det_name '/tag_' num2str(tag) '/detector_data'];
%     name = [basename '/detector_2d_2/tag_' num2str(tag) '/detector_data'];
        
        dset = H5D.open(fh, name);
        image = H5D.read(dset) - dark_img;
        H5D.close(dset);
        
        % just sum counts above threshold
        total_realtime_counts(nn) = sum(sum(image(ymin:ymax,xmin:xmax)));
        
        % threshold for image
        bin =  image > threshold;
%         image = image.*bin;
        tmp = image;
%        image(~bin) = 0;
%         image = image(ymin:ymax,xmin:xmax); % ROI
        % make average image
        
        % no dropletting
%       neighbors to pixel above threshold
        tmp = tmp + circshift(image,[1 0]);
        tmp = tmp + circshift(image,[-1 0]);
        tmp = tmp + circshift(image,[0 1]);
        tmp = tmp + circshift(image,[0 -1]);
        % next nearest neighbors
        tmp = tmp + circshift(image,[1 1]);
        tmp = tmp + circshift(image,[1 -1]);
        tmp = tmp + circshift(image,[-1 -1]);
        tmp = tmp + circshift(image,[-1 1]);
        image = tmp;
%         
        % grab image
%         hit_list = image(bin);
%         image(image < threshold) = 0;
%         image(~bin) = 0;
        avg_img = avg_img + image; % add in average image (thresholded)
        
        % make droplets
%         drops = regionprops(bin, 'Area','Centroid','PixelIdxList');
        % make droplet
        
        % make histogram
        % xmin 
        [aduhist,~]=hist(reshape(image,[],1),adubins); % not sure reshape needed
        aduhist_all = aduhist_all + aduhist;
        
        f = adubins > threshold;
        total_realtime_counts_adu(nn) = sum(f.*aduhist.*adubins);


        %display progress every 100th step
        if mod(nn,100) == 0
        fprintf('\b\b\b\b');
        fprintf('%04i',nn)
        end
        
end
% normalize avg. image by shots
avg_img = avg_img/N_shots_to_average;
%

figure(1)
imagesc(log10(abs(avg_img)))
% caxis([0 1e3])
colorbar
% 
figure(3);hold on;
% plot(total_realtime_counts/total_realtime_counts(1))
plot(total_realtime_counts_adu/total_realtime_counts_adu(1),'b')
set(gca,'xscale','log')
% xlim([0 100])
xlabel('N shots')
ylabel('Relative Intensity')

%% Plot histograms for droplet

figure(1);clf;
imagesc(log10(abs(avg_img)));
colorbar;
caxis([0 2]);
title('average image (log scale)')

% Energy range for ADUs
adu_lower_1 = 300;
adu_upper_1 = 550;

adu_lower_2 = adu_lower_1*2; % lower bound low energy
adu_upper_2 = adu_upper_1*2; % upper bound high energy (SHG)


% Check pileup
% rescaling 
sig_per_shot = aduhist_all/N_shots_to_average;
% rescaling = (xmin-xmax-1)*(ymin-ymax-1)/numel(image);

pileup_per_shot = prod(siz)*(sig_per_shot/prod(siz)).^2; % photons/px/shot^2*npix
pileup_per_shot(adu_lower_1 > adubins) = 0; % threshold out low energy
hymin =  max(sig_per_shot)/1e6; % placeholder, lower limit for yaxis


% Plot histogram
figure(2);clf;%hold on;
plot(adubins, sig_per_shot,'o - m');

%plot(adubins*2,pileup_per_shot,'b . --') % x2 for pileup
% plot([adu_lower_1 adu_lower_1],[hymin max(sig_per_shot)],'r')
% plot([adu_upper_1 adu_upper_1],[hymin max(sig_per_shot)],'r')
% plot([adu_lower_2 adu_lower_2],[hymin max(sig_per_shot)],'b') % lower bound
% plot([adu_upper_2 adu_upper_2],[hymin max(sig_per_shot)],'b') % upper bound
    set(gca,'yscale','log');
    xlabel('droplets ADUs'); 
    xlabel('ADU'); 
    xlim([min(adubins) max(adubins)])
    ylabel('hits per shot');
    legend('detector histogram');%,'Expected pileup','1\omega bounds','2\omega bounds');
    drawnow
    title('Histogram')
%     title({['Events in SHG = ' num2str(sum(sig_per_shot(adu_lower_2:adu_upper_2)))];...
%         ['Expected Pileup =' num2str((sum(bgd_per_shot(adu_lower_1:adu_upper_1)*rescaling)))]})

%%

load Drill_Checks
Drill_Checks = [test_R53; test_R54; test_R55; test_R58];
figure;
plot(Drill_Checks')
set(gca,'xscale','log')
legend('R53','R54','R55','R58');