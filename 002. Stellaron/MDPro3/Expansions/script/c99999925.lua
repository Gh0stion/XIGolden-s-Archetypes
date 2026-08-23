local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Material: 3 "Stellaron" Monsters
	c:EnableReviveLimit()
	aux.AddFusionProcMixRep(c,true,true,s.matfilter,3,3)

	-- 1. Continuous Counter Logic (Summon & Standby)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_ADJUST)
	e1:SetRange(LOCATION_MZONE)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	-- 2. Constant ATK Boost: +2500 if Scales exist + Direct Attack
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetCondition(s.scalecon)
	e2:SetValue(2500)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_DIRECT_ATTACK)
	c:RegisterEffect(e3)

	-- 3. Gains 500 ATK/DEF per S/T card
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetValue(s.stval)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e5)

	-- 4. Damage Halving if ATK > 2500
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e6:SetCondition(s.halfcon)
	e6:SetValue(aux.ChangeBattleDamage(1,HALF_DAMAGE))
	c:RegisterEffect(e6)

	-- 5. Quick Effect: Synchro from Deck (HOPT + Total SS Lock)
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,0))
	e7:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e7:SetType(EFFECT_TYPE_QUICK_O)
	e7:SetCode(EVENT_FREE_CHAIN)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCountLimit(1,id)
	e7:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e7:SetCondition(s.sccon)
	e7:SetCost(s.sccost)
	e7:SetTarget(s.sctg)
	e7:SetOperation(s.scop)
	c:RegisterEffect(e7)
end

-- Continuous Counter Logic
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- If it has no counters and wasn't used as cost this turn, add 1
	if c:GetCounter(0x57fc)==0 and c:GetFlagEffect(id)==0 then
		c:AddCounter(0x57fc,1)
	end
end

-- Filters
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x999) and c:IsType(TYPE_MONSTER)
end
function s.scalecon(e)
	return Duel.IsExistingMatchingCard(nil,e:GetHandlerPlayer(),LOCATION_PZONE,0,1,nil)
end
function s.stval(e,c)
	return Duel.GetFieldGroupCount(c:GetControler(),LOCATION_SZONE,0)*500
end
function s.halfcon(e)
	return e:GetHandler():GetAttack()>2500
end

-- Engine Logic
function s.sccon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end

function s.sccost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsCanRemoveCounter(tp,0x57fc,1,REASON_COST) end
	c:RemoveCounter(tp,0x57fc,1,REASON_COST)
	-- Register flag so the Continuous effect doesn't immediately refill it
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
end

function s.syncfilter(c,e,tp)
	return c:IsSetCard(0x999) and c:IsType(TYPE_SYNCHRO) 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
		and Duel.IsExistingMatchingCard(s.matfilter1,tp,LOCATION_DECK,0,1,nil,c,tp)
end
function s.matfilter1(c,syncard,tp)
	return c:IsSetCard(0x999) and c:IsType(TYPE_TUNER) and c:IsAbleToGrave()
		and Duel.IsExistingMatchingCard(s.matfilter2,tp,LOCATION_DECK,0,1,c,syncard,c)
end
function s.matfilter2(c,syncard,tuner)
	return c:IsSetCard(0x999) and not c:IsType(TYPE_TUNER) and c:IsAbleToGrave()
		and (c:GetLevel()+tuner:GetLevel()==syncard:GetLevel())
end

function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCountFromEx(tp)>0
		and Duel.IsExistingMatchingCard(s.syncfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.scop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp)<=0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local scg=Duel.SelectMatchingCard(tp,s.syncfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local sc=scg:GetFirst()
	if not sc then return end
	
	Duel.ConfirmCards(1-tp,sc)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.matfilter1,tp,LOCATION_DECK,0,1,1,nil,sc,tp)
	local tc1=g1:GetFirst()
	if not tc1 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(tp,s.matfilter2,tp,LOCATION_DECK,0,1,1,tc1,sc,tc1)
	local tc2=g2:GetFirst()
	if not tc2 then return end
	
	local mat=Group.FromCards(tc1,tc2)
	if Duel.SendtoGrave(mat,REASON_EFFECT)>0 then
		Duel.BreakEffect()
		if Duel.SpecialSummonStep(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP) then
			sc:CompleteProcedure()
			Duel.SpecialSummonComplete()
			
			-- Total SS Lockout
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
			e1:SetDescription(aux.Stringid(id,2)) 
			e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
			e1:SetTargetRange(1,0)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
		end
	end
end
