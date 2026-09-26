--[[ Spinach config — pure settings table. Sliders only write here. ]]
local Config = {}

Config.Name = "Spinach"
Config.Version = "0.2.0"

-- Player
Config.WalkSpeed = 16
Config.JumpPower = 50
Config.FlightSpeed = 50
Config.SpinSpeed = 2
Config.Noclip = false
Config.InfJump = false
Config.Flight = false
Config.CharSpin = false

-- Throw CONFIG ONLY (never applied in slider callbacks)
Config.SuperThrow = false
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
Config.AntiGucciMode = "Normal" -- Normal | Aggressive
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
Config.NoclipBarrier = false -- plot barrier; NOT character noclip
Config.AntiInvis = false
Config.AutoReset = false
-- UNSUPPORTED / UNKNOWN (not implemented as fake behavior)
Config.AntiNetworkOwnership = false -- UNKNOWN
Config.NetOwnerSpam = false -- UNKNOWN

-- Camera / Third Person
Config.ThirdPerson = false
Config.TPDistance = 8
Config.TPShoulder = 2
Config.TPHeight = 1
Config.TPCollision = true
Config.FOV = 70

-- Visual
Config.PlayerESP = false
Config.DistESP = false
Config.HealthESP = false
Config.TargetESP = false
Config.Rainbow = false
Config.ESPMaxDist = 400

-- Settings
Config.MenuKey = Enum.KeyCode.RightControl
Config.SkipIntro = false
Config.NotifEnabled = true
Config.Accent = Color3.fromRGB(0, 200, 130)
Config.WhitelistEnabled = true
Config.AutoWLFriends = true

return Config
