%% Liam Peterson
% Auto-Find Signal Region
%% Function

function [signal, background,data, LB, UB]=sigfind(file_name, t_um)
%% Call your data from a .csv
data=readmatrix(file_name); % import the raw data, column 1 is wavenumber, column 2 is absorbance
%% Trim data to spectral region that includes water peaks
data=data(data(:,1)>=3000,:);
data=data(data(:,1)<=4000,:);
if min(data(:,2))<0 % If the global minimum of the data is less than zero, this shifts the spectra vertically so that the global minimum is zero
    v_shift=abs(min(data(:,2)));
    data(:,2)=data(:,2)+v_shift;
end
if data(1,1)>data(length(data),1)
    data=flip(data);
end

%% Correct the Signal Absorbance to 1 cm thickness
data(:,2)=(data(:,2).*10^4)./t_um;

data(:,2)=data(:,2)-min(data(:,2)); % shift the data to the x-axis

%% Find the Rubber Banding Points under the Spectra
rband=convhull(data(:,1),data(:,2)); % Finds the convex hull of the data
id=find([diff(rband)]<0); % finds the upper part of the convex hull that is above the data
rband(id(1)+1:length(rband))=[]; %removes upper part of convex hull to leave baseline

%% Create Linear Interpolation Between Rubber Banding Points
Y(:,1)=data(:,1);
f(:,:)=NaN(length(rband),2);
for i=1:length(rband)-1
    coefficients = polyfit([data(rband(i),1),data(rband(i+1),1)], [data(rband(i),2), data(rband(i+1),2)], 1);
    f(i,1) = coefficients (1);
    f(i,2) = coefficients (2);
    Y(rband(i):rband(i+1),2)=polyval(coefficients,data((rband(i):rband(i+1))));
    %Y(rband(i):rband(i+1),2)=data((rband(i):rband(i+1))).*f(i,1)+f(i,2);
end
rubberband=Y;
%% Find the max peak height (M)
% Because no smoothing is done, the max peak height will be found relative
% to the rubber banding baseline
tmp=data(:,2)-Y(:,2);
[M, M_idx]=max(tmp);
mx=islocalmax(data(:,2));

%% Create Array of all Data Greater than 5% of max peak height
p1_sig=find(tmp>0.05*M); % Gives indices of >5% max peak height
sig_tmp=find(islocalmax(data(p1_sig,2))); %finds indices of local maxima in p1_sig
sig_tmp=p1_sig(sig_tmp); % Indices of major peaks
[Mr, Mr_idx]=max(data((sig_tmp),1)); % Mr_idx is the location of the right-most peak
Mr_idx=sig_tmp(Mr_idx); % returns the index of the right-most peak in the primary data file
[Ml, Ml_idx]=min(data((sig_tmp))); % Ml_idx is the location of the left-most peak
Ml_idx=sig_tmp(Ml_idx);

%% Smooth Data to remove "kinkiness" and find minima and inflection points
%%to right of Mr and left of Ml
%NOTE: smoothing is important as it will allow the code to work around
%small double peaks, without this the code may get stuck on small
%shoulders. We use a sufficiently large span to smooth the data without removing peak information.
smth=smooth(data(:,2),20,'rloess'); % this method is chosen as it reduces outlier effects
% Find Minima
min_idx=islocalmin(smth); % finds local minima and records as logical values
min_idx=find(min_idx==1); % returns the indices of the local minima
% Find Inflection Points (uses 2nd derivative)
dydx = gradient(smth) ./ gradient(data(:,1));                            
ddydx=gradient(dydx)./gradient(data(:,1));
inflp_idx=find(ddydx(1:end-1)>0 & ddydx(2:end) < 0);

%% Find min or infl. point immediately to the left of Ml
% Find closest minima
a=find(data(min_idx,1)<data(Ml_idx,1)); % finds all indices of minima to the left of Ml
a=min_idx(a); % returns the values of the indices relative to the original data
if a~[]
    a2=a(length(a));
end
if isempty(a)==1
    a2=NaN;
end
% for i=1:length(min_idx)
%     if data((min_idx(i)),1)<data(Ml_idx,1)
%         a(i)=min_idx(i)
%     else a(i)=NaN;
%     end
% end
% a(isnan(a))=[];
% if a~=[]
%     a2=a(length(a)); % pulls the last value of a which should be the closest minima to the left of Ml based on the above syntax
% else a2=NaN
% end
% Find closest inflection point (shift 20 cm^-1 to move off shoulders)
% for i=1:length(inflp_idx)
%     if data(inflp_idx(i),1)<data(Ml_idx,1)
%         b(i)=inflp_idx(i)
%     else b(i)=NaN;
%     end
% end
% b(isnan(b))=[];
% if b~=[]
%     b2=b(length(b));
% else b2=NaN
% end
    
b=find(data(inflp_idx,1)<data(Ml_idx,1)); % finds all indices of minima to the left of Ml
b=inflp_idx(b); % returns the values of the indices relative to the original data
b2=b(length(b)); % pulls the last value of a which should be the closest minima to the left of Ml based on the above syntax
B=data(b2)-20; % find wavenumber 20 cm^-1 to the left
Bb=abs(data(:,1)-B);
[~, bb_idx]=min(Bb);

% If a minima is present, select the minima; if not, select the inflection point
if ~isnan(a2)
    LB=a2;
    else LB=bb_idx;
end

%% Find max or infl. point immediately to the right of Mr
% Find closest minima
a=find(data(min_idx,1)>data(Mr_idx,1)); % finds all indices of minima to the right of Mr
a=min_idx(a); % returns the values of the indices relative to the original data
if a~[]
    a2=a(1); % pulls the last value of a which should be the closest minima to the left of Ml based on the above syntax
end
if isempty(a)==1
    a2=NaN;
end 
% Find closest inflection point (shift 20 cm^-1 to move off shoulders)
b=find(inflp_idx>Mr_idx); % finds all indices of minima to the left of Ml
b=inflp_idx(b); % returns the values of the indices relative to the original data
b2=b(1); % pulls the last value of a which should be the closest minima to the left of Ml based on the above syntax
B=data(b2)+20; % find wavenumber 20 cm^-1 to the left
Bb=abs(data(:,1)-B);
[~, bb_idx]=min(Bb);

% If a minima is present, select the minima; if not, select the inflection point
if ~isnan(a2)
    UB=a2;
    else UB=bb_idx;
end

%% Adjust LB and UB to the nearest Anchor point of the Convex Hull
[~, timon]=min(abs(rband-LB));
LB=rband(timon);
[~, pumbaa]=min(abs(rband-UB));
UB=rband(pumbaa);

%% Create a matrix of just the signal
signal=data(LB:UB,:);

%% Create a matrix of the background
background_L=data(1:LB,:);
background_R=data(UB:length(data(:,1)),:);
background=zeros(length(background_L(:,1))+length(background_R(:,1)),2);
background((1:length(background_L(:,1))),:)=background_L;
background(((length(background_L(:,1))+1):length(background)),:)=background_R;
%% Add any Anchor Points of Convex Hull within LB and UB to the background
for i=1:length(rband)
    if rband(i)>LB & rband(i)<UB
        background(rband(i),:)=data(rband(i),:);
    end
end
background(background(:,1)==0,:)=[];
[C, ia, ic]=unique(background(:,1));
background=background(ia,:);
