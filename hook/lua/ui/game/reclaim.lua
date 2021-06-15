local GetPixelScaleFactor = import('/lua/maui/layouthelpers.lua').GetPixelScaleFactor

-- Mielus: Creates a smaller reclaim logo & color and text size depend on reclaim amount
function CreateReclaimLabel(view)
    local label = WorldLabel(view, Vector(0, 0, 0))

    label.mass = Bitmap(label)
    label.oldMass = 0 --fix compare bug
    label.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
    LayoutHelpers.AtLeftIn(label.mass, label)
    LayoutHelpers.AtVerticalCenterIn(label.mass, label)
    label.mass.Height:Set(10)
    label.mass.Width:Set(10)

    label.text = UIUtil.CreateText(label, "", 10, UIUtil.bodyFont)
    label.text:SetColor('ffc7ff8f')
    label.text:SetDropShadow(true)
    LayoutHelpers.AtLeftIn(label.text, label, 16)
    LayoutHelpers.AtVerticalCenterIn(label.text, label)

    label:DisableHitTest(true)
    label.OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end

    label.Update = function(self)
        local view = self.parent.view
        local proj = view:Project(self.position)
		LayoutHelpers.AtLeftTopIn(self, self.parent, (proj.x / GetPixelScaleFactor()) - self.Width() / 2, (proj.y / GetPixelScaleFactor()) - self.Height() / 2 + 1)
        self.proj = {x=proj.x, y=proj.y }
    end

    label.DisplayReclaim = function(self, r)
        if self:IsHidden() then
            self:Show()
        end
        self:SetPosition(r.position)
        if r.mass ~= self.oldMass then
            local mass = tostring(math.floor(0.5 + r.mass))
	    if (r.mass > 200) then
 	      if (r.mass > 800) then
                self.text:SetFont(UIUtil.bodyFont, 20) --r.mass > 800
                self.text:SetColor('orange')
	      else
                self.text:SetFont(UIUtil.bodyFont, 15) --r.mass > 200
                self.text:SetColor('yellow')
              end
	    else
              self.text:SetFont(UIUtil.bodyFont, 10)   --r.mass <= 200
              self.text:SetColor('ffc7ff8f')
	    end
            self.text:SetText(mass)
            self.oldMass = r.mass
        end
    end

    label:Update()

    return label
end

-- Strogo: Make a reclaim counter
local ReclaimTotal

function UpdateLabels()
    local view = import('/lua/ui/game/worldview.lua').viewLeft -- Left screen's camera
    local onScreenReclaimIndex = 1
    local onScreenReclaims = {}
    local onScreenMassTotal = 0

    -- One might be tempted to use a binary insert; however, tests have shown that it takes about 140x more time
    for _, r in Reclaim do
        r.onScreen = OnScreen(view, r.position)
        if r.onScreen and r.mass >= MinAmount then
            onScreenMassTotal = onScreenMassTotal + r.mass
            onScreenReclaims[onScreenReclaimIndex] = r
            onScreenReclaimIndex = onScreenReclaimIndex + 1
        end
    end
    
    
    if ReclaimTotal then
        reclaimFrame:Destroy()
        reclaimFrame = nil
        reclaimLine:Destroy()
        reclaimLine = nil
        CreateRecalimTotalUI(onScreenMassTotal)
    else
        CreateRecalimTotalUI(onScreenMassTotal)
        ReclaimTotal = true
    end
    
    table.sort(onScreenReclaims, function(a, b) return a.mass > b.mass end)

    -- Create/Update as many reclaim labels as we need
    local labelIndex = 1
    for _, r in onScreenReclaims do
        if labelIndex > MaxLabels then
            break
        end
        local label = LabelPool[labelIndex]
        if label and IsDestroyed(label) then
            label = nil
        end
        if not label then
            label = CreateReclaimLabel(view.ReclaimGroup, r)
            LabelPool[labelIndex] = label
        end

        label:DisplayReclaim(r)
        labelIndex = labelIndex + 1
    end

    -- Hide labels we didn't use
    for index = labelIndex, MaxLabels do
        local label = LabelPool[index]
        if label then
            if IsDestroyed(label) then
                LabelPool[index] = nil
            elseif not label:IsHidden() then
                label:Hide()
            end
        end
    end
end

function OnCommandGraphShow(bool)
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    if view.ShowingReclaim and not CommandGraphActive then return end -- if on by toggle key

    CommandGraphActive = bool
    if CommandGraphActive then
        ForkThread(function()
            local keydown

            while CommandGraphActive do
                
                keydown = IsKeyDown('Control')

                if keydown == false and ReclaimTotal then
                    reclaimFrame:Destroy()
                    reclaimFrame = nil
                    reclaimLine:Destroy()
                    reclaimLine = nil
                    ReclaimTotal = nil
                end
                
                if keydown ~= view.ShowingReclaim then -- state has changed
                    ShowReclaim(keydown)
                end
                WaitSeconds(.1)
            end
            
            if ReclaimTotal then
                reclaimFrame:Destroy()
                reclaimFrame = nil
                reclaimLine:Destroy()
                reclaimLine = nil
                ReclaimTotal = nil
            end
            
            ShowReclaim(false)
        end)
    else
        CommandGraphActive = false -- above coroutine runs until now
    end
end

function CreateRecalimTotalUI(MassTotal)
        reclaimFrame = Bitmap(GetFrame(0))
        reclaimFrame:SetTexture('/textures/ui/common/game/economic-overlay/econ_bmp_m.dds')
        reclaimFrame.Depth:Set(99)
        reclaimFrame.Height:Set(24)
        reclaimFrame.Width:Set(100)
        reclaimFrame:DisableHitTest(true)
        LayoutHelpers.AtLeftTopIn(reclaimFrame, GetFrame(0), 420, 44)
        
        local titleLine = UIUtil.CreateText(reclaimFrame, 'Reclaim', 10, UIUtil.bodyFont)
        LayoutHelpers.CenteredAbove(titleLine, reclaimFrame, -12)
        titleLine:DisableHitTest(true)
        
        reclaimLine = UIUtil.CreateText(reclaimFrame, '', 10, UIUtil.bodyFont)
        reclaimLine:SetColor('FFB8F400')
        LayoutHelpers.AtRightTopIn(reclaimLine, reclaimFrame, 4, 10)
        reclaimLine:DisableHitTest(true)
        
        if MassTotal then
            reclaimLine:SetText(string.format("%d", MassTotal))
        end
end
