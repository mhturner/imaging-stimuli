classdef LightCrafterDevice < symphonyui.core.Device
    
    properties (Access = private, Transient)
        stageClient
        lightCrafter
        patternRatesToAttributes
    end
    
    methods
        
        function obj = LightCrafterDevice(varargin)
            ip = inputParser();
            ip.addParameter('host', 'localhost', @ischar);
            ip.addParameter('port', 5678, @isnumeric);
            ip.parse(varargin{:});
            
            cobj = Symphony.Core.UnitConvertingExternalDevice(['LightCrafter Stage@' ip.Results.host], 'Texas Instruments', Symphony.Core.Measurement(0, symphonyui.core.Measurement.UNITLESS));
            obj@symphonyui.core.Device(cobj);
            obj.cobj.MeasurementConversionTarget = symphonyui.core.Measurement.UNITLESS;
            
            obj.stageClient = stage.core.network.StageClient();
            obj.stageClient.connect(ip.Results.host, ip.Results.port);
            obj.stageClient.setMonitorGamma(1);
            
            trueCanvasSize = obj.stageClient.getCanvasSize();
            canvasSize = [trueCanvasSize(1) * 2, trueCanvasSize(2)];
            
            obj.stageClient.setCanvasProjectionIdentity();
            obj.stageClient.setCanvasProjectionFlyPerspective(canvasSize(1), canvasSize(2));
            
            obj.lightCrafter = LightCrafter4500(obj.stageClient.getMonitorRefreshRate());
            obj.lightCrafter.connect();
            obj.lightCrafter.setMode('pattern');
            obj.lightCrafter.setLedEnables(false, false, false, true);
            [auto, red, green, blue] = obj.lightCrafter.getLedEnables();
            
            refreshRate = obj.stageClient.getMonitorRefreshRate();
            obj.patternRatesToAttributes = containers.Map('KeyType', 'double', 'ValueType', 'any');
            obj.patternRatesToAttributes(1 * refreshRate)  = {8, 'white', 1};
            obj.patternRatesToAttributes(2 * refreshRate)  = {8, 'white', 2};
            obj.patternRatesToAttributes(4 * refreshRate)  = {6, 'white', 4};
            obj.patternRatesToAttributes(6 * refreshRate)  = {4, 'white', 6};
            obj.patternRatesToAttributes(8 * refreshRate)  = {3, 'white', 8};
            obj.patternRatesToAttributes(12 * refreshRate) = {2, 'white', 12};
            obj.patternRatesToAttributes(24 * refreshRate) = {1, 'white', 24};
            
            attributes = obj.patternRatesToAttributes(refreshRate);
            obj.lightCrafter.setPatternAttributes(attributes{:});
            
            renderer = stage.builtin.renderers.PatternRenderer(attributes{3}, attributes{1});
            obj.stageClient.setCanvasRenderer(renderer);
            
            obj.addConfigurationSetting('canvasSize', canvasSize, 'isReadOnly', true);
            obj.addConfigurationSetting('trueCanvasSize', trueCanvasSize, 'isReadOnly', true);
            obj.addConfigurationSetting('centerOffset', [0 0], 'isReadOnly', true);
            obj.addConfigurationSetting('monitorRefreshRate', refreshRate, 'isReadOnly', true);
            obj.addConfigurationSetting('prerender', false, 'isReadOnly', true);
            obj.addConfigurationSetting('lightCrafterLedEnables',  [auto, red, green, blue], 'isReadOnly', true);
            obj.addConfigurationSetting('lightCrafterPatternRate', obj.lightCrafter.currentPatternRate(), 'isReadOnly', true);
        end
        
        function close(obj)
            try %#ok<TRYNC>
                obj.stageClient.resetCanvasProjection();
                obj.stageClient.resetCanvasRenderer();
            end
            if ~isempty(obj.stageClient)
                obj.stageClient.disconnect();
            end
            if ~isempty(obj.lightCrafter)
                obj.lightCrafter.disconnect();
            end
        end
        
        function v = getConfigurationSetting(obj, name)
            v = obj.tryCoreWithReturn(@()obj.cobj.Configuration.Item(name));
            v = obj.valueFromPropertyValue(convert(v));
        end
        
        function s = getCanvasSize(obj)
            s = obj.getConfigurationSetting('canvasSize');
        end
        
        function s = getTrueCanvasSize(obj)
            s = obj.getConfigurationSetting('trueCanvasSize');
        end
        
        function setCenterOffset(obj, o)
            obj.setReadOnlyConfigurationSetting('centerOffset', [o(1) o(2)]);
        end
        
        function o = getCenterOffset(obj)
            o = obj.getConfigurationSetting('centerOffset');
        end
        
        function r = getMonitorRefreshRate(obj)
            r = obj.getConfigurationSetting('monitorRefreshRate');
        end
        
        function setPrerender(obj, tf)
            obj.setReadOnlyConfigurationSetting('prerender', logical(tf));
        end
        
        function tf = getPrerender(obj)
            tf = obj.getConfigurationSetting('prerender');
        end
        
        function play(obj, presentation)
            % set center offset on all user-defined stimuli
            centerOffset = obj.getCenterOffset();
            for ss = 1:length(presentation.stimuli)
                presentation.stimuli{ss}.azimuth = centerOffset(1);
                presentation.stimuli{ss}.elevation = centerOffset(2);
            end

            % add background by making a uniform semisphere at the bottom
            % level of the presentation:
            background = clandininlab.stimuli.PerspectiveSphere();
            background.color = presentation.backgroundColor;
            presentation.insertStimulus(1, background);
            
            % add frame tracker stimulus to the top:
            Tracker = clandininlab.stimuli.FrameTracker();
            presentation.addStimulus(Tracker);
            trackerColor = stage.builtin.controllers.PropertyController(Tracker, 'color', @(s)mod(s.frame, 2) && double(s.time + (1/s.frameRate) < presentation.duration));
            presentation.addController(trackerColor);            

            if obj.getPrerender()
                player = stage.builtin.players.PrerenderedPlayer(presentation);
            else
                player = stage.builtin.players.RealtimePlayer(presentation);
            end
            player.setCompositor(stage.builtin.compositors.PatternCompositor());
            obj.stageClient.play(player);
        end
        
        function replay(obj)
            obj.stageClient.replay();
        end
        
        function i = getPlayInfo(obj)
            i = obj.stageClient.getPlayInfo();
        end
        
        function clearMemory(obj)
           obj.stageClient.clearMemory();
        end
        
        function setSingleLedEnable(obj, setting)
            switch lower(setting)
                case 'auto'
                    obj.setLedEnables(true, false, false, false);
                case 'red'
                    obj.setLedEnables(false, true, false, false);
                case 'green'
                    obj.setLedEnables(false, false, true, false);
                case 'blue'
                    obj.setLedEnables(false, false, false, true);
                otherwise
                    error('Unknown LED enable setting');
            end
        end
        
        function setLedEnables(obj, auto, red, green, blue)
            obj.lightCrafter.setLedEnables(auto, red, green, blue);
            [a, r, g, b] = obj.lightCrafter.getLedEnables();
            obj.setReadOnlyConfigurationSetting('lightCrafterLedEnables', [a, r, g, b]);
        end
        
        function [auto, red, green, blue] = getLedEnables(obj)
            [auto, red, green, blue] = obj.lightCrafter.getLedEnables();
        end
        
        function r = availablePatternRates(obj)
            r = obj.patternRatesToAttributes.keys;
        end
        
        function setPatternRate(obj, rate)
            if ~obj.patternRatesToAttributes.isKey(rate)
                error([num2str(rate) ' is not an available pattern rate']);
            end
            attributes = obj.patternRatesToAttributes(rate);
            obj.lightCrafter.setPatternAttributes(attributes{:});
            obj.setReadOnlyConfigurationSetting('lightCrafterPatternRate', obj.lightCrafter.currentPatternRate());
            
            renderer = stage.builtin.renderers.PatternRenderer(attributes{3}, attributes{1});
            obj.stageClient.setCanvasRenderer(renderer);
        end
        
        function r = getPatternRate(obj)
            r = obj.lightCrafter.currentPatternRate();
        end
        
    end
    
end

function v = convert(dotNetValue)
    v = dotNetValue;
    if ~isa(v, 'System.Object')
        return;
    end
    
    clazz = strtok(class(dotNetValue), '[');
    switch clazz
        case 'System.Int16'
            v = int16(v);
        case 'System.UInt16'
            v = uint16(v);
        case 'System.Int32'
            v = int32(v);
        case 'System.UInt32'
            v = uint32(v);
        case 'System.Int64'
            v = int64(v);
        case 'System.UInt64'
            v = uint64(v);
        case 'System.Single'
            v = single(v);
        case 'System.Double'
            v = double(v);
        case 'System.Boolean'
            v = logical(v);
        case 'System.Byte'
            v = uint8(v);
        case {'System.Char', 'System.String'}
            v = char(v);
    end
end