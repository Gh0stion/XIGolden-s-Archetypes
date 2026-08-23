local s,id=GetID()
function s.initial_effect(c)
    -- 0. Effects cannot be negated
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetCode(EFFECT_CANNOT_DISABLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    c:RegisterEffect(e0)
    local e1=e0:Clone()
    e1:SetCode(EFFECT_CANNOT_DISEFFECT)
    c:RegisterEffect(e1)

    -- 1. SS from Hand/Deck and Negate the opponent's effect
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_NEGATE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_HAND+LOCATION_DECK)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.discon)
    e2:SetTarget(s.distg)
    e2:SetOperation(s.disop)
    c:RegisterEffect(e2)
end

-- Condition: Opponent activates a card/effect that negates or disables
function s.discon(e,tp,eg,ep,ev,re,r,rp)
    if rp==tp or not Duel.IsChainNegatable(ev) then return false end
    -- Checks if the opponent's effect is a negation or disable type
    return re:IsHasCategory(CATEGORY_NEGATE) or re:IsHasCategory(CATEGORY_DISABLE)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    -- Special Summon this card
    if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
        -- Then Negate the opponent's activation
        Duel.NegateActivation(ev)
    end
end
