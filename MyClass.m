classdef MyClass < handle
   properties
      Prop1
   end
   methods
      function obj = MyClass(arg)
         obj.Prop1 = arg;
      end
      function change(obj,arg)
          obj.Prop1 = arg;
      end
   end
end
