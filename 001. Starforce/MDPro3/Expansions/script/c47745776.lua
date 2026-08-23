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
    
    --1. Place as Continuous Spell when Special Summoned (Quick Effect)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.pltg)
    e2:SetOperation(s.plop)
    c:RegisterEffect(e2)
    
    --2a. Opponent's monsters lose 1500 ATK/DEF
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_SZONE)
    e3:SetTargetRange(0,LOCATION_MZONE)
    e3:SetCondition(s.effcon)
    e3:SetValue(-1500)
    c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e4)
    
    --2b. Negate Level 4/8/11 monsters
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_DISABLE)
    e5:SetRange(LOCATION_SZONE)
    e5:SetTargetRange(0,LOCATION_MZONE)
    e5:SetCondition(s.effcon)
    e5:SetTarget(s.distg)
    c:RegisterEffect(e5)
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e6:SetCode(EVENT_ADJUST)
    e6:SetRange(LOCATION_SZONE)
    e6:SetCondition(s.effcon)
    e6:SetOperation(s.disop)
    c:RegisterEffect(e6)
    local e7=Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_FIELD)
    e7:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
    e7:SetRange(LOCATION_SZONE)
    e7:SetTargetRange(0,LOCATION_MZONE)
    e7:SetCondition(s.effcon)
    e7:SetTarget(s.distg)
    c:RegisterEffect(e7)
    
    --2c. Level 5/7/12 monsters have 0 ATK
    local e8=Effect.CreateEffect(c)
    e8:SetType(EFFECT_TYPE_FIELD)
    e8:SetCode(EFFECT_SET_ATTACK_FINAL)
    e8:SetRange(LOCATION_SZONE)
    e8:SetTargetRange(0,LOCATION_MZONE)
    e8:SetCondition(s.effcon)
    e8:SetTarget(s.atktg)
    e8:SetValue(0)
    c:RegisterEffect(e8)
    
    --3. Special Summon from S/T Zone during Battle Phase
    local e9=Effect.CreateEffect(c)
    e9:SetDescription(aux.Stringid(id,1))
    e9:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY+CATEGORY_ATKCHANGE)
    e9:SetType(EFFECT_TYPE_QUICK_O)
    e9:SetCode(EVENT_FREE_CHAIN)
    e9:SetRange(LOCATION_SZONE)
    e9:SetCondition(s.spcon2)
    e9:SetTarget(s.sptg2)
    e9:SetOperation(s.spop2)
    c:RegisterEffect(e9)
    
    --Cannot be banished with 2 Tribe On materials
    local e10=Effect.CreateEffect(c)
    e10:SetType(EFFECT_TYPE_SINGLE)
    e10:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e10:SetCode(EFFECT_CANNOT_REMOVE)
    e10:SetRange(LOCATION_MZONE)
    e10:SetCondition(s.bancon)
    c:RegisterEffect(e10)
end

s.listed_series={0x99b,0x100b}
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

--1. Place as Continuous Spell
function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
end

function s.plop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true) then
        local e1=Effect.CreateEffect(c)
        e1:SetCode(EFFECT_CHANGE_TYPE)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
        e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
        c:RegisterEffect(e1)
    end
end

--Check if treated as Continuous Spell
function s.effcon(e)
    return e:GetHandler():IsType(TYPE_SPELL) and e:GetHandler():IsType(TYPE_CONTINUOUS)
end

--2b. Negate Level 4/8/11
function s.distg(e,c)
    local lv=c:GetLevel()
    return c:IsFaceup() and (lv==4 or lv==8 or lv==11)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetMatchingGroup(s.distg,tp,0,LOCATION_MZONE,nil)
    for tc in aux.Next(g) do
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e2)
    end
end

--2c. Level 5/7/12 have 0 ATK
function s.atktg(e,c)
    local lv=c:GetLevel()
    return c:IsFaceup() and (lv==5 or lv==7 or lv==12)
end

--3. Special Summon from S/T Zone
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsBattlePhase() and e:GetHandler():IsType(TYPE_SPELL) and e:GetHandler():IsType(TYPE_CONTINUOUS)
end

function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD+LOCATION_HAND)
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 then
        --Destroy 1 card opponent controls
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
        local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
        if #g>0 then
            Duel.HintSelection(g)
            Duel.Destroy(g,REASON_EFFECT)
        end
        
        --Randomly destroy 1 card in opponent's hand
        local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
        if #hg>0 then
            local sg=hg:RandomSelect(tp,1)
            Duel.Destroy(sg,REASON_EFFECT)
        end
        
        --Gain 200 ATK/DEF per card in opponent's GY
        local ct=Duel.GetMatchingGroupCount(Card.IsType,tp,0,LOCATION_GRAVE,nil,TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
        if ct>0 and c:IsFaceup() then
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(ct*200)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
            c:RegisterEffect(e1)
            local e2=e1:Clone()
            e2:SetCode(EFFECT_UPDATE_DEFENSE)
            c:RegisterEffect(e2)
        end
        
        --Attach up to 2 Tribe On from GY
        local og=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.attfilter),tp,LOCATION_GRAVE,0,nil)
        if #og>0 and c:IsFaceup() and c:IsType(TYPE_XYZ) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
            local sg=og:Select(tp,1,math.min(2,#og),nil)
            if #sg>0 then
                Duel.Overlay(c,sg)
            end
        end
    end
end

function s.attfilter(c)
    return c:IsSetCard(0x100b) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS)
end

--Cannot be banished with 2 Tribe On
function s.bancon(e)
    local og=e:GetHandler():GetOverlayGroup()
    return og:FilterCount(s.attfilter,nil)>=2
end