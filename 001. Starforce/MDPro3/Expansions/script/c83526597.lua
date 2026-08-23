local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_DRAW+CATEGORY_TODECK)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

s.listed_series={0x99b}

-- We check for ANY Spell/Trap cards to make activation easier
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_SZONE) and chkc:IsControler(tp) and chkc~=e:GetHandler() end
    
    -- Count ALL S/T you control (including Face-downs and Field Spells)
    local g=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_ONFIELD,0,e:GetHandler(),TYPE_SPELL+TYPE_TRAP)
    local b1 = #g>=3
    
    if chk==0 then 
        return Duel.IsPlayerCanDraw(tp,1) or (b1 and Duel.IsExistingTarget(nil,tp,LOCATION_SZONE,0,1,e:GetHandler()))
    end

    if b1 then
        e:SetLabel(1) -- Mark for Shuffle Mode
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
        local tg=Duel.SelectTarget(tp,nil,tp,LOCATION_SZONE,0,1,3,e:GetHandler())
        Duel.SetOperationInfo(0,CATEGORY_TODECK,tg,#tg,0,0)
    else
        e:SetLabel(0) -- Mark for Draw Mode
        Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
    end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local label=e:GetLabel()
    
    if label==1 then
        -- SHUFFLE AND SET
        local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
        if #tg==0 then return end
        
        local shuffled_codes={}
        for tc in aux.Next(tg) do table.insert(shuffled_codes,tc:GetCode()) end

        if Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
            Duel.ShuffleDeck(tp)
            -- NOW we look specifically for Starforce S/Ts in the deck
            local deck_g=Duel.GetMatchingGroup(function(c)
                return c:IsSetCard(0x99b) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
            end,tp,LOCATION_DECK,0,nil)

            -- Remove names that were just shuffled
            local filtered_g=deck_g:Filter(function(c)
                for _,code in ipairs(shuffled_codes) do
                    if c:IsCode(code) then return false end
                end
                return true
            end,nil)

            -- If we have 3+ unique names, Set them
            if filtered_g:GetClassCount(Card.GetCode)>=3 and Duel.GetLocationCount(tp,LOCATION_SZONE)>=3 then
                Duel.BreakEffect()
                local sg=Group.CreateGroup()
                for i=1,3 do
                    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
                    local g1=filtered_g:Select(tp,1,1,nil)
                    sg:Merge(g1)
                    filtered_g:Remove(Card.IsCode,nil,g1:GetFirst():GetCode())
                end
                Duel.SSet(tp,sg)
            end
        end
    else
        -- DRAW 1
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end
