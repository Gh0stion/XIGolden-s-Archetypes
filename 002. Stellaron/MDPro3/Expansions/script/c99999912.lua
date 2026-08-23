local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Material: 99999901 + 99999902
	c:EnableReviveLimit()
	aux.AddFusionProcMix(c,true,true,99999901,99999902)
	
	-- MUST enable the ability to hold Spell Counters (0x1)
	c:EnableCounterPermit(0x1)

	-- 1. Continuous: Place 1 Spell Counter on Fusion Summon
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.cntcon)
	e1:SetOperation(s.cntop)
	c:RegisterEffect(e1)

	-- 2. Continuous: Gain 500 LP during each Standby Phase (While has counter)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.lpcon)
	e2:SetOperation(s.lpop)
	c:RegisterEffect(e2)

	-- 3. Ignition: Remove 1 Counter to Banish (Main Phase)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCost(s.remcost)
	e3:SetTarget(s.remtg)
	e3:SetOperation(s.remop)
	c:RegisterEffect(e3)

	-- 4. Quick Effect: Spell/Trap Negation
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_NEGATE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.negcon)
	e4:SetCost(s.negcost)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)

	-- 5. Continuous: Place 1 Spell Counter during each Standby Phase
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetOperation(s.cntop)
	c:RegisterEffect(e5)
end

-- Counter Logic (Continuous)
function s.cntcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.cntop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() then
		c:AddCounter(0x1,1)
	end
end

-- LP Logic (Continuous)
function s.lpcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetCounter(0x1)>0
end
function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id) -- Visual cue since continuous effects don't "activate"
	Duel.Recover(tp,500,REASON_EFFECT)
end

-- Banish Logic (Ignition)
function s.remcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,0x1,1,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,0x1,1,REASON_COST)
end
function s.remtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end 
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_MZONE,1,nil)
		and Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g1=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g2=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,1,nil)
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g1,2,0,0)
end
function s.remop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainTargetsInfo(e):Filter(Card.IsRelateToEffect,nil,e)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end

-- Negation Logic
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and (re:IsActiveType(TYPE_SPELL) or re:IsActiveType(TYPE_TRAP))
		and Duel.IsChainNegatable(ev)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.SendtoGrave(eg,REASON_EFFECT)
	end
end
