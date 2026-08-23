local s,id=GetID()
function s.initial_effect(c)
    --1. Special Summon from hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)
    
    --2. Send "Tribe On" to GY to destroy
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)
    
    --3. Grant effects to Xyz Monster
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_XMATERIAL)
    e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.xmatcon)
    e4:SetValue(aux.tgoval)
    c:RegisterEffect(e4)
    
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCondition(s.xmatcon)
    e5:SetTargetRange(LOCATION_SZONE,0)
    e5:SetTarget(s.indestg)
    e5:SetValue(aux.indoval)
    c:RegisterEffect(e5)
end

s.listed_series={0x99b,0x100b}

--1. Special Summon condition
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    local g=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
    return #g==0 or g:IsExists(Card.IsSetCard,1,nil,0x99b)
end

--2. Send to GY and destroy
function s.tgfilter(c)
    return c:IsSetCard(0x100b) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS) and c:IsAbleToGrave()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)~=0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
        local dg
        if Duel.IsTurnPlayer(1-tp) then
            --Opponent's turn: can destroy monster or S/T
            local op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
            if op==0 then
                dg=Duel.SelectMatchingCard(tp,Card.IsType,tp,0,LOCATION_MZONE,1,1,nil,TYPE_MONSTER)
            else
                dg=Duel.SelectMatchingCard(tp,Card.IsType,tp,0,LOCATION_ONFIELD,1,1,nil,TYPE_SPELL+TYPE_TRAP)
            end
        else
            --Your turn: can only destroy S/T
            dg=Duel.SelectMatchingCard(tp,Card.IsType,tp,0,LOCATION_ONFIELD,1,1,nil,TYPE_SPELL+TYPE_TRAP)
        end
        if #dg>0 then
            Duel.HintSelection(dg)
            Duel.Destroy(dg,REASON_EFFECT)
        end
    end
end

--3. Xyz Material condition
function s.xmatcon(e)
    local c=e:GetHandler()
    return c:IsSetCard(0x99b) and c:IsType(TYPE_XYZ)
end

--3. Indestructible target for "Tribe On" Continuous Spells
function s.indestg(e,c)
    return c:IsSetCard(0x100b) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS)
end