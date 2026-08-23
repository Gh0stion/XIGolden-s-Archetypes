local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    -- 1. Monsters leaving field -> Place Wedge Counter
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_LEAVE_FIELD)
    e1:SetRange(LOCATION_SZONE)
    e1:SetCondition(s.ctcon)
    e1:SetOperation(s.ctop)
    c:RegisterEffect(e1)

    -- 2. Discard to Set from GY/Banish
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,id)
    e2:SetCost(s.setcost)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)

    -- 3a. Black Ace Summon -> Place 10 Counters
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetRange(LOCATION_SZONE)
    e3:SetOperation(s.aceop)
    c:RegisterEffect(e3)

    -- 3b. ATK Gain for Black Ace
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_UPDATE_ATTACK)
    e4:SetRange(LOCATION_SZONE)
    e4:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e4:SetTarget(aux.TargetBoolFunction(Card.IsCode,97626301))
    e4:SetValue(s.atkval)
    c:RegisterEffect(e4)

    -- 4. Standby Phase: Shuffle and Set from Deck
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_SZONE)
    e5:SetCode(EVENT_FREE_CHAIN)
    e5:SetCountLimit(1,id+100)
    e5:SetCondition(s.sbcon)
    e5:SetTarget(s.sbtg)
    e5:SetOperation(s.sbop)
    c:RegisterEffect(e5)

    -- 5. NEW: Evolution Trigger (7+ Counters on Megaman)
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,2))
    e6:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e6:SetProperty(EFFECT_FLAG_DELAY)
    e6:SetCode(EVENT_CUSTOM+id)
    e6:SetRange(LOCATION_SZONE)
    e6:SetTarget(s.evotg)
    e6:SetOperation(s.evoop)
    c:RegisterEffect(e6)

    -- Helper to monitor Megaman's counter state
    local e7=Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e7:SetCode(EVENT_ADJUST)
    e7:SetRange(LOCATION_SZONE)
    e7:SetOperation(s.checkop)
    c:RegisterEffect(e7)
end

s.counter_type=0x1002
s.megaman=21298482
s.black_ace=97626301
s.listed_names={s.megaman, s.black_ace}

-- Evolution Monitoring
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,s.megaman)
    for tc in aux.Next(g) do
        if tc:GetCounter(s.counter_type)>=7 then
            -- Raise custom event to trigger the summon effect
            Duel.RaiseEvent(tc,EVENT_CUSTOM+id,e,0,tp,tp,0)
        end
    end
end

function s.evotg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCountFromEx(tp)>0
        and Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_EXTRA,0,1,nil,s.black_ace) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.evoop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local g=Duel.SelectMatchingCard(tp,function(c) return c:IsCode(s.megaman) and c:GetCounter(s.counter_type)>=7 end,tp,LOCATION_MZONE,0,1,1,nil)
    if #g>0 and Duel.Release(g,REASON_EFFECT)~=0 then
        local sc=Duel.GetFirstMatchingCard(Card.IsCode,tp,LOCATION_EXTRA,0,nil,s.black_ace)
        if sc then
            local zone=Duel.GetLocationCountFromEx(tp,tp,nil,sc)
            if Duel.SpecialSummon(sc,0,tp,tp,true,false,POS_FACEUP,zone)~=0 then
                sc:CompleteProcedure()
            end
        end
    end
end

-- [The rest of your original functions]
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(Card.IsPreviousLocation,1,nil,LOCATION_MZONE)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    if #g>0 then
        local tc=g:RandomSelect(tp,1):GetFirst()
        tc:AddCounter(s.counter_type,1)
    end
end
function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.setfilter(c)
    return c:IsSetCard(0x99b) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    if #g>0 then Duel.SSet(tp,g) end
end
function s.aceop(e,tp,eg,ep,ev,re,r,rp)
    local tc=eg:GetFirst()
    if tc:IsCode(s.black_ace) and tc:IsFaceup() then
        tc:AddCounter(s.counter_type,10)
    end
end
function s.atkval(e,c)
    return c:GetCounter(s.counter_type)*500
end
function s.sbcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetCurrentPhase()==PHASE_STANDBY
end
function s.sbfilter1(c)
    return c:IsFaceup() and c:IsSetCard(0x99b) and c:IsType(TYPE_SPELL) and c:IsAbleToDeck()
end
function s.sbfilter2(c,old_code)
    return c:IsSetCard(0x99b) and c:IsType(TYPE_SPELL+TYPE_TRAP) and not c:IsCode(old_code) and c:IsSSetable()
end
function s.sbtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.sbfilter1,tp,LOCATION_SZONE,0,1,nil) 
        and Duel.IsExistingMatchingCard(s.sbfilter2,tp,LOCATION_DECK,0,1,nil,0) end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_SZONE)
end
function s.sbop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g1=Duel.SelectMatchingCard(tp,s.sbfilter1,tp,LOCATION_SZONE,0,1,1,nil)
    if #g1>0 then
        local old_code=g1:GetFirst():GetCode()
        if Duel.SendtoDeck(g1,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
            local g2=Duel.SelectMatchingCard(tp,s.sbfilter2,tp,LOCATION_DECK,0,1,1,nil,old_code)
            if #g2>0 then Duel.SSet(tp,g2) end
        end
    end
end
