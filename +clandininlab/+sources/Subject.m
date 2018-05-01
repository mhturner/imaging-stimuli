classdef (Abstract) Subject < symphonyui.core.persistent.descriptions.SourceDescription
    
    methods
        
        function obj = Subject()
            import symphonyui.core.*;
            
            obj.addProperty('id', '', ...
                'description', 'ID of animal (lab convention)');
            obj.addProperty('description', '', ...
                'description', 'Description of subject and where subject came from (eg, breeder, if animal)');
            obj.addProperty('sex', '', ...
                'type', PropertyType('char', 'row', {'', 'male', 'female'}), ...
                'description', 'Gender of the subject');
            obj.addProperty('age', '', ...
                'description', 'Age of animal');
        end
        
    end
    
end

