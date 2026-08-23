local s,id=GetID()
function s.initial_effect(c)
    -- Link Summon Procedure: 1 "Starforce" Monster
    c:EnableReviveLimit()
    aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x99b),1,1)
    
    -- 1a. Gain 500 ATK while co-linked
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetCondition(s.mutuallinkcon)
    e1:SetValue(500)
    c:RegisterEffect(e1)
    
    -- 1b. Cannot be banished OR targeted while co-linked (The Fix)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_CANNOT_REMOVE) -- Cannot be banished
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.mutuallinkcon)
    c:RegisterEffect(e2)
    
    local e2b=Effect.CreateEffect(c)
    e2b:SetType(EFFECT_TYPE_SINGLE)
    e2b:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2b:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET) -- Cannot be targeted (Stops Karma Cut activation)
    e2b:SetRange(LOCATION_MZONE)
    e2b:SetCondition(s.mutuallinkcon)
    e2b:SetValue(aux.tgoval)
    c:RegisterEffect(e2b)
    
    -- 1c. Negate monster effect when co-linked
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
    
    -- 2b. Cannot be destroyed if opponent controls 3+ monsters
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCondition(s.swarmcon)
    e5:SetValue(aux.indoval)
    c:RegisterEffect(e5)
    
    -- 3. Send Starforce S/T to GY to search Meteor Server
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,1))
    e6:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e6:SetType(EFFECT_TYPE_IGNITION)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCountLimit(1)
    e6:SetTarget(s.thtg)
    e6:SetOperation(s.thop)
    c:RegisterEffect(e6)
end

s.listed_series={0x99b}
s.listed_names={17715087} -- Meteor Server ID

-- Condition: Is this card Co-Linked?
function s.mutuallinkcon(e)
    return e:GetHandler():GetMutualLinkedGroupCount()>0
end

-- Condition: Does opponent have 3+ monsters?
function s.swarmcon(e)
    return Duel.GetFieldGroupCount(e:GetHandlerPlayer(),0,LOCATION_MZONE)>=3
end

-- Negation Logic
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and re:IsActiveType(TYPE_MONSTER) and s.mutuallinkcon(e) and Duel.IsChainNegatable(ev)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemoveAsCost,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemoveAsCost,tp,LOCATION_GRAVE,0,1,1,nil)
    Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.NegateActivation(ev)
end

-- Search Logic
function s.costfilter(c)
    return c:IsSetCard(0x99b) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToGrave()
end

function s.thfilter(c)
    return c:IsCode(17715087) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_DECK,0,1,nil)
           and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) 
    end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g1=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g1>0 and Duel.SendtoGrave(g1,REASON_EFFECT)~=0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g2=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
        if #g2>0 then
            Duel.SendtoHand(g2,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g2)
        end
    end
end
