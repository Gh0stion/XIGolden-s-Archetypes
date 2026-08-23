local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_LIMIT_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_names={93717133}
s.listed_series={0x55,0x7b,0x48,0x307b,0x999}

function s.xyzfilter(c,e,tp)
	return c:IsType(TYPE_XYZ) and c:IsRankBelow(8) 
		and (c:IsSetCard(0x55) or c:IsSetCard(0x7b) or c:IsSetCard(0x48))
		and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK,0,1,nil,c,e,tp)
end

function s.spfilter1(c,xyzc,e,tp)
	return (c:IsSetCard(0x55) or c:IsSetCard(0x7b) or c:IsSetCard(0x307b))
		and c:GetLevel()==xyzc:GetRank()
		and (c:IsType(xyzc:GetType()&TYPE_MONSTER) or c:IsAttribute(xyzc:GetAttribute()))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(s.gepdfilter,tp,LOCATION_DECK,0,1,c,e,tp)
end

function s.gepdfilter(c,e,tp)
	return c:IsCode(93717133) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
			and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT)
			and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
			and Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- Xyz Lockout for rest of turn
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 or Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT) then return end
	
	-- 1. Reveal Xyz Monster
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local xyzg=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local xyzc=xyzg:GetFirst()
	if not xyzc then return end
	Duel.ConfirmCards(1-tp,xyzc)
	
	-- 2. Special Summon 1st Monster matching conditions
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g1=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_DECK,0,1,1,nil,xyzc,e,tp)
	local tc1=g1:GetFirst()
	if not tc1 then return end
	
	-- 3. Special Summon Galaxy-Eyes Photon Dragon
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g2=Duel.SelectMatchingCard(tp,s.gepdfilter,tp,LOCATION_DECK,0,1,1,tc1,e,tp)
	local tc2=g2:GetFirst()
	if not tc2 then return end
	
	local sg=Group.FromCards(tc1,tc2)
	if Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)==2 then
		for tc in aux.Next(sg) do
			-- Permanent "Stellaron" archetype assignment while on field
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_ADD_SETCODE)
			e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e2:SetValue(0x999)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2)
			
			-- FIXED: Granted effect is now permanent while on the field
			local e3=Effect.CreateEffect(e:GetHandler())
			e3:SetDescription(aux.Stringid(id,0))
			e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
			e3:SetType(EFFECT_TYPE_IGNITION)
			e3:SetRange(LOCATION_MZONE)
			e3:SetCountLimit(1)
			e3:SetCondition(s.granted_con)
			e3:SetTarget(s.granted_tg)
			e3:SetOperation(s.granted_op)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e3)
		end
		
		-- 4. Shuffle 1 card from hand into the Deck
		if Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
			local handg=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_HAND,0,1,1,nil)
			if #handg>0 then
				Duel.SendtoDeck(handg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
			end
		end
	end
end

-- Extra Deck restriction filter
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsType(TYPE_XYZ)
end

-- Granted Effect Logic
function s.granted_con(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end

function s.grant_filter(c,e,tp)
	return (c:IsSetCard(0x999) or c:IsSetCard(0x55) or c:IsSetCard(0x7b) or c:IsSetCard(0x307b))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.granted_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if ft<=0 then return false end
		if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT) then ft=1 end
		return Duel.IsExistingMatchingCard(s.grant_filter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.granted_op(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT) then ft=1 end
	if ft>2 then ft=2 end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.grant_filter,tp,LOCATION_DECK,0,1,ft,nil,e,tp)
	if #g>0 then
		Duel.ConfirmCards(1-tp,g)
		if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
			local matg=Duel.GetOperatedGroup()
			for tc in aux.Next(matg) do
				-- Permanent "Stellaron" archetype assignment for sub-summoned monsters too
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_ADD_SETCODE)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e1:SetValue(0x999)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
			end
		end
	end
end
