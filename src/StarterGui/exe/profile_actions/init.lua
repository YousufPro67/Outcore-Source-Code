----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------

local run_service = game:GetService("RunService")

assert(run_service:IsClient(), "Profile Commands module can only be accessed from the Client.")

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------

local ui = script.Parent
local frame = ui.frame
local profile = frame.profile_panel

local signal = require(script.Signal)

local module = {}
module.__index = module

----------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------

export type CategoryConfigurationDictionary = {
	LayoutOrder: number;
	Name: string;
}

-- Creates a new category.
function module.createCategory(ConfigurationDictionary: CategoryConfigurationDictionary)
	local self = setmetatable({}, module)

	self.Enabled = true
	self.LayoutOrder = ConfigurationDictionary.LayoutOrder or 1
	self.Name = ConfigurationDictionary.Name or "Category"
	
	-- Adding a new category in the interface.
	
	local category = profile.frame.scroll.list.Category:Clone()
	
	category.Name = self.Name
	category.Visible = self.Enabled
	category.LayoutOrder = ConfigurationDictionary.LayoutOrder or 1
	category.Parent = profile.frame.scroll
	
	self._data = {
		object = category
	}

	return self
end

export type ActionConfigurationDictionary = {
	ActionTypes: "Instant" | "Input";
	Display: "Icon" | "Label";
	DisplayValue: "rbxassetid://12974384137";
	LayoutOrder: number;
	Name: string;
}

-- Creates a new action.
function module.createAction(ConfigurationDictionary: ActionConfigurationDictionary, Category)
	local self = setmetatable({}, module)
	
	self.ActionTypes = ConfigurationDictionary.ActionTypes
	
	self.Display = ConfigurationDictionary.Display
	self.DisplayValue = ConfigurationDictionary.DisplayValue
	
	self.Enabled = true
	self.LayoutOrder = ConfigurationDictionary.LayoutOrder or 1
	self.Name = ConfigurationDictionary.Name or "Action"
	
	if self.ActionType == "Instant" then
		self.Triggered = signal.new()
	elseif self.ActionType == "Input" then
		self.Typed = signal.new()
	end
	
	-- Adding a new action in the interface.
	
	local action = Category._data.object.list.Action:Clone()
	
	action.Name = self.Name
	action.Visible = self.Enabled
	
	action.label.Text = self.Name
	
	if self.Display == "Icon" then
		action.icon.Visible = true
		action.icon.Image = self.DisplayValue
		
		action.value.Visible = false
		
	elseif self.Display == "Label" then
		action.value.Visible = true
		action.value.Text = self.DisplayValue
		
		action.icon.Visible = false
	end
	
	action.Parent = Category._data.object
	
	-- Actions and Events
	
	action.MouseButton1Click:Connect(function()
		if self.ActionType == "Instant" and self.Triggered then
			self.Triggered:Fire(Category._data.object.Parent.Parent.Parent.properties.id.Value)
		else
			action.icon.Visible = false
			action.value.Visible = false
			
			action.textbox.Visible = true
			action.textbox:CaptureFocus()
		end
	end)
	
	action.textbox.FocusLost:Connect(function()
		if self.ActionType == "Input" and self.Typed then
			self.Typed:Fire(Category._data.object.Parent.Parent.Parent.properties.id.Value)
			
			action.icon.Visible = ("Icon" == self.Display)
			action.value.Visible = ("Label" == self.Display)
			
			action.textbox.Visible = false
		end
	end)
	
	self._data = {
		object = action
	}
	
	return self
end

return module