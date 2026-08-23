local s,id=GetID()
function s.initial_effect(c)
    -- Xyz Summon (Corrected Condition)
    c:EnableReviveLimit()
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    e1:SetValue(SUMMON_TYPE_XYZ)
    c:RegisterEffect(e1)
    
    -- 1. Protection & Direct Attack
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(aux.tgoval)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetValue(aux.indoval)
    c:RegisterEffect(e3)
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_DIRECT_ATTACK)
    c:RegisterEffect(e4)
    
    -- 2. Place in S/T Zone AND Summon (Combined)
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,0))
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON) -- Added Category
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_FREE_CHAIN)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetCost(s.plcost)
    e5:SetTarget(s.pltg)
    e5:SetOperation(s.plop)
    c:RegisterEffect(e5)

    -- AURA: Continuous Negation
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD)
    e6:SetCode(EFFECT_DISABLE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetTargetRange(0,LOCATION_ONFIELD+LOCATION_GRAVE)
    e6:SetTarget(s.auratg)
    c:RegisterEffect(e6)
    local e7=e6:Clone()
    e7:SetCode(EFFECT_DISABLE_EFFECT)
    c:RegisterEffect(e7)
end

s.listed_series={0x99b}
s.listed_names={53515038,23638502}

-- Summoning Logic
function s.matfilter(c)
    local mg=c:GetOverlayGroup()
    return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x99b)
        and mg:IsExists(Card.IsCode,1,nil,53515038) 
        and mg:IsExists(Card.IsCode,1,nil,23638502) 
end
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
        and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
    local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
    local sg=g:SelectSubGroup(tp,aux.TRUE,false,1,1)
    if sg then
        sg:KeepAlive()
        e:SetLabelObject(sg)
        return true
    else return false end
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    local tc=g:GetFirst()
    local mg=tc:GetOverlayGroup()
    if #mg>0 then Duel.Overlay(c,mg) end
    c:SetMaterial(g)
    Duel.Overlay(c,g)
    g:DeleteGroup()
end

-- Aura Filter
function s.auratg(e,c)
    local tp=e:GetHandlerPlayer()
    local g=Duel.GetMatchingGroup(Card.IsOriginalType,tp,0,LOCATION_SZONE,nil,TYPE_MONSTER)
    if #g==0 then return false end
    return g:IsExists(Card.IsCode,1,nil,c:GetCode())
end

-- MAIN EFFECT LOGIC
function s.plcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_SZONE)>0
        and Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.plop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ft=Duel.GetLocationCount(1-tp,LOCATION_SZONE)
    if ft<=0 then return end
    local ct=math.min(ft,2)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,ct,nil)
    
    -- Flag to track if the move happened
    local moved_count=0
    
    for tc in aux.Next(g) do
        -- Negate current chain link
        if Duel.GetCurrentChain()>0 then
            local chain_count=Duel.GetCurrentChain()
            for i=1,chain_count do
                local te=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_EFFECT)
                if te and te:GetHandler()==tc then
                    Duel.NegateActivation(i)
                end
            end
        end
        
        if Duel.MoveToField(tc,tp,1-tp,LOCATION_SZONE,POS_FACEUP,true) then
            moved_count = moved_count + 1
            -- Type Change
            local e1=Effect.CreateEffect(c)
            e1:SetCode(EFFECT_CHANGE_TYPE)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
            e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
            tc:RegisterEffect(e1)
            -- Burn Damage
            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
            e2:SetCode(EVENT_DESTROYED)
            e2:SetOperation(function(e,tp,eg,ep,ev,re,r,rp) Duel.Damage(1-tp,1500,REASON_EFFECT) end)
            tc:RegisterEffect(e2)
        end
    end

    -- INTEGRATED SUMMON CHECK
    -- Check if opponent now controls more than 1 Continuous Spell
    local c_spells=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_SZONE,nil,TYPE_CONTINUOUS)
    if #c_spells>1 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
        if Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) 
           and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
            local sc=sg:GetFirst()
            if sc and Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP_DEFENSE)~=0 then
                -- Negate effects
                local e3=Effect.CreateEffect(c)
                e3:SetType(EFFECT_TYPE_SINGLE)
                e3:SetCode(EFFECT_DISABLE)
                e3:SetReset(RESET_EVENT+RESETS_STANDARD)
                sc:RegisterEffect(e3)
                local e4=e3:Clone()
                e4:SetCode(EFFECT_DISABLE_EFFECT)
                sc:RegisterEffect(e4)
            end
        end
    end
end

function s.spfilter(c,e,tp)
    return c:IsSetCard(0x99b) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
