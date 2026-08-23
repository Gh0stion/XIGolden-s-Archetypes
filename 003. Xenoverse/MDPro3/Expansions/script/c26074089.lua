
local s,id=GetID()
function s.initial_effect(c)

    -------------------------------------------------
    -- CONTINUOUS: Turn Summoned: Gain 1500 ATK/DEF & Unaffected
    -------------------------------------------------
    -- ATK Boost (Continuous)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCondition(s.turncon)
    e1:SetValue(1500)
    c:RegisterEffect(e1)

    -- DEF Boost (Continuous)
    local e2=e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e2)

    -- Unaffected by other card effects (Continuous)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_IMMUNE_EFFECT)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.turncon)
    e3:SetValue(s.efilter)
    c:RegisterEffect(e3)

    -------------------------------------------------
    -- CONTINUOUS: Each Standby Phase: Gain 350 ATK/DEF (OPT)
    -------------------------------------------------
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e4:SetCode(EVENT_PHASE_START+PHASE_STANDBY)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetOperation(s.atkop)
    c:RegisterEffect(e4)

    -------------------------------------------------
    -- Cannot be destroyed or targeted by opponent
    -------------------------------------------------
    -- Cannot be destroyed
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCode(EFFECT_INDESTRUCTIBLE_EFFECT)
    e5:SetValue(s.indval)
    c:RegisterEffect(e5)

    -- Cannot be targeted
    local e6=e5:Clone()
    e6:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e6:SetValue(aux.tgoval)
    c:RegisterEffect(e6)

    -------------------------------------------------
    -- Team Buff: Other monsters gain 300 ATK/DEF
    -------------------------------------------------
    local e7=Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_FIELD)
    e7:SetCode(EFFECT_UPDATE_ATTACK)
    e7:SetRange(LOCATION_MZONE)
    e7:SetTargetRange(LOCATION_MZONE,0)
    e7:SetTarget(s.teamtg)
    e7:SetValue(300)
    c:RegisterEffect(e7)

    local e8=e7:Clone()
    e8:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e8)

    -------------------------------------------------
    -- Quick Effect: Negate S/T activation & Set from Deck (OPT)
    -------------------------------------------------
    local e9=Effect.CreateEffect(c)
    e9:SetDescription(aux.Stringid(id,1))
    e9:SetCategory(CATEGORY_NEGATE)
    e9:SetType(EFFECT_TYPE_QUICK_O)
    e9:SetCode(EVENT_CHAINING)
    e9:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e9:SetRange(LOCATION_MZONE)
    e9:SetCountLimit(1)
    e9:SetCondition(s.negcon)
    e9:SetTarget(s.negtg)
    e9:SetOperation(s.negop)
    c:RegisterEffect(e9)

    -------------------------------------------------
    -- Quick Effect: Target & Set 1 S/T from opponent's GY (OPT)
    -------------------------------------------------
    local e11=Effect.CreateEffect(c)
    e11:SetDescription(aux.Stringid(id,3))
    e11:SetType(EFFECT_TYPE_QUICK_O)
    e11:SetCode(EVENT_FREE_CHAIN)
    e11:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e11:SetRange(LOCATION_MZONE)
    e11:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e11:SetCountLimit(1)
    e11:SetCondition(s.stealcon)
    e11:SetTarget(s.stealtg)
    e11:SetOperation(s.stealop)
    c:RegisterEffect(e11)

    -------------------------------------------------
    -- CONTINUOUS TRIGGER: When S/T is resolved -> Destroy 1 card (OPT)
    -------------------------------------------------
    local e10=Effect.CreateEffect(c)
    e10:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e10:SetCode(EVENT_CHAIN_SOLVED)
    e10:SetRange(LOCATION_MZONE)
    e10:SetCondition(s.descon)
    e10:SetOperation(s.desop)
    c:RegisterEffect(e10)

    -------------------------------------------------
    -- Dynamic Effects based on Spell/Trap control count
    -------------------------------------------------
    -- 1+: Gain 500 ATK/DEF
    local e12=Effect.CreateEffect(c)
    e12:SetType(EFFECT_TYPE_SINGLE)
    e12:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e12:SetRange(LOCATION_MZONE)
    e12:SetCode(EFFECT_UPDATE_ATTACK)
    e12:SetCondition(s.countcon(1))
    e12:SetValue(500)
    c:RegisterEffect(e12)

    local e13=e12:Clone()
    e13:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e13)

    -- 2+: Cannot be banished by opponent's card effects
    local e14=Effect.CreateEffect(c)
    e14:SetType(EFFECT_TYPE_SINGLE)
    e14:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e14:SetRange(LOCATION_MZONE)
    e14:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e14:SetCondition(s.countcon(2))
    e14:SetValue(s.banishval)
    c:RegisterEffect(e14)
    
    local e15=e14:Clone()
    e15:SetCode(EFFECT_IMMUNE_EFFECT)
    e15:SetValue(s.banishfilter)
    c:RegisterEffect(e15)

    -- 3+: Direct Attack capability
    local e16=Effect.CreateEffect(c)
    e16:SetType(EFFECT_TYPE_SINGLE)
    e16:SetCode(EFFECT_DIRECT_ATTACK)
    e16:SetCondition(s.countcon(3))
    c:RegisterEffect(e16)

end

-------------------------------------------------
-- Helper: Counts ALL Spells/Traps you control (SZONE + FZONE)
-------------------------------------------------
function s.stcount(tp)
    return Duel.GetMatchingGroupCount(nil,tp,LOCATION_SZONE+LOCATION_FZONE,0,nil)
end

function s.countcon(count)
    return function(e)
        return s.stcount(e:GetHandlerPlayer())>=count
    end
end

-------------------------------------------------
-- Turn Summoned Conditions & Immunity Filters
-------------------------------------------------
function s.turncon(e)
    local c=e:GetHandler()
    local ph=Duel.GetCurrentPhase()
    return c:GetTurnID()==Duel.GetTurnCount() 
        and ph~=PHASE_BATTLE and ph~=PHASE_END
end

function s.efilter(e,te)
    return te:GetOwner()~=e:GetHandler()
end

-------------------------------------------------
-- Standby Phase ATK/DEF Gain execution
-------------------------------------------------
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(350)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
        c:RegisterEffect(e1)
        
        local e2=e1:Clone()
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        c:RegisterEffect(e2)
    end
end

-------------------------------------------------
-- Opponent targeting protection value
-------------------------------------------------
function s.indval(e,re,tp)
    return tp~=e:GetHandlerPlayer()
end

-------------------------------------------------
-- Other team monsters filter
-------------------------------------------------
function s.teamtg(e,c)
    return c~=e:GetHandler()
end

-------------------------------------------------
-- Negate S/T Logic
-------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and re:IsActiveType(TYPE_SPELL+TYPE_TRAP) and Duel.IsChainNegatable(ev)
end

function s.setfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and not c:IsType(TYPE_CONTINUOUS+TYPE_FIELD+TYPE_EQUIP+TYPE_QUICKPLAY+TYPE_COUNTER) 
        and not c:IsCode(26074088) and c:IsSSetable()
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    if Duel.NegateActivation(ev) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
        local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then
            Duel.SSet(tp,g)
        end
    end
end

-------------------------------------------------
-- GY Steal Logic
-------------------------------------------------
function s.stealcon(e,tp,eg,ep,ev,re,r,rp)
    local ph=Duel.GetCurrentPhase()
    return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

function s.stealfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end

function s.stealtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(1-tp) and s.stealfilter(chkc) end
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingTarget(s.stealfilter,tp,0,LOCATION_GRAVE,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectTarget(tp,s.stealfilter,tp,0,LOCATION_GRAVE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
end

function s.stealop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
        Duel.SSet(tp,tc)
    end
end

-------------------------------------------------
-- Continuous Destruction Logic (Once Per Turn)
-------------------------------------------------
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    return re:IsActiveType(TYPE_SPELL+TYPE_TRAP) 
        and e:GetHandler():GetFlagEffect(id)==0 
        and Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:GetFlagEffect(id)~=0 then return end
    
    c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
    
    Duel.Hint(HINT_CARD,0,id)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
    if #g>0 then
        Duel.HintSelection(g)
        Duel.Destroy(g,REASON_EFFECT)
    end
end

-------------------------------------------------
-- Banish Protection Filters (Targeted & Non-Targeted)
-------------------------------------------------
function s.banishval(e,re,rp)
    return rp~=e:GetHandlerPlayer() and re:GetCategory()&CATEGORY_REMOVE==CATEGORY_REMOVE
end

function s.banishfilter(e,te)
    return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:GetCategory()&CATEGORY_REMOVE==CATEGORY_REMOVE
end
