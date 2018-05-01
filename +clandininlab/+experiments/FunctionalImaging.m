classdef FunctionalImaging < symphonyui.core.persistent.descriptions.ExperimentDescription
    
    methods
        
        function obj = FunctionalImaging()
            import symphonyui.core.*;
            
            obj.addProperty('experimenter', '', ...
                'description', 'Who performed the experiment');
            obj.addProperty('project', '', ...
                'description', 'Project the experiment belongs to');
            obj.addProperty('institution', 'Stanford', ...
                'description', 'Institution where the experiment was performed');
            obj.addProperty('lab', 'Clandinin Lab', ...
                'description', 'Lab where experiment was performed');
            obj.addProperty('rig', '', ...
                'type', PropertyType('char', 'row', {'', 'Bruker', 'Leica',}), ...
                'description', 'Rig where experiment was performed');
        end
        
    end
    
end

