local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon: 1 "Stellaron" Tuner + 1+ non-Tuner monsters
	aux.AddSynchroProcedure(c,s.tfilter,aux.NonTuner(nil),1)
	c:EnableReviveLimit()

	-- 1. Continuous Level Change
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_LEVEL)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.lvcon)
	e1:SetValue(12)
	c:RegisterEffect(e1)

	-- 2. Forced Defense Position
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SET_POSITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetTarget(s.postg)
	e2:SetValue(POS_FACEUP_DEFENSE)
	c:RegisterEffect(e2)

	-- 3. Cannot Change Battle Position
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)
	c:RegisterEffect(e3)

	-- 4. Burn & End Battle Phase (Quick Effect)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_DAMAGE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_BE_BATTLE_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetTarget(s.damtg)
	e4:SetOperation(s.damop)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EVENT_BE_CUSTOM_TARGET)
	c:RegisterEffect(e5)
end

-- Synchro Material Filter
function s.tfilter(c)
	return c:IsSetCard(0x999)
end

-- 1. Level Change Logic
function s.lvfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x999)
end
function s.lvcon(e)
	return Duel.IsExistingMatchingCard(s.lvfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,e:GetHandler())
end

-- 2. Defense Position Logic
function s.postg(e,c)
	return c:IsStatus(STATUS_SUMMON_TURN) or c:IsStatus(STATUS_SPSUMMON_TURN)
end

-- 4. Burn Logic
function s.damfilter(c)
	return (c:IsLocation(LOCATION_MZONE) and c:IsFaceup()) or c:IsLocation(LOCATION_GRAVE)
end
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and s.damfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.damfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.damfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,1,1,nil)
	local tc=g:GetFirst()
	local val=tc:GetAttack()+tc:GetDefense()
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,val)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		local val=math.max(0,tc:GetAttack()+tc:GetDefense())
		if Duel.Damage(1-tp,val,REASON_EFFECT)>0 then
			Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_BATTLE,RESET_PHASE+PHASE_BATTLE,1)
		end
	end
end
