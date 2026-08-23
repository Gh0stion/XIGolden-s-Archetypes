local s,id=GetID()
function s.initial_effect(c)
    -- Enable Pendulum
    aux.EnablePendulumAttribute(c)

    -- Pendulum Effect 1: Stellaron monsters gain 400 ATK & DEF
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_PZONE)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x999))
    e1:SetValue(400)
    c:RegisterEffect(e1)

    local e2=e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e2)

    -- Pendulum Effect 2 - Trigger 1: EVENT_MOVE (manual placement / activation)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_MOVE)
    e3:SetRange(LOCATION_PZONE)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.plcon)
    e3:SetTarget(s.pltg)
    e3:SetOperation(s.plop)
    c:RegisterEffect(e3)

    -- Pendulum Effect 2 - Trigger 2: EVENT_SSET (catches Sets by monster effects)
    local e4=e3:Clone()
    e4:SetCode(EVENT_SSET)
    c:RegisterEffect(e4)

    -- Monster Effect: Set 1 "Stellaron" Spell/Trap (unchanged - already working)
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,1))
    e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e6:SetCode(EVENT_SUMMON_SUCCESS)
    e6:SetProperty(EFFECT_FLAG_DELAY)
    e6:SetCountLimit(1,id+100)
    e6:SetTarget(s.settg)
    e6:SetOperation(s.setop)
    c:RegisterEffect(e6)

    local e7=e6:Clone()
    e7:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e7)
end

-- Condition for both triggers
function s.plcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(function(tc)
        return tc:IsControler(tp)
           and (tc:IsLocation(LOCATION_SZONE) or tc:IsLocation(LOCATION_PZONE))
           and not tc:IsPreviousLocation(LOCATION_SZONE)
           and not tc:IsPreviousLocation(LOCATION_PZONE)
    end, 1, nil)
end

function s.plspfilter(c,e,tp)
    return c:IsSetCard(0x999) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.plthfilter(c)
    return c:IsSetCard(0x999) and c:IsAbleToHand()
end

function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and (Duel.IsExistingMatchingCard(s.plspfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
                or Duel.IsExistingMatchingCard(s.plthfilter,tp,LOCATION_DECK,0,1,nil))
    end
end

function s.plop(e,tp,eg,ep,ev,re,r,rp)
    local b1 = Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
        and Duel.IsExistingMatchingCard(s.plspfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
    local b2 = Duel.IsExistingMatchingCard(s.plthfilter,tp,LOCATION_DECK,0,1,nil)

    if not (b1 or b2) then return end

    local opt = {}
    if b1 then table.insert(opt, aux.Stringid(id,2)) end  -- Special Summon
    if b2 then table.insert(opt, aux.Stringid(id,3)) end  -- Add to hand

    local choice = Duel.SelectOption(tp, table.unpack(opt))

    if (b1 and choice == 0) or (not b1 and b2) then
        -- Special Summon
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g = Duel.SelectMatchingCard(tp,s.plspfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
        if #g > 0 then
            Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
        end
    else
        -- Add to hand
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g = Duel.SelectMatchingCard(tp,s.plthfilter,tp,LOCATION_DECK,0,1,1,nil)
        if #g > 0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end
end

-- Monster Set Effect (unchanged)
function s.setfilter(c)
    return c:IsSetCard(0x999) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE) > 0
            and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
    end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE) <= 0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g = Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g > 0 then
        Duel.SSet(tp,g:GetFirst())
        Duel.BreakEffect()
    end
end