local s,id=GetID()
function s.initial_effect(c)
    -- Unaffected by other cards' effects on summon turn except DBXV2
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetCondition(s.immcon)
    e1:SetValue(s.immval)
    c:RegisterEffect(e1)

    -- Counter: When 4 effects activated, declare type and negate
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_NEGATE)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.negcon)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)

    -- Continuous Trap count scaling effects
    -- 1: Cannot be targeted
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e3:SetCondition(s.ct1con)
    e3:SetValue(aux.tgoval)
    c:RegisterEffect(e3)

    -- 2: Cannot be banished
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_CANNOT_REMOVE_EFFECT)
    e4:SetCondition(s.ct2con)
    e4:SetValue(1)
    c:RegisterEffect(e4)

    -- 3: Gain 400 ATK
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_UPDATE_ATTACK)
    e5:SetCondition(s.ct3con)
    e5:SetValue(400)
    c:RegisterEffect(e5)

    -- 4: Cannot be tributed or used as Link/Fusion material
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_UNRELEASABLE_SUM)
    e6:SetCondition(s.ct4con)
    e6:SetValue(1)
    c:RegisterEffect(e6)
    local e6b=e6:Clone()
    e6b:SetCode(EFFECT_UNRELEASABLE_NONSUM)
    c:RegisterEffect(e6b)
    local e6c=e6:Clone()
    e6c:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
    c:RegisterEffect(e6c)
    local e6d=e6:Clone()
    e6d:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
    c:RegisterEffect(e6d)

    -- 5: Can attack directly
    local e7=Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_SINGLE)
    e7:SetCode(EFFECT_DIRECT_ATTACK)
    e7:SetCondition(s.ct5con)
    e7:SetValue(1)
    c:RegisterEffect(e7)

    -- Quick Effect: Send Continuous Trap to shuffle opponent's card
    local e8=Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id,1))
    e8:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TODECK)
    e8:SetType(EFFECT_TYPE_QUICK_O)
    e8:SetCode(EVENT_FREE_CHAIN)
    e8:SetRange(LOCATION_MZONE)
    e8:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e8:SetCountLimit(1,id)
    e8:SetCost(s.qcost)
    e8:SetTarget(s.qtg)
    e8:SetOperation(s.qop)
    c:RegisterEffect(e8)
end

-- Immunity on summon turn
function s.immcon(e)
    local c=e:GetHandler()
    return c:IsStatus(STATUS_SPSUMMONED) and Duel.GetTurnCount()==c:GetFieldID()
end
function s.immval(e,re)
    local c=e:GetHandler()
    local rc=re:GetHandler()
    return re:GetOwner()~=c
        and not rc:IsSetCard(0x1990)
        and not rc:IsSetCard(0x990)
end

-- 4 effect counter
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    local ct=Duel.GetFlagEffect(tp,id)
    Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
    return ct+1>=4 and Duel.GetFlagEffect(tp,id+1)==0
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE+PHASE_END,0,1)
    local opt=Duel.AnnounceType(tp)
    local typ=opt==0 and TYPE_MONSTER or (opt==1 and TYPE_SPELL or TYPE_TRAP)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_CHAINING)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetLabel(typ)
    e1:SetCondition(s.chaincon)
    e1:SetOperation(s.chainop)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end
function s.chaincon(e,tp,eg,ep,ev,re,r,rp)
    return re:IsActiveType(e:GetLabel())
end
function s.chainop(e,tp,eg,ep,ev,re,r,rp)
    Duel.NegateActivation(ev)
end

-- Continuous Trap count helpers
function s.ctfilter(c)
    return (c:IsSetCard(0x1990) or c:IsSetCard(0x990))
        and c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS)
        and c:IsFaceup()
end
function s.ctcount(e)
    return Duel.GetMatchingGroup(s.ctfilter,e:GetHandlerPlayer(),LOCATION_SZONE,0,nil):GetCount()
end

function s.ct1con(e) return s.ctcount(e)>=1 end
function s.ct2con(e) return s.ctcount(e)>=2 end
function s.ct3con(e) return s.ctcount(e)>=3 end
function s.ct4con(e) return s.ctcount(e)>=4 end
function s.ct5con(e) return s.ctcount(e)>=5 end

-- Quick Effect cost: send Continuous Trap to GY
function s.costfilter(c)
    return (c:IsSetCard(0x1990) or c:IsSetCard(0x990))
        and c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS)
        and c:IsAbleToGrave()
end
function s.qcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_SZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_SZONE,0,1,1,nil)
    Duel.SendtoGrave(g,REASON_COST)
end

-- Target opponent's card
function s.qtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsAbleToDeck() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToDeck,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    Duel.SelectTarget(tp,Card.IsAbleToDeck,tp,0,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,1-tp,LOCATION_ONFIELD)
end
function s.qop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
end