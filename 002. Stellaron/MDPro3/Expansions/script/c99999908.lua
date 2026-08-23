local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon: 1 "Stellaron" Tuner + 1+ non-Tuner monsters
	aux.AddSynchroProcedure(c,s.tfilter,aux.NonTuner(nil),1)
	c:EnableReviveLimit()

	-- 1. Continuous Effect: Level becomes 12 while you control other "Stellaron" monsters
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_LEVEL)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.lvcon)
	e1:SetValue(12)
	c:RegisterEffect(e1)

	-- 2. Multi-choice Negation (Opponent Only)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	-- 3. Equip Effect: Special Summon Fusion from Extra Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.eqcon)
	e3:SetTarget(s.eqtg)
	e3:SetOperation(s.eqop)
	c:RegisterEffect(e3)
end

-- Synchro Material Filter
function s.tfilter(c)
	return c:IsSetCard(0x999)
end

-- 1. Continuous Level Change Logic
function s.lvfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x999)
end
function s.lvcon(e)
	local tp=e:GetHandlerPlayer()
	-- Check for other "Stellaron" monsters
	return Duel.IsExistingMatchingCard(s.lvfilter,tp,LOCATION_MZONE,0,1,e:GetHandler())
end

-- 2. Negation Logic (Opponent Only)
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local sg=g:Select(tp,1,4,nil)
	local count=#sg
	if Duel.SendtoGrave(sg,REASON_EFFECT)>0 and Duel.NegateActivation(ev) then
		if count>=1 then
			local rg=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil)
			if #rg>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
				local rsg=rg:Select(tp,1,1,nil)
				Duel.Remove(rsg,POS_FACEUP,REASON_EFFECT)
			end
		end
		if count>=2 then
			local gy=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil)
			if #gy>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
				local rgy=gy:Select(tp,1,math.min(#gy,2),nil)
				Duel.Remove(rgy,POS_FACEUP,REASON_EFFECT)
			end
		end
		if count>=3 then
			local f1=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_ONFIELD,nil,TYPE_MONSTER)
			local f2=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_ONFIELD,nil,TYPE_SPELL+TYPE_TRAP)
			if #f1>0 then
				local sf1=f1:Select(tp,1,1,nil)
				Duel.Remove(sf1,POS_FACEUP,REASON_EFFECT)
			end
			if #f2>0 then
				local sf2=f2:Select(tp,1,1,nil)
				Duel.Remove(sf2,POS_FACEUP,REASON_EFFECT)
			end
			local h=Duel.GetFieldGroup(tp,0,LOCATION_HAND):RandomSelect(tp,1)
			if #h>0 then Duel.Remove(h,POS_FACEUP,REASON_EFFECT) end
		end
		if count>=4 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_IMMUNE_EFFECT)
			e1:SetTargetRange(LOCATION_MZONE,0)
			e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x999))
			e1:SetValue(s.efilter)
			e1:SetReset(RESET_PHASE+PHASE_MAIN1+RESET_SELF_TURN,1)
			Duel.RegisterEffect(e1,tp)
		end
	end
end
function s.efilter(e,re)
	return e:GetHandler()~=re:GetOwner()
end

-- 3. Equip Effect
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetEquipTarget()~=nil
end
function s.fssfilter(c,e,tp,lv)
	return c:IsSetCard(0x999) and c:IsType(TYPE_FUSION) and c:IsLevel(lv)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.synfilter(c,e,tp)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsLevelAbove(7) and c~=e:GetHandler()
		and Duel.IsExistingMatchingCard(s.fssfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c:GetLevel())
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.synfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.synfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.synfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.fssfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc:GetLevel())
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end
