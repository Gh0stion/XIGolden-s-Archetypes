local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Material: 3 "Stellaron" Monsters
	c:EnableReviveLimit()
	aux.AddFusionProcMixRep(c,true,true,s.matfilter,3,3)

	-- 1. Cannot be negated
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_DISABLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EFFECT_CANNOT_DISEFFECT)
	c:RegisterEffect(e1b)
	
	local e1c=Effect.CreateEffect(c)
	e1c:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1c:SetCode(EVENT_CHAINING)
	e1c:SetRange(LOCATION_MZONE)
	e1c:SetOperation(s.chainop)
	c:RegisterEffect(e1c)

	-- 2. Targeted Trap Negate (Extra Deck) - HOPT
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN+CATEGORY_NEGATE+CATEGORY_REMOVE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	-- 3. Counter on Summon + ATK boost
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_COUNTER+CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetOperation(s.sumctop)
	c:RegisterEffect(e3)
	
	local e3b=Effect.CreateEffect(c)
	e3b:SetType(EFFECT_TYPE_SINGLE)
	e3b:SetCode(EFFECT_UPDATE_ATTACK)
	e3b:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3b:SetRange(LOCATION_MZONE)
	e3b:SetValue(s.atkval)
	c:RegisterEffect(e3b)

	-- 4. Quick Effect: Remove counter to SS Token - HOPT
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e4:SetCountLimit(1,id+1)
	e4:SetCondition(function(e) return Duel.IsMainPhase() end)
	e4:SetCost(s.tkcost)
	e4:SetTarget(s.tktg)
	e4:SetOperation(s.tkop)
	c:RegisterEffect(e4)

	-- 5. Standby Phase: Add Counter
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetOperation(s.standbyctop)
	c:RegisterEffect(e5)
end

s.listed_names={99999924}

function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x999) and c:IsType(TYPE_MONSTER)
end

function s.chainop(e,tp,eg,ep,ev,re,r,rp)
	if re:GetHandler()==e:GetHandler() then
		Duel.SetChainLimit(s.chainlimit)
	end
end
function s.chainlimit(e,rp,tp)
	return tp==rp
end

-- Ultimate Floodgate Detection Logic
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not re:IsActiveType(TYPE_TRAP) or not Duel.IsChainNegatable(ev) then return false end
	
	local rc=re:GetHandler()
	local check=false

	-- 1. Check Card IDs for absolute certainty
	local floodgates = {
		82732707, -- Skill Drain
		10045474, -- There Can Only Be One
		53582587, -- Gozen Match
		81674782, -- Anti-Spell Fragrance
		47355498, -- Macro Cosmos
		92731388, -- Rivalry of Warlords
		27204311, -- Dimensional Barrier
		58851034  -- Summon Limit
	}
	for _,code in ipairs(floodgates) do
		if rc:IsCode(code) then check=true break end
	end

	-- 2. Check if it's Continuous/Field (Most floodgates are)
	if not check and (rc:IsType(TYPE_CONTINUOUS) or rc:IsType(TYPE_FIELD)) then
		check=true
	end

	-- 3. Check for specific Categories even if it's a Normal Trap
	if not check then
		local cat=re:GetCategory()
		if (cat&CATEGORY_DISABLE)~=0 or (cat&CATEGORY_SPECIAL_SUMMON)~=0 then
			check=true
		end
	end

	return check
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,99999924,0,TYPES_TOKEN,2500,2000,4,RACE_WARRIOR,ATTRIBUTE_LIGHT) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 
		or not Duel.IsPlayerCanSpecialSummonMonster(tp,99999924,0,TYPES_TOKEN,2500,2000,4,RACE_WARRIOR,ATTRIBUTE_LIGHT) then return end
	local token=Duel.CreateToken(tp,99999924)
	if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)>0 then
		if Duel.NegateActivation(ev) then
			-- Look at all facedown S/T
			local g=Duel.GetMatchingGroup(Card.IsFacedown,tp,0,LOCATION_SZONE,nil)
			if #g>0 then Duel.ConfirmCards(tp,g) end
			
			-- Banish up to 2 Spell/Traps
			for i=1,2 do
				if Duel.IsExistingMatchingCard(Card.IsType,tp,0,LOCATION_SZONE,1,nil,TYPE_SPELL+TYPE_TRAP) then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
					local sg=Duel.SelectMatchingCard(tp,Card.IsType,tp,0,LOCATION_SZONE,1,1,nil,TYPE_SPELL+TYPE_TRAP)
					if #sg>0 then Duel.Remove(sg,POS_FACEUP,REASON_EFFECT) end
				end
			end
			
			-- Token disappears if summoned from Extra Deck
			if c:IsLocation(LOCATION_EXTRA) then
				Duel.BreakEffect()
				Duel.Destroy(token,REASON_EFFECT)
			end
		end
	end
end

-- Counter Mechanics
function s.sumctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:GetCounter(0x57fc)<1 then
		c:AddCounter(0x57fc,1)
	end
end
function s.standbyctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:GetCounter(0x57fc)<1 then
		c:AddCounter(0x57fc,1)
	end
end
function s.atkval(e,c)
	return c:GetCounter(0x57fc)*500
end

-- Quick Effect: Token Summon
function s.tkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,0x57fc,1,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,0x57fc,1,REASON_COST)
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,99999924,0,TYPES_TOKEN,2500,2000,4,RACE_WARRIOR,ATTRIBUTE_LIGHT) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and Duel.IsPlayerCanSpecialSummonMonster(tp,99999924,0,TYPES_TOKEN,2500,2000,4,RACE_WARRIOR,ATTRIBUTE_LIGHT) then
		local token=Duel.CreateToken(tp,99999924)
		Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
	end
end
