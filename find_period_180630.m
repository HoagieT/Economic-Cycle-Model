%--------------------------------------------------------------------------
% ����˵��
% �ĳ������ڷ�������ͬ�����е�Ƶ�׼�ֵ�㣬�Ӷ��ҵ���ǿ����λ��
% �������ݸ�ʽ��һ��Ϊ���ڣ���2-n��Ϊ�������̼�
% ����period_mean_fft���ڻ������ף�����������ֵ�洢�ڱ���T��
%--------------------------------------------------------------------------
clear; clc; close all;
% ��ȡ����
workdir = '.\';
cd(workdir)
[num, ~,raw] = xlsread('m1.xlsx',1);
index_name = raw(1,2:end);
fft_size = 1024*4;
index = 1;
% ��ȡָ��ͬ������
seq = num(1:end,index);
seq_log = seq;
dseq_log = detrend(seq_log); %ȥ������


% ��FFT�任��������0��������0��Ϊ������Ƶ��ֱ��ʣ����ڸ���׼����ȡ������Ҫ�����ڷ���
freq_index = 0:1:fft_size-1;
freq_index(1:fft_size/2+1) = [0:1:fft_size/2]/fft_size;
freq_index(fft_size/2+2:end) = [-fft_size/2+1:1:-1]/fft_size;
data_fft = abs(fftshift(fft(dseq_log, fft_size)));
freq_index = fftshift(freq_index);
% ��ͼ
peak_num = 3;
[peaks,posi] = findpeaks(data_fft(fft_size/2:end),'NPeaks',peak_num,'SortStr','descend');
figure;
plot(freq_index(fft_size/2+1:end), data_fft(fft_size/2+1:end));
grid on
xlabel('Ƶ��(Hz)')
ylabel('����')
title(index_name{index},'FontSize',12,'FontWeight','bold')
set(gca,'Fontname','Monospaced');
set(gca,'FontSize',12,'box','off','FontWeight','bold')
display(index_name{index});
for i = 1:peak_num
    display(num2str(1/freq_index(posi(i)+fft_size/2-1)))
    text(freq_index(posi(i)+fft_size/2-1),peaks(i),['[',num2str(1/freq_index(posi(i)+fft_size/2-1)),',',num2str(round(peaks(i))),']'],'FontSize',12)
end
fprintf('\n');
T=period_mean_fft(dseq_log,fft_size,'��ծ');
title(index_name{index},'FontSize',12,'FontWeight','bold')






