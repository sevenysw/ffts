addpath E:\matlab\NFFT\Daqing\matlab-nfft-3.3.2-core2-openmp\nfft;

X = rand(100,1) * 4 * pi;
V = sin(X) + sin(X*2);
Xq = linspace(0, 4 * pi , 65); Xq=Xq(1:end-1);

Fq = ffts(X,V,Xq,'grid','bspline');
Fq_alt = ffts(X,V,Xq,'fit');
Fq_nfft = nfft1d_wrap(X,V,64)/2;

Vground = sin(Xq) + sin(Xq*2);
Fground = fftshift(fft(ifftshift(Vground)));

figure,
subplot(2,1,1), hold on;
  plot(X,V,'r.'); 
  plot(Xq,Vground,'b');
  legend('scattered data','ground truth data');
subplot(2,1,2), hold on;
  plot(abs(Fq),'r','LineWidth',2); 
  plot(abs(Fq_alt),'g','LineWidth',2); 
  plot(abs(Fq_nfft),'c--','LineWidth',2); 
  plot(abs(Fground),'b');
  legend('Fourier scattered data','Fourier scattered data, alternative','NFFT','Fourier ground truth');
