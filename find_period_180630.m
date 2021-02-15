%--------------------------------------------------------------------------
% 程序说明
% 改程序用于分析数据同比序列的频谱极值点，从而找到最强周期位置
% 输入数据格式第一列为日期，第2-n列为数据收盘价
% 函数period_mean_fft用于画功率谱，核心周期数值存储在变量T中
%--------------------------------------------------------------------------
clear; clc; close all;
% 读取数据
workdir = '.\';
cd(workdir)
[num, ~,raw] = xlsread('m1.xlsx',1);
index_name = raw(1,2:end);
fft_size = 1024*4;
index = 1;
% 获取指数同比序列
seq = num(1:end,index);
seq_log = seq;
dseq_log = detrend(seq_log); %去趋势项


% 做FFT变换，并做补0操作，补0是为了提升频域分辨率，便于更精准的提取我们想要的周期分量
freq_index = 0:1:fft_size-1;
freq_index(1:fft_size/2+1) = [0:1:fft_size/2]/fft_size;
freq_index(fft_size/2+2:end) = [-fft_size/2+1:1:-1]/fft_size;
data_fft = abs(fftshift(fft(dseq_log, fft_size)));
freq_index = fftshift(freq_index);
% 作图
peak_num = 3;
[peaks,posi] = findpeaks(data_fft(fft_size/2:end),'NPeaks',peak_num,'SortStr','descend');
figure;
plot(freq_index(fft_size/2+1:end), data_fft(fft_size/2+1:end));
grid on
xlabel('频率(Hz)')
ylabel('幅度')
title(index_name{index},'FontSize',12,'FontWeight','bold')
set(gca,'Fontname','Monospaced');
set(gca,'FontSize',12,'box','off','FontWeight','bold')
display(index_name{index});
for i = 1:peak_num
    display(num2str(1/freq_index(posi(i)+fft_size/2-1)))
    text(freq_index(posi(i)+fft_size/2-1),peaks(i),['[',num2str(1/freq_index(posi(i)+fft_size/2-1)),',',num2str(round(peaks(i))),']'],'FontSize',12)
end
fprintf('\n');
T=period_mean_fft(dseq_log,fft_size,'国债');
title(index_name{index},'FontSize',12,'FontWeight','bold')






