function Fq = ffts3(X,Y,Z,V,Xq,Yq,Zq,method,window)
% FFTS, Performs the fast fourier transform (FFT) on scatter data. 
%
%    Yq = ffts(X,V,Xq)
%
%     or
%   
%    Yq = ffts(X,V,Xq, method, window)
%
%  inputs,
%       X : Array with positions [m x 1]
%       V : Array with values    [m x 1]
%       Xq : Node locations [ n x 1], with equally spaced points (see linspace)
%     (optional)
%       method : 1. 'grid', gridding (Default)
%                2. 'fit' , b-spline fit
%       window : 1. 'bspline', bspline (default)
%                2. 'kaiser', kaiser Bessel function
%
%  outputs,
%       Fq : The Fourier spectrum of the scatter data [ n x 1].
%
%
% Gridding:
%   1. The scatterd values (V) at positions (X) are smoothed ( convolution ) 
%      by a kernel to a regular grid. With the grid a 2 times oversampled 
%      version of Xq
%   2. The data is  multiplied with a set of density compensation weights.
%      Calculate as in step 1, but instead all values are set to 1. The 
%      density compensation is 1 divided by this result.
%   3. The values on the regular grid are converted to the fourier 
%      domain using a FFT.
%   4. Trim field of view, to size of Xq. This compensates the oversampling
%      of step 2. The sidelobes due to finite window size are now
%      clipped off.
%   5. The fourier domain is multipled by an apodization correction
%      function. Which is the 1/Fourier Transform of the kernel of step 1
%      to remove the effect of the kernel.
% 
% B-spline fit:
%   1. B-splines sampled on a regular grid are fitted to the values (V) at
%      positions (X), so they least squares approximate the data.
%   2. At the regular grid (Xq), values are interpolated using the fitted
%      B-splines
%   3. The FFT is done on the b-spline interpolated points
%
%
%  Example,
%    X = rand(1000,1) * 4 * pi;
%    V = sin(X) + sin(X*2);
%    Xq = linspace(0, 4 * pi , 65); Xq=Xq(1:end-1);
%
%    Fq = ffts(X,V,Xq,'grid','bspline');
%    Fq_alt = ffts(X,V,Xq,'fit');
%
%    Vground = sin(Xq) + sin(Xq*2);
%    Fground = fftshift(fft(ifftshift(Vground)));
%
%    figure,
%    subplot(1,2,1), hold on;
%       plot(X,V,'r.'); 
%       plot(Xq,Vground,'b');
%       legend('scattered data','ground truth data');
%    subplot(1,2,2), hold on;
%       plot(abs(Fq),'r','LineWidth',2); 
%       plot(abs(Fq_alt),'g','LineWidth',2); 
%       plot(abs(Fground),'b');
%       legend('Fourier scattered data','Fourier scattered data, alternative','Fourier ground truth');
%   
%
%  See also fft
%
% This method is written by D. Kroon at Focal, December 2014.

% Input check
if((~ismatrix(V))||(~ismatrix(X))||(size(X,1)~=size(V,1))||(size(X,2)~=size(V,2))||(numel(X)~=length(X)))
    error('ffts: X and V have not dimensions m x 1');
end

% Input check
if(length(Xq)<2)
    error('ffts: Xq must at least contain two points');
end
if(numel(Xq)~=length(Xq))
    error('ffts: Xq must be an array of n x 1 poitns');
end
crange=Xq(2:end)-Xq(1:(end-1));
if((max(crange)-min(crange))> 1e-10)
    error('ffts: Points in Xq must be equally spaced');
end

if(nargin<4)
    method = 'grid';
end

if(nargin<5)
    window = 'bspline';
end

% Transform inputs (row vectors) to column vectors.

V  = V(:);
X  = X(:);
Y  = Y(:);
Z = Z(:);
Xq = Xq(:);
Yq = Yq(:);
Zq = Zq(:);

    
% Do the convolution of the scattered points to the regular spaced grid
switch(method)
    case 'grid'
        % Calculate the spacing between the b-spline nodes
        SpacingX = mean(Xq(2:end)-Xq(1:(end-1)));
        SpacingY = mean(Yq(2:end)-Yq(1:(end-1)));
        SpacingZ = mean(Zq(2:end)-Zq(1:(end-1)));
        % Upsampled version of Xq
        Xql = linspace(Xq(1),Xq(end)+(SpacingX/2),length(Xq));
        Yql = linspace(Yq(1),Yq(end)+(SpacingY/2),length(Yq));
        Zql = linspace(Zq(1),Zq(end)+(SpacingZ/2),length(Zq));
        % Calculate B-spline interpolation weights
%         [W, index] =Interpolation_Weights(X,Xql,window);
        [Wx, indexx] =Interpolation_Weights(X,Xql,window);
        [Wy, indexy] =Interpolation_Weights(Y,Yql,window);
        [Wz, indexz] =Interpolation_Weights(Z,Zql,window);
        % Construct new 2d W
        for i=1:size(Wx,1)
            W(i,:) = kron(kron(Wx(i,:),Wy(i,:)),Wz(i,:));
            [xp,yp,zp] = meshgrid(indexx(i,:),indexy(i,:),indexz(i,:));
            index(i,:) = sub2ind([length(Xql),length(Yql),length(Zql)],xp(:),yp(:),zp(:));
        end
        % Construct new 2d index
        % Convolution
        WV  = bsxfun(@times, W,V);
        num = accumarray(index(:), WV(:),[length(Xql)*length(Yql)*length(Zql),1]);

        % Sample density function
        dnum = accumarray(index(:), W(:),[length(Xql)*length(Yql)*length(Zql),1]);
        
        % Remove zeros
        ind = abs(dnum)<eps;
        dnum(ind)=eps;

        Vq = num./dnum;
    case 'fit'
        % Calculate B-spline interpolation weights
        [W, index] =Interpolation_Weights(X,Xq,'bspline');
        % Least-squares approximate the data by b-splines on a regular grid
        Vq = InvMatrixFit(index,W,Xq,V);
    otherwise
        error('ffts: Unknown method');
end

% Go to the fourier domain
Vq2 = reshape(Vq,[length(Xql),length(Yql),length(Zql)]);

Fq2 = fftshift(fftn(ifftshift(Vq2)));
 

switch(method)
    case 'grid'
        % Make apodization correction function
        if(mod(length(Xql),2)==0)
             wx = linspace(-0.5,0.5,length(Xql)+1);  wx=wx(1:end-1);
             wy = linspace(-0.5,0.5,length(Yql)+1);  wy=wy(1:end-1);
             wz = linspace(-0.5,0.5,length(Zql)+1);  wz=wz(1:end-1);
        else
             wx = linspace(-0.5,0.5,length(Xql));
             wy = linspace(-0.5,0.5,length(Yql));
             wz = linspace(-0.5,0.5,length(Zql));
        end
        [wx,wy,wz] = meshgrid(wy,wx,wz);
        switch(window)
            case 'bspline'
                % ^4 because we use a cubic spline.
                Ys = sincc(wx*pi).^4.* sincc(wy*pi).^4.* sincc(wz*pi).^4.;
            case 'kaiser'
                cb = 5.7567;
                cw = 4;
                c1 = sqrt(pi^2 * cw^2 * w.^2 - cb^2);
                Ys = sin(c1)./c1;
                Ys = Ys./27.4721;
            otherwise
                error('ffts: Unknown window function');
        end

        % Compensate for the b-spline smoothing
        Fq = Fq2./Ys;
    case 'fit'
    otherwise
        error('ffts: Unknown method');
end

% Trim fourier domain
Fq = TrimFourier(Fq,length(Xq),length(Yq),length(Zq));

end

% This function trims an upsampled fourier transformed signal
% to go back to the original  (downsampled) fourier domain.
function F_trimmed = TrimFourier(F,num,numy,numz)
    if(num == size(F,1))
        F_trimmed = F;
    else
        zf = ceil((size(F,1)+1)/2);
        if(floor(num/2)==ceil(num/2))
            F_trimmed = F(zf + (((-num/2)):((num/2)-1)),zf + (((-numy/2)):((numy/2)-1)),zf + (((-numz/2)):((numz/2)-1)))* num^3/numel(F);
        else
            F_trimmed = F(zf + (((-(num-1)/2)):(((num-1)/2))),zf + (((-(numy-1)/2)):(((numy-1)/2))),zf + (((-(numz-1)/2)):(((numz-1)/2)))) * num^3/numel(F);
            acx = -linspace(-pi/2,pi/2,size(F,1)+1); acx= acx(1:end-1);
            acy = -linspace(-pi/2,pi/2,size(F,2)+1); acy= acy(1:end-1);
            acz = -linspace(-pi/2,pi/2,size(F,2)+1); acz= acz(1:end-1);
            [acx,acy,acz] = meshgrid(acx,acy,acz);
            F_trimmed =F_trimmed.* (1i*sin(acx+acy+acz) + cos(acx+acy+acz));
        end
    end
end




function [W, index] =Interpolation_Weights(X,Xq,window)
    %% Bspline Fitting

    % Calculate the spacing between the b-spline nodes
    Spacing = mean(Xq(2:end)-Xq(1:(end-1)));

    % calculate which is the closest point on the lattic to the left
    % and find ratio's of influence between lattice point.
    gx  = floor((X(:)-Xq(1))/Spacing); 

    % Calculate b-spline coordinate within b-spline cell, range 0..1
    ax  = (X(:)-gx*Spacing)/Spacing;

    % Matlab index start at 1
    gx = gx + 1;

    % Make bspline_coefficients
    switch(window)
        case 'bspline'
            W = bspline_coefficients_1d(ax);
        case 'kaiser'
            W = kaiser_coefficients_1d(ax);
        otherwise
            error('ffts: Unknown window function');
    end
        

    % Make indices of all neighborh knots to every point
    ix = (-1:2)';
    index=repmat(gx,[1 4])+repmat(ix',[length(X) 1]); 

    % Limit indices, to boundaries of the nodes. Note we use a FFT thus
    % which implicitly assumes that the input array is periodic.
    % Therefore we use circular boundary conditions;
    index = mod(index-1, length(Xq))+1;

    if(length(unique(index))<length(Xq))
        warning('ffts: Some nodes have no nearby data points, use less nodes or more data');
    end
end

  
function Vq = InvMatrixFit(index,W,Xq,V)
    % Make matrix
    M = sparse((1:numel(index))',index(:),W(:),numel(index),length(Xq));
    M = M(1:length(V),:) + M((length(V)+1):(2*length(V)),:) + M((2*length(V)+1):(3*length(V)),:) + M((3*length(V)+1):end,:) ;

    % Regularize inverse, by adding
    % error term : (uy * 1e-10 ).^2 .
    % this will prevent uy from having infinity values if ill-posed
    M = [M;sparse(1:length(Xq),1:length(Xq),1e-10)];
    V = [V;zeros(length(Xq),1)];

    % Fit knots (solve least-squares inverse problem)
    uy = full(M \ sparse(V));

    % Calculate the interpolated values on the regular grid.
    Spacing = mean(Xq(2:end)-Xq(1:(end-1)));
    gx  = floor((Xq(:)-Xq(1))/Spacing); 
    ax  = (Xq(:)-gx*Spacing)/Spacing;
    gx = gx + 1;
    W = bspline_coefficients_1d(ax);
    ix = (-1:2)';
    index=repmat(gx,[1 4])+repmat(ix',[length(Xq) 1]); 
    index = mod(index-1, length(Xq))+1;
    Vq = sum(W.*uy(index),2);
end

function y = sincc (x)
    ind = x==0;
    x(ind) = eps;
    y = sin(x)./(x);
    y(ind) = 1;
end


function W = bspline_coefficients_1d(u)
    W(:,1) = (1-u).^3/6;
    W(:,2) = ( 3*u.^3 - 6*u.^2+ 4)/6;
    W(:,3) = (-3*u.^3 + 3*u.^2 + 3*u + 1)/6;
    W(:,4) = u.^3/6;
end


function W = kaiser_coefficients_1d(u)
    W(:,1) =  u.^3* 0.8324 + u.^2 * 3.2606 + u *-10.4465 + 6.3421;
    W(:,2) =  u.^3* 3.7616 + u.^2 *-10.8568+ u * 0.1994  + 13.2025;
    W(:,3) =  u.^3*-3.7616 + u.^2 * 0.2023 + u * 10.2420 + 6.5115;
    W(:,4) =  u.^3*-0.8324 + u.^2 * 5.7077 + u * 1.6575  + 0.0194;
    W = W * (1/ 26.0765);

end


