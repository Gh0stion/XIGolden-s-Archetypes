local s,id=GetID()
function s.initial_effect(c)
    -- Activate: Fusion Summon from Hand, Deck, or GY
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_DECKDES+CATEGORY_GRAVE_SPSUMMON+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- GY Effect: Banish to boost ATK/DEF by 500
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+100)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.atktg)
    e2:SetOperation(s.atkop)
    c:RegisterEffect(e2)
end

-- Filter for Stellaron Fusion Monsters
function s.ffilter(c,e,tp,m,f,chkf)
    return c:IsType(TYPE_FUSION) and c:IsSetCard(0x999) and (not f or f(c))
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(m,nil,chkf)
end

-- Validation: Tells the engine that Deck/GY are valid sources
function s.fcheck(tp,sg,fc)
    return sg:FilterCount(Card.IsLocation,nil,LOCATION_DECK+LOCATION_GRAVE)<=sg:GetCount()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local chkf=tp
        local mg1=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_MZONE+LOCATION_GRAVE,0,nil)
        aux.FCheckAdditional=s.fcheck
        local res=Duel.IsExistingMatchingCard(s.ffilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil,chkf)
        aux.FCheckAdditional=nil
        return res
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local chkf=tp
    local mg1=Duel.GetMatchingGroup(function(c) return c:IsCanBeFusionMaterial() and (c:IsAbleToGrave() or c:IsLocation(LOCATION_GRAVE)) end,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_MZONE+LOCATION_GRAVE,0,nil)
    
    aux.FCheckAdditional=s.fcheck
    local sg1=Duel.GetMatchingGroup(s.ffilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil,chkf)
    
    if #sg1>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local tc=sg1:Select(tp,1,1,nil):GetFirst()
        if tc then
            local mat1=Duel.SelectFusionMaterial(tp,tc,mg1,nil,chkf)
            tc:SetMaterial(mat1)
            
            -- Split materials: Banish if from GY, otherwise send to GY
            local rg=mat1:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
            local gg=mat1:Filter(function(c) return not c:IsLocation(LOCATION_GRAVE) end,nil)
            
            if #rg>0 then Duel.Remove(rg,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION) end
            if #gg>0 then Duel.SendtoGrave(gg,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION) end
            
            Duel.BreakEffect()
            Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
            tc:CompleteProcedure()
        end
    end
    aux.FCheckAdditional=nil
    
    -- Restriction: Stellaron only
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c)
    return not c:IsSetCard(0x999)
end

-- GY ATK/DEF Logic
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsFaceup() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) and tc:IsFaceup() then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        e1:SetValue(500)
        tc:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        tc:RegisterEffect(e2)
    end
end
