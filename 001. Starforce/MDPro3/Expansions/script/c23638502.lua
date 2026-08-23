local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)
    
    --1. DEF boost for "Starforce" monsters
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_UPDATE_DEFENSE)
    e1:SetRange(LOCATION_SZONE)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(s.deftg)
    e1:SetValue(500)
    c:RegisterEffect(e1)
    
    --2. Send "Tribe On" to GY when opponent's monster leaves field
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOGRAVE)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_LEAVE_FIELD)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCondition(s.tgcon)
    e2:SetTarget(s.tgtg)
    e2:SetOperation(s.tgop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_BATTLE_DESTROYED)
    c:RegisterEffect(e3)
    
    --3. Replace battle destruction
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EFFECT_DESTROY_REPLACE)
    e4:SetRange(LOCATION_SZONE)
    e4:SetCountLimit(1)
    e4:SetTarget(s.reptg)
    e4:SetValue(s.repval)
    e4:SetOperation(s.repop)
    c:RegisterEffect(e4)
end

s.listed_series={0x99b,0x100b}

--1. DEF boost target
function s.deftg(e,c)
    return c:IsSetCard(0x99b)
end

--2. Send "Tribe On" to GY condition
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.tgfilter,1,nil,tp,re)
end

function s.tgfilter(c,tp,re)
    return c:IsPreviousControler(1-tp) and c:IsPreviousLocation(LOCATION_MZONE)
        and (c:IsReason(REASON_BATTLE) or (re and re:GetOwnerPlayer()==tp and re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)))
end

function s.tgfilter2(c)
    return c:IsSetCard(0x100b) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS) and c:IsAbleToGrave()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter2,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.tgfilter2,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end

--3. Replace battle destruction
function s.repfilter(c,tp)
    return c:IsFaceup() and c:IsSetCard(0x99b) and c:IsControler(tp)
        and c:IsLocation(LOCATION_MZONE) and c:IsReason(REASON_BATTLE) and not c:IsReason(REASON_REPLACE)
end

function s.repfilter2(c)
    return c:IsSetCard(0x99b) and c:IsAbleToGraveAsCost()
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return eg:IsExists(s.repfilter,1,nil,tp)
        and Duel.IsExistingMatchingCard(s.repfilter2,tp,LOCATION_HAND,0,1,nil) end
    return Duel.SelectEffectYesNo(tp,e:GetHandler(),96)
end

function s.repval(e,c)
    return s.repfilter(c,e:GetHandlerPlayer())
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.repfilter2,tp,LOCATION_HAND,0,1,1,nil)
    if #g>0 then
        Duel.SendtoGrave(g,REASON_COST+REASON_REPLACE)
    end
end