local s,id=GetID()
function s.initial_effect(c)
	-- 1. Standard Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	c:RegisterEffect(e1)

	-- 2. Activate from hand
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)

	-- 3. Trigger Effect: Resource Cycle (Mandatory)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOEXTRA)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCondition(s.cyclecon)
	e3:SetTarget(s.cycletg)
	e3:SetOperation(s.cycleop)
	c:RegisterEffect(e3)

	-- 4. Protection for "Altria Pendragon Saber Servant" (99999925)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e4:SetTarget(aux.TargetBoolFunction(Card.IsCode,99999925))
	e4:SetValue(s.efilter)
	c:RegisterEffect(e4)

	-- 5. Anti-Response: Opponent cannot respond to Stellaron Spells (Fixes Ash Blossom issue)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_SZONE)
	e5:SetOperation(s.chainop)
	c:RegisterEffect(e5)
end

s.listed_names={99999925}
s.listed_series={0x999}

-- Hand activation check
function s.handcon(e)
	return Duel.GetFieldGroupCount(e:GetHandlerPlayer(),LOCATION_MZONE,0)==0
end

-- Cycle Logic
function s.cyclefilter(c,tp)
	return c:IsSetCard(0x999) and c:GetSummonPlayer()==tp
end
function s.cyclecon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cyclefilter,1,nil,tp)
end

function s.pfilter(c)
	return c:IsSetCard(0x999) and c:IsType(TYPE_PENDULUM) 
		and (c:IsLocation(LOCATION_GRAVE) or (c:IsFaceup() and c:IsLocation(LOCATION_REMOVED)))
end
function s.gfilter(c)
	return c:IsSetCard(0x999) and c:IsLocation(LOCATION_REMOVED)
end

function s.cycletg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.cycleop(e,tp,eg,ep,ev,re,r,rp)
	local b1=Duel.IsExistingMatchingCard(s.pfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.gfilter,tp,LOCATION_REMOVED,0,1,nil)
	local opt=0
	if b1 and b2 then
		opt=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		opt=Duel.SelectOption(tp,aux.Stringid(id,1))
	elseif b2 then
		opt=Duel.SelectOption(tp,aux.Stringid(id,2))
		opt=1
	else return end
	if opt==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOEXTRA)
		local g=Duel.SelectMatchingCard(tp,s.pfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
		if #g>0 then Duel.SendtoExtraP(g,tp,REASON_EFFECT) end
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,s.gfilter,tp,LOCATION_REMOVED,0,1,1,nil)
		if #g>0 then Duel.SendtoGrave(g,REASON_EFFECT+REASON_RETURN) end
	end
end

-- Altria Protection
function s.efilter(e,te)
	return not te:GetHandler():IsSetCard(0x999)
end

-- Anti-Response Logic
function s.chainop(e,tp,eg,ep,ev,re,r,rp)
	local tc=re:GetHandler()
	if re:IsActiveType(TYPE_SPELL) and tc:IsSetCard(0x999) and rp==tp then
		Duel.SetChainLimit(s.chainlimit)
	end
end
function s.chainlimit(e,rp,tp)
	return tp==rp
end
