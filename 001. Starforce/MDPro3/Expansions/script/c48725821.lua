local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_CHAINING)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    --Protect "Starforce" cards while in GY
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetTargetRange(LOCATION_ONFIELD,0)
    e2:SetTarget(s.indtg)
    e2:SetValue(aux.indoval)
    c:RegisterEffect(e2)
end

-- Check if opponent activated a monster effect
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and re:IsActiveType(TYPE_MONSTER)
end

function s.filter(c)
    return c:IsFaceup() and c:IsType(TYPE_EFFECT)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    e:SetLabel(100) -- Flag to indicate cost is being checked
    if chk==0 then return true end
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local dg=Duel.GetMatchingGroup(s.filter,tp,0,LOCATION_MZONE,nil)
    if chk==0 then
        if e:GetLabel()~=100 then return false end
        e:SetLabel(0)
        return Duel.IsExistingMatchingCard(Card.IsAbleToGraveAsCost,tp,LOCATION_ONFIELD+LOCATION_HAND,0,1,e:GetHandler()) and #dg>0
    end
    
    -- Select 1 to #dg (number of enemy monsters) cards to send to GY
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local cg=Duel.SelectMatchingCard(tp,Card.IsAbleToGraveAsCost,tp,LOCATION_ONFIELD+LOCATION_HAND,0,1,#dg,e:GetHandler())
    local tc=cg:GetFirst()
    local ctype=0
    while tc do
        -- Bitwise OR the types of cards sent
        for _,type in ipairs({TYPE_MONSTER,TYPE_SPELL,TYPE_TRAP}) do
            if tc:GetOriginalType()&type~=0 then
                ctype=ctype|type
            end
        end
        tc=cg:GetNext()
    end
    
    -- Set the count for the operation phase
    e:SetLabel(#cg)
    Duel.SendtoGrave(cg,REASON_COST)
    
    -- Apply the Chain Limit (The Droplet Effect)
    if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
        Duel.SetChainLimit(s.chlimit(ctype))
    end
    
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,dg,#cg,0,0)
end

-- Chain limit function: checks if the card being activated matches the types sent
function s.chlimit(ctype)
    return function(e,ep,tp)
        return tp==ep or e:GetHandler():GetOriginalType()&ctype==0
    end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local count=e:GetLabel()
    local g=Duel.GetMatchingGroup(s.filter,tp,0,LOCATION_MZONE,nil)
    
    if #g>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPERATECARD)
        local sg=g:Select(tp,count,count,nil) -- Must select exactly the number of cards sent
        Duel.HintSelection(sg)
        
        local c=e:GetHandler()
        for tc in aux.Next(sg) do
            local atk=tc:GetAttack()
            -- Halve ATK
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_SET_ATTACK_FINAL)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            e1:SetValue(math.ceil(atk/2))
            tc:RegisterEffect(e1)
            
            -- Negate
            Duel.NegateRelatedChain(tc,RESET_TURN_SET)
            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_DISABLE)
            e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e2)
            local e3=Effect.CreateEffect(c)
            e3:SetType(EFFECT_TYPE_SINGLE)
            e3:SetCode(EFFECT_DISABLE_EFFECT)
            e3:SetValue(RESET_TURN_SET)
            e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e3)
        end
    end
end

function s.indtg(e,c)
    return c:IsFaceup() and c:IsSetCard(0x99b) and c:IsType(TYPE_CONTINUOUS) and (c:IsSpell() or c:IsTrap())
end
