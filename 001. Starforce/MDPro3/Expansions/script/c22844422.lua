local s,id=GetID()
function s.initial_effect(c)
    --Xyz Summon Procedures
    c:EnableReviveLimit()
    
    --Method 1: Using Level 4 "Starforce" Xyz
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
    
    --Method 2: Send "Tribe On - Ninja" + Geo
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
    
    --Attach Ninja from GY (Trigger - No Description needed)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCondition(s.attcon)
    e3:SetOperation(s.attop)
    c:RegisterEffect(e3)
    
    --1. Summon token when attacked (QUICK EFFECT - ID 0)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0)) 
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_BE_BATTLE_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,id)
    e4:SetCondition(s.tkcon)
    e4:SetCost(s.cost_detach)
    e4:SetTarget(s.tktg)
    e4:SetOperation(s.tkop)
    c:RegisterEffect(e4)
    
    --2. Damage when token is targeted (Trigger - No Description)
    local e5=Effect.CreateEffect(c)
    e5:SetCategory(CATEGORY_DAMAGE)
    e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e5:SetCode(EVENT_BE_BATTLE_TARGET)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1,id+100)
    e5:SetCondition(s.damcon)
    e5:SetTarget(s.damtg)
    e5:SetOperation(s.damop)
    c:RegisterEffect(e5)
    local e6=e5:Clone()
    e6:SetCode(EVENT_BECOME_TARGET)
    c:RegisterEffect(e6)
    
    --3. Shuffle/Negate (QUICK EFFECT - ID 1)
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,1)) 
    e7:SetCategory(CATEGORY_TODECK+CATEGORY_ATKCHANGE+CATEGORY_DISABLE)
    e7:SetType(EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_FREE_CHAIN)
    e7:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(1,id+200)
    e7:SetCost(s.cost_detach)
    e7:SetTarget(s.negtg)
    e7:SetOperation(s.negop)
    c:RegisterEffect(e7)
    
    --4. Standby Recovery (Trigger - No Description)
    local e8=Effect.CreateEffect(c)
    e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e8:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCountLimit(1,id+300)
    e8:SetCondition(s.attcon2)
    e8:SetOperation(s.attop2)
    c:RegisterEffect(e8)
end

s.listed_series={0x99b}
s.listed_names={59999377,53515038,75457135}

-- Shared Logic
function s.cost_detach(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- Method 1 Transfer
function s.matfilter1(c)
    return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x99b) and c:IsRank(4)
        and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,53515038)
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
function s.ninjafilter(c)
    return c:IsFaceup() and c:IsCode(53515038) and c:IsAbleToGraveAsCost()
end
function s.geofilter(c)
    return c:IsFaceup() and c:IsCode(59999377) and c:IsCanBeXyzMaterial(nil)
end
function s.spcon2(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
        and Duel.IsExistingMatchingCard(s.ninjafilter,tp,LOCATION_ONFIELD,0,1,nil)
        and Duel.IsExistingMatchingCard(s.geofilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk,c)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g1=Duel.SelectMatchingCard(tp,s.ninjafilter,tp,LOCATION_ONFIELD,0,1,1,nil)
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
    local ninja=g:Filter(Card.IsCode,nil,53515038):GetFirst()
    local geo=g:Filter(Card.IsCode,nil,59999377):GetFirst()
    if ninja and geo then
        Duel.SendtoGrave(ninja,REASON_COST)
        c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD,0,1)
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
    local tc=Duel.GetFirstMatchingCard(Card.IsCode,tp,LOCATION_GRAVE,0,nil,53515038)
    if tc then Duel.Overlay(e:GetHandler(),tc) end
end

-- Token Summon
function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler()==Duel.GetAttackTarget()
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsPlayerCanSpecialSummonMonster(tp,75457135,0,TYPES_TOKEN,1500,1000,7,RACE_CYBERSE,ATTRIBUTE_WATER) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local token=Duel.CreateToken(tp,75457135)
    if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)~=0 then
        Duel.ChangeAttackTarget(token)
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
        e1:SetValue(1)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e1)
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e2:SetCode(EVENT_PHASE+PHASE_BATTLE)
        e2:SetCountLimit(1)
        e2:SetLabelObject(token)
        e2:SetOperation(function(e) if e:GetLabelObject() then Duel.Destroy(e:GetLabelObject(),REASON_EFFECT) end end)
        e2:SetReset(RESET_PHASE+PHASE_BATTLE)
        Duel.RegisterEffect(e2,tp)
        Duel.SetChainLimit(aux.FALSE)
    end
end

-- Damage
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(function(c) return c:IsCode(75457135) and c:IsControler(tp) end,1,nil)
end
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local ac=Duel.GetAttacker() or (re and re:GetHandler())
    local val=0
    if ac then val=ac:IsType(TYPE_XYZ) and ac:GetRank() or ac:GetLevel() end
    Duel.SetTargetPlayer(1-tp)
    Duel.SetTargetParam(val*300)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,val*300)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
    local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
    Duel.Damage(p,d,REASON_EFFECT)
end

-- Negate Strike
function s.tdfilter(c)
    return c:IsSetCard(0x99b) and c:IsType(TYPE_SPELL) and c:IsAbleToDeck()
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsFaceup() end
    if chk==0 then return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil)
        and Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    e:SetLabelObject(g:GetFirst())
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,1,nil)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    local sc=e:GetLabelObject()
    if sc and Duel.SendtoDeck(sc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 then
        if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
            local c=e:GetHandler()
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_SET_ATTACK_FINAL)
            e1:SetValue(0)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
            tc:RegisterEffect(e1)
            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_DISABLE)
            e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
            tc:RegisterEffect(e2)
        end
    end
end

-- Standby Re-Attach
function s.attcon2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return not c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,53515038)
        and Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_GRAVE,0,1,nil,53515038)
end
function s.attop2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstMatchingCard(Card.IsCode,tp,LOCATION_GRAVE,0,nil,53515038)
    if tc and c:IsRelateToEffect(e) then Duel.Overlay(c,tc) end
end
