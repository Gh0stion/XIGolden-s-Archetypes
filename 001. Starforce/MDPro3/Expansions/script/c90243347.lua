local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- ID References
s.listed_names={59999377, 21298482, 16440678} 

-- 1. Condition: Do not control a "Starforce" Extra Deck monster
function s.cfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x99b) and c:IsType(TYPE_LINK+TYPE_XYZ)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return not Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- 2. Target Check: Check Deck for Geo and Extra Deck for specific Megaman forms
function s.exfilter(c,e,tp,mc)
    local code=c:GetCode()
    return (code==21298482 or code==16440678) 
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
        and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_DECK,0,1,nil,59999377)
            and Duel.IsExistingMatchingCard(s.exfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_DECK+LOCATION_EXTRA)
end

-- 3. Operation: Transform Geo Stelar
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    
    -- Step A: Special Summon Geo Stelar from Deck
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,Card.IsCode,tp,LOCATION_DECK,0,1,1,nil,59999377)
    local tc=g:GetFirst()
    
    if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
        -- Step B: Select Megaman (Link) or XYZ Megaman
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g2=Duel.SelectMatchingCard(tp,s.exfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc)
        local sc=g2:GetFirst()
        
        if sc then
            Duel.BreakEffect()
            if sc:IsType(TYPE_XYZ) then
                -- Manual Xyz Summon logic using 1 material
                local mg=Group.FromCards(tc)
                sc:SetMaterial(mg)
                Duel.Overlay(sc,mg)
                Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
                sc:CompleteProcedure()
            else
                -- Manual Link Summon logic using 1 material
                sc:SetMaterial(Group.FromCards(tc))
                Duel.SendtoGrave(tc,REASON_MATERIAL+REASON_LINK)
                Duel.SpecialSummon(sc,SUMMON_TYPE_LINK,tp,tp,false,false,POS_FACEUP)
                sc:CompleteProcedure()
            end
        end
    end
end
