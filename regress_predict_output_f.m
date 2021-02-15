function [d_a_seq,trend_a_seq,filter_result,predict_trend_seq,predict_result_temp,predict_result,period,regress_result] = regress_predict_output_f(seq,predict_len,pad_to_len,gauss_alpha,mean_flag,period_flag)
%regress_predict_output_f:用高斯滤波和线性回归对数据做滤波预测的函数
% d_a_seq：趋势项处理
% trend_a_seq:趋势项
%filter_result：滤波结果
% predict_trend_seq：趋势项预测
% predict_result_temp:周期项回归结果
% predict_result：序列的预测结果
% predict_len:预测的长度
% period   高斯滤波目标周期
% regress_result:回归方程的参数输出
% predict_len  预测长度，单位为月
% pad_to_len  填0后长度，填0是为了提升频谱分辨率
% gauss_alpha 高斯滤波器带宽，推荐设置为1
% mean_flag  傅里叶变换前是否去均值 0:原数据 1：去均值 2：去趋势项
% period_flag:周期使用0：【42，100，200】or1：傅里叶变换寻找出来的前三个周期 如不足三个，用42 100 200补全
% regress_flag: 单变量回归or多变量回归
% 需调用 gauss_wave_predict
    if mean_flag ==0 
        d_a_seq = seq; % 去趋势项之后的数据，即残差
        trend_a_seq = seq - d_a_seq; %常数项+趋势项；
        d_seq_len = length(d_a_seq);
        predict_trend_seq = zeros(d_seq_len + predict_len,1);
    elseif mean_flag == 1
        d_a_seq = seq - mean(seq);
        trend_a_seq = seq - d_a_seq; %常数项+趋势项；
        d_seq_len = length(d_a_seq);
        predict_trend_seq = ones(d_seq_len + predict_len,1)*mean(seq);
    else
        d_a_seq = detrend(seq);
        trend_a_seq = seq - d_a_seq; %常数项+趋势项；
        d_seq_len = length(d_a_seq);
        predict_trend_seq = nan(d_seq_len + predict_len,1);
        predict_trend_seq(1:d_seq_len) = trend_a_seq;  
        predict_trend_seq  = interpolation(predict_trend_seq ); 
    end
    if strcmp(period_flag,'固定周期') == 1
        period = [39 56 89];
    else
        period = period_mean_fft(d_a_seq,pad_to_len,period_flag);
        if length(period) ==2
            period = [period,200];
        elseif length(period) == 1
            if period < 60
                period = [period,100,200];
            else
                period = [period,40,200];
            end
        end
    end
    period
    %在对数同比序列前面补0，提升频域分辨率
    d_seq_pad = zeros(pad_to_len,1);
    d_seq_pad(end-d_seq_len+1:end) = d_a_seq;
    %高斯滤波获取三周期对应的序列以及预测结果
    filter_result = zeros(pad_to_len + predict_len, size(period,2));
    for iPeriod = 1:size(period,2)
        filter_result(:,iPeriod) = gauss_wave_predict(d_seq_pad, period(iPeriod), pad_to_len,predict_len, gauss_alpha)';
    end
    filter_result = filter_result(end-(d_seq_len+predict_len)+1:end,:);
    
    Y = d_a_seq;
    regress_result = zeros(4,6);
    % 单变量回归
    for iPeriod =1:size(period,2)
        X = [ones(d_seq_len,1) filter_result(1:d_seq_len,iPeriod)];
        [b, ~, ~, ~, stats] = regress(Y, X);
        regress_result(iPeriod,1:2) = b;
        regress_result(iPeriod,5:6) = stats([1 3]);
    end
    % 多变量回归
    X = [ones(d_seq_len,1) filter_result(1:d_seq_len,:)];
    [b, ~, ~, ~, stats] = regress(Y, X);
    regress_result(4,1:4) = b;
    regress_result(4,5:6) = stats([1 3]);
    Y = d_a_seq;
    X = [ones(d_seq_len,1) filter_result(1:d_seq_len,:)];
    [b, ~, ~, ~, stats] = regress(Y, X);
    predict_result_temp = [ones(d_seq_len+predict_len,1) filter_result]*b;
    predict_result = [ones(d_seq_len+predict_len,1) filter_result]*b+predict_trend_seq;
end

function output = gauss_wave_predict(wave,period,n_fft,n_predict,gauss_alpha)
% -------------------------------------------------------------------------
% 高斯滤波提取特定周期成分，通过前向补零提升分辨率,2018.1修改 提升速度
% [输入]
% wave：       输入序列，为列向量
% period：     需要提取的周期长度，单位为月
% n_fft：      FFT长度，也即填0后的长度
% n_predict：  外延预测的长度
% gauss_alpha：高斯滤波器带宽
% [输出]
% output：滤波提取的目标周期成分，长度为输入长度+n_predict
% -------------------------------------------------------------------------

% 1、填充0
wave_pad = [zeros(n_fft-length(wave),1); wave];

% 2、进行FFT变换
wave_fft = fft(wave_pad, n_fft);

% 3、生成高斯滤波频率响应，注意这里只刻画了低频部分，后续做共轭对称处理
gauss_index = 1:n_fft;
center_frequency = n_fft / period + 1;
gauss_win = exp(-(gauss_index - center_frequency).^2 / gauss_alpha^2)';

% 4、频域滤波，因为时域为实数，所以频域序列有共轭对称的属性
wave_filter = wave_fft .* gauss_win;
if mod(n_fft,2)==0
    wave_filter((n_fft/2+2):n_fft)=conj(wave_filter((n_fft/2):-1:2));
else
    wave_filter((n_fft-1)/2+2:n_fft)=conj(wave_filter((n_fft-1)/2+1:-1:2));
end

% 5、逆傅里叶变换得到时域还原序列，外延预测本质上是在延拓主值序列
ret = real(ifft(wave_filter));
output = [ret(end-length(wave)+1:end); ret(1:n_predict)];
    
end

function  [y2]  = interpolation( data )
% 插值函数，用来对部分有季节性缺失的指标做补全
%   主要使用matlab自带的interp1函数，分段三次hermite插值
index = (1:length(data))';
indexa = find(~isnan(data));
indexnan = find(isnan(data));
y = data(indexa);
y1=interp1(indexa,y,indexnan,'PCHIP');
for i = 1:length(data)
    if ismember(i,indexa);
        y2(i) = y(find(indexa==i));
    else
        y2(i) = y1(find(indexnan==i));
    end
end
y2 = y2';
end

