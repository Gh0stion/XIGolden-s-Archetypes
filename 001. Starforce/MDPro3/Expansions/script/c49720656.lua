local s,id=GetID()
function s.initial_effect(c)
	-- ① Activate: Search on activation
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- ① Opponent cannot target Starforce monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_FZONE)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.tglimit)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
	
	-- ② Cannot activate during battle
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(0,1)
	e3:SetCondition(s.actcon)
	e3:SetValue(s.actlimit)
	c:RegisterEffect(e3)
	
	-- ③ Make Starforce monster unaffected
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TARGET)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_FZONE)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCountLimit(1,{id,1})
	e4:SetTarget(s.immtg)
	e4:SetOperation(s.immop)
	c:RegisterEffect(e4)
	
	-- ④ Banish from opponent's hand when Megaman is summoned
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetRange(LOCATION_FZONE)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCountLimit(1,{id,2})
	e5:SetCondition(s.rmcon)
	e5:SetTarget(s.rmtg)
	e5:SetOperation(s.rmop)
	c:RegisterEffect(e5)
	
	-- ⑤ ATK/DEF reduction in Standby Phase (One trigger per turn marker)
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e6:SetRange(LOCATION_FZONE)
	e6:SetCondition(s.atkcon)
	e6:SetOperation(s.atkop)
	c:RegisterEffect(e6)
	
	-- ⑤ Additional ATK/DEF reduction during Battle Phase
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetCode(EFFECT_UPDATE_ATTACK)
	e7:SetRange(LOCATION_FZONE)
	e7:SetTargetRange(0,LOCATION_MZONE)
	e7:SetCondition(s.bpcon)
	e7:SetValue(-200)
	c:RegisterEffect(e7)
	local e8=e7:Clone()
	e8:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e8)
end

-- 1. Search filter and merged activation operation
function s.thfilter(c)
	return c:IsSetCard(0x99b) and c:IsLevelBelow(4) and c:IsAbleToHand()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,1,nil)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end

-- 1. Targeting Protection
function s.tglimit(e,c)
	return c:IsSetCard(0x99b) and c:IsFaceup()
end

-- 2. Battle Protection
function s.actcon(e)
	local tp=e:GetHandlerPlayer()
	local bc=Duel.GetAttacker()
	if bc and bc:IsControler(1-tp) then bc=Duel.GetAttackTarget() end
	return bc and bc:IsSetCard(0x99b) and bc:IsControler(tp)
end
function s.actlimit(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
end

-- 3. Unaffected Target
function s.immfilter(c)
	return c:IsSetCard(0x99b) and c:IsFaceup()
end
function s.immtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.immfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.immfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.immfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.immop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetValue(s.efilter)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
		e1:SetOwnerPlayer(tp)
		tc:RegisterEffect(e1)
	end
end
function s.efilter(e,re)
	return e:GetOwnerPlayer()~=re:GetOwnerPlayer()
end

-- 4. Hand Rip
function s.rmfilter(c,tp)
	return c:IsFaceup() and (c:IsCode(16440678) or c:IsCode(21298482)) 
		and c:IsControler(tp) and c:IsSummonType(SUMMON_TYPE_SPECIAL)
end
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.rmfilter,1,nil,tp)
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	if #g>0 then
		local sg=g:RandomSelect(tp,1)
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
	end
end

-- 5. ATK/DEF Reduction
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnCount()~=e:GetLabel() and Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	e:SetLabel(Duel.GetTurnCount())
	if #g==0 then return end
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-200)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		tc:RegisterEffect(e2)
	end
end
function s.bpcon(e)
	return Duel.IsBattlePhase()
end
