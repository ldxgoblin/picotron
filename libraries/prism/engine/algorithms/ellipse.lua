--- Generates points for an ellipse on a grid using the Vector2 class.
--- @param mode ("fill" | "line") The mode to use
--- @param center Vector2 The center of the ellipse.
--- @param rx number The radius along the x-axis.
--- @param ry number The radius along the y-axis.
--- @param callback fun(x: number, y: number) Function to call for each ellipse point.
return function(mode, center, rx, ry, callback)
   for y = center.y - ry, center.y + ry do
      for x = center.x - rx, center.x + rx do
         local dx = (x - center.x)
         local dy = (y - center.y)
         local rx, ry = rx + 0.5, ry + 0.5
         local outer = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry)
         if mode == "fill" and outer <= 1 then
            callback(x, y)
         elseif mode == "line" then
            local inner = (dx * dx) / ((rx - 1) * (rx - 1)) + (dy * dy) / ((ry - 1) * (ry - 1))
            if outer <= 1 and inner >= 1 then callback(x, y) end
         end
      end
   end
end
