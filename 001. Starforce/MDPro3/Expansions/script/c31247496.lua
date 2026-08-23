local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    c:RegisterEffect(e1)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) end
    if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_MZONE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
    Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND)
    Duel.SetPossibleOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end

function s.sffilter(c)
    return c:IsFaceup() and c:IsSetCard(0x99b) and c:IsType(TYPE_LINK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) then return end
    
    local atk=tc:GetAttack()
    if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_REMOVED) then
        --Check if you control a Starforce Link
        if Duel.IsExistingMatchingCard(s.sffilter,tp,LOCATION_MZONE,0,1,nil) then
            local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
            if #g>0 then
                local sg=g:RandomSelect(tp,1)
                Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
            end
        end
        
        --Check if opponent has no monsters
        if Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)==0 then
            Duel.Damage(1-tp,atk,REASON_EFFECT)
        end
    end
end