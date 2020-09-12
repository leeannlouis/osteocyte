function todayStr = getTodayStr()
% Output today's date in the char format 'yyyyMMdd'.

% Get the date in the proper format
todayStr = today('datetime');
todayStr.Format = 'yyyyMMdd';
todayStr = char(todayStr);

end
