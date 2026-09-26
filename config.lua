--[[ Pengu config — pure settings table. Sliders only write here. ]]
local Config = {}

Config.Name = "Pengu"
Config.Version = "0.3.1"

-- Player / movement
Config.SpeedEnabled = false
Config.WalkSpeed = 16
Config.JumpEnabled = false
Config.JumpPower = 50
Config.Flight = false
Config.FlightSpeed = 50
Config.CharSpin = false
Config.SpinSpeed = 12
Config.Noclip = false
Config.InfJump = false

-- Throw CONFIG ONLY
Config.SuperThrow = false -- legacy alias
Config.ThrowMult = 3.5
Config.StrengthValue = 3.5
Config.SuperStrength = false
Config.FlingUp = false
Config.Slam = false
Config.VoidFling = false
Config.SpinFling = false
Config.GrabReach = false
Config.MaxGrabReach = 30

-- Target
Config.NearestTarget = false
Config.TargetLock = false
Config.DistLimit = 200
Config.FriendWL = true

-- Auras
Config.FlingAura = false
Config.RagdollAura = false
Config.SitAura = false
Config.SpinAura = false
Config.BringAura = false
Config.VoidAura = false
Config.AuraRange = 25
Config.AuraCD = 0.4
Config.AuraMax = 3
Config.AuraIgnoreFriends = true

-- Blobman
Config.BlobLoop = false
Config.BlobGrabAll = false

-- Defense
Config.AntiGrab = false
Config.AntiGrabGucci = false
Config.AntiGucci = false
Config.AntiGucciMode = "Normal"
Config.AntiGucciInterval = 0.15
Config.AntiGucciEmergencyOnly = true
Config.AntiBlobman = false
Config.AntiRagdoll = false
Config.InstantGetUp = false
Config.AntiSit = false
Config.AntiVoid = false
Config.AntiFling = false
Config.AntiBurn = false
Config.AntiLag = false
Config.AutoAntiLag = true
Config.AntiSticky = false
Config.AntiBanana = false
Config.AntiPaint = false
Config.AntiSnowball = false
Config.AntiPoison = false
Config.AntiExplosion = false
Config.DisableVoid = false
Config.NoclipBarrier = false
Config.AntiInvis = false
Config.AutoReset = false
Config.AntiNetworkOwnership = false
Config.NetOwnerSpam = false

-- Camera
Config.ThirdPerson = false
Config.TPDistance = 8
Config.TPMinZoom = 0.5
Config.TPMaxZoom = 32
Config.TPShoulder = 0
Config.TPHeight = 1
Config.TPCollision = true
Config.FOV = 70

-- Visual
Config.PlayerESP = false
Config.DistESP = false
Config.HealthESP = false
Config.TargetESP = false
Config.ObjectESP = false
Config.Rainbow = false
Config.ESPMaxDist = 400

-- World
Config.Fullbright = false
Config.NoFog = false
Config.NoShadows = false
Config.CustomTime = false
Config.ClockTime = 14

-- UI
Config.RainbowUI = false
Config.RainbowSpeed = 0.12
Config.MenuKey = Enum.KeyCode.RightControl
Config.SkipIntro = false
Config.NotifEnabled = true
Config.Accent = Color3.fromRGB(119, 0, 255)
Config.WhitelistEnabled = true
Config.AutoWLFriends = true

return Config
