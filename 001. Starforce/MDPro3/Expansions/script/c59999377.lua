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
    
    --2. Grant effect to Xyz Monster
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCondition(s.xmatcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    
    --3. Special Summon from GY
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_DESTROYED)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.spcon2)
    e3:SetTarget(s.sptg2)
    e3:SetOperation(s.spop2)
    c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EVENT_LEAVE_FIELD)
    c:RegisterEffect(e4)
end

s.listed_series={0x99b,0x100b}

--1. Special Summon condition
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    local g=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
    return #g==0 or (g:FilterCount(Card.IsSetCard,nil,0x99b)==#g and #g>0)
end

--2. Xyz Material condition - check if host is Starforce Xyz
function s.xmatcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsSetCard(0x99b) and c:IsType(TYPE_XYZ)
end

--2. Add "Tribe On" Continuous Spell
function s.thfilter(c)
    return c:IsSetCard(0x100b) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
    if #g>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg=g:Select(tp,1,1,nil)
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
    end
end

--3. Special Summon from GY condition
function s.cfilter(c,tp)
    return c:IsPreviousControler(tp) and c:IsSetCard(0x99b) and c:IsType(TYPE_XYZ)
        and (c:IsReason(REASON_BATTLE) or (c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp))
end

function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter,1,nil,tp)
end

function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end