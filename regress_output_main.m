clc,clear,close all,tic
%% 1、路径设置和参数设置
workdir = '.\';
savedir = '.\';
name='国债'; %可选变量：CPI、PPI、国债、商品房销售额、M1、M2、工业企业产成品库存，输入任意变量即可
readname = [name,'.xlsx'];
period_flag = '同比序列'; %中心频率选择方式：固定周期42，100，200 ；变化周期由傅里叶变换得出
savename = [savedir,name,char(period_flag),'24个月滤波预测.xls'];
cd(workdir);
sheetname = {'原始数据','同比序列','环比序列'};
nyoysheet = 0; %不是同比序列的sheet
predict_len = 24*1;     % 预测长度，单位为月
pad_to_len = 4096;    % 填0后长度，填0是为了提升频谱分辨率
gauss_alpha = 1;      % 高斯滤波器带宽，推荐设置为1
mean_flag  = 0;%数据处理方式1：去均值项 0：不处理 2：去趋势项
N = 10;%绘图显示的坐标轴
fig_fft = 1; %fft函刻度数
n =3; %提取三大周期数0：不画图 1：画图


%% 每个sheet循环
% 汇总回归系数和拐点的结构体设置
isheetidx =1;
out_r2{1,1} = '指标名称';
out_r2{1,2} = '可决系数';
out_r2{1,3} = '最近拐点出现时间';
for isheet = 1
    %%  2、读取数据文件，判断是否是同比序列
    [~,~,raw] = xlsread(readname, isheet);
    if isheet == nyoysheet
        yoy_type = 0;%原始数据不是同比序列
    else
        yoy_type = 1;%原始数据是同比序列
    end
    % 获取数据
    asset_list = raw(1,2:end);
    asset_num = length(asset_list);
    data = cell2mat(raw(2:end,2:end));
    % 回归结果结构体设置
    out_regress = cell(4*asset_num+1, 7);    
    out_regress(1,1:end)={'品种','Intercept','Beta1','Beta2','Beta3','R2','P-Value'};
    % 变化周期输出结构体设置
    out_period = cell(length(asset_list)+1,6);
    out_period(2:end,1) = asset_list;
    out_period(1,2:end) = {'第一大周期','第二大周期','第三大周期','开始时间','结束时间'};
    period = nan(asset_num,3);
    % 三周期滤波结果输出结构体设置
    output_filter_result = {raw,raw,raw};
     %% 3、遍历每个资产，进行高斯滤波，并将滤波结果对比，各资产预测结果，回归系数对比，（变化周期长度），各指标拐点出现的时间汇总写入文件
    for iAsset = 1:asset_num
        % step1:取出有效时间，计算对数同比序列
        seq = data(:,iAsset);
        seq(seq==0)=nan;
        a = find(~isnan(seq));
        a = a(1):a(end);
        a_seq = seq(a(1):a(end)); %去除nan
        a_seq = interpolation(a_seq);
        if yoy_type~=1
            log_a_seq = log(a_seq(13:end))-log(a_seq(1:end-12)); %原始的同比序列
            date_list_yoy = raw((a(1)+1+12):a(end)+1,1);
        else
            log_a_seq = a_seq; %原始的同比序列
            date_list_yoy = raw((a(1)+1):a(end)+1,1);
        end
        date_list = raw((a(1)+1):a(end)+1,1);
        out_period(iAsset+1,5)=raw(a(1)+1,1);
        out_period(iAsset+1,6)=raw(a(end)+1,1);   
        startDate = datenum(raw(a(1)+1,1));% 该指标的开始时间
        endDate = datenum(raw(a(end)+1,1)); %该指标的结束时间
        a_seq_len = length(a_seq);  
        % 同比序列滤波预测，输出预测值，滤波值，趋势项等        
        [d_a_seq,trend_a_seq,filter_result,predict_trend_seq,predict_result_temp,predict_result,period(iAsset,:),regress_result] = regress_predict_output_f( log_a_seq,predict_len,pad_to_len,gauss_alpha,mean_flag,period_flag);  
        % 结果写入文件
        
        if yoy_type~=1
            output_begin = 14;
        else
            output_begin = 2;
        end
        % 滤波对比结果写入结构体
        for ip = 1:size(period,2)
            output_filter_result{1,ip}{1,1} = [num2str(period(iAsset,ip)),'个月滤波结果汇总'];
            for t_nan = 2:a(output_begin)-1
                output_filter_result{1,ip}{t_nan,iAsset+1} = nan;
            end
            output_filter_result{1,ip}(a(output_begin):end,iAsset+1) = num2cell(filter_result(1:end-predict_len,ip));
        end
        % 回顾系数写入结构体
        out_regress(2+(iAsset-1)*4,1) = asset_list(iAsset);
        out_regress(2+(iAsset-1)*4:5+(iAsset-1)*4,2:7) = num2cell(regress_result);    
        % 将资产序列回归预测结果写入结构体
        output = cell(a_seq_len+predict_len+1, 11);
        output(1,1) = {'Date'};
        output(1,2) = asset_list(iAsset);
        output(1,3) = {'同比序列'};
        output(1,4) = {'去趋势序列'};
        output(1,5) = {'趋势项'};
        output(1,6) = {[num2str(period(iAsset,1)) '个月高斯滤波']};
        output(1,7) = {[num2str(period(iAsset,2)) '个月高斯滤波']};
        output(1,8) = {[num2str(period(iAsset,3)) '个月高斯滤波']};
        output(1,9) = {'残差回归拟合曲线'};
        output(1,10) = {'趋势项拟合曲线'};
        output(1,11) = {'回归拟合曲线'};
        % 日期转换为格式 yyyy-mm
        date_list = raw(1+a(1):1+a(end),1);
        func = @(x) datestr(datenum(x),'yyyy-mm');
        date_list = cellfun(func,date_list,'UniformOutput', false);
        % 生成日期    
        output(2:length(date_list)+1,1) = date_list; 
        prev_date = date_list(end);
        for iDate = 1:predict_len
            date_vec = datevec(prev_date);
            date_vec(2) = date_vec(2) + 1;
            prev_date = datestr(date_vec,'yyyy-mm');
            output(a_seq_len+1+iDate,1) = cellstr(prev_date);
        end        
        % 设置数据
        output(2:a_seq_len+1,2) = num2cell(a_seq);       
        output(output_begin:a_seq_len+1,3) = num2cell(log_a_seq);
        output(output_begin:a_seq_len+1,4) = num2cell(d_a_seq);
        output(output_begin:a_seq_len+1,5) = num2cell(trend_a_seq);
        output(output_begin:end,6:8) = num2cell(filter_result);
        output(output_begin:end,9) = num2cell(predict_result_temp);
        output(output_begin:end,10) = num2cell(predict_trend_seq);
        output(output_begin:end,11) = num2cell(predict_result);
    
        f=figure('PaperType','A4');
        set(gcf,'outerposition',get(0,'screensize'),'name',name);
        temp=datenum(output(2:end,1));
        plot(datenum(date_list),cell2mat(output(2:a_seq_len+1,2)),temp,cell2mat(output(2:end,11)),'r')
        datetick
        xlim([temp(1),temp(end)])
        legend(name,[name,'回归拟合曲线'])
        % 结构体写入文件
        xlswrite(savename, output, 'sheet1');       
        % 记录拐点出现的时间，并写入结构体
        [~,pidx] = findpeaks(predict_result);
        [~,nidx] = findpeaks(0-predict_result);
        idx = max(max(pidx),max(nidx));
        out_r2(isheetidx+1,3) = output(output_begin+idx-1,1);
        out_r2{isheetidx+1,1} = char(asset_list(iAsset));
        out_r2{isheetidx+1,2} = regress_result(4,5);% 记录R^2;
        isheetidx = isheetidx+1;
    end
    % 滤波预测结果写入文件
    for ip = 1:size(period,2)
        xlswrite(savename, output_filter_result{1,ip},[num2str(period(iAsset,ip)),'个月滤波结果汇总']);
    end
    % 回归系数写入文件
    out_period(2:end,2:4) = num2cell(period);
    xlswrite(savename, out_regress, [char(period_flag),'回归系数']);
    xlswrite(savename,out_period, [char(period_flag),'长度']);
end
xlswrite(savename, out_r2, '可决系数与最近拐点出现时间');
toc