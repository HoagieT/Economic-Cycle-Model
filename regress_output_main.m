clc,clear,close all,tic
%% 1��·�����úͲ�������
workdir = '.\';
savedir = '.\';
name='��ծ'; %��ѡ������CPI��PPI����ծ����Ʒ�����۶M1��M2����ҵ��ҵ����Ʒ��棬���������������
readname = [name,'.xlsx'];
period_flag = 'ͬ������'; %����Ƶ��ѡ��ʽ���̶�����42��100��200 ���仯�����ɸ���Ҷ�任�ó�
savename = [savedir,name,char(period_flag),'24�����˲�Ԥ��.xls'];
cd(workdir);
sheetname = {'ԭʼ����','ͬ������','��������'};
nyoysheet = 0; %����ͬ�����е�sheet
predict_len = 24*1;     % Ԥ�ⳤ�ȣ���λΪ��
pad_to_len = 4096;    % ��0�󳤶ȣ���0��Ϊ������Ƶ�׷ֱ���
gauss_alpha = 1;      % ��˹�˲��������Ƽ�����Ϊ1
mean_flag  = 0;%���ݴ���ʽ1��ȥ��ֵ�� 0�������� 2��ȥ������
N = 10;%��ͼ��ʾ��������
fig_fft = 1; %fft���̶���
n =3; %��ȡ����������0������ͼ 1����ͼ


%% ÿ��sheetѭ��
% ���ܻع�ϵ���͹յ�Ľṹ������
isheetidx =1;
out_r2{1,1} = 'ָ������';
out_r2{1,2} = '�ɾ�ϵ��';
out_r2{1,3} = '����յ����ʱ��';
for isheet = 1
    %%  2����ȡ�����ļ����ж��Ƿ���ͬ������
    [~,~,raw] = xlsread(readname, isheet);
    if isheet == nyoysheet
        yoy_type = 0;%ԭʼ���ݲ���ͬ������
    else
        yoy_type = 1;%ԭʼ������ͬ������
    end
    % ��ȡ����
    asset_list = raw(1,2:end);
    asset_num = length(asset_list);
    data = cell2mat(raw(2:end,2:end));
    % �ع����ṹ������
    out_regress = cell(4*asset_num+1, 7);    
    out_regress(1,1:end)={'Ʒ��','Intercept','Beta1','Beta2','Beta3','R2','P-Value'};
    % �仯��������ṹ������
    out_period = cell(length(asset_list)+1,6);
    out_period(2:end,1) = asset_list;
    out_period(1,2:end) = {'��һ������','�ڶ�������','����������','��ʼʱ��','����ʱ��'};
    period = nan(asset_num,3);
    % �������˲��������ṹ������
    output_filter_result = {raw,raw,raw};
     %% 3������ÿ���ʲ������и�˹�˲��������˲�����Աȣ����ʲ�Ԥ�������ع�ϵ���Աȣ����仯���ڳ��ȣ�����ָ��յ���ֵ�ʱ�����д���ļ�
    for iAsset = 1:asset_num
        % step1:ȡ����Чʱ�䣬�������ͬ������
        seq = data(:,iAsset);
        seq(seq==0)=nan;
        a = find(~isnan(seq));
        a = a(1):a(end);
        a_seq = seq(a(1):a(end)); %ȥ��nan
        a_seq = interpolation(a_seq);
        if yoy_type~=1
            log_a_seq = log(a_seq(13:end))-log(a_seq(1:end-12)); %ԭʼ��ͬ������
            date_list_yoy = raw((a(1)+1+12):a(end)+1,1);
        else
            log_a_seq = a_seq; %ԭʼ��ͬ������
            date_list_yoy = raw((a(1)+1):a(end)+1,1);
        end
        date_list = raw((a(1)+1):a(end)+1,1);
        out_period(iAsset+1,5)=raw(a(1)+1,1);
        out_period(iAsset+1,6)=raw(a(end)+1,1);   
        startDate = datenum(raw(a(1)+1,1));% ��ָ��Ŀ�ʼʱ��
        endDate = datenum(raw(a(end)+1,1)); %��ָ��Ľ���ʱ��
        a_seq_len = length(a_seq);  
        % ͬ�������˲�Ԥ�⣬���Ԥ��ֵ���˲�ֵ���������        
        [d_a_seq,trend_a_seq,filter_result,predict_trend_seq,predict_result_temp,predict_result,period(iAsset,:),regress_result] = regress_predict_output_f( log_a_seq,predict_len,pad_to_len,gauss_alpha,mean_flag,period_flag);  
        % ���д���ļ�
        
        if yoy_type~=1
            output_begin = 14;
        else
            output_begin = 2;
        end
        % �˲��ԱȽ��д��ṹ��
        for ip = 1:size(period,2)
            output_filter_result{1,ip}{1,1} = [num2str(period(iAsset,ip)),'�����˲��������'];
            for t_nan = 2:a(output_begin)-1
                output_filter_result{1,ip}{t_nan,iAsset+1} = nan;
            end
            output_filter_result{1,ip}(a(output_begin):end,iAsset+1) = num2cell(filter_result(1:end-predict_len,ip));
        end
        % �ع�ϵ��д��ṹ��
        out_regress(2+(iAsset-1)*4,1) = asset_list(iAsset);
        out_regress(2+(iAsset-1)*4:5+(iAsset-1)*4,2:7) = num2cell(regress_result);    
        % ���ʲ����лع�Ԥ����д��ṹ��
        output = cell(a_seq_len+predict_len+1, 11);
        output(1,1) = {'Date'};
        output(1,2) = asset_list(iAsset);
        output(1,3) = {'ͬ������'};
        output(1,4) = {'ȥ��������'};
        output(1,5) = {'������'};
        output(1,6) = {[num2str(period(iAsset,1)) '���¸�˹�˲�']};
        output(1,7) = {[num2str(period(iAsset,2)) '���¸�˹�˲�']};
        output(1,8) = {[num2str(period(iAsset,3)) '���¸�˹�˲�']};
        output(1,9) = {'�в�ع��������'};
        output(1,10) = {'�������������'};
        output(1,11) = {'�ع��������'};
        % ����ת��Ϊ��ʽ yyyy-mm
        date_list = raw(1+a(1):1+a(end),1);
        func = @(x) datestr(datenum(x),'yyyy-mm');
        date_list = cellfun(func,date_list,'UniformOutput', false);
        % ��������    
        output(2:length(date_list)+1,1) = date_list; 
        prev_date = date_list(end);
        for iDate = 1:predict_len
            date_vec = datevec(prev_date);
            date_vec(2) = date_vec(2) + 1;
            prev_date = datestr(date_vec,'yyyy-mm');
            output(a_seq_len+1+iDate,1) = cellstr(prev_date);
        end        
        % ��������
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
        legend(name,[name,'�ع��������'])
        % �ṹ��д���ļ�
        xlswrite(savename, output, 'sheet1');       
        % ��¼�յ���ֵ�ʱ�䣬��д��ṹ��
        [~,pidx] = findpeaks(predict_result);
        [~,nidx] = findpeaks(0-predict_result);
        idx = max(max(pidx),max(nidx));
        out_r2(isheetidx+1,3) = output(output_begin+idx-1,1);
        out_r2{isheetidx+1,1} = char(asset_list(iAsset));
        out_r2{isheetidx+1,2} = regress_result(4,5);% ��¼R^2;
        isheetidx = isheetidx+1;
    end
    % �˲�Ԥ����д���ļ�
    for ip = 1:size(period,2)
        xlswrite(savename, output_filter_result{1,ip},[num2str(period(iAsset,ip)),'�����˲��������']);
    end
    % �ع�ϵ��д���ļ�
    out_period(2:end,2:4) = num2cell(period);
    xlswrite(savename, out_regress, [char(period_flag),'�ع�ϵ��']);
    xlswrite(savename,out_period, [char(period_flag),'����']);
end
xlswrite(savename, out_r2, '�ɾ�ϵ��������յ����ʱ��');
toc