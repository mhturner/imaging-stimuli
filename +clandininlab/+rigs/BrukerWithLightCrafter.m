classdef BrukerWithLightCrafter < symphonyui.core.descriptions.RigDescription
    
    methods
        
        function obj = BrukerWithLightCrafter()
            import symphonyui.builtin.devices.*;
            import symphonyui.builtin.daqs.*;
            import symphonyui.core.*;
            import edu.washington.*;

            daq = NiSimulationDaqController();
            obj.daqController = daq;

            lightCrafter = clandininlab.devices.LightCrafterDevice();
            lightCrafter.bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(lightCrafter, 15);
            obj.addDevice(lightCrafter);
            
            %laser scan trigger device
            scanTrigger = clandininlab.devices.ScanTriggerDevice();
            scanTrigger.bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(scanTrigger, 10);
            obj.addDevice(scanTrigger);
            
%             frameMonitor = UnitConvertingDevice('Frame Monitor', 'V').bindStream(daq.getStream('ai7'));
%             obj.addDevice(frameMonitor);
        end
        
    end
    
end

