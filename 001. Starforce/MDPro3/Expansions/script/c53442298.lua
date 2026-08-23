local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    --Banish from GY to boost ATK
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_ATKCHANGE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.atktg)
    e2:SetOperation(s.atkop)
    c:RegisterEffect(e2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then 
        return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,0,1,nil)
            and Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) 
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g1=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g2=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
    g1:Merge(g2)
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,g1,2,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,2,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
    if not g or #g~=2 then return end
    
    for tc in aux.Next(g) do
        if tc:IsRelateToEffect(e) and tc:IsFaceup() then
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
            
            --Destroy in next Standby Phase (individual effect per monster)
            local e3=Effect.CreateEffect(c)
            e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
            e3:SetCode(EVENT_PHASE+PHASE_STANDBY)
            e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
            e3:SetLabel(Duel.GetTurnCount())
            e3:SetLabelObject(tc)
            e3:SetCondition(s.descon)
            e3:SetOperation(s.desop)
            e3:SetReset(RESET_PHASE+PHASE_STANDBY,2)
            Duel.RegisterEffect(e3,tp)
        end
    end
end

function s.descon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnCount()~=e:GetLabel()
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    if tc and tc:IsLocation(LOCATION_MZONE) then
        Duel.Destroy(tc,REASON_EFFECT)
    end
    e:Reset()
end

function s.sffilter(c)
    return c:IsFaceup() and c:IsSetCard(0x99b)
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.sffilter,tp,LOCATION_MZONE,0,1,nil) end
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetMatchingGroup(s.sffilter,tp,LOCATION_MZONE,0,nil)
    if #g>0 then
        for tc in aux.Next(g) do
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(500)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e1)
        end
    end
end