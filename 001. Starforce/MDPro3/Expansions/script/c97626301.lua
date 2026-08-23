local s,id=GetID()
function s.initial_effect(c)
    --Link Summon
    c:EnableReviveLimit()
    aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsCode,21298482),1,1)
    
    --1. Send to GY if don't control Finalize and Meteor Server
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCondition(s.descon)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)
    
    --2. Remove 5 Wedge Counters to negate (ONCE PER TURN)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_NEGATE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetCondition(s.negcon)
    e2:SetCost(s.negcost)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)
    
    --3a. Unaffected by Spell/Trap when opponent has more monsters
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetCode(EFFECT_IMMUNE_EFFECT)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.immcon1)
    e3:SetValue(s.efilter)
    c:RegisterEffect(e3)
    
    --3b. Cannot be banished/destroyed when opponent has less monsters
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.immcon2)
    e4:SetValue(1)
    c:RegisterEffect(e4)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetCode(EFFECT_CANNOT_REMOVE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCondition(s.immcon2)
    c:RegisterEffect(e5)
    
    --4a. Opponent must attack this card
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD)
    e6:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
    e6:SetRange(LOCATION_MZONE)
    e6:SetTargetRange(0,LOCATION_MZONE)
    e6:SetValue(s.atlimit)
    c:RegisterEffect(e6)
    
    --4b. Gain ATK when targeted for attack
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,1))
    e7:SetCategory(CATEGORY_ATKCHANGE)
    e7:SetType(EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_BE_BATTLE_TARGET)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(1)
    e7:SetCost(s.atkcost)
    e7:SetOperation(s.atkop)
    c:RegisterEffect(e7)
end

s.listed_names={21298482,93501094,17715087}

--1. Send to GY if don't control Finalize (Continuous Spell) and Meteor Server (Continuous Trap)
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    return not (Duel.IsExistingMatchingCard(s.finalizefilter,tp,LOCATION_SZONE,0,1,nil)
        and Duel.IsExistingMatchingCard(s.meteorfilter,tp,LOCATION_SZONE,0,1,nil))
end

function s.finalizefilter(c)
    return c:IsFaceup() and c:IsCode(93501094) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS)
end

function s.meteorfilter(c)
    return c:IsFaceup() and c:IsCode(17715087) and c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    Duel.SendtoGrave(e:GetHandler(),REASON_EFFECT)
end

--2. Negate activation (HOPT, COST)
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and (re:IsActiveType(TYPE_MONSTER) or re:IsActiveType(TYPE_SPELL+TYPE_TRAP))
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0x1002)>=5 end
    Duel.RemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0x1002,5,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.NegateActivation(ev)
end

--3a. Unaffected by Spell/Trap when opponent has more
function s.immcon1(e)
    local tp=e:GetHandlerPlayer()
    return Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)
end

function s.efilter(e,te)
    return te:IsActiveType(TYPE_SPELL+TYPE_TRAP) and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

--3b. Cannot be banished/destroyed when opponent has less
function s.immcon2(e)
    local tp=e:GetHandlerPlayer()
    return Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)<Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)
end

--4a. Must attack this card
function s.atlimit(e,c)
    return c~=e:GetHandler()
end

--4b. Gain ATK when attacked (HOPT, COST)
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0x1002)>=5 end
    Duel.RemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0x1002,5,REASON_COST)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local bc=c:GetBattleTarget()
    if c:IsRelateToEffect(e) and c:IsFaceup() and bc and bc:IsFaceup() then
        local atk=bc:GetAttack()
        if atk<0 then atk=0 end
        --Gain ATK
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(atk)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
        c:RegisterEffect(e1)
        --No battle damage
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_FIELD)
        e2:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
        e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e2:SetTargetRange(0,1)
        e2:SetReset(RESET_PHASE+PHASE_DAMAGE)
        Duel.RegisterEffect(e2,tp)
    end
end