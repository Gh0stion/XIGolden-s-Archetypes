local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_ATTACK_ANNOUNCE)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetAttackTarget()==nil and Duel.GetAttacker():IsControler(1-tp)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
    Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,g,#g,0,0)
    Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,PLAYER_ALL,LOCATION_MZONE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
    if #g==0 then return end
    
    for tc in aux.Next(g) do
        --Set ATK to 0
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_SET_ATTACK_FINAL)
        e1:SetValue(0)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
    
    --Banish all 0 ATK monsters during End Phase
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_PHASE+PHASE_END)
    e2:SetCountLimit(1)
    e2:SetOperation(s.banop)
    e2:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e2,tp)
end

function s.banfilter(c)
    return c:IsFaceup() and c:GetAttack()==0
end

function s.banop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.banfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
    if #g>0 then
        Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
    end
end