local s,id=GetID()
function s.initial_effect(c)
    --1. Special Summon from Deck
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)
    
    --2. Change Levels
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_LVCHANGE)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetCountLimit(1)
    e3:SetTarget(s.lvtg)
    e3:SetOperation(s.lvop)
    c:RegisterEffect(e3)
    
    --3. Special Summon from GY when detached
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_TO_GRAVE)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCondition(s.spcon2)
    e4:SetTarget(s.sptg2)
    e4:SetOperation(s.spop2)
    c:RegisterEffect(e4)
    
    --4. Grant ATK/DEF to Xyz Monster
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_XMATERIAL)
    e5:SetCode(EFFECT_UPDATE_ATTACK)
    e5:SetCondition(s.xmatcon)
    e5:SetValue(300)
    c:RegisterEffect(e5)
    local e6=e5:Clone()
    e6:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e6)
end

s.listed_names={30984319}
s.listed_series={0x99b}

--1. Special Summon from Deck
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x99b) and not c:IsCode(30984319) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

--2. Change Levels
function s.lvfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x99b) and c:HasLevel()
end

function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.lvfilter(chkc) and chkc~=e:GetHandler() end
    if chk==0 then return e:GetHandler():IsFaceup() and e:GetHandler():HasLevel()
        and Duel.IsExistingTarget(s.lvfilter,tp,LOCATION_MZONE,0,1,e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.lvfilter,tp,LOCATION_MZONE,0,1,1,e:GetHandler())
end

function s.lvop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not c:IsRelateToEffect(e) or c:IsFacedown() or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
    
    local op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
    local lv=1
    if op==1 then lv=-1 end
    
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_LEVEL)
    e1:SetValue(lv)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    c:RegisterEffect(e1)
    
    local e2=e1:Clone()
    tc:RegisterEffect(e2)
end

--3. Special Summon from GY when detached
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local reason=c:GetReason()
    return c:IsPreviousLocation(LOCATION_OVERLAY) 
        and bit.band(reason,REASON_COST+REASON_EFFECT)~=0
        and c:GetReasonCard():IsSetCard(0x99b) and c:GetReasonCard():IsType(TYPE_XYZ)
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

--4. Xyz Material condition - check if host is Starforce Xyz
function s.xmatcon(e)
    local c=e:GetHandler()
    return c:IsSetCard(0x99b) and c:IsType(TYPE_XYZ)
end