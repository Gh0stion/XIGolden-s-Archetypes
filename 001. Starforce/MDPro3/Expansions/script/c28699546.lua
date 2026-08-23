local s,id=GetID()
function s.initial_effect(c)
    --Xyz Summon
    c:EnableReviveLimit()
    
    --Must use Starforce Xyz with both Zerker and Saurian attached
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
    
    --1a. Can attack up to 3 monsters
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
    e2:SetValue(2)
    c:RegisterEffect(e2)
    
    --1b. Banish and burn at damage step
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_BATTLE_START)
    e3:SetCost(s.rmcost)
    e3:SetTarget(s.rmtg)
    e3:SetOperation(s.rmop)
    c:RegisterEffect(e3)
    
    --2. Set Spell/Trap and banish (cannot respond)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_REMOVE)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetCost(s.setcost)
    e4:SetTarget(s.settg)
    e4:SetOperation(s.setop)
    c:RegisterEffect(e4)
    
    --3a. Unaffected by opponent's monster effects (Saurian)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetCode(EFFECT_IMMUNE_EFFECT)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCondition(s.saurcon)
    e5:SetValue(s.efilter)
    c:RegisterEffect(e5)
    
    --3b. Cannot be destroyed by Spells/Traps (Zerker)
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e6:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCondition(s.zerkcon)
    e6:SetValue(s.indval)
    c:RegisterEffect(e6)
end

s.listed_series={0x99b}
s.listed_names={26384578,23638502}

--Use Starforce Xyz with both Zerker and Saurian attached
function s.matfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x99b)
        and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,26384578)
        and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,23638502)
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
    else
        return false
    end
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    local tc=g:GetFirst()
    c:SetMaterial(g)
    Duel.Overlay(c,g)
    g:DeleteGroup()
end

--1b. Banish and burn
function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    local g=e:GetHandler():GetOverlayGroup()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVEXYZ)
    local sg=g:Select(tp,1,1,nil)
    Duel.SendtoGrave(sg,REASON_COST)
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local bc=e:GetHandler():GetBattleTarget()
    if chk==0 then return bc and bc:IsAbleToRemove() end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,bc,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    local bc=e:GetHandler():GetBattleTarget()
    if bc and bc:IsRelateToBattle() and Duel.Remove(bc,POS_FACEUP,REASON_EFFECT)~=0 then
        Duel.Damage(1-tp,1000,REASON_EFFECT)
    end
end

--2. Set and banish (cannot respond)
function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    local g=e:GetHandler():GetOverlayGroup()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVEXYZ)
    local sg=g:Select(tp,1,1,nil)
    Duel.SendtoGrave(sg,REASON_COST)
end

function s.setfilter(c)
    return c:IsSetCard(0x99b) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,PLAYER_ALL,LOCATION_ONFIELD)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.setfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 and Duel.SSet(tp,g:GetFirst())~=0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
        local rg=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
        if #rg>0 then
            Duel.HintSelection(rg)
            Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)
        end
        --Cannot respond
        Duel.SetChainLimit(aux.FALSE)
    end
end

--3a. Unaffected by opponent's monster effects (Saurian)
function s.saurcon(e)
    return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,23638502)
end

function s.efilter(e,te)
    return te:IsActiveType(TYPE_MONSTER) and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

--3b. Cannot be destroyed by Spells/Traps (Zerker)
function s.zerkcon(e)
    return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,26384578)
end

function s.indval(e,re,rp)
    return re:IsActiveType(TYPE_SPELL+TYPE_TRAP) and rp~=e:GetHandlerPlayer()
end