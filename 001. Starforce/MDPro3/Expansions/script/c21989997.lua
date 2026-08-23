local s,id=GetID()
function s.initial_effect(c)
    -- Xyz Summon (Transfer Fix Included)
    c:EnableReviveLimit()
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    e1:SetValue(SUMMON_TYPE_XYZ)
    c:RegisterEffect(e1)
    
    -- 1a. Cannot respond to Starforce cards
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_INACTIVATE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(s.chainlm)
    c:RegisterEffect(e2)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_CANNOT_DISEFFECT)
    e3:SetRange(LOCATION_MZONE)
    e3:SetValue(s.chainlm)
    c:RegisterEffect(e3)
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE)
    e4:SetOperation(s.chainop)
    c:RegisterEffect(e4)
    
    -- 1b. Direct attack (First attack only)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_DIRECT_ATTACK)
    e5:SetCondition(s.dircon)
    c:RegisterEffect(e5)
    
    -- 1c. Double Attack
    local e7=Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_SINGLE)
    e7:SetCode(EFFECT_EXTRA_ATTACK)
    e7:SetValue(1)
    c:RegisterEffect(e7)
    
    -- 2. Set Spell/Trap and banish
    local e8=Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id,0))
    e8:SetCategory(CATEGORY_REMOVE)
    e8:SetType(EFFECT_TYPE_QUICK_O)
    e8:SetCode(EVENT_FREE_CHAIN)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCountLimit(1)
    e8:SetTarget(s.settg2)
    e8:SetOperation(s.setop2)
    c:RegisterEffect(e8)
    
    -- 3. Negate attack/effect when THIS CARD is targeted
    -- Changed to SINGLE + TRIGGER to ensure it only reacts to itself
    local e9=Effect.CreateEffect(c)
    e9:SetDescription(aux.Stringid(id,1))
    e9:SetCategory(CATEGORY_NEGATE+CATEGORY_POSITION)
    e9:SetType(EFFECT_TYPE_QUICK_O)
    e9:SetCode(EVENT_BE_BATTLE_TARGET)
    e9:SetRange(LOCATION_MZONE)
    e9:SetCost(s.negcost)
    e9:SetCondition(s.negcon_battle) -- Check if this card is the target
    e9:SetOperation(s.negop)
    c:RegisterEffect(e9)
    
    local e10=Effect.CreateEffect(c)
    e10:SetDescription(aux.Stringid(id,1))
    e10:SetCategory(CATEGORY_NEGATE+CATEGORY_POSITION)
    e10:SetType(EFFECT_TYPE_QUICK_O)
    e10:SetCode(EVENT_BECOME_TARGET)
    e10:SetRange(LOCATION_MZONE)
    e10:SetCost(s.negcost)
    e10:SetCondition(s.negcon_effect) -- Check if this card is the target
    e10:SetOperation(s.negop)
    c:RegisterEffect(e10)
end

s.listed_series={0x99b,0x100b}
s.listed_names={53515038,26384578}

-- Summoning Logic (Transfer Fix)
function s.matfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x99b)
        and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,53515038)
        and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,26384578)
end
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
        and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
    local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
    local sg=g:SelectSubGroup(tp,aux.TRUE,false,1,1)
    if sg then
        sg:KeepAlive()
        e:SetLabelObject(sg)
        return true
    else return false end
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    local tc=g:GetFirst()
    -- Transfer old materials
    local mg=tc:GetOverlayGroup()
    if #mg>0 then Duel.Overlay(c,mg) end
    c:SetMaterial(g)
    Duel.Overlay(c,g)
    g:DeleteGroup()
end

-- Anti-Response Logic
function s.chainlm(e,ct)
    local p=e:GetHandlerPlayer()
    local te,tp=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
    local tc=te:GetHandler()
    return p~=tp and tc:IsSetCard(0x99b)
end
function s.chainop(e,tp,eg,ep,ev,re,r,rp)
    if re:GetHandler():IsSetCard(0x99b) and ep==tp then
        Duel.SetChainLimit(s.chlimit)
    end
end
function s.chlimit(e,rp,tp)
    return tp==rp
end

-- Direct Attack
function s.dircon(e)
    return e:GetHandler():GetBattledGroupCount()==0
end

-- Set & Banish
function s.setfilter(c)
    return (c:IsSetCard(0x99b) or (c:IsSetCard(0x100b) and c:IsType(TYPE_CONTINUOUS))) 
        and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end
function s.settg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
end
function s.setop2(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.setfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 and Duel.SSet(tp,g:GetFirst())~=0 then
        if Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
            and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
            local rg=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
            if #rg>0 then
                Duel.HintSelection(rg)
                Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)
            end
        end
    end
end

-- NEGATE LOGIC FIXES
-- Ensure battle target is THIS card
function s.negcon_battle(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetAttackTarget()==e:GetHandler()
end

-- Ensure effect target is THIS card
function s.negcon_effect(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and eg:IsContains(e:GetHandler())
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
    local pos=c:IsAttackPos() and POS_FACEUP_DEFENSE or POS_FACEUP_ATTACK
    if Duel.ChangePosition(c,pos)~=0 then
        -- Negate attack (if battle) or effect (if chaining)
        if Duel.GetCurrentChain()==0 then
            Duel.NegateAttack()
        else
            Duel.NegateEffect(ev)
        end
        
        -- Optional Book of Moon on opponent
        local g=Duel.GetMatchingGroup(Card.IsCanTurnSet,tp,0,LOCATION_MZONE,nil)
        if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEDOWN)
            local sg=g:Select(tp,1,1,nil)
            local tc=sg:GetFirst()
            if tc and Duel.ChangePosition(tc,POS_FACEDOWN_DEFENSE)~=0 then
                local e1=Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                tc:RegisterEffect(e1)
            end
        end
    end
end
