classdef (Abstract) EpochGroup < symphonyui.core.persistent.descriptions.EpochGroupDescription
    
    methods
        
        function obj = EpochGroup()
            import symphonyui.core.*;

            obj.addProperty('laser wavelength', int32(0), ...
                'type', PropertyType('int32', 'scalar', [0 1200]));
            
            obj.addAllowableParentType([]);
        end
        
    end
    
end

