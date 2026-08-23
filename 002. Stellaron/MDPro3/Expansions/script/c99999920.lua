local s,id=GetID()
function s.initial_effect(c)
    -- Link Summon Procedure: 1 Specific Monster (99999919)
    aux.AddLinkProcedure(c,s.mfilter,1,1)
    c:EnableReviveLimit()

    -- 0. Effects cannot be negated
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetCode(EFFECT_CANNOT_DISABLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    c:RegisterEffect(e0)
    local e1=e0:Clone()
    e1:SetCode(EFFECT_CANNOT_DISEFFECT)
    c:RegisterEffect(e1)

    -- 1. Link Summon Search (Up to 2 Normal + 1 Dragon/Dragon Tuner)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.srchcon)
    e2:SetTarget(s.srchtg)
    e2:SetOperation(s.srchop)
    c:RegisterEffect(e2)

    -- 2. Discard to SS "Stellaron" to pointed zone
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id+100)
    e3:SetCost(s.spcost)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)
end

-- Link Material
function s.mfilter(c)
    return c:IsCode(99999919)
end

-- 1. Search Logic
function s.srchcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
function s.filter1(c)
    return c:IsType(TYPE_NORMAL) and c:IsAbleToHand()
end
function s.filter2(c)
    return c:IsRace(RACE_DRAGON) and c:IsAbleToHand()
end
function s.srchtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_DECK,0,1,nil)
        or Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.srchop(e,tp,eg,ep,ev,re,r,rp)
    -- Add up to 2 Normal Monsters
    local g1=Duel.GetMatchingGroup(s.filter1,tp,LOCATION_DECK,0,nil)
    if #g1>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg1=g1:Select(tp,1,2,nil)
        Duel.SendtoHand(sg1,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg1)
    end
    -- Add 1 Dragon or Dragon Tuner
    local g2=Duel.GetMatchingGroup(s.filter2,tp,LOCATION_DECK,0,nil)
    if #g2>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg2=g2:Select(tp,1,1,nil)
        Duel.SendtoHand(sg2,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg2)
    end
end

-- 2. GY Special Summon Logic
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.ssfilter(c,e,tp,zone)
    return c:IsSetCard(0x999) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,tp,zone)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local zone=e:GetHandler():GetLinkedZone(tp)
    if chk==0 then return zone~=0 and Duel.IsExistingMatchingCard(s.ssfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp,zone) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local zone=c:GetLinkedZone(tp)
    if zone==0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.ssfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp,zone)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP,zone)
    end
end
