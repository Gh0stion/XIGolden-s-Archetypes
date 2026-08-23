local s,id=GetID()
function s.initial_effect(c)
    --Xyz Summon
    c:EnableReviveLimit()
    
    --Method 1: Using "Starforce" Xyz with Material Transfer Fix
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.spcon1)
    e1:SetTarget(s.sptg1)
    e1:SetOperation(s.spop1)
    e1:SetValue(SUMMON_TYPE_XYZ)
    c:RegisterEffect(e1)
    
    --Method 2: Send "Tribe On - Saurian" then use Geo Stelar
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_SPSUMMON_PROC)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e2:SetRange(LOCATION_EXTRA)
    e2:SetCondition(s.spcon2)
    e2:SetTarget(s.sptg2)
    e2:SetOperation(s.spop2)
    e2:SetValue(SUMMON_TYPE_XYZ)
    c:RegisterEffect(e2)
    
    --Attach sent spell when summoned (Trigger)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCondition(s.attcon)
    e3:SetOperation(s.attop)
    c:RegisterEffect(e3)
    
    --1a. Gain 800 ATK (Fixed: Trigger Type prevents infinite loops)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0)) -- "Saurian Rage: +800 ATK"
    e4:SetCategory(CATEGORY_ATKCHANGE)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F) -- Changed to Trigger_F
    e4:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1) -- Ensures only once per BP
    e4:SetCondition(s.atkcon)
    e4:SetOperation(s.atkop)
    c:RegisterEffect(e4)
    
    --1b. Gain ATK/DEF when destroying by battle
    local e5=Effect.CreateEffect(c)
    e5:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_BATTLE_DESTROYING)
    e5:SetOperation(s.batop)
    c:RegisterEffect(e5)
    
    --1c. Can attack up to 3 times
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
    e6:SetValue(2)
    c:RegisterEffect(e6)
    
    --1d. Change to defense at End of Battle Phase if it attacked multiple times
    local e7=Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e7:SetCode(EVENT_PHASE+PHASE_BATTLE)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(1)
    e7:SetCondition(s.poscon)
    e7:SetOperation(s.posop)
    c:RegisterEffect(e7)
    
    --2. Detach to Special Summon (IGNITION - ID 1)
    local e9=Effect.CreateEffect(c)
    e9:SetDescription(aux.Stringid(id,1))
    e9:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e9:SetType(EFFECT_TYPE_IGNITION)
    e9:SetRange(LOCATION_MZONE)
    e9:SetCountLimit(1)
    e9:SetCost(s.spcost)
    e9:SetTarget(s.sptg3)
    e9:SetOperation(s.spop3)
    c:RegisterEffect(e9)
    
    --3. Protection Logic
    local e10=Effect.CreateEffect(c)
    e10:SetType(EFFECT_TYPE_SINGLE)
    e10:SetCode(EFFECT_CANNOT_DISABLE)
    e10:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e10:SetRange(LOCATION_MZONE)
    e10:SetCondition(s.immcon)
    c:RegisterEffect(e10)
    local e11=Effect.CreateEffect(c)
    e11:SetType(EFFECT_TYPE_SINGLE)
    e11:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e11:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e11:SetRange(LOCATION_MZONE)
    e11:SetCondition(s.immcon)
    e11:SetValue(1)
    c:RegisterEffect(e11)
    local e12=Effect.CreateEffect(c)
    e12:SetType(EFFECT_TYPE_SINGLE)
    e12:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
    e12:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e12:SetRange(LOCATION_MZONE)
    e12:SetCondition(s.immcon)
    e12:SetValue(1)
    c:RegisterEffect(e12)
    local e13=Effect.CreateEffect(c)
    e13:SetType(EFFECT_TYPE_SINGLE)
    e13:SetCode(EFFECT_IMMUNE_EFFECT)
    e13:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e13:SetRange(LOCATION_MZONE)
    e13:SetCondition(s.immcon)
    e13:SetValue(s.efilter)
    c:RegisterEffect(e13)
end

s.listed_series={0x99b}
s.listed_names={59999377,23638502}

-- Method 1: Proper Transfer
function s.matfilter1(c)
    return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x99b)
        and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,23638502)
end
function s.spcon1(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
        and Duel.IsExistingMatchingCard(s.matfilter1,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk,c)
    local g=Duel.GetMatchingGroup(s.matfilter1,tp,LOCATION_MZONE,0,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
    local sg=g:SelectSubGroup(tp,aux.TRUE,false,1,1)
    if sg then
        sg:KeepAlive()
        e:SetLabelObject(sg)
        return true
    else return false end
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    local tc=g:GetFirst()
    local mg=tc:GetOverlayGroup()
    if #mg>0 then Duel.Overlay(c,mg) end
    c:SetMaterial(g)
    Duel.Overlay(c,g)
    g:DeleteGroup()
end

-- Method 2 Login
function s.saurianfilter(c)
    return c:IsFaceup() and c:IsCode(23638502) and c:IsAbleToGraveAsCost()
end
function s.geofilter(c)
    return c:IsFaceup() and c:IsCode(59999377) and c:IsCanBeXyzMaterial(nil)
end
function s.spcon2(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
        and Duel.IsExistingMatchingCard(s.saurianfilter,tp,LOCATION_ONFIELD,0,1,nil)
        and Duel.IsExistingMatchingCard(s.geofilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk,c)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g1=Duel.SelectMatchingCard(tp,s.saurianfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
    if #g1>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
        local g2=Duel.SelectMatchingCard(tp,s.geofilter,tp,LOCATION_MZONE,0,1,1,nil)
        if #g2>0 then
            g1:Merge(g2)
            g1:KeepAlive()
            e:SetLabelObject(g1)
            return true
        end
    end
    return false
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    local saurian=g:Filter(Card.IsCode,nil,23638502):GetFirst()
    local geo=g:Filter(Card.IsCode,nil,59999377):GetFirst()
    if saurian and geo then
        Duel.SendtoGrave(saurian,REASON_COST)
        c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD,0,1,saurian:GetCode())
        local mg=Group.FromCards(geo)
        c:SetMaterial(mg)
        Duel.Overlay(c,mg)
    end
    g:DeleteGroup()
end

function s.attcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ) and e:GetHandler():GetFlagEffect(id)>0
end
function s.attop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local code=c:GetFlagEffectLabel(id)
    local tc=Duel.GetFirstMatchingCard(Card.IsCode,tp,LOCATION_GRAVE,0,nil,code)
    if tc then Duel.Overlay(c,tc) end
end

-- 1a. Gain 800 ATK Logic
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()==tp
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsFaceup() and c:IsRelateToEffect(e) then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(800)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_BATTLE)
        c:RegisterEffect(e1)
    end
end

-- 1b. Destroy by battle gain
function s.batop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(500)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e2)
end

-- 1d. Forced Defense
function s.poscon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():GetBattledGroupCount()>1
end
function s.posop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsFaceup() and c:IsAttackPos() then
        Duel.ChangePosition(c,POS_FACEUP_DEFENSE)
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
        c:RegisterEffect(e1)
    end
end

-- 2. Detach to Special Summon
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
    -- Standard engine prompt
    local g=c:GetOverlayGroup()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVEXYZ)
    local sg=g:Select(tp,1,1,nil)
    local tc=sg:GetFirst()
    -- Register what was detached to check for Geo Stelar
    c:RegisterFlagEffect(id+100,RESET_CHAIN,0,1,tc:GetCode())
    Duel.SendtoGrave(sg,REASON_COST)
end
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x99b) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.spop3(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local loc=LOCATION_HAND+LOCATION_GRAVE
    -- If Geo Stelar was the one detached, include the Deck
    if c:GetFlagEffect(id+100)>0 and c:GetFlagEffectLabel(id+100)==59999377 then
        loc=loc+LOCATION_DECK
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,loc,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- 3. Protection
function s.immcon(e)
    return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,23638502)
end
function s.efilter(e,re)
    if e:GetHandler()==re:GetOwner() then return false end
    return re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP) and not re:IsHasCategory(CATEGORY_ATKCHANGE)
end
