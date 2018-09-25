addpath E:\matlab\NFFT\Daqing\matlab-nfft-3.3.2-core2-openmp\nfft;

N = 1000;
X = rand(N,1) * 4 * pi;
Y = rand(N,1) * 4 * pi;
V = sin(X+Y) + sin(X*2+Y*2) ;
Xq = linspace(0, 4 * pi , 65); Xq=Xq(1:end-1);
Yq = linspace(0, 4 * pi , 65); Yq=Yq(1:end-1);
figure,
subplot(131),scatter(X,Y,5,V);title('Scatter data');axis([0 4*pi 0 4*pi]);
Fq = ffts2(X,Y,V,Xq,Yq,'grid','bspline');
subplot(132),imagesc(abs(Fq));title('Convolutional method')

Fq_nfft = nfft2d_wrap([X Y],V,64,64)/4;

subplot(133),imagesc(abs(reshape(Fq_nfft,[64,64])));title('NFFT method')