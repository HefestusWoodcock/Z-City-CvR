hg.class = hg.class or {}

---@class CLASS_TYPE
---@field name string Name of the class. Shared by all instances initialised under said class.
local CLASS_TYPE = hg.class
CLASS_TYPE.__index = CLASS_TYPE
CLASS_TYPE.name = "Class"

---Checks if `other` is a member of self's ancestry chain.
---@param other CLASS_TYPE An instance or a class to compare to.
---@return boolean bVal Returns true if other is member of the ancestry chain.
function CLASS_TYPE:IsInstanceOf(other)
    for _, meta in ipairs(self:GetChain()) do 
        if meta == other then 
            return true
        end
    end

    return false
end

---Returns the metatable membership chain for an instance.
---@return CLASS_TYPE[] metaChain The metatable chain for the instance.
function CLASS_TYPE:GetChain()
    local metaChain = { self }

    local meta = getmetatable(self)
    while (meta) do 
        table.insert(metaChain, meta)

        meta = getmetatable(meta)
    end

    return metaChain
end

---This method calls the super method of the next table up.
---@see Try looking into making it so you don't need to add in the name of the method whose super you wanna call.
---@param methodName string Name of the method shared by both the parent and child instance.
---@param ... any Any argumets to be passed through the method.
---@return any? # Returns the method's return values.
function CLASS_TYPE:Super(methodName, ...)
    local chain = self:GetChain()

    local callerInfo = debug.getinfo(2, "f")
    local callerFunc = callerInfo and callerInfo.func

    local startIndex = 2
    if callerFunc then 
        for i, cls in ipairs(chain) do 
            if rawget(cls, methodName) == callerFunc then 
                startIndex = i + 1
                break
            end
        end
    end

    for i = startIndex, #chain do 
        local fn = rawget(chain[i], methodName)
        if fn then
            return fn(self, ...)
        end
    end

    error(string.format("Super method %s could not be found.", methodName))
end

---Debugging methods.

---Prints out the name of object, and all its indexed fields.
function CLASS_TYPE:Dump()
    print(tostring(self))

    for k, v in pairs(self) do 
        print(string.format(
            "Key: %s | Value: %s",
            tostring(k),
            tostring(v)))
    end
end

---Returns a string which includes the object name.
---@return string str A string representation of the table.
function CLASS_TYPE:__tostring()
    return "Object of type " .. self.name
end

---Create a new class type using `parent` as inheritance, if provided.
---@generic T : self
---@param name string Replaces the name field for the new class type.
---@param parent CLASS_TYPE A parent class to inherit from.
---@return T new The newly created class type.
---@usage local NEW_CLASS = hg.class:CreateClass("Name", parent)
---@usage local NEW_CLASS = hg.class:CreateCLass("Name")
function CLASS_TYPE:CreateClass(name, parent)
    parent = parent or hg.class

    local new = setmetatable({}, parent)
    new.__index = new
    new.name = name

    return new
end

---Instantiate a new object from the class base.
---@generic T : self
---@return CLASS_TYPE new The newly instantiated object.
---@usage local NEW_CLASS = hg.class:New("New_Class")
function CLASS_TYPE:New()
    local new = setmetatable({}, self)

    return new
end

return CLASS_TYPE