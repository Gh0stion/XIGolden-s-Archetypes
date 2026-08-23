local s,id=GetID()
function s.initial_effect(c)
    -- Xyz Summon Procedure
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
    
    -- 1a. Multi-Attack & Direct Attack
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_EXTRA_ATTACK)
    e2:SetValue(2)
    c:RegisterEffect(e2)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_DIRECT_ATTACK)
    c:RegisterEffect(e3)
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
    e4:SetCondition(s.damcon)
    e4:SetValue(aux.ChangeBattleDamage(1,HALF_DAMAGE))
    c:RegisterEffect(e4)

    -- 1b. Protection: Cannot be targeted for attacks while you control other monsters
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_CANNOT_BE_BATTLE_TARGET)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCondition(s.atklimitcon)
    e5:SetValue(aux.imval1)
    c:RegisterEffect(e5)

    -- 1c. Floodgate: Skip opponent's Battle Phase if this is your only monster
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD)
    e6:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e6:SetCode(EFFECT_SKIP_BP)
    e6:SetRange(LOCATION_MZONE)
    e6:SetTargetRange(0,1) -- Target the opponent
    e6:SetCondition(s.skipcon)
    c:RegisterEffect(e6)
    
    -- 2. Special Summon Logic (Clean)
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,0))
    e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e7:SetCode(EVENT_BATTLE_DAMAGE)
    e7:SetCountLimit(1,id)
    e7:SetCondition(s.spcon2)
    e7:SetTarget(s.sptg2)
    e7:SetOperation(s.spop2)
    c:RegisterEffect(e7)
    
    -- 3. Detach & Set (Cooldown)
    local e8=Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id,1))
    e8:SetType(EFFECT_TYPE_QUICK_O)
    e8:SetCode(EVENT_FREE_CHAIN)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCountLimit(1,id+100) 
    e8:SetCondition(s.setcon)
    e8:SetCost(s.setcost)
    e8:SetTarget(s.settg)
    e8:SetOperation(s.setop)
    c:RegisterEffect(e8)
end

s.listed_series={0x99b,0x100b}
s.listed_names={26384578,53515038}

-- Skip Condition: Only monster in Main Monster Zone
function s.skipcon(e)
    local tp=e:GetHandlerPlayer()
    -- Count monsters in the Main Monster Zone only
    local g=Duel.GetMatchingGroup(Card.IsLocation,tp,LOCATION_MZONE,0,nil,LOCATION_MZONE)
    return #g==1 and g:GetFirst()==e:GetHandler()
end

-- Protection Condition: You control other monsters
function s.atklimitcon(e)
    return Duel.IsExistingMatchingCard(nil,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,e:GetHandler())
end

-- Summoning Logic
function s.matfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x99b)
        and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,26384578)
        and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,53515038)
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

function s.damcon(e)
    local bc=e:GetHandler():GetBattleTarget()
    return not bc or not bc:IsLocation(LOCATION_MZONE)
end

-- 2. Special Summon Logic
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
    return ep~=tp
end
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x99b) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
    end
end

-- 3. Detach & Set Logic
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():GetFlagEffect(id)==0
end
function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.setfilter(c)
    return c:IsSetCard(0x99b) and not c:IsSetCard(0x100b) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.setfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 and Duel.SSet(tp,g:GetFirst())~=0 then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_IMMUNE_EFFECT)
        e1:SetValue(s.efilter)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN,2)
        c:RegisterEffect(e1)
        c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN,EFFECT_FLAG_CLIENT_HINT,2,0,aux.Stringid(id,2))
    end
end
function s.efilter(e,te)
    return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end
