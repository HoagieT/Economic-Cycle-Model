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

