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

	-- 6. BACKROW PROTECTION (Set and Face-up)
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e7:SetRange(LOCATION_MZONE)
	e7:SetTargetRange(LOCATION_SZONE,0)
	e7:SetTarget(s.backrow_tg)
	e7:SetValue(s.prot_val)
	c:RegisterEffect(e7)

	local e8=e7:Clone()
	e8:SetCode(EFFECT_CANNOT_REMOVE)
	c:RegisterEffect(e8)

	local e9=e7:Clone()
	e9:SetCode(EFFECT_CANNOT_TO_DECK)
	c:RegisterEffect(e9)

	-- 7. NEW QUICK EFFECT: REIVE ON SUMMON
	local e10=Effect.CreateEffect(c)
	e10:SetDescription(aux.Stringid(id,0))
	e10:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e10:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e10:SetCode(EVENT_SPSUMMON_SUCCESS)
	e10:SetRange(LOCATION_MZONE)
	e10:SetProperty(EFFECT_FLAG_DELAY)
	e10:SetCountLimit(1,id)
	e10:SetCost(s.countercost)
	e10:SetCondition(s.revcon)
	e10:SetTarget(s.revtg)
	e10:SetOperation(s.revop)
	c:RegisterEffect(e10)

	-- 8. MAIN PHASE: RECRUIT 2
	local e11=Effect.CreateEffect(c)
	e11:SetDescription(aux.Stringid(id,1))
	e11:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e11:SetType(EFFECT_TYPE_IGNITION)
	e11:SetRange(LOCATION_MZONE)
	e11:SetCost(s.countercost)
	e11:SetTarget(s.sptg)
	e11:SetOperation(s.spop)
	c:RegisterEffect(e11)
end

-- SUMMON PROC
function s.syncon(e,c,smat,mg)
	if c==nil then return true end
	if smat then return false end
	local tp=c:GetControler()
	local g1=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,38615480)
	local g2=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,59999377)
	return #g1>0 and #g2>0 and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end
function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk,c,smat,mg)
	local g1=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,38615480)
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

-- HELPERS
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

-- S/T PROTECTION
function s.backrow_tg(e,c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
end
function s.prot_val(e,re,rp)
	return rp==1-e:GetHandlerPlayer()
end

-- REVIVE LOGIC
function s.countercost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,0x1,1,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,0x1,1,REASON_COST)
end
function s.revfilter(c,e,tp)
	return (c:IsType(TYPE_LINK) or c:IsType(TYPE_XYZ))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.revcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c,p) return c:IsControler(p) and (c:IsType(TYPE_LINK) or c:IsType(TYPE_XYZ)) end,1,nil,tp)
end
function s.revtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.revfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.revop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.revfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetValue(s.rev_immune)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end
function s.rev_immune(e,te)
	return te:GetOwner()~=e:GetOwner()
end

-- RECRUIT 2
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x99b) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,2,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,nil,e,tp)
	if #g>=2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=g:Select(tp,2,2,nil)
		Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
	end
end
