do 
    function CheckConsumptionChange()
        while true do
            local massOut = 0
            local energyOut = 0
            local massCost = 0
            local energyCost = 0
            for index, unit in GetSelectedUnits() or {} do
                local econ_data = unit:GetEconData()

                massOut = massOut + econ_data['massConsumed']
                energyOut = energyOut + econ_data['energyConsumed']
                
                if not unit:IsInCategory('COMMAND') then
                    massCost = massCost + unit:GetBlueprint().Economy.BuildCostMass
                    energyCost = energyCost + unit:GetBlueprint().Economy.BuildCostEnergy
                end
            end
            
            massLine:SetText(string.format("%d (%d/s)", massCost, massOut))
            energyLine:SetText(string.format("%d (%d/s)", energyCost, energyOut))

            WaitSeconds(0.1)
        end
    end
    
    function CreateSelectionUI()
        --Setup reclaim window style frame
        statsFrame = Bitmap(GetFrame(0))
        statsFrame:SetTexture('/textures/ui/common/game/economic-overlay/econ_bmp_m.dds')
        statsFrame.Depth:Set(99)
        statsFrame.Height:Set(36)
        statsFrame.Width:Set(100)
        statsFrame:DisableHitTest(true)
        LayoutHelpers.AtLeftTopIn(statsFrame, GetFrame(0), 420, 8)
        
        local titleLine = UIUtil.CreateText(statsFrame, 'Cost  (Spending)', 10, UIUtil.bodyFont)
        LayoutHelpers.CenteredAbove(titleLine, statsFrame, -12)
        titleLine:DisableHitTest(true)
        
        massLine = UIUtil.CreateText(statsFrame, '', 10, UIUtil.bodyFont)
        massLine:SetColor('FFB8F400')
        LayoutHelpers.AtRightTopIn(massLine, statsFrame, 4, 10)
        massLine:DisableHitTest(true)
        
        energyLine = UIUtil.CreateText(statsFrame, '', 10, UIUtil.bodyFont)
        energyLine:SetColor('FFF8C000')
        LayoutHelpers.AtRightTopIn(energyLine, statsFrame, 4, 20)
        energyLine:DisableHitTest(true)
    end
    
    local OldCreateUI = CreateUI
    function CreateUI(isReplay)
        OldCreateUI(isReplay)
        ForkThread(CheckConsumptionChange)
        CreateSelectionUI()
    end
end