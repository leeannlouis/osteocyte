function out = createSqlValueList(values_to_add)
% Given a cell array of values to add to a SQL table (values_to_add),
% outputs the list of values as a string in the proper format (out). 
% That is, values are delimited by commas, and strings have double 
% quotes around them. 

% Make a copy to use
values = values_to_add;

for i = 1:size(values, 2)
    
    this = values{i};
    
    if ischar(this)
        % Give strings double quotes
        values{i} = ['"', this, '"'];
        
    
    elseif isnumeric(this)
        % Convert numbers to strings
        values{i} = num2str(this);

    else
        % Otherwise throw an error
        error('All inputs must be characters or numbers');
    end 
    
end


% Create the comma-delimted output
out = strjoin(values, ', ');

end
