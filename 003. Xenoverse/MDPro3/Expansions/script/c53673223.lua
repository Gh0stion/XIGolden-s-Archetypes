local s,id=GetID()
function s.initial_effect(c)

    -------------------------------------------------
    -- Activate
    -------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)

    -------------------------------------------------
    -- Hand activation condition
    -------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
    e2:SetCondition(s.handcon)
    c:RegisterEffect(e2)

    -------------------------------------------------
    -- Field buff
    -------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_SZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetTarget(s.xvfilter)
    e3:SetValue(150)
    c:RegisterEffect(e3)

    local e4=e3:Clone()
    e4:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e4)

    -------------------------------------------------
    -- Leave field punishment
    -------------------------------------------------
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_LEAVE_FIELD)
    e5:SetRange(LOCATION_SZONE)
    e5:SetOperation(s.leaveop)
    c:RegisterEffect(e5)

    -------------------------------------------------
    -- Special Summon as Trap Monster
    -------------------------------------------------
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,0))
    e6:SetType(EFFECT_TYPE_IGNITION)
    e6:SetRange(LOCATION_SZONE)
    e6:SetCountLimit(1)
    e6:SetCondition(s.spcon)
    e6:SetTarget(s.sptg)
    e6:SetOperation(s.spop)
    c:RegisterEffect(e6)

end

-------------------------------------------------
-- Archetype check
-------------------------------------------------
function s.is_dbxv2(c)
    return c:IsSetCard(0x1990)
end

function s.xvfilter(e,c)
    return c:IsFaceup() and c:IsSetCard(0x1990)
end

-------------------------------------------------
-- Hand activation
-------------------------------------------------
function s.handcon(e)
    local tp=e:GetHandlerPlayer()
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
        or Duel.IsExistingMatchingCard(s.xvfilter,tp,LOCATION_ONFIELD,0,1,nil)
end

-------------------------------------------------
-- Leave field punishment
-------------------------------------------------
function s.leaveop(e,tp,eg,ep,ev,re,r,rp)
    if not eg then return end
    for tc in aux.Next(eg) do
        if tc:IsControler(tp) and s.is_dbxv2(tc) then
            if Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) then
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
                local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
                if #g>0 then
                    Duel.SendtoGrave(g,REASON_EFFECT)
                end
            end
        end
    end
end

-------------------------------------------------
-- Summon condition (REMOVED REQUIREMENT)
-------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return true
end

-------------------------------------------------
-- Trap Monster transform
-------------------------------------------------
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,
                TYPES_NORMAL_TRAP_MONSTER,
                2000,2500,8,RACE_WARRIOR,ATTRIBUTE_DARK)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

-------------------------------------------------
-- Trap Monster transform
-------------------------------------------------
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    if not Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,
        TYPES_NORMAL_TRAP_MONSTER,2000,2500,8,RACE_WARRIOR,ATTRIBUTE_DARK) then return end

    c:AddMonsterAttribute(TYPE_NORMAL,ATTRIBUTE_DARK,RACE_WARRIOR,8,0,0)

    if Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP_DEFENSE)~=0 then

        local estat=Effect.CreateEffect(c)
        estat:SetType(EFFECT_TYPE_SINGLE)
        estat:SetCode(EFFECT_SET_BASE_ATTACK)
        estat:SetValue(2000)
        estat:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(estat)

        local estat2=Effect.CreateEffect(c)
        estat2:SetType(EFFECT_TYPE_SINGLE)
        estat2:SetCode(EFFECT_SET_BASE_DEFENSE)
        estat2:SetValue(2500)
        estat2:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(estat2)

        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CHANGE_CODE)
        e1:SetValue(35007848)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e1)

        -------------------------------------------------
        -- Attack position effects
        -------------------------------------------------
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_UPDATE_ATTACK)
        e2:SetCondition(s.atkposcon)
        e2:SetValue(1000)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e2)

        local e3=Effect.CreateEffect(c)
        e3:SetType(EFFECT_TYPE_SINGLE)
        e3:SetCode(EFFECT_IMMUNE_EFFECT)
        e3:SetCondition(s.atkposcon)
        e3:SetValue(s.immval)
        e3:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e3)

        -------------------------------------------------
        -- Defense position effects
        -------------------------------------------------
        local e4=Effect.CreateEffect(c)
        e4:SetType(EFFECT_TYPE_SINGLE)
        e4:SetCode(EFFECT_UPDATE_DEFENSE)
        e4:SetCondition(s.defposcon)
        e4:SetValue(500)
        e4:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e4)

        local e5=Effect.CreateEffect(c)
        e5:SetType(EFFECT_TYPE_FIELD)
        e5:SetCode(EFFECT_IMMUNE_EFFECT)
        e5:SetRange(LOCATION_MZONE)
        e5:SetTargetRange(LOCATION_MZONE,0)
        e5:SetTarget(s.allyfilter)
        e5:SetCondition(s.defposcon)
        e5:SetValue(s.immval)
        e5:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e5)

        local e6=Effect.CreateEffect(c)
        e6:SetType(EFFECT_TYPE_FIELD)
        e6:SetCode(EFFECT_CANNOT_BE_DESTROYED)
        e6:SetRange(LOCATION_MZONE)
        e6:SetTargetRange(LOCATION_MZONE,0)
        e6:SetTarget(s.allyfilter)
        e6:SetCondition(s.defposcon)
        e6:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e6)

        -------------------------------------------------
        -- Anti duplicate rule
        -------------------------------------------------
        local e7=Effect.CreateEffect(c)
        e7:SetType(EFFECT_TYPE_FIELD)
        e7:SetCode(EFFECT_CANNOT_SUMMON)
        e7:SetRange(LOCATION_MZONE)
        e7:SetTargetRange(0,LOCATION_MZONE+LOCATION_SZONE)
        e7:SetTarget(s.dupfilter)
        e7:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e7)

        -------------------------------------------------
        -- Xenoverse trigger effect
        -------------------------------------------------
        local e8=Effect.CreateEffect(c)
        e8:SetType(EFFECT_TYPE_QUICK_O)
        e8:SetCode(EVENT_CHAINING)
        e8:SetRange(LOCATION_MZONE)
        e8:SetCountLimit(1)
        e8:SetCondition(s.xvcon)
        e8:SetOperation(s.xvop)
        e8:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e8)

    end
end

-------------------------------------------------
-- Position condition helpers
-------------------------------------------------
function s.atkposcon(e)
    return e:GetHandler():IsAttackPos()
end

function s.defposcon(e)
    return e:GetHandler():IsDefensePos()
end

-------------------------------------------------
-- Immunity value
-------------------------------------------------
function s.immval(e,te)
    return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-------------------------------------------------
-- Ally filter
-------------------------------------------------
function s.allyfilter(e,c)
    return s.is_dbxv2(c) and c~=e:GetHandler()
end

-------------------------------------------------
-- Anti duplicate filter
-------------------------------------------------
function s.dupfilter(e,c)
    return c:IsCode(35007848)
end

-------------------------------------------------
-- Xenoverse trigger condition
-------------------------------------------------
function s.xvcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=re:GetHandler()
    return rc
        and rc~=c
        and rc:IsControler(tp)
        and rc:IsSetCard(0x1990)
        and re:IsActiveType(TYPE_MONSTER)
end

-------------------------------------------------
-- Effect: tribute → shuffle → switch position
-------------------------------------------------
function s.xvop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local g=Duel.SelectMatchingCard(tp,Card.IsReleasable,tp,LOCATION_MZONE,0,1,1,nil)
    if #g==0 then return end
    Duel.Release(g,REASON_COST)

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local dg=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,0,LOCATION_ONFIELD,1,1,nil)
    if #dg>0 then
        Duel.SendtoDeck(dg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end

    if c:IsRelateToEffect(e) then
        Duel.ChangePosition(c,POS_FACEUP_ATTACK)
    end
end