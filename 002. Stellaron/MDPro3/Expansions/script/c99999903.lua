local s,id=GetID()
function s.initial_effect(c)
    -- 1. Activate: Special Summon 1 Stellaron Pendulum
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- 2. GY Effect: Equip Fusion from Extra Deck
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_EQUIP)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+100)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.eqtg)
    e2:SetOperation(s.eqop)
    c:RegisterEffect(e2)
end

-- 1. Special Summon Logic
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x999) and c:IsType(TYPE_PENDULUM) and c:IsLevelBelow(5)
        and (c:IsLocation(LOCATION_HAND+LOCATION_DECK) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup()))
        and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- 2. GY Equip Logic
function s.tgfilter(c)
    return c:IsFaceup() and (c:IsSetCard(0x999) or c:IsRace(RACE_DRAGON))
end
function s.eqfilter(c)
    return c:IsType(TYPE_FUSION) and not c:IsForbidden()
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.tgfilter(chkc) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
        and Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_MZONE,0,1,nil)
        and Duel.IsExistingMatchingCard(s.eqfilter,tp,LOCATION_EXTRA,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_EXTRA)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) and tc:IsFaceup() and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
        local g=Duel.SelectMatchingCard(tp,s.eqfilter,tp,LOCATION_EXTRA,0,1,1,nil)
        local ec=g:GetFirst()
        if ec then
            if not Duel.Equip(tp,ec,tc) then return end
            -- Add ATK boost and Equip limit
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_EQUIP_LIMIT)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetValue(s.eqlimit)
            e1:SetLabelObject(tc)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            ec:RegisterEffect(e1)
            local e2=Effect.CreateEffect(e:GetHandler())
            e2:SetType(EFFECT_TYPE_EQUIP)
            e2:SetCode(EFFECT_UPDATE_ATTACK)
            e2:SetValue(400)
            e2:SetReset(RESET_EVENT+RESETS_STANDARD)
            ec:RegisterEffect(e2)
        end
    end
end
function s.eqlimit(e,c)
    return c==e:GetLabelObject()
end
