local s,id=GetID()
function s.initial_effect(c)
    -- 1. Discard to place in Pendulum Zone
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.pcost)
    e1:SetTarget(s.ptg)
    e1:SetOperation(s.pop)
    c:RegisterEffect(e1)

    -- 2. Special Summon from GY when Extra Deck monster hits the field
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    -- 3. Special Summon Level 8 from Deck when targeted (Maiden Style)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCode(EVENT_BECOME_TARGET) -- Matches Maiden of White
    e3:SetCountLimit(1,id+200)
    e3:SetCondition(s.tgcon)
    e3:SetTarget(s.tgtg)
    e3:SetOperation(s.tgop)
    c:RegisterEffect(e3)
    -- Also trigger on battle target
    local e4=e3:Clone()
    e4:SetCode(EVENT_BE_BATTLE_TARGET)
    c:RegisterEffect(e4)
end

-- 1. Pendulum Placement Logic
function s.pcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsDiscardable() end
    Duel.SendtoGrave(c,REASON_COST+REASON_DISCARD)
end
function s.pfilter(c)
    return c:IsSetCard(0x999) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end
function s.ptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return (Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1))
        and Duel.IsExistingMatchingCard(s.pfilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.pop(e,tp,eg,ep,ev,re,r,rp)
    if not (Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local g=Duel.SelectMatchingCard(tp,s.pfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.MoveToField(g:GetFirst(),tp,tp,LOCATION_PZONE,POS_FACEUP,true)
    end
end

-- 2. GY Special Summon Logic
function s.cfilter(c,tp)
    return c:IsFaceup() and c:IsControler(tp) and c:IsSetCard(0x999) and c:IsType(TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end

-- 3. Target Reaction Logic (Maiden Style)
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsContains(e:GetHandler())
end
function s.tgspfilter(c,e,tp)
    return c:IsSetCard(0x999) and c:IsLevel(8) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.tgspfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.tgspfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end
