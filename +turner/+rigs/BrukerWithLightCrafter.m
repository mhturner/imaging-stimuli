classdef BrukerWithLightCrafter < symphonyui.core.descriptions.RigDescription
    
    methods
        
        function obj = BrukerWithLightCrafter()
            import symphonyui.builtin.devices.*;
            import symphonyui.builtin.daqs.*;
            import symphonyui.core.*;
            import edu.washington.*;

            
            daq = NiSimulationDaqController();
            obj.daqController = daq;
            
            daq = obj.daqController;
            
            lightCrafter = riekelab.devices.LightCrafterDevice('micronsPerPixel', 1.3);
            lightCrafter.bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(lightCrafter, 15);
            
            obj.addDevice(lightCrafter);
            
%             frameMonitor = UnitConvertingDevice('Frame Monitor', 'V').bindStream(daq.getStream('ai7'));
%             obj.addDevice(frameMonitor);
        end
        
    end
    
end

