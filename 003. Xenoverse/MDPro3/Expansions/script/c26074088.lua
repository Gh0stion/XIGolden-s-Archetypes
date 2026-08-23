local s,id=GetID()
function s.initial_effect(c)

    -------------------------------------------------
    -- Activate (Trap Card Activation)
    -------------------------------------------------
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    e0:SetCondition(s.actcon)
    c:RegisterEffect(e0)

    -------------------------------------------------
    -- Chain Link 1 Protection (Cannot be negated)
    -------------------------------------------------
    local e_prot=Effect.CreateEffect(c)
    e_prot:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e_prot:SetCode(EVENT_CHAIN_ACTIVATING)
    e_prot:SetRange(LOCATION_SZONE+LOCATION_HAND)
    e_prot:SetCondition(s.protcon)
    e_prot:SetOperation(s.protop)
    c:RegisterEffect(e_prot)

    -------------------------------------------------
    -- Activate from hand
    -------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_TRAP_ACT_IN_HAND)
    e1:SetCondition(s.handcon)
    c:RegisterEffect(e1)

    -------------------------------------------------
    -- Protect Spell/Traps
    -------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_ACTIVATE)
    e2:SetRange(LOCATION_SZONE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetTargetRange(0,1)
    e2:SetValue(s.aclimit)
    c:RegisterEffect(e2)

    -------------------------------------------------
    -- Special Summon during Battle Phase
    -------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1)
    e3:SetHintTiming(0,TIMING_BATTLE_PHASE)
    e3:SetCondition(s.spcon)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)

    -------------------------------------------------
    -- Destroy Replacement
    -------------------------------------------------
    local e10=Effect.CreateEffect(c)
    e10:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
    e10:SetCode(EFFECT_DESTROY_REPLACE)
    e10:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e10:SetRange(LOCATION_MZONE)
    e10:SetTarget(s.reptg)
    e10:SetOperation(s.repop)
    c:RegisterEffect(e10)

    -------------------------------------------------
    -- Leave field token summon
    -------------------------------------------------
    local e13=Effect.CreateEffect(c)
    e13:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e13:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e13:SetCode(EVENT_LEAVE_FIELD)
    e13:SetTarget(s.tktg)
    e13:SetOperation(s.tkop)
    c:RegisterEffect(e13)

end

-------------------------------------------------
-- Chain Link 1 activation verification
-------------------------------------------------
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetCurrentChain()==0
end

-------------------------------------------------
-- Chain Link 1 Protection logic
-------------------------------------------------
function s.protcon(e,tp,eg,ep,ev,re,r,rp)
    return re:GetHandler()==e:GetHandler() and ev==1
end

function s.protop(e,tp,eg,ep,ev,re,r,rp)
    Duel.SetChainLimitTillChainEnd(s.chlimit)
end

function s.chlimit(e,ep,tp)
    return tp==ep
end

-------------------------------------------------
-- Activate from hand condition
-------------------------------------------------
function s.handcon(e)
    local tp=e:GetHandlerPlayer()
    return Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>=2
        or Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
end

-------------------------------------------------
-- Protect Spell/Traps limit value
-------------------------------------------------
function s.aclimit(e,re,tp)
    return re:IsHasProperty(EFFECT_FLAG_CARD_TARGET)
        or re:IsHasCategory(CATEGORY_DESTROY)
        or re:IsHasCategory(CATEGORY_REMOVE)
end

-------------------------------------------------
-- Battle Phase summon condition
-------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsBattlePhase()
end

-------------------------------------------------
-- Summon target checks
-------------------------------------------------
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,TYPES_NORMAL_TRAP_MONSTER,3000,3000,8,RACE_WARRIOR,ATTRIBUTE_DARK)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

-------------------------------------------------
-- Trap Monster Summon operation
-------------------------------------------------
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,TYPES_NORMAL_TRAP_MONSTER,3000,3000,8,RACE_WARRIOR,ATTRIBUTE_DARK) then

        c:AddMonsterAttribute(TYPE_EFFECT,ATTRIBUTE_DARK,RACE_WARRIOR,8,0,0)

        if Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP_ATTACK)~=0 then

            -- Base ATK fix
            local estat=Effect.CreateEffect(c)
            estat:SetType(EFFECT_TYPE_SINGLE)
            estat:SetCode(EFFECT_SET_BASE_ATTACK)
            estat:SetValue(3000)
            estat:SetReset(RESET_EVENT+RESETS_STANDARD)
            c:RegisterEffect(estat)

            -- Base DEF fix
            local estat2=Effect.CreateEffect(c)
            estat2:SetType(EFFECT_TYPE_SINGLE)
            estat2:SetCode(EFFECT_SET_BASE_DEFENSE)
            estat2:SetValue(3000)
            estat2:SetReset(RESET_EVENT+RESETS_STANDARD)
            c:RegisterEffect(estat2)

            -- Bulletproof Name Change Helper (MZONE only)
            aux.EnableChangeCode(c,74496811,LOCATION_MZONE)

            -- Opponent monsters lose ATK/DEF
            local e8=Effect.CreateEffect(c)
            e8:SetType(EFFECT_TYPE_FIELD)
            e8:SetCode(EFFECT_UPDATE_ATTACK)
            e8:SetRange(LOCATION_MZONE)
            e8:SetTargetRange(0,LOCATION_MZONE)
            e8:SetValue(s.atkval)
            e8:SetReset(RESET_EVENT+RESETS_STANDARD)
            c:RegisterEffect(e8)

            local e9=e8:Clone()
            e9:SetCode(EFFECT_UPDATE_DEFENSE)
            c:RegisterEffect(e9)

        end
    end
end

-------------------------------------------------
-- ATK/DEF reduction value calculation
-------------------------------------------------
function s.atkval(e,c)
    return Duel.GetFieldGroupCount(e:GetHandlerPlayer(),LOCATION_HAND,0)*-300
end

-------------------------------------------------
-- Destroy replacement filter
-------------------------------------------------
function s.repfilter(c)
    return c:IsLocation(LOCATION_HAND+LOCATION_EXTRA) and c:IsAbleToGrave()
end

-------------------------------------------------
-- Destroy replacement target checks
-------------------------------------------------
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return c:IsLocation(LOCATION_MZONE) and c:IsFaceup() and not c:IsReason(REASON_REPLACE)
            and Duel.IsExistingMatchingCard(s.repfilter,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,nil)
    end
    return Duel.SelectEffectYesNo(tp,c,96)
end

-------------------------------------------------
-- Destroy replacement execution
-------------------------------------------------
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.repfilter,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,1,nil)
    Duel.SendtoGrave(g,REASON_EFFECT+REASON_REPLACE)
end

-------------------------------------------------
-- Leave field token target checks
-------------------------------------------------
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsPlayerCanSpecialSummonMonster(tp,26074089,0,TYPES_TOKEN,3500,3000,10,RACE_WARRIOR,ATTRIBUTE_FIRE)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

-------------------------------------------------
-- Leave field token summon execution
-------------------------------------------------
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    if not Duel.IsPlayerCanSpecialSummonMonster(tp,26074089,0,TYPES_TOKEN,3500,3000,10,RACE_WARRIOR,ATTRIBUTE_FIRE) then return end

    local token=Duel.CreateToken(tp,26074089)

    local e1=Effect.CreateEffect(token)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SET_BASE_ATTACK)
    e1:SetValue(3500)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    token:RegisterEffect(e1)

    local e2=e1:Clone()
    e2:SetCode(EFFECT_SET_BASE_DEFENSE)
    e2:SetValue(3000)
    token:RegisterEffect(e2)

    Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
end
