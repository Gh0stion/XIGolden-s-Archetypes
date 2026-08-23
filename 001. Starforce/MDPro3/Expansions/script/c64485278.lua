local s,id=GetID()
function s.initial_effect(c)
    -- Token properties are usually set by the parent card, 
    -- but we define the continuous effects here.
    
    -- 1. Immune to other card effects (except own and Rouge Noise)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetValue(s.efilter)
    c:RegisterEffect(e1)
    
    -- 2. Battle Protection (No destruction + No damage)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e2:SetValue(1)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
    c:RegisterEffect(e3)
    
    -- 3. Protect Extra Monster Zone
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_IMMUNE_EFFECT)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTargetRange(LOCATION_MZONE,0)
    e4:SetTarget(s.emzfilter)
    e4:SetValue(s.oppfilter)
    c:RegisterEffect(e4)
    
    -- 4. Gain 3000 ATK/DEF if it's the only Token
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCode(EFFECT_UPDATE_ATTACK)
    e5:SetCondition(s.atkcon)
    e5:SetValue(3000)
    c:RegisterEffect(e5)
    local e6=e5:Clone()
    e6:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e6)
    
    -- 5. Destroy if opponent Special Summons 5 times from Extra Deck
    local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e7:SetCode(EVENT_SPSUMMON_SUCCESS)
	e7:SetRange(LOCATION_MZONE)
	e7:SetOperation(s.regop)
	c:RegisterEffect(e7)
end

-- Immune Filter: Affected only by itself and Rouge Noise (60411322)
function s.efilter(e,te)
    return te:GetOwner()~=e:GetOwner() and not te:GetOwner():IsCode(60411322)
end

-- Target monsters in EMZ
function s.emzfilter(e,c)
    return c:GetSequence()>=5
end

-- Immune to opponent's effects
function s.oppfilter(e,te)
    return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- Check if it is the only token
function s.atkcon(e)
    local tp=e:GetHandlerPlayer()
    local g=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_MZONE,0,nil,TYPE_TOKEN)
    return #g==1
end

-- Counter logic for the 5-Summon destruction
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local turn_player=Duel.GetTurnPlayer()
	if rp==turn_player or rp==tp then return end -- Only count opponent's summons
	
	local count=0
	local tc=eg:GetFirst()
	while tc do
		if tc:IsSummonLocation(LOCATION_EXTRA) and tc:GetSummonPlayer()~=tp then
			count=count+1
		end
		tc=eg:GetNext()
	end
	
	if count>0 then
		for i=1,count do
			-- We use a custom flag to track the count per turn
			local ct=c:GetFlagEffectLabel(id) or 0
			c:ResetFlagEffect(id)
			c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1,ct+1)
			if ct+1>=5 then
				Duel.Destroy(c,REASON_EFFECT)
				break
			end
		end
	end
end
