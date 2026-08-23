local s,id=GetID()
function s.initial_effect(c)
    -- 0. Restriction: Control Synchro OR Specific Satellites = Cannot Summon or Set
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_CANNOT_SUMMON)
    e0:SetCondition(s.nosumcon)
    c:RegisterEffect(e0)
    local e0b=e0:Clone()
    e0b:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    c:RegisterEffect(e0b)
    local e0c=e0:Clone()
    e0c:SetCode(EFFECT_CANNOT_MSET)
    c:RegisterEffect(e0c)

    -- 1. Special Summon Procedure (From Hand)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    -- 2. Level becomes 4 & Unaffected by other effects
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CHANGE_LEVEL)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(4)
    c:RegisterEffect(e2)
    
    local e3=e2:Clone()
    e3:SetCode(EFFECT_IMMUNE_EFFECT)
    e3:SetValue(s.efilter)
    c:RegisterEffect(e3)

    -- 3. Cannot declare attacks
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_CANNOT_ATTACK)
    c:RegisterEffect(e4)

    -- 4. Search Field Spell on Summon (Only if none in hand/field)
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e5:SetCode(EVENT_SPSUMMON_SUCCESS)
    e5:SetProperty(EFFECT_FLAG_DELAY)
    e5:SetCondition(s.fthcon)
    e5:SetTarget(s.fthtg)
    e5:SetOperation(s.fthop)
    c:RegisterEffect(e5)

    -- 5. Discard to Special Summon Level 4 from Deck
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,2))
    e6:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e6:SetType(EFFECT_TYPE_IGNITION)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCountLimit(1,id)
    e6:SetCost(s.spcost)
    e6:SetTarget(s.sptg)
    e6:SetOperation(s.spop)
    c:RegisterEffect(e6)

    -- 6. Shuffle and Draw (HOPT)
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,3))
    e7:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_SPSUMMON_SUCCESS)
    e7:SetRange(LOCATION_HAND)
    e7:SetCountLimit(1,{id,1})
    e7:SetCondition(s.drcon)
    e7:SetTarget(s.drtg)
    e7:SetOperation(s.drop)
    c:RegisterEffect(e7)
end

s.listed_series={0x99b}
s.listed_names={30411028,89901622}

-- Restriction Logic
function s.nosumcon(e)
    local tp=e:GetHandlerPlayer()
    return Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_MZONE,0,1,nil)
        or Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_MZONE,0,1,nil,30411028,89901622)
end
function s.synfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x99b) and c:IsType(TYPE_SYNCHRO)
end

-- Special Summon from Hand Condition
function s.spfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x99b)
end
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    if s.nosumcon(e) then return false end
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- Immunity Filter
function s.efilter(e,te)
    return te:GetOwner()~=e:GetOwner()
end

-- Field Spell Search Condition
function s.fthcon(e,tp,eg,ep,ev,re,r,rp)
    local f1=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
    local f2=Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_HAND,0,1,nil,TYPE_FIELD)
    return not f1 and not f2
end
function s.fthfilter(c)
    return c:IsSetCard(0x99b) and c:IsType(TYPE_FIELD) and c:IsAbleToHand()
end
function s.fthtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.fthfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.fthop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.fthfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- Discard to Summon Logic
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.spmonfilter(c,e,tp)
    return c:IsSetCard(0x99b) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spmonfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spmonfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- Shuffle and Draw Logic
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.synfilter,1,nil)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToDeck() and Duel.IsPlayerCanDraw(tp,1) end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 then
        Duel.ShuffleDeck(tp)
        Duel.BreakEffect()
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end
