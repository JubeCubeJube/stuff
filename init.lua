AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')

ENT.NoAI = false


function ENT:PlayGesture(name, rate, layerblend, loop, cycleTime)
    local layer = self:AddLayeredSequence(self:LookupSequence(name or ''))
    self:SetLayerPlaybackRate(layer, rate or 1)
    self:SetLayerBlendIn(layer, layerblend2 or 0)
    self:SetLayerBlendOut(layer, layerblend or 0)
    self:SetLayerCycle(layer, cycleTime or 0)
    self:SetLayerLooping(layer, loop or false)
    if not loop then
		self:SetLayerAutokill(layer, 1)
    end
end

function ENT:Initialize()
    -- self:SetModel("models/sn/forsaken/coolkid/minion.mdl")

    self:SetCollisionBounds(Vector(-12, -12, 0)/2, Vector(12, 12, 80)/2)

	self.Active = true

	self.loco:SetDesiredSpeed( 192 )

	self.loco:SetStepHeight(20)

	self:SetSolid( SOLID_BBOX )
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:SetMoveType(MOVETYPE_VPHYSICS)

	self:SetHealth(10)

	timer.Simple(30,function()
		if IsValid(self) then
			self:Remove()
		end
	end)
end

ENT.CurrentAnim = 'ref'

function ENT:PlayAnim(name, rate, cycle)
	if self.CurrentAnim == self:LookupSequence(name or '') then
		return
	end
    self.CurrentAnim = self:LookupSequence(name or '')
	self:ResetSequence(self.CurrentAnim)
    self:SetPlaybackRate(rate)
    self:SetCycle(cycle or 0)
end

function ENT:SetEnemy()
	ent = player.GetAll()[math.random(1,#player.GetAll())]
	self.Enemy = ent
end

function ENT:FindEnemy()
    local nearestDist = math.huge
    for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and ply ~= self:GetOwner() and IsValid(ply) then
			local dist = self:GetPos():Distance(ply:GetPos())
			if dist < nearestDist then
				nearestDist = dist
				if ply == self then return end
                self.Enemy = ply
            end
        end
    end
end

function ENT:AnimationBehavior()
	velocity = self.loco:GetVelocity():Length()/2
    if velocity < 10 then
        self:PlayAnim('idle', 1)
    elseif velocity > 10 then
        self:PlayAnim('walk', 1.45)
    end
end

function ENT:Think()

	if self.NoAI then self.Enemy = nil return end
	self:AnimationBehavior()

	if not self.Enemy then
		self:FindEnemy()
		return
	end
end

function ENT:HitEnemy(enemy)
	if self.hittime then return end
	self.hittime = true
	self.NoAI = true
	timer.Simple(0.1,function()
		if IsValid(self) then
			self:PlayGesture('m1',1,0,false,0)
			enemy:SNApplyEffect('slowness', {time = 15, lvl = 2})
			enemy:SNApplyEffect('burning', {time = 3, lvl = 1, owner = self:GetOwner()})
			
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(15)
            dmginfo:SetAttacker(self)
            dmginfo:SetDamageType(DMG_BURN)
            dmginfo:SetDamagePosition(self:GetPos())
            dmginfo:SetDamageForce(self:EyeAngles():Forward() * 1000000000)

			enemy:TakeDamageInfo(dmginfo)
		end
		timer.Simple(2,function()
			if IsValid(self) then
				self:Remove()
			end
		end)
	end)
end

function ENT:RunBehaviour()
	while ( true ) do
		if ( self.Enemy ) then

			self.loco:FaceTowards(self.Enemy:GetPos())

			self:ChaseEnemy( {draw=false} )
		else
		end
		coroutine.wait(0.1)
	end
end

function ENT:ChaseEnemy( options )
	local enemy = self.Enemy

	local options = options or {}
	local path = Path( "Follow" )

	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )

	path:Chase( self, enemy )
	path:Compute( self, enemy:GetPos() )

	if ( !path:IsValid() ) then return "failed" end
	
	while ( path:IsValid() and enemy ) do
		
		if ( self.NoAI ) then return "failed" end

		local trace = {
			start = enemy:GetPos(),
			endpos = enemy:GetPos() - Vector(0, 0, 16384),
			filter = enemy
		}
		local tr = util.TraceEntity(trace, enemy)
		if tr.Hit and util.IsInWorld(tr.HitPos) then
			targetPos = tr.HitPos
		end

		path:Compute(self, targetPos)

		self:FindEnemy()

		if enemy:IsFlagSet(FL_FROZEN) then enemy = nil self:FindEnemy() return "failed" end
		if not IsValid(enemy) or not IsValid(self) then return end

		if self:GetPos():Distance(enemy:GetPos())<48 and enemy:Alive() and not enemy:IsFlagSet(FL_FROZEN) then
			local trace = {
				start = self:GetPos(),
				endpos = enemy:GetPos(),
				filter = {self, enemy}
			}
			local tr = util.TraceLine(trace)

			if tr.HitWorld then return end
			self:HitEnemy(enemy)
		end
		path:Update( self )
		if ( options.draw ) then path:Draw() end
		if ( self.loco:IsStuck() ) then
			self:HandleStuck()
			return "stuck"
		end
		coroutine.yield()
	end

	return "ok"
end