local s,id=GetID()
function s.initial_effect(c)
    aux.EnablePendulumAttribute(c)

    -- Pendulum Effect 1: Ignition - Special Summon Level 4 or lower Stellaron from Deck
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_PZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- Pendulum Effect 2: Search when a Stellaron or Dragon monster activates its effect
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_CHAIN_SOLVED)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetRange(LOCATION_PZONE)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    -- Monster Effect: Send 1 and Special Summon 1 (unchanged)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_SUMMON_SUCCESS)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,id+200)
    e3:SetTarget(s.sumtg)
    e3:SetOperation(s.sumop)
    c:RegisterEffect(e3)

    local e4=e3:Clone()
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e4)
end

-- Pendulum Effect 1 (unchanged)
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x999) and c:IsLevelBelow(5) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- Pendulum Effect 2: Search Condition (Stellaron or Dragon)
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    if not re:IsActiveType(TYPE_MONSTER) or rp~=tp then return false end
    local rc=re:GetHandler()
    -- Check if it is a Stellaron (0x999) OR a Dragon
    return rc:IsSetCard(0x999) or rc:IsRace(RACE_DRAGON)
end

function s.thfilter(c)
    return c:IsSetCard(0x999) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- Monster Effect Logic (unchanged)
function s.gyfilter(c)
    return c:IsAbleToGrave()
end
function s.sumspfilter(c,e,tp)
    return c:IsLevelBelow(9) and (c:IsRace(RACE_DRAGON) or c:IsRace(RACE_WARRIOR))
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_DECK,0,1,nil)
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.sumspfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.gyfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
        if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g2=Duel.SelectMatchingCard(tp,s.sumspfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
        if #g2>0 then
            Duel.SpecialSummon(g2,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end
