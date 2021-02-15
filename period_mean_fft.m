function [T]=period_mean_fft(data,nfft,name)
%�ú���ʹ�ÿ��ٸ���Ҷ�任FFT��������ƽ�����ں����,���������ڣ�������ͼ
%data��ʱ�����У�ʵ��������
%T�����ؿ��ٸ���Ҷ�任FFT����������е�������������ֵ���Ӧ������
% nfft��������Ҷ�任ʱ�����ݵ�ĸ���
    [r,c]=size(data);
    if r<c
        data = data';
    end
    Y = fft(data,nfft);       %����FFT�任
    nfft = length(Y);    %FFT�任�����ݳ���
    Y(1) = [];           %ȥ��Y�ĵ�һ�����ݣ�������Ƶ����
    power = abs(Y(1:floor(nfft/2))).^2;  %������
    Amplitude = abs(Y(1:floor(nfft/2)));  %�����
    nyquist = 1/2;
    freq = (1:floor(nfft/2))/(floor(nfft/2))*nyquist; %��Ƶ�ʣ��ӵ�Ƶ����Ƶ����ߵ�Ƶ����nyquist,��͵�Ƶ����2/N
    period = 1./freq;                %��������
    % ��ͼ
    figure 
    plot(period,power); grid on ,hold on %�������ڣ����������� h
    ylabel('����')
    xlabel('����(��)')
    title([name,'-���ͼ']);
    % Ѱ�Ҽ���ֵ�㣬��������
    peak_num = 3;   
    [peaks,posi] = findpeaks(power,'NPeaks',peak_num,'SortStr','descend'); 
    T = round(period(posi));
    
    legend(sprintf('%.1f����,%.1f���£�%.1f����', T(1),T(2),T(3)'));
    for inum = 1:peak_num       
        display(num2str(period(posi(inum)))) 
        text(period(posi(inum)),peaks(inum),['[',num2str(period(posi(inum))),',',num2str(round(peaks(inum))),']'],'FontSize',12)
        plot(period(posi(inum)),peaks(inum),'ro');hold on;
        plot(period(posi(inum)),peaks(inum),'r*')
    end
    xlim([12 300]); % ȥ��300�������ϵĵ�Ƶ�ɷ�
end

