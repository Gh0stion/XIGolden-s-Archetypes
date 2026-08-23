local s,id=GetID()
function s.initial_effect(c)
    -- Xyz Summon (Must use Starforce Xyz with all 3 materials)
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
    
    -- 1a. Unaffected by Spells/Traps
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_IMMUNE_EFFECT)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(s.efilter)
    c:RegisterEffect(e2)
    
    -- 1b. Rank becomes 12 and Turn Timer starts
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetOperation(s.rkop)
    c:RegisterEffect(e3)
    
    -- 1c. Direct Attack & Half Damage
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_DIRECT_ATTACK)
    c:RegisterEffect(e4)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
    e5:SetCondition(s.damcon)
    e5:SetValue(aux.ChangeBattleDamage(1,HALF_DAMAGE))
    c:RegisterEffect(e5)
    
    -- 2. Multi-choice Quick Effect
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,0))
    e6:SetType(EFFECT_TYPE_QUICK_O)
    e6:SetCode(EVENT_FREE_CHAIN)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCountLimit(1)
    e6:SetCost(s.effcost)
    e6:SetTarget(s.efftg)
    e6:SetOperation(s.effop)
    c:RegisterEffect(e6)
    
    -- 3. Discard for Escalating Effects
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,1))
    e7:SetCategory(CATEGORY_HANDES+CATEGORY_DRAW)
    e7:SetType(EFFECT_TYPE_IGNITION)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(1)
    e7:SetTarget(s.distg)
    e7:SetOperation(s.disop)
    c:RegisterEffect(e7)
    
    -- 4. Send to GY after 3 turns
    local e8=Effect.CreateEffect(c)
    e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e8:SetCode(EVENT_PHASE+PHASE_END)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCountLimit(1)
    e8:SetCondition(s.tgcon)
    e8:SetOperation(s.tgop)
    c:RegisterEffect(e8)
end

s.listed_series={0x99b}
s.listed_names={26384578,23638502,53515038}

-- Summon Logic
function s.matfilter(c)
    local mg=c:GetOverlayGroup()
    return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x99b)
        and mg:IsExists(Card.IsCode,1,nil,26384578) -- Ninja
        and mg:IsExists(Card.IsCode,1,nil,23638502) -- Zerker
        and mg:IsExists(Card.IsCode,1,nil,53515038) -- Saurian
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

-- 1a. Immunity
function s.efilter(e,te)
    return te:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end

-- 1b. Rank 12 Fix & Timer Flag
function s.rkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CHANGE_RANK)
    e1:SetValue(12)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
    c:RegisterEffect(e1)
    -- Register flag with a value of 0, we will increment it every turn
    c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,0)
end

-- 1c. Damage Condition
function s.damcon(e)
    return Duel.GetAttackTarget()==nil and e:GetHandler():IsDirectAttacked()
end

-- 2. Multi-choice Quick Effect Logic
function s.effcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3),aux.Stringid(id,4),aux.Stringid(id,5))
    e:SetLabel(op)
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
    local op=e:GetLabel()
    if op==0 then -- Destroy & Damage
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
        local g=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
        if #g>0 then
            local atk=g:GetFirst():GetBaseAttack()
            if Duel.Destroy(g,REASON_EFFECT)~=0 and atk>0 then
                Duel.Damage(1-tp,atk,REASON_EFFECT)
            end
        end
    elseif op==1 then -- Banish Face-down
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
        local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
        if #g>0 then Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT) end
    elseif op==2 then -- Wipe S/T
        local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_ONFIELD,nil,TYPE_SPELL+TYPE_TRAP)
        if #g>0 then Duel.Destroy(g,REASON_EFFECT) end
    elseif op==3 then -- Shuffle to Deck
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
        local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,1,nil)
        if #g>0 then Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT) end
    end
end

-- 3. Discard Scaling
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ct=Duel.DiscardHand(tp,Card.IsDiscardable,1,4,REASON_EFFECT+REASON_DISCARD)
    if ct<=0 then return end
    
    -- 1+ Cards: Triple Attack
    if ct>=1 and c:IsRelateToEffect(e) then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_EXTRA_ATTACK)
        e1:SetValue(2)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        c:RegisterEffect(e1)
    end
    -- 2+ Cards: Draw 2
    if ct>=2 then
        Duel.BreakEffect()
        Duel.Draw(tp,2,REASON_EFFECT)
    end
    -- 3+ Cards: Full Immunity
    if ct>=3 and c:IsRelateToEffect(e) then
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_IMMUNE_EFFECT)
        e2:SetValue(function(e,te) return te:GetOwner()~=e:GetOwner() end)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
        c:RegisterEffect(e2)
    end
    -- 4 Cards: Cold Wave (Opponent cannot activate)
    if ct>=4 then
        local e3=Effect.CreateEffect(c)
        e3:SetType(EFFECT_TYPE_FIELD)
        e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e3:SetCode(EFFECT_CANNOT_ACTIVATE)
        e3:SetTargetRange(0,1)
        e3:SetValue(1)
        e3:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e3,tp)
    end
end

-- 4. Timer Logic: Send to GY after 3 of YOUR turns
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()==tp
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ct=c:GetFlagEffectLabel(id)
    if not ct then return end
    ct=ct+1
    c:SetFlagEffectLabel(id,ct)
    if ct>=3 then
        Duel.SendtoGrave(c,REASON_EFFECT)
    end
end
