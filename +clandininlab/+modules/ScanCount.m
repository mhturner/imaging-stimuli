classdef ScanCount < symphonyui.ui.Module
    
    properties (Access = private)
        toolbar
        settings
        updateButton
        scanDevice
        deviceListener
        deviceGrid
    end
    
    methods
        
        function obj = ScanCount()
            obj.settings = clandininlab.modules.settings.ScanCountSettings();
        end
        
        function createUi(obj, figureHandle)
            import appbox.*;
            
            set(figureHandle, ...
                'Name', 'Scan Counter', ...
                'Position', screenCenter(250, 20));
            
            obj.toolbar = Menu(figureHandle);
            obj.updateButton = obj.toolbar.addPushTool( ...
                'Label', 'Reset Scan Number to 1', ...
                'Callback', @obj.onSelectedReset);
            
            mainLayout = uix.VBox( ...
                'Parent', figureHandle);
            
            obj.deviceGrid = uiextras.jide.PropertyGrid(mainLayout, ...
                'BorderType', 'none', ...
                'Callback', @obj.onSetScanNumber);
        end
        
    end
    
    methods (Access = protected)

        function willGo(obj)
            devices = obj.configurationService.getDevices('scanTrigger');
            obj.scanDevice = devices{1};
            field = uiextras.jide.PropertyGridField(obj.scanDevice.name, ...
                obj.scanDevice.scanNumber, ...
                'DisplayName', 'Scan number:');
            set(obj.deviceGrid, 'Properties', field);
            
            try
                obj.loadSettings();
            catch x
                obj.log.debug(['Failed to load settings: ' x.message], x);
            end
        end
        
        function willStop(obj)
            try
                obj.saveSettings();
            catch x
                obj.log.debug(['Failed to save settings: ' x.message], x);
            end
        end
        
        function bind(obj)
            bind@symphonyui.ui.Module(obj);
            obj.deviceListener = obj.addListener(obj.scanDevice,...
                'scanNumber', 'PostSet', @obj.onSelectedUpdate);
        end
   
    end
    
    methods (Access = private)
        
       
        function onSelectedUpdate(obj, ~, ~)
            obj.willGo();
        end
        
        function onSelectedReset(obj, ~, ~)
            obj.scanDevice.scanNumber = 1;
        end
        
        function onSetScanNumber(obj, ~, event)
            obj.scanDevice.scanNumber = event.Property.Value;
        end
        
        function loadSettings(obj)
            if ~isempty(obj.settings.viewPosition)
                p1 = obj.view.position;
                p2 = obj.settings.viewPosition;
                obj.view.position = [p2(1) p2(2) p1(3) p1(4)];
            end
        end

        function saveSettings(obj)
            obj.settings.viewPosition = obj.view.position;
            obj.settings.save();
        end
        
    end
    
end

