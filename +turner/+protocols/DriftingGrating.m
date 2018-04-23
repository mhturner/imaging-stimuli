classdef DriftingGrating < io.github.stage_vss.protocols.StageProtocol
    
    properties
        preTime = 1000                  % Leading duration (ms)
        stimTime = 5000                 % Duration (ms)
        tailTime = 1000                 % Trailing duration (ms)
        spatialFreq = 0.1               % (c.p.d.)
        contrast = 0.9                  % Grating contrast
        backgroundIntensity = 0.5       % Background light intensity (0-1)
        orientation = 0                 % Degrees
        numberOfAverages = uint16(5)    % Number of epochs
    end
    
    properties (Hidden)

    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@io.github.stage_vss.protocols.StageProtocol(obj);
        end
        
        function p = getPreview(obj, panel)
            if isempty(obj.rig.getDevices('Stage'))
                p = [];
                return;
            end
            p = io.github.stage_vss.previews.StagePreview(panel, @()obj.createPresentation(), ...
                'windowSize', obj.rig.getDevice('Stage').getTrueCanvasSize());
        end
        
        function prepareRun(obj)
            prepareRun@io.github.stage_vss.protocols.StageProtocol(obj);
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            % Grating stimulus:
            Grate = turner.stimuli.Grating('square');
            Grate.contrast = obj.contrast;
            Grate.color = 2 * obj.backgroundIntensity;
            Grate.orientation = obj.orientation;
            Grate.spatialFreq = obj.spatialFreq;
            p.addStimulus(Grate);

            speed_cyclesPerSecond = 2;
            phaseController = stage.builtin.controllers.PropertyController(Grate, 'phase', @(state)520*state.time*speed_cyclesPerSecond);
            p.addController(phaseController);
            grateVisible = stage.builtin.controllers.PropertyController(Grate, 'visible', @(state)state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3);
            p.addController(grateVisible);

            % Frame tracker stimulus:
            Tracker = turner.stimuli.FrameTracker();
            p.addStimulus(Tracker);
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@io.github.stage_vss.protocols.StageProtocol(obj, epoch);
            
%             device = obj.rig.getDevice(obj.amp);
%             duration = (obj.preTime + obj.stimTime + obj.tailTime) / 1e3;
%             epoch.addDirectCurrentStimulus(device, device.background, duration, obj.sampleRate);
%             epoch.addResponse(device);
        end

        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
    end
    
end

