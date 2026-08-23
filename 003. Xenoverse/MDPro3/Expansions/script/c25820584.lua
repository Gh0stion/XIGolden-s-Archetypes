local s,id=GetID()
function s.initial_effect(c)
    -- Standard Activation
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)

    -- Hand Activation
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
    e2:SetCondition(s.handcon)
    c:RegisterEffect(e2)

    -- Anti-duplicate rule
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_ADJUST)
    e3:SetRange(LOCATION_SZONE)
    e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e3:SetOperation(s.uniquely_control)
    c:RegisterEffect(e3)

    -- Cannot be destroyed by opponent's card effects
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e4:SetRange(LOCATION_SZONE)
    e4:SetValue(1)
    c:RegisterEffect(e4)

    -- Cannot be banished by opponent's card effects
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_CANNOT_REMOVE_EFFECT)
    e5:SetRange(LOCATION_SZONE)
    e5:SetValue(1)
    c:RegisterEffect(e5)

    -- Negate all activated effects in opponent's GY
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e6:SetCode(EVENT_CHAINING)
    e6:SetRange(LOCATION_SZONE)
    e6:SetOperation(s.negop)
    c:RegisterEffect(e6)

    -- Quick Effect Trap Monster summon
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,0))
    e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e7:SetType(EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_FREE_CHAIN)
    e7:SetRange(LOCATION_SZONE)
    e7:SetCountLimit(1)
    e7:SetCondition(s.spcon)
    e7:SetCost(s.spcost)
    e7:SetTarget(s.sptg)
    e7:SetOperation(s.spop)
    c:RegisterEffect(e7)

    -- Name change on MZONE/GY only when Special Summoned
    local e8=Effect.CreateEffect(c)
    e8:SetType(EFFECT_TYPE_SINGLE)
    e8:SetCode(EFFECT_CHANGE_CODE)
    e8:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
    e8:SetCondition(s.namecon)
    e8:SetValue(68761173)
    c:RegisterEffect(e8)

    -- 1: Gain 200 ATK/DEF
    local e9=Effect.CreateEffect(c)
    e9:SetType(EFFECT_TYPE_SINGLE)
    e9:SetCode(EFFECT_UPDATE_ATTACK)
    e9:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e9:SetRange(LOCATION_MZONE)
    e9:SetCondition(s.ct1con)
    e9:SetValue(200)
    c:RegisterEffect(e9)
    local e10=e9:Clone()
    e10:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e10)

    -- 2: Monsters that battle this card have effects negated
    local e11=Effect.CreateEffect(c)
    e11:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e11:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
    e11:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e11:SetRange(LOCATION_MZONE)
    e11:SetCondition(s.ct2con)
    e11:SetOperation(s.batop)
    c:RegisterEffect(e11)

    -- 3: Opponent monsters lose 200 ATK/DEF
    local e12=Effect.CreateEffect(c)
    e12:SetType(EFFECT_TYPE_FIELD)
    e12:SetCode(EFFECT_UPDATE_ATTACK)
    e12:SetRange(LOCATION_MZONE)
    e12:SetTargetRange(0,LOCATION_MZONE)
    e12:SetCondition(s.ct3con)
    e12:SetValue(-200)
    c:RegisterEffect(e12)
    local e13=e12:Clone()
    e13:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e13)

    -- Quick Effect: Target 1 card you control, gain 350 ATK/DEF + protection
    local e14=Effect.CreateEffect(c)
    e14:SetDescription(aux.Stringid(id,1))
    e14:SetCategory(CATEGORY_ATKCHANGE)
    e14:SetType(EFFECT_TYPE_QUICK_O)
    e14:SetCode(EVENT_FREE_CHAIN)
    e14:SetRange(LOCATION_MZONE)
    e14:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e14:SetCountLimit(1,id+100)
    e14:SetTarget(s.btg)
    e14:SetOperation(s.bop)
    c:RegisterEffect(e14)

    -- End Phase Coin Flip
    local e15=Effect.CreateEffect(c)
    e15:SetDescription(aux.Stringid(id,2))
    e15:SetCategory(CATEGORY_TODECK+CATEGORY_NEGATE+CATEGORY_COIN)
    e15:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e15:SetCode(EVENT_PHASE+PHASE_END)
    e15:SetRange(LOCATION_MZONE)
    e15:SetCountLimit(1,id+200)
    e15:SetTarget(s.cointf)
    e15:SetOperation(s.coinop)
    c:RegisterEffect(e15)
end

-- Hand activation condition
function s.handcon(e)
    local tp=e:GetHandlerPlayer()
    return Duel.IsExistingMatchingCard(s.dbxv2filter,tp,LOCATION_ONFIELD,0,1,nil)
end

function s.dbxv2filter(c)
    return c:IsSetCard(0x990) and c:IsFaceup()
end

-- Anti-duplicate
function s.uniquefilter(c)
    return c:IsSetCard(0x990) and c:IsFaceup()
end

function s.uniquely_control(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.uniquefilter,tp,LOCATION_ONFIELD,0,nil)
    if #g<=1 then return end
    local check_codes={}
    local tg=Group.CreateGroup()
    for tc in aux.Next(g) do
        local code=tc:GetCode()
        if not check_codes[code] then
            check_codes[code]=tc
        else
            tg:AddCard(tc)
        end
    end
    if #tg>0 then
        Duel.SendtoGrave(tg,REASON_RULE)
        Duel.Readjust()
    end
end

-- Negate GY effects
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if rp==tp then return end
    local rc=re:GetHandler()
    if rc:IsLocation(LOCATION_GRAVE) then
        Duel.NegateActivation(ev)
    end
end

-- Trap Monster summon
function s.costfilter(c,handler)
    return c:IsSetCard(0x990) and c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS)
        and c:IsAbleToGrave() and c~=handler
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local ph=Duel.GetCurrentPhase()
    return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
        or (ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE)
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_SZONE,0,1,nil,c) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_SZONE,0,1,3,nil,c)
    Duel.SendtoGrave(g,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsPlayerCanSpecialSummonMonster(
                tp,id,0,
                TYPE_EFFECT+TYPE_TRAP+TYPE_MONSTER,
                2500,2500,8,
                RACE_WARRIOR,
                ATTRIBUTE_DIVINE)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.IsPlayerCanSpecialSummonMonster(
        tp,id,0,
        TYPE_EFFECT+TYPE_TRAP+TYPE_MONSTER,
        2500,2500,8,
        RACE_WARRIOR,
        ATTRIBUTE_DIVINE) then
        c:AddMonsterAttribute(
            TYPE_EFFECT+TYPE_TRAP+TYPE_MONSTER,
            ATTRIBUTE_DIVINE,
            RACE_WARRIOR,
            8,
            2500,
            2500)
        if Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP_ATTACK)~=0 then
            c:AddMonsterAttributeComplete()
        end
    end
end

-- Name change condition
function s.namecon(e)
    local c=e:GetHandler()
    return c:IsSummonType(SUMMON_TYPE_SPECIAL) or c:IsLocation(LOCATION_GRAVE)
end

-- GY Continuous Trap count
function s.gyfilter(c)
    return c:IsSetCard(0x990) and c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS)
end
function s.gycount(tp)
    return Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil):GetCount()
end

function s.ct1con(e) return s.gycount(e:GetHandlerPlayer())>=1 end
function s.ct2con(e) return s.gycount(e:GetHandlerPlayer())>=2 end
function s.ct3con(e) return s.gycount(e:GetHandlerPlayer())>=3 end

-- Negate battling monster's effects
function s.batop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetAttacker()
    if tc==c then tc=Duel.GetAttackTarget() end
    if tc and tc~=c then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE_CAL)
        tc:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        tc:RegisterEffect(e2)
    end
end

-- Quick Effect: 350 ATK/DEF + protection
function s.btg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(tp) and chkc:IsOnField() end
    if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,nil,1,tp,LOCATION_ONFIELD)
end

function s.bop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc==nil or not tc:IsRelateToEffect(e) then return end
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(350)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    tc:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    tc:RegisterEffect(e2)
    local e3=Effect.CreateEffect(e:GetHandler())
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetValue(1)
    e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    tc:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EFFECT_CANNOT_REMOVE_EFFECT)
    tc:RegisterEffect(e4)
end

-- End Phase Coin Flip
function s.cointf(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,0,LOCATION_MZONE,1,nil)
            or Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_COIN,nil,0,tp,1)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,1-tp,LOCATION_MZONE)
end

function s.coinop(e,tp,eg,ep,ev,re,r,rp)
    local result=Duel.TossCoin(tp,1)
    if result==1 then
        if not Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,0,LOCATION_MZONE,1,nil) then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
        local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,0,LOCATION_MZONE,1,1,nil)
        local tc=g:GetFirst()
        if tc==nil then return end
        local opp_code=tc:GetCode()
        if Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_FIELD)
            e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
            e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
            e1:SetTargetRange(0,1)
            e1:SetValue(function(e,c) return c:IsCode(opp_code) end)
            e1:SetReset(RESET_PHASE+PHASE_END)
            Duel.RegisterEffect(e1,tp)
        end
    else
        if not Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
        local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
        local tc=g:GetFirst()
        if tc==nil then return end
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        tc:RegisterEffect(e2)
    end
end