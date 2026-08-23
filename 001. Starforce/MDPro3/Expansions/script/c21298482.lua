local s,id=GetID()
function s.initial_effect(c)
    -- Link Summon: 1 "Starforce" Monster
    c:EnableReviveLimit()
    aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x99b),1,1)
    
    -- 1a. Gain 500 ATK while co-linked
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetCondition(s.mutuallinkcon)
    e1:SetValue(500)
    c:RegisterEffect(e1)
    
    -- 1b. Cannot be destroyed while co-linked
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.mutuallinkcon)
    e2:SetValue(aux.indoval)
    c:RegisterEffect(e2)
    
    -- 1c. Negate Spell/Trap when co-linked
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_NEGATE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.negcon)
    e3:SetCost(s.negcost)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    e3:SetCountLimit(1,id)
    c:RegisterEffect(e3)
    
    -- 2a. Gain 1500 ATK if opponent controls 3+ monsters
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_UPDATE_ATTACK)
    e4:SetCondition(s.swarmcon)
    e4:SetValue(1500)
    c:RegisterEffect(e4)
    
    -- 2b. Cannot be banished/targeted if opponent controls 3+ monsters
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetCode(EFFECT_CANNOT_REMOVE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCondition(s.swarmcon)
    c:RegisterEffect(e5)

    local e5b=Effect.CreateEffect(c)
    e5b:SetType(EFFECT_TYPE_SINGLE)
    e5b:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5b:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e5b:SetRange(LOCATION_MZONE)
    e5b:SetCondition(s.swarmcon)
    e5b:SetValue(aux.tgoval)
    c:RegisterEffect(e5b)
    
    -- 3. Banish Tribe On to search Finalize
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,1))
    e6:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e6:SetType(EFFECT_TYPE_IGNITION)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCountLimit(1)
    e6:SetCost(s.thcost)
    e6:SetTarget(s.thtg)
    e6:SetOperation(s.thop)
    c:RegisterEffect(e6)

    -- 4. Evolution: Last Man Standing (Quick Effect)
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,2))
    e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e7:SetType(EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_FREE_CHAIN)
    e7:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCondition(s.evocon)
    e7:SetCost(s.evocost)
    e7:SetTarget(s.evotg)
    e7:SetOperation(s.evoop)
    c:RegisterEffect(e7)
end

s.black_ace=97626301

-- Logic: Condition
function s.evocon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==1
end

-- Logic: Cost (Tribute)
function s.evocost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsReleasable() end
    Duel.Release(e:GetHandler(),REASON_COST)
end

function s.evotg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_EXTRA,0,1,nil,s.black_ace) 
        and Duel.GetLocationCountFromEx(tp)>0 end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- Logic: Operation (The Step-by-Step Fix)
function s.evoop(e,tp,eg,ep,ev,re,r,rp)
    local sc=Duel.GetFirstMatchingCard(Card.IsCode,tp,LOCATION_EXTRA,0,nil,s.black_ace)
    if sc then
        local zone=Duel.GetLocationCountFromEx(tp,tp,nil,sc)
        -- SpecialSummonStep allows us to set flags BEFORE the summon finishes
        if Duel.SpecialSummonStep(sc,SUMMON_TYPE_LINK,tp,tp,true,false,POS_FACEUP,zone) then
            -- 1. Tell the engine it was Link Summoned properly
            sc:SetSummonType(SUMMON_TYPE_LINK)
            -- 2. Flip the "Properly Summoned" flag so it isn't game-ruled to GY
            sc:SetStatus(STATUS_PROC_COMPLETE,true)
            -- 3. Finalize the placement on field
            Duel.SpecialSummonComplete()
        end
    end
end

-- Shared Conditions & Logic
function s.mutuallinkcon(e)
    return e:GetHandler():GetMutualLinkedGroupCount()>0
end
function s.swarmcon(e)
    return Duel.GetFieldGroupCount(e:GetHandlerPlayer(),0,LOCATION_MZONE)>=3
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and re:IsActiveType(TYPE_SPELL+TYPE_TRAP) and s.mutuallinkcon(e) and Duel.IsChainNegatable(ev)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.NegateActivation(ev)
end
function s.costfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x100b) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS) and c:IsAbleToRemoveAsCost()
end
function s.thfilter(c)
    return c:IsCode(93501094) and c:IsAbleToHand()
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_ONFIELD,0,1,nil) end
    local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
     Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end
