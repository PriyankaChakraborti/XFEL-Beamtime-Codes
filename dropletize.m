 function [xdrop,ydrop,adudrop,ndrop,dropsum] = dropletize(x_hit,y_hit,imo,adu_basethreshold,adu_roi)
 tic
%imo=original image with threshold applied 
%binary_image=binary image with threshold  applied
%adu_roi=additional adu thresholds
%x_hit=x index of the hit 
%y_hit=y index of the hit

% fprintf('/n creating 3x3 grid around x_hit and y_hit as central pixel')
set_hits=[x_hit y_hit];
 L=size(set_hits,1);
x_centre_pixel=2;y_centre_pixel=2;dim_x=3;dim_y=3;
drop_centre=[x_centre_pixel y_centre_pixel];
data_posn=cell(size(xdim*ydim),1);
droplet_original=cell(L,1);


i=1;
% condn=isempty(set_hits);
while isempty(set_hits)~=1
    row=set_hits(1,1);
    column=set_hits(1,2);
    radius=1;
    %extract 3*3grid around row and column as central pixel'
    %avoid edge effects using below%
    submat = imo(max((row-radius), 1):min((row+radius), end), max((column-radius),1):min((column+radius),end));
    temp=submat;
    %if hit is in edge case ask Johann about edge padding
    %% check for possibility of other pixel hits within temp
    [x_shared,y_shared]=find(temp>adu_basethreshold);
    if size(x_shared,1)>1
       shared_pix=[x_shared y_shared];
       offset_pix=shared_pix-[x_centre_pixel y_centre_pixel];
       %find coordinates in original matrix and adu weighted centre of mass
       droplet_original{i}=offset_original+[row column];
       temp1=droplet_original{i};
       x_coord=temp1(:,1);
       y_coord=temp1(:,2);
       adu_coord=imo (sub2ind(size(imo),x_coord,y_coord));
       xdrop(i)=round(dot(adu_coord,x_coord)/sum(adu_coord));                   
       ydrop(i)=round(dot(adu_coord,y_coord)/sum(adu_coord));
%     perform azimuthal scan within a certain radius around this adu weighted
%     pixel       
      N=2.5;
        %generate 2d grid of coordinates surrounding this droplet coordinate
        [X_grid,Y_grid]=meshgrid(1:size(imo,2),1:size(imo,1));
        mask=(X_grid-xdrop(i)).^2+(Y_grid-ydrop(i)).^2<=N^2;% circular mask of radius 2.5 
        imo_new=imo.*mask;%apply circular mask to original image
        %isolate if there are any other pixels within imo_new that are
        %central hits. If so make their adu value zero as they will be
        %treated as their own hit.
        %This will prevent overcounting
        
        [x_mask,y_mask]=find(imo_new>adu_basethreshold);
        if (size(x_mask,1)>size(x_coord,1))
          [C,~]=setdiff([x_mask y_mask],[x_coord y_coord],'rows');
            imo_new(sub2ind(size(imo),C(:,1),C(:,2)))=0;% avoid counting the adu values of these extra hits.They will be treated as their own central pixel
            imo_new(imo_new<adu_roi(3))=0;%setting any adus below lowest threshold to zero;
            mask(sub2ind(size(mask),C(:,1),C(:,2)))=0;
        end   
        ndrop(i)=sum(sum(mask));%size of the droplet for this hit
        adudrop(i)=sum(sum(imo_new));  %sum of adu values for this hit
        % remove the  pixel hits found with 3*3 grid from the
        % list so that they are not used to find droplets
        [C,~]=setdiff(set_hits,[x_coord y_coord],'rows');%remove ith central hit
        set_hits=C;
     
        
    else  
    
    %check nearest neighbours for second threshold by computing Euclidean
    %pixel distance
    offset_mask=eclddist(x_centre_pixel,y_centre_pixel,dim_x,dim_y);
    %create binary distance mask for nearest neighbours
    binary_distance_mask=(offset_mask==1);
    second_adu_threshold=temp.*binary_distance_mask;
    % apply adu roi
    [x_second,y_second]=find(second_adu_threshold >adu_roi(2) & second_adu_threshold<adu_roi(1));
    if size(x_second,1)>2
        warning('possible large droplet')
    end   
    %store index address of second nearest neighbour that satisfies
    %threshold
    data_posn{1}=[x_second y_second];
    %search nearest neighbour(left and right only) of second nearest
    %neighbour
    for ii=1:size(x_second,1)
        % create offset mask again%
        x_p=x_second(ii);
        y_p=y_second(ii);
        offset_mask_two=eclddist(x_p,y_p,dim_x,dim_y);
        %force set central pixel to zero to avoid over counting
        offset_mask_two(x_centre_pixel,y_centre_pixel)=0;
        binary_distance_mask=(offset_mask==1);
        third_adu_threshold=temp.*binary_distance_mask;
        [x_third,y_third]=find(third_adu_threshold >adu_roi(3) & third_adu_threshold<adu_roi(2));
        data_posn{ii+1}=[x_third y_third];
    end
    % now that we have the positions of all the droplets we can
    % check for double counting
    posn_droplet=unique(cell2mat(data_posn),'rows');%leaves us with a matrix whose columns are (x,y) pairs of coordinates
    %map these positions back to original image so that we can find adu
    %weighted x and y centre of mass and include any additional pixels.
    offset_original=posn_droplet-drop_centre;
    droplet_original{i}=offset_original+[row column];% used to identify shared pixel.
    temp1=droplet_original{i};
    x_coord=temp1(:,1);
    y_coord=temp1(:,2);
    adu_coord=imo (sub2ind(size(imo),x_coord,y_coord));
    ndrop(i)=size(temp1,1);%size of the droplet for this hit
    adudrop(i)=sum(adu_coord);                %sum of adu values for this hit
    xdrop(i)=round(dot(adu_coord,x_coord)/adudrop(i));                   %x-centre of mass for the droplet of this hit
    ydrop(i)=round(dot(adu_coord,y_coord)/adudrop(i));  %y-centre of mass for the droplet of this hit.
    [C,~]=setdiff(set_hits,[row column],'rows');%remove ith central hit
    set_hits=C;
    
    end 
    i=i+1;
end
% identify droplets with shared pixels
   
 dropsum=sum(ndrop);%total no of pixels for this shot 
 toc
 end
    
    
    
        
    
    
    
    
    
    
    
    
        
        
        
        
    
    
    
    
    
    
    
    
    



% A=zeros(size(imo,1),size(imo,2));
% 
% A(1:3,1:3)=1;
% c=1;C=zeros(10,10);
% for i=0:8
%     for j=0:8
%         C(:,:,c)=circshift(A,[i,j]);
%         c=c+1;
%     end
% end
% % A=rand(10,10)



    
    
