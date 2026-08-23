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
    -- Activate from hand
    -------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
    e2:SetCondition(s.handcon)
    c:RegisterEffect(e2)

    -------------------------------------------------
    -- Xenoverse 2 monsters gain 200 ATK/DEF
    -------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_SZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetTarget(s.atktg)
    e3:SetValue(200)
    c:RegisterEffect(e3)

    local e4=e3:Clone()
    e4:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e4)

    -------------------------------------------------
    -- Crossover S/T cannot be destroyed
    -------------------------------------------------
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e5:SetRange(LOCATION_SZONE)
    e5:SetTargetRange(LOCATION_SZONE,0)
    e5:SetTarget(s.crosstg)
    e5:SetValue(1)
    c:RegisterEffect(e5)

    -------------------------------------------------
    -- Crossover S/T cannot be banished
    -------------------------------------------------
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD)
    e6:SetCode(EFFECT_CANNOT_REMOVE)
    e6:SetRange(LOCATION_SZONE)
    e6:SetTargetRange(LOCATION_SZONE,0)
    e6:SetTarget(s.crosstg)
    c:RegisterEffect(e6)

    -------------------------------------------------
    -- Trap Monster Summon
    -------------------------------------------------
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,0))
    e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e7:SetType(EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_FREE_CHAIN)
    e7:SetRange(LOCATION_SZONE)
    e7:SetCountLimit(1)
    e7:SetCondition(s.spcon)
    e7:SetTarget(s.sptg)
    e7:SetOperation(s.spop)
    c:RegisterEffect(e7)

    -------------------------------------------------
    -- Name change
    -------------------------------------------------
    aux.EnableChangeCode(c,45492062,LOCATION_MZONE+LOCATION_GRAVE)

    -------------------------------------------------
    -- ATK transfer trigger (twice per turn)
    -------------------------------------------------
    local e8=Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id,1))
    e8:SetCategory(CATEGORY_ATKCHANGE)
    e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e8:SetCode(EVENT_CHAINING)
    e8:SetRange(LOCATION_MZONE)
    e8:SetProperty(EFFECT_FLAG_DELAY)
    e8:SetCountLimit(2)
    e8:SetCondition(s.atkcon)
    e8:SetTarget(s.atktg2)
    e8:SetOperation(s.atkop)
    c:RegisterEffect(e8)

    -------------------------------------------------
    -- Must attack this card (Yubel style)
    -------------------------------------------------
    local e9=Effect.CreateEffect(c)
    e9:SetType(EFFECT_TYPE_FIELD)
    e9:SetCode(EFFECT_MUST_BATTLE)
    e9:SetRange(LOCATION_MZONE)
    e9:SetTargetRange(0,LOCATION_MZONE)
    e9:SetValue(s.atlimit)
    c:RegisterEffect(e9)

    -- Prevent opponent from selecting other attack targets
    local e9b=Effect.CreateEffect(c)
    e9b:SetType(EFFECT_TYPE_FIELD)
    e9b:SetCode(EFFECT_CANNOT_SELECT_ATTACK_TARGET)
    e9b:SetRange(LOCATION_MZONE)
    e9b:SetTargetRange(0,LOCATION_MZONE)
    e9b:SetTarget(s.notbroly)
    c:RegisterEffect(e9b)

    -------------------------------------------------
    -- Protect allies during Battle Phase
    -------------------------------------------------
    local e10=Effect.CreateEffect(c)
    e10:SetType(EFFECT_TYPE_FIELD)
    e10:SetCode(EFFECT_IMMUNE_EFFECT)
    e10:SetRange(LOCATION_MZONE)
    e10:SetTargetRange(LOCATION_MZONE,0)
    e10:SetTarget(s.immtg)
    e10:SetCondition(s.bpcon)
    e10:SetValue(s.immval)
    c:RegisterEffect(e10)

    -------------------------------------------------
    -- Continuous ATK/DEF gain per turn
    -------------------------------------------------
    local e11=Effect.CreateEffect(c)
    e11:SetType(EFFECT_TYPE_SINGLE)
    e11:SetCode(EFFECT_UPDATE_ATTACK)
    e11:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e11:SetRange(LOCATION_MZONE)
    e11:SetValue(s.stbyval)
    c:RegisterEffect(e11)

    local e12=e11:Clone()
    e12:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e12)

end

-------------------------------------------------
-- Archetype helper
-------------------------------------------------
function s.dbxvfilter(c)
    return c:IsSetCard(0x1990)
end

-------------------------------------------------
-- Hand activation
-------------------------------------------------
function s.handfilter(c)
    return c:IsFaceup()
        and (c:IsType(TYPE_MONSTER)
        or (c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS)))
        and c:IsSetCard(0x1990)
end

function s.handcon(e)
    local tp=e:GetHandlerPlayer()
    local ph=Duel.GetCurrentPhase()
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
        or Duel.IsExistingMatchingCard(s.handfilter,tp,LOCATION_ONFIELD,0,1,nil)
        or (Duel.GetTurnPlayer()~=tp
        and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2))
end

-------------------------------------------------
-- Xenoverse boost target
-------------------------------------------------
function s.atktg(e,c)
    return c:IsSetCard(0x1990)
end

-------------------------------------------------
-- Crossover protection target
-------------------------------------------------
function s.crosstg(e,c)
    return c:IsSetCard(0x990)
end

-------------------------------------------------
-- Summon condition
-------------------------------------------------
function s.spfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x1990)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_ONFIELD,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsPlayerCanSpecialSummonMonster(
                tp,id,0,
                TYPE_EFFECT+TYPE_TRAP+TYPE_MONSTER,
                3000,2500,10,
                RACE_WARRIOR,
                ATTRIBUTE_WIND)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    c:AddMonsterAttribute(
        TYPE_EFFECT+TYPE_TRAP+TYPE_MONSTER,
        ATTRIBUTE_WIND,
        RACE_WARRIOR,
        10,
        3000,
        2500)
    if Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP_ATTACK)~=0 then
        c:AddMonsterAttributeComplete()
    end
end

-------------------------------------------------
-- ATK transfer condition
-------------------------------------------------
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return rp~=tp
        and re~=nil
        and re:GetHandler()~=c
        and re:GetHandler():IsSetCard(0x1990)
        and re:IsActivated()
        and re:IsActiveType(TYPE_MONSTER)
end

function s.atktg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
    end
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
    local tc=g:GetFirst()
    if not tc then return end

    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(-800)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    tc:RegisterEffect(e1)

    local e2=e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    tc:RegisterEffect(e2)

    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetValue(800)
    e3:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e3)

    local e4=e3:Clone()
    e4:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e4)
end

-------------------------------------------------
-- Must attack Broly (Yubel style)
-------------------------------------------------
function s.atlimit(e,c)
    return e:GetHandler()
end

-------------------------------------------------
-- Block targeting anything that isn't this card
-------------------------------------------------
function s.notbroly(e,c)
    return c~=e:GetHandler()
end

-------------------------------------------------
-- Battle Phase protection
-------------------------------------------------
function s.bpcon(e)
    local ph=Duel.GetCurrentPhase()
    return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end

function s.immtg(e,c)
    return c~=e:GetHandler()
end

function s.immval(e,re)
    return re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-------------------------------------------------
-- Continuous ATK/DEF gain per turn
-------------------------------------------------
function s.stbyval(e,c)
    return Duel.GetTurnCount()*150
end