local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon: 5 "Stellaron" monsters
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c,s.matfilter,5,5)

	-- 1. Special Summon cannot be negated
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e0)

	-- 2. Turn Summoned: Effects cannot be negated + Unaffected (except by Stellaron)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_DISABLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCondition(s.immcon)
	c:RegisterEffect(e1)
	
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetCondition(s.immcon)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)

	-- 3. Thrice Per Turn: Negate monster interference (Quick Effect)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_NEGATE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(3)
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)

	-- 4. ATK Boost: 1000 for each Extra Deck monster opponent controls
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetValue(s.atkval)
	c:RegisterEffect(e4)

	-- 5. Battle Phase: Direct Attack (Halved Damage)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_DIRECT_ATTACK)
	e5:SetCondition(s.bpcon)
	c:RegisterEffect(e5)
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e6:SetCondition(s.bpcon)
	e6:SetValue(aux.ChangeBattleDamage(1,HALF_DAMAGE))
	c:RegisterEffect(e6)

	-- 6. Battle Phase: Protection for "Stellaron" monsters
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e7:SetRange(LOCATION_MZONE)
	e7:SetTargetRange(LOCATION_MZONE,0)
	e7:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x999))
	e7:SetCondition(s.bpcon)
	e7:SetValue(1)
	c:RegisterEffect(e7)
	local e8=e7:Clone()
	e8:SetCode(EFFECT_CANNOT_REMOVE)
	c:RegisterEffect(e8)
	local e9=e7:Clone()
	e9:SetCode(EFFECT_CANNOT_TO_GRAVE)
	c:RegisterEffect(e9)

	-- 7. Targeting Response: Set "Fusion" or "Poly" Spell (Quick Effect)
	local e10=Effect.CreateEffect(c)
	e10:SetDescription(aux.Stringid(id,1))
	e10:SetType(EFFECT_TYPE_QUICK_O)
	e10:SetCode(EVENT_BECOME_TARGET)
	e10:SetRange(LOCATION_MZONE)
	e10:SetCondition(s.setcon)
	e10:SetTarget(s.settg)
	e10:SetOperation(s.setop)
	c:RegisterEffect(e10)

	-- 8. Pointing Protection: (If pointing to 3+ monsters)
	local e11=Effect.CreateEffect(c)
	e11:SetType(EFFECT_TYPE_FIELD)
	e11:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e11:SetRange(LOCATION_MZONE)
	e11:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e11:SetCondition(s.protcon)
	e11:SetTarget(s.prottg)
	e11:SetValue(1)
	c:RegisterEffect(e11)
end

-- Helpers & Filters
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x999)
end

function s.immcon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK) and e:GetHandler():GetTurnID()==Duel.GetTurnCount()
end

function s.efilter(e,te)
	return not te:GetOwner():IsSetCard(0x999)
end

-- ATK Logic
function s.atkfilter(c)
	return c:IsType(TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK)
end
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,c:GetControler(),0,LOCATION_MZONE,nil)*1000
end

-- Battle Phase Check
function s.bpcon(e)
	local ph=Duel.GetCurrentPhase()
	return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end

-- Negation Logic
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if not (rp==1-tp and Duel.IsChainNegatable(ev)) then return false end
	local ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
	local ex2,tg2,tc2=Duel.GetOperationInfo(ev,CATEGORY_REMOVE)
	local ex3,tg3,tc3=Duel.GetOperationInfo(ev,CATEGORY_TODECK)
	local ex4,tg4,tc4=Duel.GetOperationInfo(ev,CATEGORY_DISABLE)
	
	local function filter(c,p)
		return c:IsControler(p) and c:IsLocation(LOCATION_MZONE)
	end
	
	return (ex and tg and tg:IsExists(filter,1,nil,tp))
		or (ex2 and tg2 and tg2:IsExists(filter,1,nil,tp))
		or (ex3 and tg3 and tg3:IsExists(filter,1,nil,tp))
		or (ex4 and tg4 and tg4:IsExists(filter,1,nil,tp))
		or re:IsHasCategory(CATEGORY_NEGATE)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-- Targeting/Set Logic
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsContains(e:GetHandler())
end
function s.setfilter(c)
	return c:IsSetCard(0x46) and c:IsType(TYPE_SPELL) 
		and (c:IsType(TYPE_NORMAL) or c:IsType(TYPE_QUICKPLAY)) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
	end
end

-- Pointing Logic
function s.protcon(e)
	local c=e:GetHandler()
	local g=c:GetLinkedGroup():Filter(Card.IsType,nil,TYPE_MONSTER)
	return #g>=3
end
function s.prottg(e,c)
	return e:GetHandler():GetLinkedGroup():IsContains(c)
end
