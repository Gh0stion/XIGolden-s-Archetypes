local s,id=GetID()
function s.initial_effect(c)
    --Xyz Summon
    c:EnableReviveLimit()
    
    --Method 1: Using Level 4 "Starforce" Xyz with "Tribe On - Zerker" attached
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.spcon1)
    e1:SetTarget(s.sptg1)
    e1:SetOperation(s.spop1)
    e1:SetValue(SUMMON_TYPE_XYZ)
    c:RegisterEffect(e1)
    
    --Method 2: Send "Tribe On - Zerker" then use Geo Stelar
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_SPSUMMON_PROC)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e2:SetRange(LOCATION_EXTRA)
    e2:SetCondition(s.spcon2)
    e2:SetTarget(s.sptg2)
    e2:SetOperation(s.spop2)
    e2:SetValue(SUMMON_TYPE_XYZ)
    c:RegisterEffect(e2)
    
    --Attach sent spell when summoned
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCondition(s.attcon)
    e3:SetOperation(s.attop)
    c:RegisterEffect(e3)
    
    --1. Set or attach "Tribe On"
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e4:SetTarget(s.settg)
    e4:SetOperation(s.setop)
    c:RegisterEffect(e4)
    
    --2. Detach to destroy
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,3))
    e5:SetCategory(CATEGORY_DESTROY+CATEGORY_DRAW)
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_FREE_CHAIN)
    e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetCost(s.descost)
    e5:SetTarget(s.destg)
    e5:SetOperation(s.desop)
    c:RegisterEffect(e5)
    
    --3. Gain ATK and second attack when card destroyed
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,4))
    e6:SetCategory(CATEGORY_ATKCHANGE)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e6:SetCode(EVENT_DESTROYED)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCondition(s.atkcon)
    e6:SetOperation(s.atkop)
    c:RegisterEffect(e6)
end

s.listed_series={0x99b,0x100b}
s.listed_names={59999377,26384578}

--Method 1: Use Starforce Xyz with Zerker attached
function s.matfilter1(c)
    return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x99b) and c:IsRank(4)
        and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,26384578)
end

function s.spcon1(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
        and Duel.IsExistingMatchingCard(s.matfilter1,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk,c)
    local g=Duel.GetMatchingGroup(s.matfilter1,tp,LOCATION_MZONE,0,nil)
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

function s.spop1(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    local tc=g:GetFirst()
    c:SetMaterial(g)
    Duel.Overlay(c,g)
    g:DeleteGroup()
end

--Method 2: Send Zerker, use Geo Stelar
function s.zerkerfilter(c)
    return c:IsFaceup() and c:IsCode(26384578) and c:IsAbleToGraveAsCost()
end

function s.geofilter(c)
    return c:IsFaceup() and c:IsCode(59999377) and c:IsCanBeXyzMaterial(nil)
end

function s.spcon2(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
        and Duel.IsExistingMatchingCard(s.zerkerfilter,tp,LOCATION_ONFIELD,0,1,nil)
        and Duel.IsExistingMatchingCard(s.geofilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk,c)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g1=Duel.SelectMatchingCard(tp,s.zerkerfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
    if #g1>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
        local g2=Duel.SelectMatchingCard(tp,s.geofilter,tp,LOCATION_MZONE,0,1,1,nil)
        if #g2>0 then
            g1:Merge(g2)
            g1:KeepAlive()
            e:SetLabelObject(g1)
            return true
        end
    end
    return false
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    local zerker=g:Filter(Card.IsCode,nil,26384578):GetFirst()
    local geo=g:Filter(Card.IsCode,nil,59999377):GetFirst()
    if zerker and geo then
        Duel.SendtoGrave(zerker,REASON_COST)
        c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD,0,1,zerker:GetCode())
        local mg=Group.FromCards(geo)
        c:SetMaterial(mg)
        Duel.Overlay(c,mg)
    end
    g:DeleteGroup()
end

--Attach sent spell when summoned via method 2
function s.attcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ) and e:GetHandler():GetFlagEffect(id)>0
end

function s.attop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local code=c:GetFlagEffectLabel(id)
    local tc=Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsCode),tp,LOCATION_GRAVE,0,nil,code):GetFirst()
    if tc then
        Duel.Overlay(c,Group.FromCards(tc))
    end
end

--1. Set or attach "Tribe On"
function s.setfilter(c)
    return c:IsSetCard(0x100b) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS) and (c:IsSSetable() or not c:IsForbidden())
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local c=e:GetHandler()
    local alone=c:IsLocation(LOCATION_MZONE) and Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==1
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.setfilter(chkc) end
    if chk==0 then
        if alone then
            return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
        else
            return Duel.IsExistingTarget(s.setfilter,tp,LOCATION_GRAVE,0,1,nil)
        end
    end
    if alone then
        e:SetProperty(EFFECT_FLAG_DELAY)
        Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
    else
        e:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
        Duel.SelectTarget(tp,s.setfilter,tp,LOCATION_GRAVE,0,1,1,nil)
        Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_GRAVE)
    end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local alone=c:IsLocation(LOCATION_MZONE) and Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==1
    local tc
    if alone then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
        local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
        tc=g:GetFirst()
    else
        tc=Duel.GetFirstTarget()
    end
    if tc then
        local op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
        if op==0 then
            --Set face-up
            if Duel.SSet(tp,tc)~=0 then
                local e1=Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
                e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
                e1:SetValue(LOCATION_REMOVED)
                tc:RegisterEffect(e1)
                Duel.ConfirmCards(1-tp,tc)
            end
        else
            --Attach as material
            if c:IsRelateToEffect(e) then
                Duel.Overlay(c,Group.FromCards(tc))
            end
        end
    end
end

--2. Detach to destroy - SIMPLIFIED
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    local g=e:GetHandler():GetOverlayGroup()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVEXYZ)
    local sg=g:Select(tp,1,1,nil)
    local tc=sg:GetFirst()
    e:GetHandler():RegisterFlagEffect(id+1000,RESET_CHAIN,0,1,tc:GetCode())
    Duel.SendtoGrave(sg,REASON_COST)
end

function s.stfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then return Duel.IsExistingTarget(s.stfilter,tp,LOCATION_ONFIELD,0,1,nil)
        and Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g1=Duel.SelectTarget(tp,s.stfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
    local tg=g:Filter(Card.IsRelateToEffect,nil,e)
    if #tg>0 then
        if Duel.Destroy(tg,REASON_EFFECT)>0 and c:GetFlagEffect(id+1000)>0 then
            local detachedcode=c:GetFlagEffectLabel(id+1000)
            local tribeon=Duel.CreateToken(tp,detachedcode)
            if tribeon:IsSetCard(0x100b) and tribeon:IsType(TYPE_SPELL) and tribeon:IsType(TYPE_CONTINUOUS) then
                if Duel.SelectYesNo(tp,aux.Stringid(id,5)) then
                    Duel.BreakEffect()
                    Duel.Draw(tp,1,REASON_EFFECT)
                end
            end
        end
    end
end

--3. ATK gain and second attack
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(Card.IsPreviousLocation,1,nil,LOCATION_ONFIELD)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsFaceup() then
        --Gain 400 ATK
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(400)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
        c:RegisterEffect(e1)
        --Second attack
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_EXTRA_ATTACK)
        e2:SetValue(1)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        c:RegisterEffect(e2)
    end
end