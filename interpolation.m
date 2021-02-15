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

