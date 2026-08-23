local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMING_ATTACK+TIMING_END_PHASE)
    c:RegisterEffect(e1)
    
    -- Counter Placement
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_SZONE)
    e2:SetOperation(s.ctop_act)
    c:RegisterEffect(e2)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_ATTACK_ANNOUNCE)
    e3:SetRange(LOCATION_SZONE)
    e3:SetOperation(s.ctop_atk)
    c:RegisterEffect(e3)
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_CHAIN_NEGATED)
    e4:SetRange(LOCATION_SZONE)
    e4:SetOperation(s.ctop_neg)
    c:RegisterEffect(e4)
    local e5=e4:Clone()
    e5:SetCode(EVENT_CHAIN_DISABLED)
    c:RegisterEffect(e5)

    -- MAIN EFFECT (Tiers 1, 5, 10)
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,0))
    e6:SetType(EFFECT_TYPE_IGNITION)
    e6:SetRange(LOCATION_SZONE)
    e6:SetCountLimit(1,id)
    e6:SetTarget(s.efftg)
    e6:SetOperation(s.effop)
    c:RegisterEffect(e6)

    -- SPECIAL SUMMON: EM Black Ace (Tier 15 Condition)
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,1))
    e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e7:SetType(EFFECT_TYPE_IGNITION)
    e7:SetRange(LOCATION_SZONE)
    e7:SetCountLimit(1,id+1)
    e7:SetCondition(s.acecon)
    e7:SetCost(s.acecost)
    e7:SetTarget(s.acetg)
    e7:SetOperation(s.aceop)
    c:RegisterEffect(e7)
end

s.counter_type=0x1002
s.listed_names={21298482, 97626301}

-- Counter Helpers
function s.add_wedge(c)
    if c and c:IsLocation(LOCATION_MZONE) and c:IsFaceup() then c:AddCounter(s.counter_type,1) end
end
function s.ctop_act(e,tp,eg,ep,ev,re,r,rp) if re:IsActiveType(TYPE_MONSTER) then s.add_wedge(re:GetHandler()) end end
function s.ctop_atk(e,tp,eg,ep,ev,re,r,rp) s.add_wedge(Duel.GetAttacker()) end
function s.ctop_neg(e,tp,eg,ep,ev,re,r,rp) if re:IsActiveType(TYPE_MONSTER) then s.add_wedge(re:GetHandler()) end end

-- Target for 1, 5, 10
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
    local total=Duel.GetCounter(tp,LOCATION_MZONE,LOCATION_MZONE,s.counter_type)
    if chk==0 then return total>=1 end
    local t={}
    if total>=1 then table.insert(t,1) end
    if total>=5 then table.insert(t,5) end
    if total>=10 then table.insert(t,10) end
    local sc=Duel.AnnounceNumber(tp,table.unpack(t))
    Duel.RemoveCounter(tp,LOCATION_MZONE,LOCATION_MZONE,s.counter_type,sc,REASON_COST)
    e:SetLabel(sc)
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
    local sc=e:GetLabel()
    if sc==1 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
        local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,1,nil)
        if #g>0 then
            local tc=g:GetFirst()
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetReset(RESET_PHASE+PHASE_END,2)
            e1:SetValue(500)
            tc:RegisterEffect(e1)
            local e2=e1:Clone(); e2:SetCode(EFFECT_UPDATE_DEFENSE); tc:RegisterEffect(e2)
        end
    elseif sc==5 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
        local g=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_ONFIELD,0,1,1,e:GetHandler())
        if #g>0 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
            local sg=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
            if #sg>0 then Duel.SSet(tp,sg) end
        end
    elseif sc==10 then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetCode(EFFECT_CANNOT_INACTIVATE)
        e1:SetValue(s.effectfilter)
        e1:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e1,tp)
        local e2=e1:Clone(); e2:SetCode(EFFECT_CANNOT_DISEFFECT); Duel.RegisterEffect(e2,tp)
    end
end

-- EM Black Ace Dedicated Summon
function s.acecon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetCounter(tp,LOCATION_MZONE,LOCATION_MZONE,s.counter_type)>=15
end
function s.acecost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckReleaseGroupCost(tp,Card.IsCode,1,false,nil,nil,21298482) end
    local g=Duel.SelectReleaseGroupCost(tp,Card.IsCode,1,1,false,nil,nil,21298482)
    Duel.Release(g,REASON_COST)
end
function s.acetg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_EXTRA,0,1,nil,97626301) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.aceop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstMatchingCard(Card.IsCode,tp,LOCATION_EXTRA,0,nil,97626301)
    if tc then
        local zone=Duel.GetLocationCountFromEx(tp,tp,nil,tc)
        if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP,zone)~=0 then
            tc:CompleteProcedure()
        end
    end
end

function s.setfilter(c)
    return c:IsSetCard(0x99b) and not c:IsSetCard(0x100b) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end
function s.effectfilter(e,ct)
    local p=e:GetHandlerPlayer()
    local te,tp=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
    return p==tp and te:IsActiveType(TYPE_MONSTER)
end
