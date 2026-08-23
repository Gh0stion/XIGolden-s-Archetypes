local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    c:EnableCounterPermit(0x1)

    -- 1. SUMMON PROCEDURE (WORKING - UNTOUCHED)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.syncon)
    e1:SetTarget(s.syntg)
    e1:SetOperation(s.synop)
    e1:SetValue(SUMMON_TYPE_SYNCHRO)
    c:RegisterEffect(e1)

    -- 2. THE GNOMATERIAL SYSTEM (WORKING - UNTOUCHED)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_ADJUST)
    e2:SetRange(LOCATION_MZONE)
    e2:SetOperation(s.gnop)
    c:RegisterEffect(e2)

    -- 3. NEGATION PROTECTION (Self)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCode(EFFECT_CANNOT_DISABLE)
    c:RegisterEffect(e3)

    -- 4. ATTACK RESTRICTION (RESTORED)
    -- Cannot attack UNLESS opponent LP >= 7000
    local e_atk=Effect.CreateEffect(c)
    e_atk:SetType(EFFECT_TYPE_SINGLE)
    e_atk:SetCode(EFFECT_CANNOT_ATTACK)
    e_atk:SetCondition(s.atklimit)
    c:RegisterEffect(e_atk)

    -- 5. COUNTER & BUFFS
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    e4:SetOperation(s.ctop)
    c:RegisterEffect(e4)

    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCode(EFFECT_UPDATE_ATTACK)
    e5:SetCondition(s.con)
    e5:SetValue(1000)
    c:RegisterEffect(e5)
    
    local e6=e5:Clone()
    e6:SetCode(EFFECT_IMMUNE_EFFECT)
    e6:SetValue(s.immune_filter)
    c:RegisterEffect(e6)

    -- 6. QUICK EFFECT NEGATE
    local e7=Effect.CreateEffect(c)
    e7:SetCategory(CATEGORY_NEGATE)
    e7:SetType(EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_CHAINING)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCondition(s.negcon)
    e7:SetCost(s.countercost)
    e7:SetTarget(s.negtg)
    e7:SetOperation(s.negop)
    c:RegisterEffect(e7)

    -- 7. RECRUIT 2
    local e8=Effect.CreateEffect(c)
    e8:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e8:SetType(EFFECT_TYPE_IGNITION)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCost(s.countercost)
    e8:SetTarget(s.sptg)
    e8:SetOperation(s.spop)
    c:RegisterEffect(e8)

    -- 8. RELOAD
    local e9=Effect.CreateEffect(c)
    e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e9:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e9:SetRange(LOCATION_MZONE)
    e9:SetCountLimit(1)
    e9:SetCondition(s.reloadcon)
    e9:SetOperation(s.ctop)
    c:RegisterEffect(e9)
end

-- ATTACK LIMIT LOGIC
function s.atklimit(e)
    -- Block attack IF opponent LP is BELOW 7000
    return Duel.GetLP(1-e:GetHandlerPlayer()) < 7000
end

-- GNOMATERIAL LOGIC (UNTOUCHED)
function s.gnop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetMatchingGroup(Card.IsControler,tp,LOCATION_MZONE,0,nil,tp)
    local tc=g:GetFirst()
    while tc do
        if Duel.GetTurnPlayer()~=tp and tc:GetFlagEffect(id)==0 then
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
            e1:SetCode(EFFECT_UNRELEASABLE_SUM)
            e1:SetValue(1)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e1)
            local e2=e1:Clone() e2:SetCode(EFFECT_UNRELEASABLE_NONSUM) tc:RegisterEffect(e2)
            local e3=e1:Clone() e3:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL) tc:RegisterEffect(e3)
            local e4=e1:Clone() e4:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL) tc:RegisterEffect(e4)
            local e5=e1:Clone() e5:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL) tc:RegisterEffect(e5)
            local e6=e1:Clone() e6:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL) tc:RegisterEffect(e6)
            tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
        end
        tc=g:GetNext()
    end
end

-- SUMMON PROC (UNTOUCHED)
function s.syncon(e,c,smat,mg)
    if c==nil then return true end
    local tp=c:GetControler()
    local g1=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,89901622)
    local g2=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,59999377)
    return #g1>0 and #g2>0 and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end
function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk,c,smat,mg)
    local g1=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,89901622)
    local g2=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,59999377)
    local g=Group.CreateGroup()
    g:AddCard(g1:GetFirst())
    g:AddCard(g2:GetFirst())
    if g then g:KeepAlive() e:SetLabelObject(g) return true end
    return false
end
function s.synop(e,tp,eg,ep,ev,re,r,rp,c,smat,mg)
    local g=e:GetLabelObject()
    c:SetMaterial(g)
    Duel.SendtoGrave(g,REASON_MATERIAL+REASON_SYNCHRO)
    g:DeleteGroup()
end

-- HELPERS (UNTOUCHED)
function s.ctop(e,tp,eg,ep,ev,re,r,rp) e:GetHandler():AddCounter(0x1,1) end
function s.con(e) return e:GetHandler():GetCounter(0x1)>0 end
function s.immune_filter(e,te) return te:GetOwner()~=e:GetOwner() and not te:GetHandler():IsSetCard(0x99b) end
function s.countercost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,0x1,1,REASON_COST) end
    e:GetHandler():RemoveCounter(tp,0x1,1,REASON_COST)
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp) return rp~=tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev) end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk) if chk==0 then return true end Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0) end
function s.negop(e,tp,eg,ep,ev,re,r,rp) Duel.NegateActivation(ev) end
function s.spfilter(c,e,tp) return c:IsSetCard(0x99b) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE) end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,2,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
    local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,nil,e,tp)
    if #g>=2 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=g:Select(tp,2,2,nil)
        Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
    end
end
function s.reloadcon(e,tp,eg,ep,ev,re,r,rp) return e:GetHandler():GetCounter(0x1)==0 end
