local s,id=GetID()
function s.initial_effect(c)
	-- 1. You can only control one (Unique)
	c:SetUniqueOnField(1,0,id)

	-- 2. Protect OTHER "Stellaron" from targeting (Quick Effect) - HOPT
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_BECOME_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.protcon)
	e1:SetTarget(s.prottg)
	e1:SetOperation(s.protop)
	c:RegisterEffect(e1)

	-- 3. Jing Yuan is unaffected while this is on field (Continuous)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsCode,99999923))
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)

	-- 4. Reveal Extra Deck for ATK/DEF (Quick Effect) - HOPT
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+1)
	e3:SetCondition(function(e) return Duel.IsMainPhase() end)
	e3:SetCost(s.atkcost)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)

	-- 5. Discard to be unaffected during Chain (Quick Effect) - HOPT
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_BECOME_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+2)
	e4:SetCondition(s.selfprotcon)
	e4:SetCost(s.selfprotcost)
	e4:SetOperation(s.selfprotop)
	c:RegisterEffect(e4)

	-- 6. Battle Phase ATK Absorption (Quick Effect) - HOPT
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_ATKCHANGE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id+3)
	e5:SetCondition(function(e) return Duel.IsBattlePhase() end)
	e5:SetTarget(s.abstg)
	e5:SetOperation(s.absop)
	c:RegisterEffect(e5)

	-- 7. Destroy during Standby Phase (Continuous)
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e6:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e6:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetOperation(s.desop)
	c:RegisterEffect(e6)

	-- 8. Destroy if Jing Yuan leaves (Continuous)
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e7:SetCode(EVENT_LEAVE_FIELD)
	e7:SetRange(LOCATION_MZONE)
	e7:SetOperation(s.desop2)
	c:RegisterEffect(e7)
end

s.listed_names={99999923}

function s.efilter(e,re)
	return not re:GetHandler():IsSetCard(0x999)
end

-- 2. Protection logic (Excluding self)
function s.protcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsControler,1,nil,tp) and eg:IsExists(Card.IsSetCard,1,nil,0x999) and rp~=tp
end
function s.prottg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsSetCard(0x999) and chkc~=c end
	if chk==0 then return Duel.IsExistingTarget(function(tc) return tc:IsSetCard(0x999) and tc~=c end,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,function(tc) return tc:IsSetCard(0x999) and tc~=c end,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.protop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetValue(s.efilter)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_BATTLE)
		tc:RegisterEffect(e1)
	end
end

-- 4. Reveal stats logic
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_EXTRA,0,1,nil,TYPE_MONSTER) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,Card.IsType,tp,LOCATION_EXTRA,0,1,1,nil,TYPE_MONSTER)
	local tc=g:GetFirst()
	Duel.ConfirmCards(1-tp,g)
	e:SetLabel(tc:GetAttack(),tc:GetDefense())
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local atk,def=e:GetLabel()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(atk)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		e2:SetValue(def)
		c:RegisterEffect(e2)
	end
end

-- 5. Discard for protection logic
function s.selfprotcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsContains(e:GetHandler()) and rp~=tp
end
function s.selfprotcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.selfprotop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetValue(s.efilter)
		e1:SetReset(RESET_CHAIN)
		c:RegisterEffect(e1)
	end
end

-- 6. Battle ATK absorption logic
function s.abstg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsType(TYPE_FUSION) and chkc:IsSetCard(0x999) end
	if chk==0 then return Duel.IsExistingTarget(function(c) return c:IsSetCard(0x999) and c:IsType(TYPE_FUSION) end,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,function(c) return c:IsSetCard(0x999) and c:IsType(TYPE_FUSION) end,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.absop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local atk=tc:GetBaseAttack()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(0)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_UPDATE_ATTACK)
		e2:SetValue(atk)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e2)
	end
end

-- 7 & 8. Destruction logic
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end
function s.desop2(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(Card.IsCode,1,nil,99999923) then
		Duel.Destroy(e:GetHandler(),REASON_EFFECT)
	end
end
