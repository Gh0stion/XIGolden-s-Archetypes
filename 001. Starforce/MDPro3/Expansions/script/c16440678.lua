local s,id=GetID()
function s.initial_effect(c)
    -- Xyz Summon Procedure
    c:EnableReviveLimit()
    -- Stringid(id,0) is used for the Geo Stelar alternative summon prompt
    aux.AddXyzProcedure(c,s.matfilter,4,2,s.ovfilter,aux.Stringid(id,0),2,s.xyzop)
    
    -- 1. Attach "Tribe On" Continuous Spell
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,1)) -- "Attach Tribe-On"
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.atttg)
    e1:SetOperation(s.attop)
    c:RegisterEffect(e1)
    
    -- 2. Quick Effect: Transformation (Xyz Summon Tribe form)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,2)) -- "Tribe On! - Transform"
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.xyzcon)
    e2:SetTarget(s.xyztg)
    e2:SetOperation(s.xyzop2)
    c:RegisterEffect(e2)
    
    -- 3. Destroy replacement
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,3)) -- "Use Material to Protect"
    e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_DESTROY_REPLACE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTarget(s.desreptg)
    e3:SetOperation(s.desrepop)
    c:RegisterEffect(e3)
end

s.listed_series={0x99b,0x100b}
s.listed_names={59999377}

-- Xyz Materials Filter
function s.matfilter(c,xyz,sumtype,tp)
    return c:IsSetCard(0x99b)
end

-- Alternative Xyz Summon: Geo Stelar
function s.ovfilter(c,tp,lc)
    return c:IsFaceup() and c:IsCode(59999377)
end

function s.xyzop(e,tp,chk)
    if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
    Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
    return true
end

-- 1. Attach Logic
function s.attfilter(c)
    return c:IsSetCard(0x100b) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS) and not c:IsForbidden()
end

function s.atttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_SZONE) and chkc:IsControler(tp) and s.attfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.attfilter,tp,LOCATION_GRAVE+LOCATION_SZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
    Duel.SelectTarget(tp,s.attfilter,tp,LOCATION_GRAVE+LOCATION_SZONE,0,1,1,nil)
end

function s.attop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) then
        Duel.Overlay(c,tc,true)
    end
end

-- 2. Quick Effect Transformation
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():GetOverlayGroup():IsExists(Card.IsSetCard,1,nil,0x100b)
end

function s.xyzfilter(c,mg,tribeon_names,tp)
    if not (c:IsSetCard(0x99b) and c:IsType(TYPE_XYZ)) then return false end
    local listed = c.listed_names
    if not listed then return false end
    local found = false
    for _,name in ipairs(tribeon_names) do
        for _,lname in ipairs(listed) do
            if lname==name then found=true break end
        end
        if found then break end
    end
    return found and c:IsXyzSummonable(nil,mg,1,1)
end

function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local c=e:GetHandler()
        local mg=c:GetOverlayGroup()
        local tribeon_cards=mg:Filter(Card.IsSetCard,nil,0x100b)
        if #tribeon_cards==0 then return false end
        local tribeon_names={}
        for tc in aux.Next(tribeon_cards) do
            table.insert(tribeon_names,tc:GetCode())
        end
        local pg=Group.FromCards(c)
        return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,pg,tribeon_names,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.xyzop2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) or c:IsControler(1-tp) then return end
    
    local mg=c:GetOverlayGroup()
    local tribeon_cards=mg:Filter(Card.IsSetCard,nil,0x100b)
    if #tribeon_cards==0 then return end
    
    local tribeon_names={}
    for tc in aux.Next(tribeon_cards) do
        table.insert(tribeon_names,tc:GetCode())
    end
    
    local pg=Group.FromCards(c)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,pg,tribeon_names,tp)
    local tc=g:GetFirst()
    
    if tc then
        -- Material Transfer Fix
        local old_materials = c:GetOverlayGroup()
        if #old_materials > 0 then
            Duel.Overlay(tc, old_materials)
        end
        tc:SetMaterial(pg)
        Duel.Overlay(tc, pg)
        
        if Duel.SpecialSummon(tc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP) ~= 0 then
            tc:CompleteProcedure()
        end
    end
end

-- 3. Protection Logic
function s.desreptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return not c:IsReason(REASON_REPLACE) and c:CheckRemoveOverlayCard(tp,1,REASON_EFFECT) end
    return Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,3))
end

function s.desrepop(e,tp,eg,ep,ev,re,r,rp)
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_EFFECT+REASON_REPLACE)
end
