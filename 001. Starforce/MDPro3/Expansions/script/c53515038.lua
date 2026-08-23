local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)
    
    --1. ATK/DEF boost for "Starforce" monsters
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_SZONE)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(s.atktg)
    e1:SetValue(300)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e2)
    
    --2. Cannot activate in response to "Starforce" effects
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_CANNOT_INACTIVATE)
    e3:SetRange(LOCATION_SZONE)
    e3:SetValue(s.chainlm)
    c:RegisterEffect(e3)
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_CANNOT_DISEFFECT)
    e4:SetRange(LOCATION_SZONE)
    e4:SetValue(s.chainlm)
    c:RegisterEffect(e4)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_CHAINING)
    e5:SetRange(LOCATION_SZONE)
    e5:SetOperation(s.chainop)
    c:RegisterEffect(e5)
    
    --3. Reveal and destroy set Trap
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,0))
    e6:SetCategory(CATEGORY_DESTROY)
    e6:SetType(EFFECT_TYPE_IGNITION)
    e6:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e6:SetRange(LOCATION_SZONE)
    e6:SetCountLimit(1)
    e6:SetTarget(s.destg)
    e6:SetOperation(s.desop)
    c:RegisterEffect(e6)
end

s.listed_series={0x99b}

--1. ATK/DEF boost target
function s.atktg(e,c)
    return c:IsSetCard(0x99b)
end

--2. Cannot respond to "Starforce" effects
function s.chainlm(e,ct)
    local p=e:GetHandlerPlayer()
    local te,tp=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
    local tc=te:GetHandler()
    return p~=tp and tc:IsSetCard(0x99b)
end

function s.chainop(e,tp,eg,ep,ev,re,r,rp)
    local rc=re:GetHandler()
    if re:IsActiveType(TYPE_MONSTER) and rc:IsSetCard(0x99b) and ep==tp then
        Duel.SetChainLimit(s.chlimit)
    end
end

function s.chlimit(e,rp,tp)
    return tp==rp
end

--3. Reveal and destroy set card
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsFacedown() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsFacedown,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,Card.IsFacedown,tp,0,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFacedown() then
        Duel.ConfirmCards(tp,tc)
        if tc:IsType(TYPE_TRAP) then
            Duel.Destroy(tc,REASON_EFFECT)
        end
    end
end