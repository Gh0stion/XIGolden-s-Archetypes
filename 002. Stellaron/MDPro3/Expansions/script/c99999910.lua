local s,id=GetID()
function s.initial_effect(c)
    -- Fusion Material: 99999909 + 1 "Stellaron" Normal + 1 "Stellaron" Pendulum
    c:EnableReviveLimit()
    aux.AddFusionProcMix(c,true,true,99999909,s.ffilter1,s.ffilter2)

    -- 1. Special Summon: Set Field Spell
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.settg)
    e1:SetOperation(s.setop)
    c:RegisterEffect(e1)

    -- 2. Target Reaction: Fusion Summon from Deck (Manual Fix)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EVENT_BECOME_TARGET)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.fuscon)
    e2:SetTarget(s.fustg)
    e2:SetOperation(s.fusop)
    c:RegisterEffect(e2)

    -- 3. Passive: Others cannot be banished
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_CANNOT_REMOVE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetTarget(s.banlimit)
    e3:SetValue(1)
    c:RegisterEffect(e3)

    -- 4. Tribute for 3 Pendulums (Quick Effect Fix)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,id+200)
    e4:SetCondition(s.spcon)
    e4:SetCost(s.spcost)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end

-- Fusion Materials
function s.ffilter1(c,fc,sumtype,tp)
    return c:IsSetCard(0x999) and c:IsType(TYPE_NORMAL)
end
function s.ffilter2(c,fc,sumtype,tp)
    return c:IsSetCard(0x999) and c:IsType(TYPE_PENDULUM)
end

-- 1. Field Spell Set
function s.fieldfilter(c)
    return c:IsSetCard(0x999) and c:IsType(TYPE_FIELD) and not c:IsForbidden()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.fieldfilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local tc=Duel.SelectMatchingCard(tp,s.fieldfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
    if tc then
        Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
    end
end

-- 2. Fusion Reaction
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsContains(e:GetHandler())
end
function s.ffilter(c,e,tp,m,f,chkf)
    return c:IsType(TYPE_FUSION) and c:IsSetCard(0x999) and (not f or f(c))
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(m,nil,chkf)
end
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local chkf=tp
        local mg=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
        return Duel.IsExistingMatchingCard(s.ffilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,nil,chkf)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
    local chkf=tp
    local mg=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
    local sg=Duel.GetMatchingGroup(s.ffilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg,nil,chkf)
    if #sg>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local tg=sg:Select(tp,1,1,nil)
        local tc=tg:GetFirst()
        local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,chkf)
        tc:SetMaterial(mat)
        Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
        Duel.BreakEffect()
        Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
        tc:CompleteProcedure()
    end
end

-- 3. Banish Protection
function s.banlimit(e,c)
    return c:IsSetCard(0x999) and c~=e:GetHandler()
end

-- 4. Tribute SS up to 3 Pendulums
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)<=2
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsReleasable() end
    Duel.Release(e:GetHandler(),REASON_COST)
end
function s.psfilter(c,e,tp)
    return c:IsType(TYPE_PENDULUM) 
        and (c:IsLocation(LOCATION_DECK+LOCATION_GRAVE) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup()))
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.psfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if ft<=0 then return end
    if ft>3 then ft=3 end
    if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.psfilter),tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA,0,1,ft,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end
