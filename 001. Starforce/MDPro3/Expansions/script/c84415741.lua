local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

function s.tgfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x99b)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.tgfilter(chkc) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsPlayerCanSpecialSummonMonster(tp,75457135,0x99b,TYPES_TOKEN,1500,1000,7,RACE_CYBERSE,ATTRIBUTE_WATER)
        and Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    if not Duel.IsPlayerCanSpecialSummonMonster(tp,75457135,0x99b,TYPES_TOKEN,1500,1000,7,RACE_CYBERSE,ATTRIBUTE_WATER) then return end
    
    local token=Duel.CreateToken(tp,75457135)
    if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)==0 then return end
    
    --Unaffected by other cards' effects
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetValue(s.efilter)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    token:RegisterEffect(e1)
    
    --Cannot be destroyed by battle
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e2:SetValue(1)
    e2:SetReset(RESET_EVENT+RESETS_STANDARD)
    token:RegisterEffect(e2)
    
    --Gain ATK if you control Starforce XYZ
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetCondition(s.atkcon)
    e3:SetValue(1000)
    e3:SetReset(RESET_EVENT+RESETS_STANDARD)
    token:RegisterEffect(e3)
    
    --Quick Effect to protect Link/XYZ monsters (HOPT)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetCondition(s.protcon)
    e4:SetCost(s.protcost)
    e4:SetOperation(s.protop)
    e4:SetReset(RESET_EVENT+RESETS_STANDARD)
    token:RegisterEffect(e4)
    
    --Link monsters in EMZ gain 1000 ATK while token is on field
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_UPDATE_ATTACK)
    e5:SetRange(LOCATION_MZONE)
    e5:SetTargetRange(LOCATION_MZONE,0)
    e5:SetTarget(s.atktg)
    e5:SetValue(1000)
    e5:SetReset(RESET_EVENT+RESETS_STANDARD)
    token:RegisterEffect(e5)
end

function s.efilter(e,te)
    return te:GetOwner()~=e:GetOwner()
end

function s.atkcon(e)
    local tp=e:GetHandlerPlayer()
    return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.xyzfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x99b) and c:IsType(TYPE_XYZ)
end

function s.atktg(e,c)
    return c:IsType(TYPE_LINK) and c:GetSequence()>=5
end

function s.protcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and re:IsActiveType(TYPE_MONSTER)
end

function s.protcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

function s.protop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    
    --Unaffected by other cards' effects
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(s.immtg)
    e1:SetValue(s.immval)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
    
    --Cannot be destroyed by battle
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetTarget(s.immtg)
    e2:SetValue(1)
    e2:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e2,tp)
end

function s.immtg(e,c)
    return c:IsFaceup() and ((c:IsType(TYPE_LINK) and c:GetSequence()>=5) 
        or (c:IsSetCard(0x99b) and c:IsType(TYPE_XYZ)))
end

function s.immval(e,te)
    return te:GetOwner()~=e:GetOwner()
end