local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)
    
    --1. ATK boost for "Starforce" monsters
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_SZONE)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(s.atktg)
    e1:SetValue(500)
    c:RegisterEffect(e1)
    
    --2. Draw when "Starforce" destroys by battle
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_BATTLE_DESTROYING)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCondition(s.drcon)
    e2:SetTarget(s.drtg)
    e2:SetOperation(s.drop)
    c:RegisterEffect(e2)
    
    --3. Add itself from GY to hand
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,id)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

s.listed_series={0x99b}

--1. ATK boost target
function s.atktg(e,c)
    return c:IsSetCard(0x99b)
end

--2. Draw when destroying
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
    local tc=eg:GetFirst()
    return tc:IsControler(tp) and tc:IsSetCard(0x99b)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(1)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
    Duel.Draw(p,d,REASON_EFFECT)
end

--3. Add itself to hand
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToHand() end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,c)
    end
end