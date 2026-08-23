local s,id=GetID()
function s.initial_effect(c)
    -- Special Summon from hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- Gains 400 ATK/DEF on chain solved
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_CHAIN_SOLVED)
    e2:SetRange(LOCATION_MZONE)
    e2:SetOperation(s.atkup)
    c:RegisterEffect(e2)

    -- Send 1 Continuous Trap to GY to gain 250 ATK
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOGRAVE+CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetTarget(s.atktg)
    e3:SetOperation(s.atkop)
    c:RegisterEffect(e3)

    -- Stat-based threshold effects
    -- 1000+: Other cards gain 200 ATK/DEF
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_UPDATE_ATTACK)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTargetRange(LOCATION_ONFIELD,0)
    e4:SetTarget(s.othertg)
    e4:SetCondition(s.stat1000con)
    e4:SetValue(200)
    c:RegisterEffect(e4)
    local e5=e4:Clone()
    e5:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e5)

    -- 1500+: Cannot be targeted for attacks
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_CANNOT_BE_BATTLE_TARGET)
    e6:SetCondition(s.stat1500con)
    e6:SetValue(aux.imval1)
    c:RegisterEffect(e6)

    -- 2000+: Negate opponent's activated monster effects on resolution
    local e7=Effect.CreateEffect(c)
e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
e7:SetCode(EVENT_CHAINING)
e7:SetRange(LOCATION_MZONE)
e7:SetCondition(s.stat2000con)
e7:SetOperation(s.negop)
c:RegisterEffect(e7)

    -- Standby Phase Quick Effect: Shuffle & Summon Token
    local e8=Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id,2))
    e8:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e8:SetType(EFFECT_TYPE_QUICK_O)
    e8:SetCode(EVENT_FREE_CHAIN)
    e8:SetRange(LOCATION_MZONE)
    e8:SetHintTiming(0,TIMING_STANDBY_PHASE)
    e8:SetCondition(s.tkcon)
    e8:SetTarget(s.tktg)
    e8:SetOperation(s.tkop)
    c:RegisterEffect(e8)
end

s.listed_names={id,32918480}

-------------------------------------------------
-- Helper archetype filter
-------------------------------------------------
function s.is_dbxv2(c)
    return c:IsSetCard(0x990) or c:IsSetCard(0x1990)
end

-------------------------------------------------
-- Hand Special Summon Mechanics
-------------------------------------------------
function s.cfilter(c)
    return c:IsFaceup() and s.is_dbxv2(c)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_ONFIELD,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-------------------------------------------------
-- ATK/DEF Gain (Fixed per image reference)
-------------------------------------------------
function s.atkup(e,tp,eg,ep,ev,re,r,rp)
    local rc=re:GetHandler()
    if s.is_dbxv2(rc) then
        local c=e:GetHandler()
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(400)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        c:RegisterEffect(e2)
    end
end

-------------------------------------------------
-- Send Cont. Trap to GY to gain 250 ATK
-------------------------------------------------
function s.trapfilter(c)
    return c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS) and c:IsAbleToGrave()
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_SZONE) and chkc:IsControler(tp) and s.trapfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.trapfilter,tp,LOCATION_SZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectTarget(tp,s.trapfilter,tp,LOCATION_SZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and Duel.SendtoGrave(tc,REASON_EFFECT)~=0 then
        if c:IsRelateToEffect(e) and c:IsFaceup() then
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(250)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            c:RegisterEffect(e1)
        end
    end
end

-------------------------------------------------
-- Stat-Based Threshold Conditions
-------------------------------------------------
function s.stat1000con(e)
    return e:GetHandler():GetAttack()>=1000
end

function s.othertg(e,c)
    return c~=e:GetHandler()
end

function s.stat1500con(e)
    return e:GetHandler():GetAttack()>=1500
end

function s.stat2000con(e)
    return e:GetHandler():GetAttack()>=2000
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if rp==tp then return end
    if not re:IsActiveType(TYPE_MONSTER) then return end

    Duel.NegateActivation(ev)
end

-------------------------------------------------
-- Standby Phase Token Evolution
-------------------------------------------------
function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetCurrentPhase()==PHASE_STANDBY
        and Duel.GetTurnPlayer()==tp
        and e:GetHandler():GetAttack()>=3000
end

function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return c:IsAbleToDeck()
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.tkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    if Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 then
        return
    end

    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    local token=Duel.CreateToken(tp,32918480)
    if token then
        Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
    end
end