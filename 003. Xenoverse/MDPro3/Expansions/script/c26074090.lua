local s,id=GetID()
function s.initial_effect(c)

    -------------------------------------------------
    -- Standard Activation + Hand Activation
    -------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)

    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
    e2:SetCondition(s.handcon)
    c:RegisterEffect(e2)

    -------------------------------------------------
    -- NATIVE NAME CHANGE: Becomes 26074091 on Field/GY
    -------------------------------------------------
    aux.EnableChangeCode(c,26074091,LOCATION_MZONE+LOCATION_GRAVE)

    -------------------------------------------------
    -- IGNITION: Place from Deck to S/T Zone
    -------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_DECK)
    e3:SetCondition(s.deckigncon)
    e3:SetTarget(s.deckigntg)
    e3:SetOperation(s.deckignop)
    c:RegisterEffect(e3)

    -------------------------------------------------
    -- Xenoverse monsters cannot be banished
    -------------------------------------------------
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_CANNOT_REMOVE)
    e4:SetRange(LOCATION_SZONE)
    e4:SetTargetRange(LOCATION_MZONE,0)
    e4:SetTarget(s.banishfilter)
    c:RegisterEffect(e4)

    -------------------------------------------------
    -- Quick Effect Trap Monster summon
    -------------------------------------------------
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_FREE_CHAIN)
    e5:SetRange(LOCATION_SZONE)
    e5:SetCountLimit(1)
    e5:SetCondition(s.spcon)
    e5:SetTarget(s.sptg)
    e5:SetOperation(s.spop)
    c:RegisterEffect(e5)

    -------------------------------------------------
    -- Search/Place on Special Summon
    -------------------------------------------------
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,2))
    e6:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e6:SetCode(EVENT_SPSUMMON_SUCCESS)
    e6:SetProperty(EFFECT_FLAG_DELAY)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCondition(s.thcon)
    e6:SetTarget(s.thtg)
    e6:SetOperation(s.thop)
    c:RegisterEffect(e6)

    -------------------------------------------------
    -- Quick Effect Shuffle / Boost
    -------------------------------------------------
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,3))
    e7:SetCategory(CATEGORY_TODECK+CATEGORY_ATKCHANGE)
    e7:SetType(EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_FREE_CHAIN)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(1)
    e7:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e7:SetCondition(s.shufcon)
    e7:SetCost(s.shufcost)
    e7:SetTarget(s.shuftg)
    e7:SetOperation(s.shufop)
    c:RegisterEffect(e7)

    -------------------------------------------------
    -- Reveal Spell/Trap to excavate 10 and mill 3 Spells/Traps
    -------------------------------------------------
    local e8=Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id,4))
    e8:SetCategory(CATEGORY_TOGRAVE)
    e8:SetType(EFFECT_TYPE_IGNITION)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCountLimit(1)
    e8:SetCost(s.millcost)
    e8:SetTarget(s.milltg)
    e8:SetOperation(s.millop)
    c:RegisterEffect(e8)

    -------------------------------------------------
    -- ATK/DEF gain (Does not stack)
    -------------------------------------------------
    local e9=Effect.CreateEffect(c)
    e9:SetType(EFFECT_TYPE_SINGLE)
    e9:SetCode(EFFECT_UPDATE_ATTACK)
    e9:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e9:SetRange(LOCATION_MZONE)
    e9:SetValue(s.atkval)
    c:RegisterEffect(e9)

    local e10=e9:Clone()
    e10:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e10)

    -------------------------------------------------
    -- Piercing
    -------------------------------------------------
    local e11=Effect.CreateEffect(c)
    e11:SetType(EFFECT_TYPE_SINGLE)
    e11:SetCode(EFFECT_PIERCE)
    e11:SetRange(LOCATION_MZONE)
    e11:SetCondition(s.piercecon)
    c:RegisterEffect(e11)

    -------------------------------------------------
    -- Opponent monsters lose DEF
    -------------------------------------------------
    local e12=Effect.CreateEffect(c)
    e12:SetType(EFFECT_TYPE_FIELD)
    e12:SetCode(EFFECT_UPDATE_DEFENSE)
    e12:SetRange(LOCATION_MZONE)
    e12:SetTargetRange(0,LOCATION_MZONE)
    e12:SetCondition(s.deflosscon)
    e12:SetValue(-1000)
    c:RegisterEffect(e12)

end

-------------------------------------------------
-- Archetype helper
-------------------------------------------------
function s.is_dbxv2(c)
    return c:IsSetCard(0x1990)
end

-------------------------------------------------
-- Hand activation
-------------------------------------------------
function s.handfilter(c)
    return s.is_dbxv2(c) and (c:IsType(TYPE_MONSTER) or (c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS)))
end

function s.handcon(e)
    local tp=e:GetHandlerPlayer()
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 
        or Duel.IsExistingMatchingCard(s.handfilter,tp,LOCATION_ONFIELD,0,1,nil)
end

-------------------------------------------------
-- Deck ignition
-------------------------------------------------
function s.deckigncon(e,tp,eg,ep,ev,re,r,rp)
    local ph=Duel.GetCurrentPhase()
    return Duel.GetTurnPlayer()==tp and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2) 
        and Duel.IsExistingMatchingCard(s.handfilter,tp,LOCATION_ONFIELD,0,1,nil)
end

function s.deckigntg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
end

function s.deckignop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
        Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
    end
end

-------------------------------------------------
-- Cannot banish
-------------------------------------------------
function s.banishfilter(e,c)
    return s.is_dbxv2(c)
end

-------------------------------------------------
-- Trap monster summon
-------------------------------------------------
function s.spconfilter(c)
    return c:IsFaceup() and s.is_dbxv2(c) and (c:IsType(TYPE_MONSTER) or (c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS)))
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local ph=Duel.GetCurrentPhase()
    local phase_check=(ph==PHASE_MAIN1 or ph==PHASE_MAIN2 or (ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE))
    return phase_check and Duel.IsExistingMatchingCard(s.spconfilter,tp,LOCATION_ONFIELD,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsPlayerCanSpecialSummonMonster(
            tp,id,0,
            TYPE_EFFECT+TYPE_TRAP+TYPE_MONSTER,
            2500,2500,8,
            RACE_WARRIOR,
            ATTRIBUTE_DARK
        ) 
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.IsPlayerCanSpecialSummonMonster(
        tp,id,0,
        TYPE_EFFECT+TYPE_TRAP+TYPE_MONSTER,
        2500,2500,8,
        RACE_WARRIOR,
        ATTRIBUTE_DARK
    ) then
        c:AddMonsterAttribute(
            TYPE_EFFECT+TYPE_TRAP+TYPE_MONSTER,
            ATTRIBUTE_DARK,
            RACE_WARRIOR,
            8,
            2500,
            2500
        )
        if Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP_ATTACK)~=0 then
            c:AddMonsterAttributeComplete()
        end
    end
end

-------------------------------------------------
-- Search/Place effect
-------------------------------------------------
function s.thhandfilter(c)
    return s.is_dbxv2(c)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return not Duel.IsExistingMatchingCard(
        s.thhandfilter,tp,LOCATION_HAND,0,1,nil)
end

function s.thfilter(c)
    return c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS) and s.is_dbxv2(c) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(
        s.thfilter,tp,LOCATION_DECK,0,1,nil) 
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(
        tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    local tc=g:GetFirst()
    if tc then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,tc)
    end
end

-------------------------------------------------
-- Shuffle / ATK boost
-------------------------------------------------
function s.shufcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()==1-tp
end

function s.shufcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(
        Card.IsAbleToGrave,tp,LOCATION_EXTRA,0,1,nil) 
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(
        tp,Card.IsAbleToGrave,tp,LOCATION_EXTRA,0,1,1,nil)
    Duel.SendtoGrave(g,REASON_COST)
end

function s.shuftg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(
        Card.IsAbleToDeck,tp,0,LOCATION_MZONE,1,nil) 
    end
    Duel.SetOperationInfo(
        0,CATEGORY_TODECK,nil,1,1-tp,LOCATION_MZONE)
end

function s.shufop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(
        tp,Card.IsAbleToDeck,tp,0,LOCATION_MZONE,1,1,nil)
    if #g>0 then
        Duel.HintSelection(g)
        if Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 then
            if c:IsFaceup() and c:IsRelateToEffect(e) then
                local e1=Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_UPDATE_ATTACK)
                e1:SetValue(500)
                if Duel.GetTurnPlayer()==tp then
                    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
                else
                    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,1)
                end
                c:RegisterEffect(e1)
            end
        end
    end
end

-------------------------------------------------
-- Reveal S/T -> Excavate 10 -> Mill exactly 3 if threshold met
-------------------------------------------------
function s.millcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(
        Card.IsType,tp,LOCATION_HAND,0,1,nil, TYPE_SPELL+TYPE_TRAP) 
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g=Duel.SelectMatchingCard(
        tp,Card.IsType,tp,LOCATION_HAND,0,1,1,nil, TYPE_SPELL+TYPE_TRAP)
    Duel.ConfirmCards(1-tp,g)
    Duel.ShuffleHand(tp)
end

function s.milltg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>=10 end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,0,1-tp,LOCATION_DECK)
end

function s.millop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)<10 then return end
    
    Duel.ConfirmDecktop(1-tp,10)
    local g=Duel.GetDecktopGroup(1-tp,10)
    local st_g=g:Filter(Card.IsType,nil,TYPE_SPELL+TYPE_TRAP)
    
    if #st_g>=3 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        local sg=st_g:Select(tp,3,3,nil)
        if #sg==3 then
            Duel.SendtoGrave(sg,REASON_EFFECT)
        end
    end
    
    Duel.MoveTurnCountGroup(g) 
end

-------------------------------------------------
-- Count helpers
-------------------------------------------------
function s.dbxv2filter(c)
    return c:IsFaceup() and s.is_dbxv2(c)
end

function s.count_dbxv2(tp)
    return Duel.GetMatchingGroupCount(
        s.dbxv2filter,tp,LOCATION_ONFIELD,0,nil)
end

-------------------------------------------------
-- ATK/DEF gain (Flat static bonus, does not stack)
-------------------------------------------------
function s.atkval(e,c)
    local n=s.count_dbxv2(c:GetControler())
    if n>=1 then 
        return 300 
    end
    return 0
end

-------------------------------------------------
-- Piercing
-------------------------------------------------
function s.piercecon(e)
    return s.count_dbxv2(e:GetHandlerPlayer())>=2
end

-------------------------------------------------
-- DEF reduction
-------------------------------------------------
function s.deflosscon(e)
    return s.count_dbxv2(e:GetHandlerPlayer())>=3
end
