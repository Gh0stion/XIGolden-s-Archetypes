local s,id,o=GetID()
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

	-- 2. Special Summon: Equip 1 Synchro
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)

	-- 3. Ignition: Place in Pendulum Zone
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetTarget(s.pentg)
	e3:SetOperation(s.penop)
	c:RegisterEffect(e3)

	-- 4. Trigger: SS/Search on P-Zone move
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_MOVE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.penmovecon)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)

	-- 5. Negate: Requires 2 Pendulums in scales OR 1 Equip Spell
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.discon)
	e5:SetTarget(s.distg)
	e5:SetOperation(s.disop)
	c:RegisterEffect(e5)

	-- 6. Standby Phase: Declare and Banish + Lockdown (Fixed)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,4))
	e6:SetCategory(CATEGORY_REMOVE)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1,id+300)
	e6:SetCondition(s.declcon)
	e6:SetTarget(s.decltg)
	e6:SetOperation(s.declop)
	c:RegisterEffect(e6)
end

function s.tfilter(c) return c:IsSetCard(0x999) end

-- Level Change Logic
function s.lvfilter(c) return c:IsFaceup() and c:IsSetCard(0x999) end
function s.lvcon(e)
	return Duel.IsExistingMatchingCard(s.lvfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,e:GetHandler())
end

-- Equip Logic
function s.eqfilter(c) return c:IsType(TYPE_SYNCHRO) and not c:IsForbidden() end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE+LOCATION_GRAVE) and chkc:IsControler(tp) and s.eqfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.Equip(tp,tc,c) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(function(e,c) return e:GetOwner()==c end)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-- Negation Logic (2 Pendulums OR 1 Equip Spell)
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local c = e:GetHandler()
	if rp == tp or c:IsStatus(STATUS_BATTLE_DESTROYED) or not Duel.IsChainNegatable(ev) then return false end

	-- 2 Pendulum Scales
	local p1 = Duel.GetFieldCard(tp,LOCATION_PZONE,0)
	local p2 = Duel.GetFieldCard(tp,LOCATION_PZONE,1)
	local has_two_pend = p1 and p2 and p1:IsType(TYPE_PENDULUM) and p2:IsType(TYPE_PENDULUM)

	-- 1 Equip Spell
	local has_equip = Duel.IsExistingMatchingCard(function(card) return card:IsType(TYPE_EQUIP) end, tp, LOCATION_SZONE, 0, 1, nil)

	if not (has_two_pend or has_equip) then return false end

	-- One per type per turn
	return (re:IsActiveType(TYPE_MONSTER) and Duel.GetFlagEffect(tp,id)==0)
		or (re:IsActiveType(TYPE_SPELL) and Duel.GetFlagEffect(tp,id+o)==0)
		or (re:IsActiveType(TYPE_TRAP) and Duel.GetFlagEffect(tp,id+o*2)==0)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end

	if re:IsActiveType(TYPE_MONSTER) then
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	elseif re:IsActiveType(TYPE_SPELL) then
		Duel.RegisterFlagEffect(tp,id+o,RESET_PHASE+PHASE_END,0,1)
	elseif re:IsActiveType(TYPE_TRAP) then
		Duel.RegisterFlagEffect(tp,id+o*2,RESET_PHASE+PHASE_END,0,1)
	end
end

-- Standby Phase Logic (Fixed)
function s.declcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsType,TYPE_SYNCHRO),tp,LOCATION_MZONE,0,1,e:GetHandler())
end

function s.decltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	e:SetLabel(Duel.AnnounceType(tp))  -- 0=Monster, 1=Spell, 2=Trap
end

function s.declop(e,tp,eg,ep,ev,re,r,rp)
	local opt = e:GetLabel()
	local typ = opt==0 and TYPE_MONSTER or (opt==1 and TYPE_SPELL or TYPE_TRAP)

	-- Banish opponent's cards of that type
	local g = Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_ONFIELD+LOCATION_HAND,nil,typ)
	if #g > 0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end

	-- Lockdown: Opponent cannot Summon or Activate that type this turn
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0,1)
	e1:SetTarget(function(e,c) return c:IsType(e:GetLabel()) end)
	e1:SetLabel(typ)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetValue(function(e,re,rp) return re:IsActiveType(e:GetLabel()) end)
	Duel.RegisterEffect(e2,tp)
end

-- Pendulum & SS/Search Logic
function s.penfilter(c) return c:IsFaceup() and c:IsSetCard(0x999) and c:IsType(TYPE_PENDULUM) end
function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.penfilter(chkc) end
	if chk==0 then return (Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1))
		and Duel.IsExistingTarget(s.penfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.penfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.penop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true) end
end

function s.penmovecon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(tc) return tc:IsLocation(LOCATION_PZONE) and tc:IsControler(tp) end,1,nil)
end

function s.spfilter(c,e,tp)
	return (c:IsSetCard(0x999) or c:IsRace(RACE_DRAGON)) and c:IsLevelBelow(8)
		and (c:IsAbleToHand() or c:IsCanBeSpecialSummoned(e,0,tp,false,false))
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		local tc=g:GetFirst()
		if tc:IsCanBeSpecialSummoned(e,0,tp,false,false) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and (not tc:IsAbleToHand() or Duel.SelectOption(tp,1190,1152)==1) then
			Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
		else
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tc)
		end
	end
end