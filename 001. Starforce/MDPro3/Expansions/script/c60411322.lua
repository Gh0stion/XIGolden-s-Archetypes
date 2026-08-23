local s,id=GetID()
function s.initial_effect(c)
    --Link Summon
    c:EnableReviveLimit()
    
    --Standard: 1 Geo Stelar + 1 Starforce monster (not another Geo)
    aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x99b),2,2,s.lcheck)
    
    --Alternative: 1 Geo Stelar counts as 2 materials
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_EXTRA_LINK_MATERIAL)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetValue(s.matval)
    c:RegisterEffect(e1)
    
    --1. Send to GY if don't control Finalize and Meteor Server
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetCondition(s.descon)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
    
    --2. When Special Summoned: Place 10 counters, banish monsters, summon tokens
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_COUNTER+CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetTarget(s.sumtg)
    e3:SetOperation(s.sumop)
    c:RegisterEffect(e3)
    
    --3. Cannot summon except Rouge Sentinel tokens
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTargetRange(1,0)
    e4:SetTarget(s.sumlimit)
    c:RegisterEffect(e4)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_CANNOT_SUMMON)
    e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e5:SetRange(LOCATION_MZONE)
    e5:SetTargetRange(1,0)
    c:RegisterEffect(e5)
    
    --4. Gain 150 ATK per Wedge Counter on field
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_UPDATE_ATTACK)
    e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetValue(s.atkval)
    c:RegisterEffect(e6)
    
    --5. Gain ATK when targeted for attack
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
    
    --6. Negate banish/destroy/negate effects
    local e8=Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id,2))
    e8:SetCategory(CATEGORY_NEGATE)
    e8:SetType(EFFECT_TYPE_QUICK_O)
    e8:SetCode(EVENT_CHAINING)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCondition(s.negcon)
    e8:SetCost(s.negcost)
    e8:SetTarget(s.negtg)
    e8:SetOperation(s.negop)
    c:RegisterEffect(e8)
end

s.listed_series={0x99b}
s.listed_names={59999377,93501094,17715087,64485278,64485279}

--Check that exactly 1 Geo Stelar is used
function s.lcheck(g,lc,sumtype,tp)
    return g:FilterCount(Card.IsCode,nil,59999377)==1
end

--Geo Stelar can count as 2 materials
function s.matval(e,lc,mg,c,tp)
    if not lc or lc~=e:GetHandler() then return false,nil end
    return c:IsCode(59999377,lc,SUMMON_TYPE_LINK,tp),c:IsCode(59999377,lc,SUMMON_TYPE_LINK,tp)
end

--1. Send to GY if don't control Finalize and Meteor Server
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

--2. Place counters, banish monsters, summon tokens
function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_COUNTER,nil,10,0,0x1002)
    local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,LOCATION_MZONE,0,e:GetHandler())
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,0)
end

function s.sumop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        --Place 10 Wedge Counters
        c:AddCounter(0x1002,10)
        
        --Banish all other monsters
        local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,LOCATION_MZONE,0,c)
        if #g>0 then
            Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
        end
        
        --Summon 2 Rouge Sentinel tokens
        if Duel.GetLocationCount(tp,LOCATION_MZONE)>=2 
            and Duel.IsPlayerCanSpecialSummonMonster(tp,64485278,0,TYPES_TOKEN,0,0,12,RACE_CYBERSE,ATTRIBUTE_DARK)
            and Duel.IsPlayerCanSpecialSummonMonster(tp,64485279,0,TYPES_TOKEN,0,0,12,RACE_CYBERSE,ATTRIBUTE_DARK) then
            
            local zone=c:GetLinkedZone(tp)
            local token1=Duel.CreateToken(tp,64485278)
            local token2=Duel.CreateToken(tp,64485279)
            
            if zone~=0 then
                Duel.SpecialSummonStep(token1,0,tp,tp,false,false,POS_FACEUP,zone)
                zone=zone&(~(1<<(token1:GetSequence())))
                if zone~=0 then
                    Duel.SpecialSummonStep(token2,0,tp,tp,false,false,POS_FACEUP,zone)
                end
                Duel.SpecialSummonComplete()
            end
        end
    end
end

--3. Cannot summon except Rouge Sentinel tokens
function s.sumlimit(e,c,sump,sumtype,sumpos,targetp)
    return not (c:IsCode(64485278) or c:IsCode(64485279))
end

--4. Gain 150 ATK per Wedge Counter
function s.atkval(e,c)
    local ct=Duel.GetCounter(e:GetHandlerPlayer(),LOCATION_ONFIELD,LOCATION_ONFIELD,0x1002)
    return ct*150
end

--5. Gain ATK when attacked (remove 2 Noise counters)
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0x1002)>=2 end
    Duel.RemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0x1002,2,REASON_COST)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local bc=c:GetBattleTarget()
    if c:IsRelateToEffect(e) and c:IsFaceup() and bc and bc:IsFaceup() then
        local atk=bc:GetAttack()
        if atk<0 then atk=0 end
        --Gain double ATK
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(atk*2)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        c:RegisterEffect(e1)
        --No battle damage
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_FIELD)
        e2:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
        e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e2:SetTargetRange(1,1)
        e2:SetReset(RESET_PHASE+PHASE_DAMAGE)
        Duel.RegisterEffect(e2,tp)
    end
end

--6. Negate banish/destroy/negate effects
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    if rp==tp then return false end
    local ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_REMOVE)
    local ex2,tg2,tc2=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
    local ex3,tg3,tc3=Duel.GetOperationInfo(ev,CATEGORY_DISABLE)
    return (ex and tg~=nil) or (ex2 and tg2~=nil) or (ex3 and tg3~=nil)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0x1091)>=5 end
    Duel.RemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0x1091,5,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
        local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then
            Duel.SSet(tp,g:GetFirst())
        end
    end
end

function s.setfilter(c)
    return c:IsSetCard(0x99b) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end