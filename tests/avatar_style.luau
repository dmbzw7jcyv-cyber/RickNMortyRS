local fs, luau, r = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox')
local source = fs.readFile('src/server/AvatarStyle.luau')
local AvatarStyle = luau.load(source, {environment = {
	game = {GetService = function() return {} end}, Instance = r.Instance, Enum = r.Enum,
	Color3 = r.Color3, Vector2 = r.Vector2, Vector3 = r.Vector3, CFrame = r.CFrame,
	UDim = r.UDim, UDim2 = r.UDim2,
}})()
local passed = 0
local function check(condition, name) assert(condition, name); passed += 1; print('PASS avatar: '..name) end
local world = r.Instance.new('Folder')
local rig = r.Instance.new('Model'); rig.Parent = world
local humanoid = r.Instance.new('Humanoid'); humanoid.RigType, humanoid.Parent = r.Enum.HumanoidRigType.R6, rig
local function part(name, size, position)
	local p = r.Instance.new('Part'); p.Name, p.Size, p.Position, p.Parent = name, size, position, rig; return p
end
local head = part('Head', r.Vector3.new(2,1,1), r.Vector3.new(0,4.5,0))
part('Torso', r.Vector3.new(2,2,1), r.Vector3.new(0,3,0))
part('Left Arm', r.Vector3.new(1,2,1), r.Vector3.new(-1.5,3,0))
part('Right Arm', r.Vector3.new(1,2,1), r.Vector3.new(1.5,3,0))
part('Left Leg', r.Vector3.new(1,2,1), r.Vector3.new(-0.5,1,0))
part('Right Leg', r.Vector3.new(1,2,1), r.Vector3.new(0.5,1,0))
local accessory = r.Instance.new('Accessory'); accessory.Parent = rig
local shirt = r.Instance.new('Shirt'); shirt.Parent = rig
local oldFace = r.Instance.new('Decal'); oldFace.Name, oldFace.Face, oldFace.Parent = 'face', r.Enum.NormalId.Front, head
check(AvatarStyle.apply(rig), 'production style applies to a complete R6 rig')
local style = rig:FindFirstChild('RickStyle')
check(style and rig:GetAttribute('RickStyled'), 'style folder and marker created')
check(not accessory.Parent and not shirt.Parent, 'old accessories and clothing removed')
check(head:FindFirstChild('RickFace') ~= nil and style:FindFirstChild('HairSpike') ~= nil, 'face and blue hair created')
check(style:FindFirstChild('CyanShirt') and style:FindFirstChild('CoatLeft') and style:FindFirstChild('CoatTailRight'), 'shirt and lab coat created')
local visualParts = 0
for _, item in style:GetDescendants() do
	if item:IsA('BasePart') then
		visualParts += 1
		check(not item.CanCollide and not item.CanTouch and not item.CanQuery, 'visual is inert: '..item.Name)
		check(item:GetAttribute('PortalSurface') == false, 'visual rejects portal placement: '..item.Name)
	end
end
check(visualParts <= 25, 'R6 style remains within lightweight part budget')
local oldStyle = style
check(AvatarStyle.apply(rig) and oldStyle.Parent == nil, 'reapply replaces rather than duplicates style')
local faces = 0
for _, child in head:GetChildren() do if child.Name == 'RickFace' then faces += 1 end end
check(faces == 1, 'reapply keeps exactly one rendered face')
local r15 = r.Instance.new('Model'); r15.Parent = world
local r15Humanoid = r.Instance.new('Humanoid'); r15Humanoid.RigType, r15Humanoid.Parent = r.Enum.HumanoidRigType.R15, r15
local function r15Part(name, size, position)
	local p = r.Instance.new('Part'); p.Name, p.Size, p.Position, p.Parent = name, size, position, r15; return p
end
r15Part('Head', r.Vector3.new(2,1,1), r.Vector3.new(0,5,0))
r15Part('UpperTorso', r.Vector3.new(2,1.6,1), r.Vector3.new(0,3.8,0))
r15Part('LowerTorso', r.Vector3.new(2,0.8,1), r.Vector3.new(0,2.6,0))
for _, side in {'Left', 'Right'} do
	r15Part(side..'UpperArm', r.Vector3.new(0.8,1.2,0.8), r.Vector3.zero)
	r15Part(side..'LowerArm', r.Vector3.new(0.7,1.1,0.7), r.Vector3.zero)
	r15Part(side..'Hand', r.Vector3.new(0.7,0.5,0.7), r.Vector3.zero)
	r15Part(side..'UpperLeg', r.Vector3.new(0.9,1.4,0.9), r.Vector3.zero)
	r15Part(side..'LowerLeg', r.Vector3.new(0.8,1.3,0.8), r.Vector3.zero)
	r15Part(side..'Foot', r.Vector3.new(0.8,0.5,1.1), r.Vector3.zero)
end
check(AvatarStyle.apply(r15), 'production style applies to R15')
check(r15.RightUpperArm.Color == r.Color3.fromRGB(238,239,235) and r15.RightHand.Color == r.Color3.fromRGB(190,181,166), 'R15 coat sleeves preserve skin-colored hands')
check(r15.RightUpperLeg.Color == r.Color3.fromRGB(105,78,42) and r15.RightFoot.Color == r.Color3.fromRGB(37,39,39), 'R15 pants and shoes recolored')
check(r15.UpperTorso.Color == r.Color3.fromRGB(121,211,202) and r15.RickStyle:FindFirstChild('CoatBack'), 'R15 torso and coat back are covered')
check(oldFace.Parent == nil, 'legacy face removed so Phoenix cannot restore its transparency')
check(head.RickFace.FaceBacking.BackgroundTransparency == 0, 'opaque skin backing covers baked face details')
check(head.RickFace.LeftEye:FindFirstChildOfClass('UIAspectRatioConstraint').AspectRatio == 1 and head.RickFace.LeftEye.Size.X.Scale < 0.25, 'eyes are smaller and constrained to circles')
local tail = r15.RickStyle.CoatTailLeft
check(tail:FindFirstChildOfClass('WeldConstraint').Part0 == r15.LowerTorso and tail.CFrame.Position.Z < -r15.LowerTorso.Size.Z/2, 'coat tails attach at hips and remain visible in front of legs')
print(string.format('%d avatar style checks passed; Studio appearance still requires inspection.', passed))
