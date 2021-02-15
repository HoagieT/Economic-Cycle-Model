function [d_a_seq,trend_a_seq,filter_result,predict_trend_seq,predict_result_temp,predict_result,period,regress_result] = regress_predict_output_f(seq,predict_len,pad_to_len,gauss_alpha,mean_flag,period_flag)
%regress_predict_output_f:�ø�˹�˲������Իع���������˲�Ԥ��ĺ���
% d_a_seq���������
% trend_a_seq:������
%filter_result���˲����
% predict_trend_seq��������Ԥ��
% predict_result_temp:������ع���
% predict_result�����е�Ԥ����
% predict_len:Ԥ��ĳ���
% period   ��˹�˲�Ŀ������
% regress_result:�ع鷽�̵Ĳ������
% predict_len  Ԥ�ⳤ�ȣ���λΪ��
% pad_to_len  ��0�󳤶ȣ���0��Ϊ������Ƶ�׷ֱ���
% gauss_alpha ��˹�˲��������Ƽ�����Ϊ1
% mean_flag  ����Ҷ�任ǰ�Ƿ�ȥ��ֵ 0:ԭ���� 1��ȥ��ֵ 2��ȥ������
% period_flag:����ʹ��0����42��100��200��or1������Ҷ�任Ѱ�ҳ�����ǰ�������� �粻����������42 100 200��ȫ
% regress_flag: �������ع�or������ع�
% ����� gauss_wave_predict
    if mean_flag ==0 
        d_a_seq = seq; % ȥ������֮������ݣ����в�
        trend_a_seq = seq - d_a_seq; %������+�����
        d_seq_len = length(d_a_seq);
        predict_trend_seq = zeros(d_seq_len + predict_len,1);
    elseif mean_flag == 1
        d_a_seq = seq - mean(seq);
        trend_a_seq = seq - d_a_seq; %������+�����
        d_seq_len = length(d_a_seq);
        predict_trend_seq = ones(d_seq_len + predict_len,1)*mean(seq);
    else
        d_a_seq = detrend(seq);
        trend_a_seq = seq - d_a_seq; %������+�����
        d_seq_len = length(d_a_seq);
        predict_trend_seq = nan(d_seq_len + predict_len,1);
        predict_trend_seq(1:d_seq_len) = trend_a_seq;  
        predict_trend_seq  = interpolation(predict_trend_seq ); 
    end
    if strcmp(period_flag,'�̶�����') == 1
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
    %�ڶ���ͬ������ǰ�油0������Ƶ��ֱ���
    d_seq_pad = zeros(pad_to_len,1);
    d_seq_pad(end-d_seq_len+1:end) = d_a_seq;
    %��˹�˲���ȡ�����ڶ�Ӧ�������Լ�Ԥ����
    filter_result = zeros(pad_to_len + predict_len, size(period,2));
    for iPeriod = 1:size(period,2)
        filter_result(:,iPeriod) = gauss_wave_predict(d_seq_pad, period(iPeriod), pad_to_len,predict_len, gauss_alpha)';
    end
    filter_result = filter_result(end-(d_seq_len+predict_len)+1:end,:);
    
    Y = d_a_seq;
    regress_result = zeros(4,6);
    % �������ع�
    for iPeriod =1:size(period,2)
        X = [ones(d_seq_len,1) filter_result(1:d_seq_len,iPeriod)];
        [b, ~, ~, ~, stats] = regress(Y, X);
        regress_result(iPeriod,1:2) = b;
        regress_result(iPeriod,5:6) = stats([1 3]);
    end
    % ������ع�
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
% ��˹�˲���ȡ�ض����ڳɷ֣�ͨ��ǰ���������ֱ���,2018.1�޸� �����ٶ�
% [����]
% wave��       �������У�Ϊ������
% period��     ��Ҫ��ȡ�����ڳ��ȣ���λΪ��
% n_fft��      FFT���ȣ�Ҳ����0��ĳ���
% n_predict��  ����Ԥ��ĳ���
% gauss_alpha����˹�˲�������
% [���]
% output���˲���ȡ��Ŀ�����ڳɷ֣�����Ϊ���볤��+n_predict
% -------------------------------------------------------------------------

% 1�����0
wave_pad = [zeros(n_fft-length(wave),1); wave];

% 2������FFT�任
wave_fft = fft(wave_pad, n_fft);

% 3�����ɸ�˹�˲�Ƶ����Ӧ��ע������ֻ�̻��˵�Ƶ���֣�����������Գƴ���
gauss_index = 1:n_fft;
center_frequency = n_fft / period + 1;
gauss_win = exp(-(gauss_index - center_frequency).^2 / gauss_alpha^2)';

% 4��Ƶ���˲�����Ϊʱ��Ϊʵ��������Ƶ�������й���ԳƵ�����
wave_filter = wave_fft .* gauss_win;
if mod(n_fft,2)==0
    wave_filter((n_fft/2+2):n_fft)=conj(wave_filter((n_fft/2):-1:2));
else
    wave_filter((n_fft-1)/2+2:n_fft)=conj(wave_filter((n_fft-1)/2+1:-1:2));
end

% 5���渵��Ҷ�任�õ�ʱ��ԭ���У�����Ԥ�Ȿ��������������ֵ����
ret = real(ifft(wave_filter));
output = [ret(end-length(wave)+1:end); ret(1:n_predict)];
    
end

function  [y2]  = interpolation( data )
% ��ֵ�����������Բ����м�����ȱʧ��ָ������ȫ
%   ��Ҫʹ��matlab�Դ���interp1�������ֶ�����hermite��ֵ
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

