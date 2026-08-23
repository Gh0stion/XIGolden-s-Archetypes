local s,id=GetID()
function s.initial_effect(c)
    -- Enable Pendulum
    aux.EnablePendulumAttribute(c)

    -- Pendulum Effect: Special Summon Level 8 Stellaron/Dragon on effect activation
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_CHAIN_SOLVED)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_PZONE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- Monster Effect: Search + Reveal Hand + Reveal Extra Deck
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,id+100)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
end

-- Pendulum Effect Logic
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    -- Trigger when a "Stellaron" monster you control activates an effect
    return rp==tp and re:IsActiveType(TYPE_MONSTER) and re:GetHandler():IsSetCard(0x999)
end

function s.spfilter(c,e,tp)
    return (c:IsSetCard(0x999) or c:IsRace(RACE_DRAGON)) and c:IsLevel(8)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
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
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
    end
end

-- Monster Effect Logic
function s.thfilter(c)
    return c:IsSetCard(0x999) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    -- 1. Search Stellaron
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
        Duel.ConfirmCards(1-tp,g)
        Duel.ShuffleHand(tp)
        
        -- 2. Break effect then look at Opponent's Hand
        Duel.BreakEffect()
        local g_hand=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
        if #g_hand>0 then
            Duel.ConfirmCards(tp,g_hand)
        end
        
        -- 3. Look at Opponent's Extra Deck
        local g_extra=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
        if #g_extra>0 then
            Duel.ConfirmCards(tp,g_extra)
        end
        
        -- Ensure hand is shuffled back for the opponent after viewing
        Duel.ShuffleHand(1-tp)
    end
end
