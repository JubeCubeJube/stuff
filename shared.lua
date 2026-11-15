ENT.Base 			= "base_nextbot"
ENT.Spawnable		= false
ENT.PrintName       = 'simple chaser lol'

function ENT:Initialize()
    
    self.matrix = Matrix()
    self.matrix:Translate(Vector(0,0,0))
    if self:GetModel() == 'models/sn/forsaken/coolkid/skins/mafioso/minion.mdl' then
        self.matrix:Rotate(Angle(0,180,0))
    end

	self:EnableMatrix("RenderMultiply", self.matrix)
end

function ENT:OnKilled()

	local ragdoll = ents.Create('prop_ragdoll')
	ragdoll:SetModel(self:GetModel())
    ragdoll:SetModelScale(1)
    ragdoll:SetPos(self:GetPos() or Vector(0,0,0))
    ragdoll:SetAngles(self:GetAngles() or Angle(0,0,0))

    for _,i in ipairs(self:GetBodyGroups()) do
        ragdoll:SetBodygroup(i.id,self:GetBodygroup(i.id))
    end

    ragdoll:SetSkin(self:GetSkin())

    ragdoll:SetColor(self:GetColor())
    ragdoll:Spawn()
    ragdoll:Activate()

    ragdoll:SetVelocity(self:GetVelocity())
    ragdoll:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

    if IsValid( self ) and IsValid( ragdoll ) then
        for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
            local bone = ragdoll:GetPhysicsObjectNum( i )
            if ( IsValid( bone ) ) then
                local pos, ang = self:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )
                if ( pos ) then bone:SetPos( pos ) end
                if ( ang ) then bone:SetAngles( ang ) end
            end
        end
    end

	timer.Simple(15,function()
		if IsValid(ragdoll) then
			ragdoll:Remove()
		end
	end)

	self:Remove()
end