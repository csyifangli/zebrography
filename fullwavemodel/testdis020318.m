% %adaptive_results_020918.mat
% z_sv = cumsum(zvec);
% ind = find(abs(z_sv-foc) < 0.5*foc);
apaz = apaz_sv;
nX = size(apaz,1);
% z_sv = z_sv(ind);
%% shift in z
nT = size(apaz_sv,2);
apaz = reshape(apaz,[587,1,nT,size(apaz,3)]);
zPos = z_sv;
tShift = zPos/c0; % time shifts (position/(m/s) = s)
apaz(isnan(apaz)) = 0;
clear apaz_sv
apaz = squeeze(apaz);
%%
apaz(:,size(apaz,2)+1:5000,:) = 0;

%%
sig = squeeze(max(max(apaz,[],2),[],1));
nn = find(sig == max(sig));
display(nn);
z_svnew = [flip(z_sv(nn):-dZ:z_sv(1)),z_sv(nn)+dZ:dZ:z_sv(end)];
apaznew = permute(interp1(z_sv,permute(apaz,[3 2 1]),z_svnew,'PCHIP',0),[3 2 1]);
for ii = 1:size(apaznew,3)
    apaz_shifted(:,:,ii) = circshift(squeeze(apaznew(:,:,ii)),[0 10*ii]);%permute(interp1((t+tShift(ii))',permute((apaz(:,:,:,ii)),[3 2 1 ]),tTarg','spline',0),[3 2 1]);
%       apaz_shifted(:,:,:,ii) = permute(interp1((t+tShift(ii))',permute((apaz(:,:,:,ii)),[3 2 1 ]),tTarg','spline',0),[3 2 1]);
%     apaz_shifted(:,:,ii) = interp1((t+tShift(ii))',squeeze(apaz_sv(:,:,ii))',tTarg','spline');%,0);
end
%% get an US cycle
sig = squeeze(max(max(apaz_shifted,[],2),[],1));
nn = find(sig == max(sig));
tmp = squeeze(apaz_shifted(294,:,nn));
tt = find(tmp == max(tmp(:))):find(tmp == max(tmp(:)))+40;
% tt = 2739:2779;
P = apaz_shifted(:,tt,:);
plot(squeeze(P(294,:,nn)));
clear apaz_shifted;
clear Pori
%% interpolate 2D to 3D profile using interp1
P = reshape(P,size(P,1),1,size(P,2),size(P,3));
cen = round([size(P,1),size(P,1)]/2);
[y1,x1] = meshgrid(1:587,1:587);
d = (sqrt((x1-cen(1)).^2+(y1-cen(2)).^2))*dX;
r =(-floor(nX/2):floor(nX/2))*dX;
d(d>293) = -1;
Pb = P;
clear P;
Pnew = zeros(size(Pb,1),size(Pb,1),size(Pb,3),size(Pb,4));
for ii = 1:size(Pnew,3) % time dimension
    for jj = 1:size(Pnew,4) % z dimension
    Pnew(:,:,ii,jj) = interp1(r,squeeze(Pb(:,1,ii,jj)),d,'spline',0);
    end
end
%% central finite differencing 
n = 4; %accuracy
A = zeros(n+1,n+1);
for ii = 1:n+1
    A(ii,:) = (-n/2:n/2).^(ii-1);
end
c = A\[0;1;zeros(n-1,1)];
n0 = 1.3325; % base index of refraction
% m, distance from center of US focus to background
Zd = 17.061e-2/2;
dn0dp = (1.3475-1.3325)/((1100-1)*100000); % dindex/dPascal, from Waxler paper, read from Figure 2 at 24.8 deg CSS
proj = sum(Pnew,2)*dX; % integrate through line of sight
nt = size(proj,3);
dz = zeros(size(proj));
% loop through z-positions and calculated centered differences
for i = 1+n/2:length(z_svnew)-1-n/2
    for j = 1:size(proj,1)
    dz(j,:,:,i) = Zd*1/n0*dn0dp*squeeze(proj(j,:,:,i-n/2:i+n/2))*c/dZ;
    end
end
dx = zeros(size(proj));
% loop through x-positions and calculated centered differences
for i = 1+n/2:size(proj,1)-1-n/2
    for j = 1:length(z_svnew)
    dx(i,:,:,j) = Zd*1/n0*dn0dp*c'*squeeze(proj(i-n/2:i+n/2,:,:,j))/dX;
    end
end

%% for real img
ds = 3e-3/16/7;

locx = (squeeze(round(dx/(ds))));
locz = (squeeze(round(dz/(ds))));

locxd = flip(locx,3);   %displacements for locations
loczd = -flip(locz,3);
% locxd = 1.2*locx;
% loczd = 1.2*locz;
nz = size(loczd,3);
nt = size(loczd,2);
nn1 = round(dX/ds);
nn2 = round(dZ/ds); 
xloc = kron(ones(nn1,1),1:587);
zloc = kron(ones(nn2,1),1:nz);
xloc = xloc(:);
zloc = zloc(:);
[zo,xo] = meshgrid(1:nz,1:587);
[zz,xx] = meshgrid(zloc,xloc);
% [xo,zo] = meshgrid(1:587,1:nz);
% [xx,zz] = meshgrid(xloc,zloc);
locxx =[];
loczz = [];
for ii = 1:nt
    locxx(:,ii,:) = interp2(zo,xo,squeeze(locxd(:,ii,:)),zz,xx);
    loczz(:,ii,:) = interp2(zo,xo,squeeze(loczd(:,ii,:)),zz,xx);
end
% locxx = flip(locxx,3);
[zzz,xxx] = meshgrid(1:length(zloc),1:length(xloc));
xdisloc = round(repmat(reshape(xxx,size(xxx,1),1,size(xxx,2)),1,nt,1)+locxx);
zdisloc = round(repmat(reshape(zzz,size(zzz,1),1,size(zzz,2)),1,nt,1)+loczz);
%caculate coordinates for each pixel at each time point

%%
img = imread('./2018_02_09/IMG_0021.CR2');
partimg = double(img(1+153:length(xloc)+153,1+1681:length(zloc)+1681,:));
nX = size(locxd,1); nZ = size(locxd,3);
nt = size(locxd,2);
nn1 = round(dX/ds);
nn2 = round(dZ/ds); 
histmp = [];
img = zeros(size(partimg));
tmp = zeros(size(xdisloc,1),size(zdisloc,3));
for kk = 1:nt
    ind = sub2ind([size(xdisloc,1),size(zdisloc,3)],squeeze(xdisloc(:,kk,:)),squeeze(zdisloc(:,kk,:)));
    tab = tabulate(ind(:)); % find how many pixels move to the same location 
    times = tab(:,2);
    tmp = tmp + reshape((times==0),size(xdisloc,1),size(zdisloc,3));
    bkg = double(partimg);
    img = zeros(size(bkg));
    for ii = 1:nX
       for jj = 1:nZ
           block = bkg((1:nn1)+(ii-1)*nn1,(1:nn2)+(jj-1)*nn2,:); % block with the same displacements
%            bkg((1:nn1)+(ii-1)*nn1,(1:nn2)+(jj-1)*nn2,:) = 0;
           indx = round((1:nn1)+(ii-1)*nn1+locxd(ii,kk,jj)); % apply displacements and get the shifted locations
           indz = round((1:nn2)+(jj-1)*nn2+loczd(ii,kk,jj));
           [tz,tx] = meshgrid(indz,indx);  
           indind = sub2ind([nX*nn1,nZ*nn2],tx,tz);   
           ttimes = reshape(tab(indind(:),2),nn1,nn2);   
           %if ttimes>1 divide it by times to get the sum of pixels which
           %are shifted to the same location 
           img(indx,indz,:) = img(indx,indz,:)+block./repmat(ttimes,1,1,3);
       end
    end
    histmp(:,:,:,kk) = img;%bkg;
end
tmp = nt - tmp;
imshow(flip(uint8(sum(histmp,4)./tmp),2));
% saveas(gcf,'./simuimg_00410228.jpg');