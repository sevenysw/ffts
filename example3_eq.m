addpath E:\matlab\NFFT\Daqing\matlab-nfft-3.3.2-core2-openmp\nfft;

N = 1000;
X = rand(N,1) * 4 * pi;
Y = rand(N,1) * 4 * pi;
Z = rand(N,1) * 4 * pi;
V = sin(X+Y+Z) + sin(X*2+Y*2+Z*2) ;
Xq = linspace(0, 4 * pi , 65); Xq=Xq(1:end-1);
Yq = linspace(0, 4 * pi , 65); Yq=Yq(1:end-1);
Zq = linspace(0, 4 * pi , 65); Zq=Zq(1:end-1);

scatter3(X,Y,Z,5,V);title('Scatter data');axis([0 4*pi 0 4*pi 0 4*pi]);
Fq = ffts3(X,Y,Z,V,Xq,Yq,Zq,'grid','bspline');
seishow3D(abs(Fq));title('Convolutional method')
figure,plot(sort(abs(Fq(:)),'descend'));title('Coefficient Distribution');
Fq_nfft = nfft3d_wrap([X Y Z],V,64,64,64)/8;

seishow3D(abs(reshape(Fq_nfft,[64,64,64])));title('NFFT method')