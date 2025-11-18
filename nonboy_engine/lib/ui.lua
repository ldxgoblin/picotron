-- Observable class: Manages a value and notifies observers when it changes
Observable = {}
Observable.__index = Observable

-- Creates a new Observable instance with an initial value
function Observable:new(value)
    local o = {
        value = value,   -- Stores the current value
        observers = {}   -- List of observers to notify on value change
    }
    setmetatable(o, self)
    return o
end

-- Sets a new value and notifies all observers of the change
function Observable:set(value)
    self.value = value  -- Update the internal value
    self:notify()       -- Notify observers that the value has changed
end

-- Gets the current value of the observable
function Observable:get()
    return self.value   -- Return the stored value
end

-- Registers an observer function to be notified when the value changes
function Observable:observe(observer)
    table.insert(self.observers, observer) -- Add the observer to the list
end

-- Notifies all registered observers by calling their functions with the updated value
function Observable:notify()
    for _, observer in ipairs(self.observers) do
        observer(self.value)  -- Call each observer with the current value
    end
end

-- Base class for concrete view components, managing view properties and behavior
ConcreteViewClass = {}
ConcreteViewClass.__index = ConcreteViewClass

-- Creates a new view component with optional properties
function ConcreteViewClass:new(props)
    local o = {}
    setmetatable(o, self)
    o._boundProperties = {}  -- Keeps track of properties bound to observables
    props = props or {}
    o:bindUniversalProperties(props) -- Bind universal view properties
    o:update()                       -- Trigger update to initialize view
    return o
end

-- Binds universal properties (padding, border, background color, etc.)
function ConcreteViewClass:bindUniversalProperties(props)
    -- Universal properties that apply to all view components
    self:bindProperty("padding_x", props.padding_x or 0)
    self:bindProperty("padding_y", props.padding_y or 0)
    self:bindProperty("border_x", props.border_x or 0)
    self:bindProperty("border_y", props.border_y or 0)
    self:bindProperty("background_color", props.background_color)
    self:bindProperty("border_color", props.border_color)
end

-- Binds a property to an observable or sets a static value
function ConcreteViewClass:bindProperty(propName, value)
    if type(value) == "table" and value.observe then
        -- If the value is observable, bind and update the property when it changes
        self[propName] = value:get() -- Initialize with the current value
        value:observe(function(new_value)
            self[propName] = new_value -- Update property with new value
            self:update()              -- Redraw the component
        end)
        table.insert(self._boundProperties, propName) -- Track bound properties
    else
        -- Static value: set the property directly
        self[propName] = value
    end
end

-- Placeholder function to be implemented by subclasses for updating the view
function ConcreteViewClass:update()
    -- To be implemented by subclasses
end

-- Calculates and returns the width of the view including padding and border
function ConcreteViewClass:width()
    local width = self._width or 0
    width = width + 2 * (self.padding_x or 0) + 2 * (self.border_x or 0) -- Add padding and border
    return width
end

-- Calculates and returns the height of the view including padding and border
function ConcreteViewClass:height()
    local height = self._height or 0
    height = height + 2 * (self.padding_y or 0) + 2 * (self.border_y or 0) -- Add padding and border
    return height
end

-- Draws the view, including the border and background, and calls drawContent for specific content
function ConcreteViewClass:draw()
    return function(x, y)
        local bx = self.border_x or 0
        local by = self.border_y or 0
        local px = self.padding_x or 0
        local py = self.padding_y or 0

        -- Draw the border if defined
        if self.border_color then
            rectfill(x, y, x + self:width() - 1, y + self:height() - 1, self.border_color)
        end

        -- Draw the background if defined
        if self.background_color then
            local bg_x = x + bx
            local bg_y = y + by
            local bg_w = self:width() - 2 * bx
            local bg_h = self:height() - 2 * by
            rectfill(bg_x, bg_y, bg_x + bg_w - 1, bg_y + bg_h - 1, self.background_color)
        end

        -- Draw the content inside the view
        local content_x = x + bx + px
        local content_y = y + by + py
        self:drawContent()(content_x, content_y) -- Call drawContent to render specific content
    end
end

-- Placeholder function to be implemented by subclasses for drawing content
function ConcreteViewClass:drawContent()
    return function(x, y)
        -- Placeholder function for content
    end
end

-- ViewClass serves as a base for composite views that can hold child views
ViewClass = {}
ViewClass.__index = ViewClass

-- Creates a new composite view with optional properties
function ViewClass:new(props)
    local o = {}
    setmetatable(o, self)
    o.children = {}          -- List to store child views
    o._boundProperties = {}   -- Keeps track of bound properties
    props = props or {}
    o:bindUniversalProperties(props) -- Bind universal properties
    o:update()                      -- Trigger update to layout the view
    return o
end

-- Binds universal properties for composite views
function ViewClass:bindUniversalProperties(props)
    self:bindProperty("padding_x", props.padding_x or 0)
    self:bindProperty("padding_y", props.padding_y or 0)
    self:bindProperty("border_x", props.border_x or 0)
    self:bindProperty("border_y", props.border_y or 0)
    self:bindProperty("background_color", props.background_color)
    self:bindProperty("border_color", props.border_color)
    self:bindProperty("spacing", props.spacing or 0) -- Spacing between child views
end

-- Binds a property, similar to ConcreteViewClass
function ViewClass:bindProperty(propName, value)
    if type(value) == "table" and value.observe then
        self[propName] = value:get()
        value:observe(function(new_value)
            self[propName] = new_value
            self:update()
        end)
        table.insert(self._boundProperties, propName)
    else
        self[propName] = value
    end
end

-- Appends a child view to the composite view
function ViewClass:append(v)
    table.insert(self.children, v) -- Add child view to the list of children
end

-- Placeholder function to be implemented by subclasses for updating the view layout
function ViewClass:update()
    -- To be implemented by subclasses
end

-- Calculates and returns the width of the composite view, accounting for children
function ViewClass:width()
    local width = self._width or 0
    width = width + 2 * (self.padding_x or 0) + 2 * (self.border_x or 0) -- Add padding and border
    return width
end

-- Calculates and returns the height of the composite view, accounting for children
function ViewClass:height()
    local height = self._height or 0
    height = height + 2 * (self.padding_y or 0) + 2 * (self.border_y or 0) -- Add padding and border
    return height
end

-- Draws the composite view and its child views
function ViewClass:draw()
    return function(x, y)
        local bx = self.border_x or 0
        local by = self.border_y or 0
        local px = self.padding_x or 0
        local py = self.padding_y or 0

        -- Draw the border if defined
        if self.border_color then
            rectfill(x, y, x + self:width() - 1, y + self:height() - 1, self.border_color)
        end

        -- Draw the background if defined
        if self.background_color then
            local bg_x = x + bx
            local bg_y = y + by
            local bg_w = self:width() - 2 * bx
            local bg_h = self:height() - 2 * by
            rectfill(bg_x, bg_y, bg_x + bg_w - 1, bg_y + bg_h - 1, self.background_color)
        end

        -- Draw content, including children
        local content_x = x + bx + px
        local content_y = y + by + py
        self:drawContent()(content_x, content_y) -- Draw child views or content
    end
end

-- Placeholder function for drawing content, implemented by subclasses
function ViewClass:drawContent()
    return function(x, y)
        -- Placeholder for subclasses
    end
end

-- TextViewClass displays text within a view
TextViewClass = {}
TextViewClass.__index = TextViewClass
setmetatable(TextViewClass, {__index = ConcreteViewClass})

-- Creates a new TextViewClass with text and color properties
function TextViewClass:new(props)
    local o = ConcreteViewClass:new(props) -- Call base class constructor
    setmetatable(o, self)
    props = props or {}
    o:bindProperty("text", props.text or "")   -- Bind text property
    o:bindProperty("color", props.color or 7)  -- Bind color property
    -- Bind any additional properties passed in props
    for k, v in pairs(props) do
        if k ~= "text" and k ~= "color" then
            o:bindProperty(k, v)
        end
    end
    o:update() -- Trigger update to adjust dimensions
    return o
end

-- Updates text view dimensions based on text length
function TextViewClass:update()
    self._width = #(self.text or "") * 5  -- Assume 5 pixels per character
    self._height = 8  -- Assume fixed height of 8 pixels for text
end

-- Draws the text content inside the view
function TextViewClass:drawContent()
    return function(x, y)
        clip(x, y, x + self._width, y + self._height) -- Clip to view dimensions
        print(self.text, x, y, self.color)            -- Draw the text
        clip()                                        -- Reset clipping
    end
end

-- Text component helper function to create TextViewClass instances
function Text(children)
    return function(props)
        local text = children[1] -- Use the first child as the text
        props = props or {}
        props.text = text         -- Set the text property
        local o = TextViewClass:new(props) -- Create new TextViewClass instance
        return o
    end
end

-- VStackClass: Arranges child views vertically with optional spacing and alignment
VStackClass = {}
VStackClass.__index = VStackClass
setmetatable(VStackClass, {__index = ViewClass})

function VStackClass:new(props)
    local o = ViewClass:new(props)
    setmetatable(o, self)
    -- Accept 'align' property with default 'left'
    o:bindProperty("align", props.align or "left")
    o:update()
    return o
end

function VStackClass:update()
    self._width = 0
    self._height = 0
    local total_spacing = self.spacing * math.max(0, #self.children - 1)

    -- Update children and determine stack dimensions
    for _, child in ipairs(self.children) do
        child:update()
        self._width = math.max(self._width, child:width())
        self._height = self._height + child:height()
    end
    self._height = self._height + total_spacing
end

function VStackClass:drawContent()
    return function(x, y)
        local current_y = y
        for _, child in ipairs(self.children) do
            local draw_func = child:draw()
            local child_width = child:width()
            local offset_x = 0

            -- Adjust x-position based on alignment
            if self.align == "center" then
                offset_x = (self._width - child_width) / 2
            elseif self.align == "right" then
                offset_x = self._width - child_width
            elseif self.align == "left" then
                offset_x = 0
            else
                -- Default to 'left' alignment
                offset_x = 0
            end

            draw_func(x + offset_x, current_y)
            current_y = current_y + child:height() + self.spacing
        end
    end
end

function VStack(children)
    return function(props)
        local o = VStackClass:new(props)
        for _, child in ipairs(children) do
            o:append(child)
        end
        return o
    end
end

-- HStackClass: Arranges child views horizontally with optional spacing and alignment
HStackClass = {}
HStackClass.__index = HStackClass
setmetatable(HStackClass, {__index = ViewClass})

function HStackClass:new(props)
    local o = ViewClass:new(props)
    setmetatable(o, self)
    -- Accept 'align' property with default 'top'
    o:bindProperty("align", props.align or "top")
    o:update()
    return o
end

function HStackClass:update()
    self._width = 0
    self._height = 0
    local total_spacing = self.spacing * math.max(0, #self.children - 1)

    -- Update children and determine stack dimensions
    for _, child in ipairs(self.children) do
        child:update()
        self._width = self._width + child:width()
        self._height = math.max(self._height, child:height())
    end
    self._width = self._width + total_spacing
end

function HStackClass:drawContent()
    return function(x, y)
        local current_x = x
        for _, child in ipairs(self.children) do
            local draw_func = child:draw()
            local child_height = child:height()
            local offset_y = 0

            -- Adjust y-position based on alignment
            if self.align == "center" then
                offset_y = (self._height - child_height) / 2
            elseif self.align == "bottom" then
                offset_y = self._height - child_height
            elseif self.align == "top" then
                offset_y = 0
            else
                -- Default to 'top' alignment
                offset_y = 0
            end

            draw_func(current_x, y + offset_y)
            current_x = current_x + child:width() + self.spacing
        end
    end
end

function HStack(children)
    return function(props)
        local o = HStackClass:new(props)
        for _, child in ipairs(children) do
            o:append(child)
        end
        return o
    end
end