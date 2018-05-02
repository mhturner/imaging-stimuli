classdef (Abstract) ClandininLabStageProtocol < symphonyui.core.Protocol
    
    properties (Access = protected)
        waitingForHardwareToStart
    end
    
    methods (Abstract)
        p = createPresentation(obj);
    end
    
    methods
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@symphonyui.core.Protocol(obj, epoch);
            
            obj.waitingForHardwareToStart = true;
            epoch.shouldWaitForTrigger = false;
            
            %scan trigger stuff:
            triggers = obj.rig.getDevices('scanTrigger');
            scanNumber = triggers{1}.scanNumber;
            epoch.addParameter('scanNumber', scanNumber);
            disp(scanNumber)
            %advance the scan count:
            triggers{1}.scanNumber = triggers{1}.scanNumber + 1; 
            
%             frameMonitor = obj.rig.getDevices('Frame Monitor');
%             if ~isempty(frameMonitor)
%                 epoch.addResponse(frameMonitor{1});
%             end
        end
        
        function controllerDidStartHardware(obj)
            controllerDidStartHardware@symphonyui.core.Protocol(obj);
            
            if obj.waitingForHardwareToStart
                obj.waitingForHardwareToStart = false;
                obj.rig.getDevice('Stage').play(obj.createPresentation());
            end
        end
        
        function tf = shouldContinuePreloadingEpochs(obj) %#ok<MANU>
            tf = false;
        end
        
        function tf = shouldWaitToContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared > obj.numEpochsCompleted || obj.numIntervalsPrepared > obj.numIntervalsCompleted;
        end
        
        function completeRun(obj)
            completeRun@symphonyui.core.Protocol(obj);
            obj.rig.getDevice('Stage').clearMemory();
        end
        
        function [tf, msg] = isValid(obj)
            [tf, msg] = isValid@symphonyui.core.Protocol(obj);
            if tf
                tf = ~isempty(obj.rig.getDevices('Stage'));
                msg = 'No stage';
            end
        end
        
    end
    
end

