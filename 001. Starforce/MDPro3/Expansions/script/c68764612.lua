local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_DISABLE+CATEGORY_ATKCHANGE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCondition(s.condition)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    c:RegisterEffect(e1)
end

function s.cfilter(c,tp)
    return c:IsControler(1-tp) and c:IsSummonLocation(LOCATION_EXTRA) and c:IsFaceup()
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter,1,nil,tp)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,e:GetHandler()) end
    local ct=Duel.DiscardHand(tp,Card.IsDiscardable,1,2,REASON_COST+REASON_DISCARD,e:GetHandler())
    e:SetLabel(ct)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup() end
    if chk==0 then 
        local ct=1
        if Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,2,e:GetHandler()) then ct=2 end
        return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) 
    end
    local ct=e:GetLabel()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,ct,nil)
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
    for tc in aux.Next(g) do
        if tc:IsFaceup() then
            --Negate effects
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e1)
            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            e2:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e2)
            --Set ATK to 0
            local e3=Effect.CreateEffect(c)
            e3:SetType(EFFECT_TYPE_SINGLE)
            e3:SetCode(EFFECT_SET_ATTACK_FINAL)
            e3:SetValue(0)
            e3:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e3)
        end
    end
end