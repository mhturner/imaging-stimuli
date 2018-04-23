classdef DriftingGrating < io.github.stage_vss.protocols.StageProtocol
    
    properties
        preTime = 500                   % Leading duration (ms)
        stimTime = 1000                 % Duration (ms)
        tailTime = 500                  % Trailing duration (ms)
        spatialFreq = 1.0               % (c.p.d.)
        contrast = 0.9                  % Grating contrast
        backgroundIntensity = 0.5       % Background light intensity (0-1)
        orientation = 0                 % Degrees
        centerOffset = [0, 0]           % Spot [x, y] center offset (pixels)
        numberOfAverages = uint16(5)    % Number of epochs
    end
    
    properties (Hidden)

    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@io.github.stage_vss.protocols.StageProtocol(obj);
            
%             [obj.amp, obj.ampType] = obj.createDeviceNamesProperty('Amp');
        end
        
        function p = getPreview(obj, panel)
            if isempty(obj.rig.getDevices('Stage'))
                p = [];
                return;
            end
            p = io.github.stage_vss.previews.StagePreview(panel, @()obj.createPresentation(), ...
                'windowSize', obj.rig.getDevice('Stage').getCanvasSize());
        end
        
        function prepareRun(obj)
            prepareRun@io.github.stage_vss.protocols.StageProtocol(obj);
%             
%             obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice(obj.amp));
%             obj.showFigure('symphonyui.builtin.figures.MeanResponseFigure', obj.rig.getDevice(obj.amp));
%             obj.showFigure('io.github.stage_vss.figures.FrameTimingFigure', obj.rig.getDevice('Stage'));
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            % Grating stimulus:
            Grate = turner.stimuli.Grating('square');
            Grate.contrast = 0.5;
            Grate.color = 2 * obj.backgroundIntensity;
            Grate.orientation = 0; %deg
            Grate.spatialFreq = obj.spatialFreq; %cpd
            presentation.addStimulus(Grate);

            speed_cyclesPerSecond = 2;
            phaseController = stage.builtin.controllers.PropertyController(Grate, 'phase', @(state)520*state.time*speed_cyclesPerSecond);
            presentation.addController(phaseController);

            % Frame tracker stimulus:
            Tracker = turner.stimuli.FrameTracker();
            presentation.addStimulus(Tracker);
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

