function msgLength = displayProgressMessage(pctComplete,avgCalcTime,...
    estTimeRemaining,forwardsOrBackwardsString,prevMsgLength)

% Init variable for previous pctComplete
persistent pctCompletePrev;
if isempty(pctCompletePrev)
    pctCompletePrev = 0;
end % if

% Only display progress if percentage has increased
if round(pctComplete)~=pctCompletePrev || pctComplete==100
    
    % Remove previous message
    if prevMsgLength>0
        fprintf(repmat('\b',1,prevMsgLength));
    end % if
    
    % Define new message
    msg{1} = sprintf(['DP running ' forwardsOrBackwardsString ...
        '. Please wait... %3i%%%%'],round(pctComplete));
    msg{2} = sprintf('Average time per iteration: %1.2f s', avgCalcTime);
    if pctComplete==100
        totalElapsedTime = estTimeRemaining;
        totalElapsedTimeTimeFormat = datestr(seconds(totalElapsedTime),'DD:HH:MM:SS');
        msg{3} = ['Total elapsed time: ', totalElapsedTimeTimeFormat];
    else
        if estTimeRemaining >= 32*24*3600 % otherwise months would neet to be shown
            if pctComplete>1
                msg{3} = sprintf('Estimated time remaining: More than 32 days!');
            else
                msg{3} = sprintf('Estimated time remaining: is being determined, please wait');
            end % if
        else
            estTimeRemainingTimeFormat = datestr(seconds(estTimeRemaining),'DD:HH:MM:SS');
            msg{3} = ['Estimated time remaining: ', estTimeRemainingTimeFormat];
        end % if
    end % if
    msgLength = sum(cellfun(@(x)length(x),msg)) + 1;
    
    % Display new message
    fprintf([msg{1} '\n']);
    fprintf([msg{2} '\n']);
    fprintf(msg{3});
    
    % Update previous pctComplete
    pctCompletePrev = round(pctComplete);
    
else
    % Skip display of this iteration
    msgLength = prevMsgLength;
end % if

end % function

% EOF