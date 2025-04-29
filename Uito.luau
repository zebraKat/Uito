--!optimize 2

local json = require("./Json")
local uito = {}

export type stringBool      = "true" | "false" | string
export type alignx          = "Left" | "Right" | "Center"| string
export type aligny     		  = "Top"  | "Bottom"| "Center"| string
export type truncate  		  = "None" | "AtEnd" | "SplitWord"| string
export type image_scaleType = "Stretch" | "Crop" | "Fit" | "Slice" | "Tile"| string
export type image_resample  = "Default" | "Pixelated"| string
export type stroke_mode     = "Contextual" | "Border" | string
export type stroke_type     = "Round" | "Miter" | "Bevel" | string
export type UitoClass       = "Frame" | "ImageLabel" | "TextLabel" | 
	"Folder"| "TextBox" | "UIStroke" | 
	"UIGradient" | "UIPadding" | "UISizeConstraint" | 
	"UIAspectRatioConstraint" | "UIGridLayout" |"UIListLayout" |
	"UICorner" | string

export type UitoObject      = {
	globalid:string,
	class:UitoClass,
	alias:string
}

-- GUI STYLING

export type UitoPadding = UitoObject&{
	top:string,
	left:string,
	bottom:string,
	right:string,
	class:"UIPadding"
}

export type UitoGradient = UitoObject&{
	rotation:string,
	gradient_transparency: string,
	gradient_color: string,
	class:"UIGradient",
	gradient_offset:string
}

export type UitoSizeConst = UitoObject&{
	class:"UISizeConstraint" | string,
	max_size:string,
	min_size:string
}

export type UitoAspect = UitoObject&{
	class: "UIAspectRatioConstraint" | string,
	ratio: string
}

export type UitoGrid = UitoObject&{
	class:"UIGridLayout"| string,
	padding:string,
	alignment_horizontal:alignx,
	alignment_vertical:aligny,
	size:string
}

export type UitoList = UitoObject&{
	class: "UIListLayout"| string,
	direction: "Horizontal" | "Vertical"| string,
	alignment_horizontal: alignx,
	alignment_vertical: aligny,
	padding:string,
	wrap_list:stringBool
}

export type UitoCorner = UitoObject&{
	radius:string,
	class:"UICorner"| string
}

export type UitoStroke = {
	stroke_color:string,
	stroke_mode:stroke_mode,
	stroke_type:stroke_type,
	stroke_thickness:string,
	stroke_transparency:string,
	class:"UIStroke"| string
}

--GUI OBJECTS
export type UitoGuiObject = UitoObject&{
	tooltip:string,
	visible:stringBool,
	rotation:string,
	background_transparency:string,
	background_color:string,
	position:string,
	anchor:string,
	z_index:string,
	children:{{UitoObject}}?,
	size:string
}
export type UitoTextParams  = {
	font_color:string,
	align_x:alignx,
	align_y:aligny,
	truncate:truncate,
	text:string,
	font_size:string,
	font:string,
	font_transparency:string,
	rich:stringBool,
	wrap:stringBool,
}
export type UitoImageParams = {
	scale_type:image_scaleType,
	image_id:string,
	image:string,
	image_color:string,
	resample_mode:image_resample,
	image_transparency:string
}
export type UitoFrame       = UitoGuiObject&{
	class: "Frame"| string
}
export type UitoScrollFrame = UitoFrame&{
	scrollbar_transparency:string,
	scrollbar_thickness:string,
	scrollbar_color:string,
	canvassize:string
}
export type UitoTextLabel = UitoGuiObject&UitoTextParams&{
	class: "TextLabel"| string
}
export type UitoImageLabel = UitoGuiObject&UitoImageParams&{
	class: "ImageLabel"| string
}
export type UitoTextInput  = UitoGuiObject&UitoTextParams&{
	class: "TextBox"| string,
	editable:stringBool,
	placeholder_color:string,
	placeholder:string,
	multiline:stringBool
}
export type UitoFolder     = UitoObject&{
	class:"Folder" | string
}


local function ParseFrame(Frame:GuiObject,Class:UitoClass):UitoFrame
	assert(Frame and Frame:IsA("GuiObject"), "Expected a valid frame to parse instead got "..typeof(Frame))
	return {
		class=Class,
		globalid=json.getID(),
		alias = Frame.Name or "FRAMENAME_PLACEHOLDER",
		tooltip = Frame:GetAttribute("tooltip") or " ",
		visible = tostring(Frame.Visible),
		rotation = tostring(Frame.Rotation),
		background_transparency = tostring(Frame.BackgroundTransparency),
		background_color = Frame.BackgroundColor3:ToHex(),
		position = tostring(Frame.Position),
		anchor = tostring(Frame.AnchorPoint),
		z_index = tostring(Frame.ZIndex),
		size = tostring(Frame.Size),
		children = {},
	}
end

local function ParseScrollFrame(Frame:ScrollingFrame):UitoScrollFrame
	assert(
		Frame and type(Frame) == "userdata" and Frame:IsA("ScrollingFrame"),
		`Expected a scrolling frame to parse instead got {typeof(Frame)}, {if typeof(Frame) == "Instance" then Frame.ClassName else "" }`
	)
	local BaseParsed = ParseFrame(Frame,"ScrollingFrame")
	
	BaseParsed.scrollbar_transparency = tostring(Frame.ScrollBarImageTransparency)
	BaseParsed.scrollbar_thickness = tostring(Frame.ScrollBarThickness)
	BaseParsed.scrollbar_color = tostring(Frame.ScrollBarImageColor3:ToHex())
	BaseParsed.canvassize = tostring(Frame.CanvasSize)
	
	return BaseParsed
end

local function ParseTextLabel(Label:TextLabel | TextButton,Class:UitoClass):UitoTextLabel
	assert(Label:IsA("TextLabel") or Label:IsA("TextButton") or Label:IsA("TextBox"), "Expected a valid text label to parse.")
	local BaseParsed = ParseFrame(Label,Class)
	
	BaseParsed.font_color = Label.TextColor3:ToHex()
	if Class ~= "TextButton" and Class ~= "TextBox" then BaseParsed.font_transparency = tostring(Label.TextTransparency) end
	BaseParsed.font = tostring(Label.Font.Name)
	BaseParsed.font_size = Label.TextScaled and "scaled" or tostring(Label.TextSize)
	
	BaseParsed.align_x = tostring(Label.TextXAlignment.Name)
	BaseParsed.align_y = tostring(Label.TextYAlignment.Name)
	
	BaseParsed.truncate = tostring(Label.TextTruncate.Name)
	
	BaseParsed.rich = tostring(Label.RichText)
	BaseParsed.wrap = tostring(Label.TextWrapped)
	
	BaseParsed.text = Label.Text
	
	
	return BaseParsed
end

local function ParseTextInput(TxtInp:TextBox)
	assert(
		TxtInp and type(TxtInp) == "userdata" and TxtInp:IsA("TextBox"),
		"Expected a valid TextBox to parse instead got "..typeof(TxtInp)..if typeof(TxtInp) == "Instance" then TxtInp.ClassName else ""
	)
	local BaseParsed = ParseTextLabel(TxtInp,"TextBox")
	BaseParsed.editable = tostring(TxtInp.TextEditable)
	BaseParsed.placeholder_color = TxtInp.PlaceholderColor3:ToHex()
	BaseParsed.placeholder = tostring(TxtInp.PlaceholderText)
	BaseParsed.multiline = tostring(TxtInp.MultiLine)	
	return BaseParsed
end

local function ParseImageObj(Obj:GuiObject,Class:UitoClass):UitoImageLabel
	assert(Obj:IsA("ImageLabel") or Obj:IsA("ImageButton"),"Expected a Image Ui Element. (Image Label | Image Button)")
	local BaseParsed = ParseFrame(Obj,Class)
	BaseParsed.scale_type = tostring(Obj.ScaleType.Name)::string
	BaseParsed.image = tostring(Obj.Image)::string
	BaseParsed.resample_mode = tostring(Obj.ResampleMode.Name)::string
	BaseParsed.image_transparency = tostring(Obj.ImageTransparency)::string
	return BaseParsed
end

local function ParseFolderObj(Folder:Folder):UitoFolder
	assert( Folder and type(Folder) == "userdata" and Folder:IsA("Folder"), "Expected a folder to parse instead got "..typeof(Folder))
	return {
		globalid = tostring(json.getID()),
		class = "Folder",
		alias = tostring(Folder.Name),
		children={}
	}
end

local function ParseUIStroke(UiStroke:UIStroke):UitoStroke
	assert(
		UiStroke and type(UiStroke) == "userdata" and UiStroke:IsA("UIStroke"),
		"Expected a valid UI stroke. Instead got "..typeof(UiStroke)..if typeof(UiStroke)=="Instance" then UiStroke.ClassName else ""
	)
	local Base = {}
	Base.globalid = json.getID()
	Base.class = "UIStroke"
	Base.alias = UiStroke.Name
	Base.stroke_color = UiStroke.Color:ToHex()
	Base.stroke_mode = tostring(UiStroke.ApplyStrokeMode.Name)
	Base.stroke_type = tostring(UiStroke.LineJoinMode.Name)
	Base.stroke_thickness = tostring(UiStroke.Thickness)
	Base.stroke_transparency = tostring(UiStroke.Transparency)
	return Base
end

local function ParseUICorner(UiCorner:UICorner):UitoCorner
	assert(
		UiCorner and type(UiCorner) == "userdata" and UiCorner:IsA("UICorner"),
		"Expected a valid UI Corner. Instead got "..typeof(UiCorner)..if typeof(UiCorner)=="Instance" then UiCorner.ClassName else ""
	)
	local Base = {}
	Base.globalid = json.getID()
	Base.alias = UiCorner.Name
	Base.class = "UICorner"
	Base.radius = tostring(UiCorner.CornerRadius)
	return Base	
end

local function ParseUIListLayout(List:UIListLayout):UitoList
	assert(
		List and type(List) == "userdata" and List:IsA("UIListLayout"),
		`Expected a valid UIListLayout to parse instead got {typeof(List)}, {if typeof(List) == "Instance" then List.ClassName else ""}`
	)
	local Parsed = {}
	Parsed.class = "UIListLayout"
	Parsed.alias = List.Name
	Parsed.globalid = json.getID()
	Parsed.direction = List.SortOrder.Name
	Parsed.alignment_horizontal = List.HorizontalAlignment.Name
	Parsed.alignment_vertical = List.VerticalAlignment.Name
	Parsed.padding = tostring(List.Padding)
	Parsed.wrap_list = tostring(List.Wraps)
	return Parsed
end

local function ParseUIGridLayout(Grid:UIGridLayout):UitoGrid
	assert(
		Grid and type(Grid) == "userdata" and Grid:IsA("UIGridLayout"),
		`Expected a valid UIGridLayout to parse instead got {typeof(Grid)}, {if typeof(Grid) == "Instance" then Grid.ClassName else ""}`
	)
	local Parsed = {}
	Parsed.alias = Grid.Name
	Parsed.class = "UIGridLayout"
	Parsed.globalid = json.getID()
	Parsed.alignment_horizontal = Grid.HorizontalAlignment.Name
	Parsed.alignment_vertical = Grid.VerticalAlignment.Name
	Parsed.padding = tostring(Grid.CellPadding)
	Parsed.size = tostring(Grid.CellSize)
	return Parsed
end

local function ParseUIAspectRatio(Ratio:UIAspectRatioConstraint):UitoAspect
	assert(
		Ratio and type(Ratio) == "userdata" and Ratio:IsA("UIAspectRatioConstraint"),
		`Expected a valid UIAspectRatioConstraint to parse instead got {typeof(Ratio)}, {if typeof(Ratio) == "Instance" then Ratio.ClassName else ""}`
	)
	local Parsed = {}
	Parsed.class = "UIAspectRatioConstraint"
	Parsed.alias = Ratio.Name
	Parsed.globalid = json.getID()::string
	Parsed.ratio = tostring(Ratio.AspectRatio)::string
	return Parsed
end

local function ParseUISizeConstraint(Constraint:UISizeConstraint):UitoAspect
	assert(
		Constraint and type(Constraint) == "userdata" and Constraint:IsA("UISizeConstraint"),
		`Expected a valid UISizeConstraint to parse instead got {typeof(Constraint)}, {if typeof(Constraint) == "Instance" then Constraint.ClassName else ""}`
	)
	local Parsed = {}
	Parsed.class = "UISizeConstraint"
	Parsed.alias = Constraint.Name
	Parsed.globalid = json.getID()::string
	Parsed.max_size = tostring(Constraint.MaxSize)
	Parsed.min_size = tostring(Constraint.MinSize)
	
	return Parsed
end

local function ParseColorSequence(ColorSequence:ColorSequence)
	assert(ColorSequence)
	local t = {} 
	for i,keypoint in ipairs(ColorSequence.Keypoints) do
		t[i] = {keypoint.Time,keypoint.Value:ToHex()} 
	end
	return json.encode(t)
end

local function ParseNumberSequence(NumSequence:NumberSequence)
	assert(NumSequence)
	local t = {} 
	for i,keypoint in ipairs(NumSequence.Keypoints) do
		t[i] = {keypoint.Time,keypoint.Value} 
	end
	return json.encode(t)
end

local function ParseUIGradient(Gradient:UIGradient):UitoGradient
	assert(
		Gradient and type(Gradient) == "userdata" and Gradient:IsA("UIGradient"),
		`Expected a valid UIGradient to parse instead got {typeof(Gradient)}, {if typeof(Gradient) == "Instance" then Gradient.ClassName else ""}`
	)
	local Parsed = {}
	Parsed.class = "UIGradient"
	Parsed.alias = Gradient.Name
	Parsed.globalid = json.getID()::string
	Parsed.gradient_color = ParseColorSequence(Gradient.Color)
	Parsed.gradient_transparency = ParseNumberSequence(Gradient.Transparency)
	Parsed.rotation = tostring(Gradient.Rotation)
	Parsed.gradient_offset = tostring(Gradient.Offset)
	return Parsed
end


local function ParseUiPadding(Padding:UIPadding)
	assert(
		Padding and type(Padding) == "userdata" and Padding:IsA("UIPadding"),
		`Expected a valid UIPadding to parse instead got {typeof(Padding)}, {if typeof(Padding) == "Instance" then Padding.ClassName else ""}`
	)
	local Parsed = {}
	Parsed.class = "UIPadding"
	Parsed.alias = Padding.Name
	Parsed.globalid = json.getID()::string
	
	Parsed.top = tostring(Padding.PaddingTop)
	Parsed.bottom = tostring(Padding.PaddingBottom)
	Parsed.left = tostring(Padding.PaddingLeft)
	Parsed.right = tostring(Padding.PaddingRight)
	
	return Parsed
end

local function PointToParserForObject(RootObject:GuiObject):UitoGuiObject
	assert(
		RootObject and type(RootObject) == "userdata",
		"Expected a valid Instance to parse as a root. Instead got ".. typeof(RootObject)
	)
	local RootParsed = nil
	if RootObject:IsA("Frame") then
		RootParsed = ParseFrame(RootObject, "Frame")
	elseif RootObject:IsA("ScrollingFrame") then
		RootParsed = ParseScrollFrame(RootObject)
	elseif RootObject:IsA("TextLabel") or RootObject:IsA("TextButton") then
		RootParsed = ParseTextLabel(RootObject,RootObject.ClassName)
	elseif RootObject:IsA("ImageLabel") then
		RootParsed = ParseImageObj(RootObject,"ImageLabel")
	elseif RootObject:IsA("Folder") then
		RootParsed = ParseFolderObj(RootObject)
	elseif RootObject:IsA("TextBox") then
		RootParsed = ParseTextInput(RootObject)
	elseif RootObject:IsA("UIStroke") then
		RootParsed = ParseUIStroke(RootObject)
	elseif RootObject:IsA("UICorner") then
		RootParsed = ParseUICorner(RootObject)
	elseif RootObject:IsA("UIListLayout") then
		RootParsed = ParseUIListLayout(RootObject)
	elseif RootObject:IsA("UIGridLayout") then
		RootParsed = ParseUIGridLayout(RootObject)
	elseif RootObject:IsA("UIAspectRatioConstraint") then
		RootParsed = ParseUIAspectRatio(RootObject)
	elseif RootObject:IsA("UISizeConstraint") then
		RootParsed = ParseUISizeConstraint(RootObject)
	elseif RootObject:IsA("UIGradient") then
		RootParsed = ParseUIGradient(RootObject)
	elseif RootObject:IsA("UIPadding") then
		RootParsed = ParseUiPadding(RootObject)
	else
		--unreachable;
		error("Invalid Gui object found. Catweb only supports: Frames, TextLabels, TextButtons, ImageLabels, TextInputs, Scrolling Frames, and Folders. "..RootObject.ClassName)
	end
	return RootParsed
end

local function RecursiveParse(Obj:GuiObject,ParentTable:{children:{}}?)
	local R = PointToParserForObject(Obj)
	local Children = Obj:GetChildren()
	if ParentTable then table.insert(ParentTable.children,R) end
	
	if #Children > 0 then 
		for _,child in Children do
			RecursiveParse(child,R)
		end 
	end
	
	return R
end

function uito.ParseUiStruct(Obj:GuiObject)
	return RecursiveParse(Obj)
end

function uito.toJson(a:UitoObject)
	return `[{json.encode(a)}]`
end

return uito
