local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	c:EnableCounterPermit(0x1)

	-- 1. CUSTOM SYNCHRO PROCEDURE (Leo 38615480 + Geo 59999377)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.syncon)
	e1:SetTarget(s.syntg)
	e1:SetOperation(s.synop)
	e1:SetValue(SUMMON_TYPE_SYNCHRO)
	c:RegisterEffect(e1)

	-- 2. EFFECTS CANNOT BE NEGATED
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_DISABLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_MZONE)
	c:RegisterEffect(e2)

	-- 3. COUNTER ON SUMMON & STANDBY RELOAD
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetOperation(s.ctop)
	c:RegisterEffect(e3)

	local e_rel=Effect.CreateEffect(c)
	e_rel:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e_rel:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e_rel:SetRange(LOCATION_MZONE)
	e_rel:SetCondition(s.reloadcon)
	e_rel:SetOperation(s.ctop)
	c:RegisterEffect(e_rel)

	-- 4. ATK BUFF & IMMUNITY (While Counter Exists)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetCondition(s.hasct)
	e4:SetValue(1000)
	c:RegisterEffect(e4)

	local e5=e4:Clone()
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetValue(s.efilter)
	c:RegisterEffect(e5)

	-- 5. ATTACK RESTRICTION (LP >= 7000)
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_CANNOT_ATTACK)
	e6:SetCondition(s.atklimit)
	c:RegisterEffect(e6)

	-- 6. LP GAIN / BURN ON OPPONENT SPECIAL SUMMON
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e7:SetCode(EVENT_SPSUMMON_SUCCESS)
	e7:SetRange(LOCATION_MZONE)
	e7:SetOperation(s.lpop)
	c:RegisterEffect(e7)

	-- 7. QUICK EFFECT: GY LOCK AND SPELL RESTRICTION
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,0))
	e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e8:SetCode(EVENT_SPSUMMON_SUCCESS)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCondition(s.lockcon)
	e8:SetCost(s.countercost)
	e8:SetOperation(s.lockop)
	c:RegisterEffect(e8)

	-- 8. MAIN PHASE: RECRUIT 2 (From Hand, Deck, or GY)
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,1))
	e9:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e9:SetType(EFFECT_TYPE_IGNITION)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCost(s.countercost)
	e9:SetTarget(s.sptg)
	e9:SetOperation(s.spop)
	c:RegisterEffect(e9)

	-- Summon Tracker for Effect #7
	if not s.global_check then
		s.global_check=true
		s.sum_count={}
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
		local ge2=ge1:Clone()
		ge2:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		ge2:SetOperation(s.clearop)
		Duel.RegisterEffect(ge2,0)
	end
end

-- SUMMON PROC
function s.syncon(e,c,smat,mg)
	if c==nil then return true end
	if smat then return false end
	local tp=c:GetControler()
	local g1=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,30411028)
	local g2=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,59999377)
	return #g1>0 and #g2>0 and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end
function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk,c,smat,mg)
	local g1=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,30411028)
	local g2=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,59999377)
	local g=Group.CreateGroup()
	g:AddCard(g1:GetFirst())
	g:AddCard(g2:GetFirst())
	if #g==2 then g:KeepAlive() e:SetLabelObject(g) return true end
	return false
end
function s.synop(e,tp,eg,ep,ev,re,r,rp,c,smat,mg)
	local g=e:GetLabelObject()
	c:SetMaterial(g)
	Duel.SendtoGrave(g,REASON_MATERIAL+REASON_SYNCHRO)
	g:DeleteGroup()
end

-- TRACKING & COUNTERS
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local p=rp
	s.sum_count[p]=(s.sum_count[p] or 0)+#eg:Filter(Card.IsControler,nil,p)
end
function s.clearop(e,tp,eg,ep,ev,re,r,rp)
	s.sum_count[0]=0
	s.sum_count[1]=0
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():AddCounter(0x1,1)
end
function s.hasct(e)
	return e:GetHandler():GetCounter(0x1)>0
end
function s.reloadcon(e)
	return e:GetHandler():GetCounter(0x1)==0
end
function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end
function s.atklimit(e)
	return Duel.GetLP(1-e:GetHandlerPlayer())<7000
end
function s.countercost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,0x1,1,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,0x1,1,REASON_COST)
end

-- LP GAIN/BURN
function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(Card.IsControler,1,nil,1-tp) then
		Duel.Recover(tp,250,REASON_EFFECT)
		Duel.Damage(1-tp,400,REASON_EFFECT)
	end
end

-- QUICK EFFECT LOCK
function s.lockcon(e,tp,eg,ep,ev,re,r,rp)
	return (s.sum_count[1-tp] or 0)>4
end
function s.lockop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- GY Lock
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0,1)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	-- Must Set Spells
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(0,1)
	e2:SetValue(s.setfirst)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end
function s.aclimit(e,re,tp)
	return re:GetActivateLocation()==LOCATION_GRAVE
end
function s.setfirst(e,re,tp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsActiveType(TYPE_SPELL) and not re:GetHandler():IsStatus(STATUS_SET_TURN)
end

-- RECRUIT 2
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x99b) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,2,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 or Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT) then return end
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,nil,e,tp)
	if #g>=2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=g:Select(tp,2,2,nil)
		Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
	end
end
