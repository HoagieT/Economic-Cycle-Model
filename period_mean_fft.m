function [T]=period_mean_fft(data,nfft,name)
%该函数使用快速傅里叶变换FFT计算序列平均周期和振幅,并画出周期，功率谱图
%data：时间序列，实数，向量
%T：返回快速傅里叶变换FFT计算出的序列的最大的三个极大值点对应的周期
% nfft：做傅里叶变换时的数据点的个数
    [r,c]=size(data);
    if r<c
        data = data';
    end
    Y = fft(data,nfft);       %快速FFT变换
    nfft = length(Y);    %FFT变换后数据长度
    Y(1) = [];           %去掉Y的第一个数据，它是零频分量
    power = abs(Y(1:floor(nfft/2))).^2;  %求功率谱
    Amplitude = abs(Y(1:floor(nfft/2)));  %求振幅
    nyquist = 1/2;
    freq = (1:floor(nfft/2))/(floor(nfft/2))*nyquist; %求频率，从低频到高频，最高的频率是nyquist,最低的频率是2/N
    period = 1./freq;                %计算周期
    % 画图
    figure 
    plot(period,power); grid on ,hold on %绘制周期－功率谱曲线 h
    ylabel('功率')
    xlabel('周期(月)')
    title([name,'-振幅图']);
    % 寻找极大值点，计算周期
    peak_num = 3;   
    [peaks,posi] = findpeaks(power,'NPeaks',peak_num,'SortStr','descend'); 
    T = round(period(posi));
    
    legend(sprintf('%.1f个月,%.1f个月，%.1f个月', T(1),T(2),T(3)'));
    for inum = 1:peak_num       
        display(num2str(period(posi(inum)))) 
        text(period(posi(inum)),peaks(inum),['[',num2str(period(posi(inum))),',',num2str(round(peaks(inum))),']'],'FontSize',12)
        plot(period(posi(inum)),peaks(inum),'ro');hold on;
        plot(period(posi(inum)),peaks(inum),'r*')
    end
    xlim([12 300]); % 去掉300个月以上的低频成分
end

