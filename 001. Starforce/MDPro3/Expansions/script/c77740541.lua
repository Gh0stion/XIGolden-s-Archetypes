local s,id=GetID()
function s.initial_effect(c)
    --Special Summon from hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    --Search on Special Summon
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    --Grant effect to XYZ monster (Cannot be banished)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_XMATERIAL)
    e3:SetCode(EFFECT_CANNOT_REMOVE)
    e3:SetCondition(s.xyzcon)
    e3:SetValue(1)
    c:RegisterEffect(e3)
end

s.listed_series={0x99b}

-- Special Summon Condition
function s.spfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x99b)
end
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and (Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
        or Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil))
end

-- Search Filters
function s.thfilter1(c)
    return c:IsSetCard(0x99b) and c:IsType(TYPE_MONSTER) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thfilter2(c)
    return c:IsSetCard(0x99b) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    -- 1. Search Monster
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
        Duel.ConfirmCards(1-tp,g)
        Duel.ShuffleHand(tp)
        
        -- 2. Optional Search S/T if opponent has more monsters
        local ct1=Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)
        local ct2=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
        if ct2>ct1 and Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK,0,1,nil) 
        and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then -- Optional prompt for the 2nd search
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local g2=Duel.SelectMatchingCard(tp,s.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
            if #g2>0 then
                Duel.SendtoHand(g2,nil,REASON_EFFECT)
                Duel.ConfirmCards(1-tp,g2)
                Duel.ShuffleHand(tp)
            end
        end
    end
    
    -- 3. Locking into Starforce Extra Deck
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
    e1:SetDescription(aux.Stringid(id,2))
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c)
    return c:IsLocation(LOCATION_EXTRA) and not c:IsSetCard(0x99b)
end

-- Condition for the granted Xyz effect
function s.xyzcon(e)
    return e:GetHandler():IsType(TYPE_XYZ)
end
