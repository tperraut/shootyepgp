local T = AceLibrary("Tablet-2.0")
local D = AceLibrary("Dewdrop-2.0")
local C = AceLibrary("Crayon-2.0")

local BC = AceLibrary("Babble-Class-2.2")
local L = AceLibrary("AceLocale-2.2"):new("shootyepgp")

sepgp_bids = sepgp:NewModule("sepgp_bids", "AceDB-2.0", "AceEvent-2.0")

function sepgp_bids:OnEnable()
  if not T:IsRegistered("sepgp_bids") then
    T:Register("sepgp_bids",
      "children", function()
        T:SetTitle(L["shootyepgp bids"])
        self:OnTooltipUpdate()
      end,
      "showTitleWhenDetached", true,
      "showHintWhenDetached", true,
      "cantAttach", true,
      "menu", function()
        D:AddLine(
          "text", L["Refresh"],
          "tooltipText", L["Refresh window"],
          "func", function() sepgp_bids:Refresh() end
        )
      end
    )
  end
  if not T:IsAttached("sepgp_bids") then
    T:Open("sepgp_bids")
  end
end

function sepgp_bids:OnDisable()
  T:Close("sepgp_bids")
end

function sepgp_bids:Refresh()
  T:Refresh("sepgp_bids")
end

function sepgp_bids:setHideScript()
  local i = 1
  local tablet = getglobal(string.format("Tablet20DetachedFrame%d", i))
  while (tablet) and i < 100 do
    if tablet.owner ~= nil and tablet.owner == "sepgp_bids" then
      sepgp:make_escable(string.format("Tablet20DetachedFrame%d", i), "add")
      tablet:SetScript("OnHide", nil)
      tablet:SetScript("OnHide", function()
        if not T:IsAttached("sepgp_bids") then
          T:Attach("sepgp_bids")
          this:SetScript("OnHide", nil)
        end
      end)
      break
    end
    i = i + 1
    tablet = getglobal(string.format("Tablet20DetachedFrame%d", i))
  end
end

function sepgp_bids:Top()
  if T:IsRegistered("sepgp_bids") and (T.registry.sepgp_bids.tooltip) then
    T.registry.sepgp_bids.tooltip.scroll = 0
  end
end

function sepgp_bids:Toggle(forceShow)
  self:Top()
  if T:IsAttached("sepgp_bids") then
    T:Detach("sepgp_bids") -- show
    if (T:IsLocked("sepgp_bids")) then
      T:ToggleLocked("sepgp_bids")
    end
    self:setHideScript()
  else
    if (forceShow) then
      sepgp_bids:Refresh()
    else
      T:Attach("sepgp_bids") -- hide
    end
  end
end

function sepgp_bids:announceWinnerMS(name, pr_and_bid)
  local pr, bid_str = unpack(pr_and_bid)
  sepgp:widestAudience(string.format(L["Winning Mainspec Bid: %s (%.03f PR) with %s"], name, pr, bid_str or ""))
end

function sepgp_bids:announceWinnerOS(name, pr)
  sepgp:widestAudience(string.format(L["Winning Offspec Bid: %s (%.03f PR)"], name, pr))
end

function sepgp_bids:countdownCounter()
  self._counter = (self._counter or 6) - 1
  if GetNumRaidMembers() > 0 and self._counter > 0 then
    self._counterText = C:Yellow(tostring(self._counter))
    sepgp:widestAudience(tostring(self._counter))
    --SendChatMessage(tostring(self._counter),"RAID")
    self:Refresh()
  end
end

function sepgp_bids:countdownFinish(reset)
  if self:IsEventScheduled("shootyepgpBidCountdown") then
    self:CancelScheduledEvent("shootyepgpBidCountdown")
  end
  self._counter = 6
  if (reset) then
    self._counterText = C:Green("Starting")
  else
    self._counterText = C:Red("Finished")
  end
  self:Refresh()
end

function sepgp_bids:bidCountdown()
  self:countdownFinish(true)
  self:ScheduleRepeatingEvent("shootyepgpBidCountdown", self.countdownCounter, 1, self)
  self:ScheduleEvent("shootyepgpBidCountdownFinish", self.countdownFinish, 6, self)
end

local pr_sorter_bids = function(a, b)
  if sepgp_minep > 0 then
    local a_over = a[3] - sepgp_minep >= 0
    local b_over = b[3] - sepgp_minep >= 0
    if a_over and b_over or (not a_over and not b_over) then
      if a[5] ~= b[5] then
        return tonumber(a[5]) > tonumber(b[5])
      else
        return tonumber(a[3]) > tonumber(b[3])
      end
    elseif a_over and (not b_over) then
      return true
    elseif b_over and (not a_over) then
      return false
    end
  else
    if a[5] ~= b[5] then
      return tonumber(a[5]) > tonumber(b[5])
    else
      return tonumber(a[3]) > tonumber(b[3])
    end
  end
end

function sepgp_bids:BuildBidsTable()
  -- {name,class,ep,gp,ep/gp[,main]}
  table.sort(sepgp.bids_main_min, pr_sorter_bids)
  table.sort(sepgp.bids_main_need, pr_sorter_bids)
  table.sort(sepgp.bids_main_allin, pr_sorter_bids)
  table.sort(sepgp.bids_off, pr_sorter_bids)
  return sepgp.bids_main_min, sepgp.bids_main_need, sepgp.bids_main_allin, sepgp.bids_off
end

function sepgp_bids:CreateBidCat(cat)
  local maincatHeader = T:AddCategory(
    "columns", 1,
    "text", cat
  ):AddLine("text", "")
  local maincat = T:AddCategory(
    "columns", 6,
    "text", C:Orange("Name"), "child_textR", 1, "child_textG", 1, "child_textB", 1, "child_justify", "LEFT",
    "text2", C:Orange("ep"), "child_text2R", 1, "child_text2G", 1, "child_text2B", 1, "child_justify2", "RIGHT",
    "text3", C:Orange("gp"), "child_text3R", 1, "child_text3G", 1, "child_text3B", 1, "child_justify3", "RIGHT",
    "text4", C:Orange("pr"), "child_text4R", 1, "child_text4G", 1, "child_text4B", 0, "child_justify4", "RIGHT",
    "text5", C:Orange("Bid"), "child_text5R", 1, "child_text5G", 1, "child_text5B", 0, "child_justify5", "RIGHT",
    "text6", C:Orange("Main"), "child_text6R", 1, "child_text6G", 1, "child_text6B", 0, "child_justify6", "RIGHT",
    "hideBlankLine", true
  )
  return maincat
end

function sepgp_bids:Addlines(cat, data, ep_median)
  for i = 1, table.getn(data) do
    local name, class, ep, gp, pr, main, bid, bid_value = unpack(data[i])
    local namedesc
    local _, grade = GetGuildInfo("player")
    namedesc = string.format("%s(%s)", C:Colorize(BC:GetHexColor(class), name), grade)
    local text2, text4
    if sepgp_minep > 0 and ep < sepgp_minep then
      text2 = C:Red(string.format("%.4g", ep))
      text4 = C:Red(string.format("%.4g", pr))
    else
      text2 = string.format("%.4g", ep)
      text4 = string.format("%.4g", pr)
    end
    if ep_median and ep < ep_median then
      text2 = C:Red(text2)
    end
    local bid_str = string.format("%s (%d)", string.upper(bid), bid_value)
    cat:AddLine(
      "text", namedesc,
      "text2", text2,
      "text3", string.format("%.4g", gp),
      "text4", text4,
      "text5", bid_str,
      "text6", (main or ""),
      "func", "announceWinnerMS", "arg1", self, "arg2", name, "arg3", {pr, bid_str}
    )
  end
end

function sepgp_bids:OnTooltipUpdate()
  if not (sepgp.bid_item and sepgp.bid_item.link) then return end
  local link = sepgp.bid_item.link
  local itemName = sepgp.bid_item.name
  local price_allin, price_need, price_min, price_os = sepgp_prices:GetPrice(link, sepgp_progress)
  local bidcat = T:AddCategory(
    "columns", 5,
    "text", C:Orange("Bid Item"), "child_textR", 1, "child_textG", 1, "child_textB", 1, "child_justify", "LEFT",
    "text2", C:Orange("Allin Cost"), "child_text2R", 50 / 255, "child_text2G", 205 / 255, "child_text2B", 50 / 255, "child_justify4", "RIGHT",
    "text3", C:Orange("Need Cost"), "child_text2R", 50 / 255, "child_text2G", 205 / 255, "child_text2B", 50 / 255, "child_justify4", "RIGHT",
    "text4", C:Orange("Min Cost"), "child_text2R", 50 / 255, "child_text2G", 205 / 255, "child_text2B", 50 / 255, "child_justify4", "RIGHT",
    "text5", C:Orange("OffSpec"), "child_text3R", 32 / 255, "child_text3G", 178 / 255, "child_text3B", 170 / 255,
    "child_justify5", "RIGHT",
    "hideBlankLine", true
  )
  bidcat:AddLine(
    "text", itemName,
    "text2", price_allin,
    "text3", price_need,
    "text4", price_min,
    "text5", price_os
  )

  local countdownHeader = T:AddCategory(
    "columns", 2,
    "text", "", "child_textR", 1, "child_textG", 1, "child_textB", 1, "child_justify", "LEFT",
    "text2", "", "child_text2R", 1, "child_text2G", 1, "child_text2B", 1, "child_justify2", "CENTER",
    "hideBlankLine", true
  )
  countdownHeader:AddLine(
    "text", C:Green("Countdown"),
    "text2", self._counterText,
    "func", "bidCountdown", "arg1", self
  )

  local raid_table = sepgp_standings:BuildStandingsTable(true)
  local ep_median = sepgp:calculateMedian(raid_table, 4)
  local mediancat = T:AddCategory(
    "columns", 4,
    "text", C:Orange(L["Median"]), "child_justify", "LEFT",
    "text2", C:Orange("EP"), "child_justify2", "RIGHT",
    "text3", C:Orange("GP"), "child_justify3", "RIGHT",
    "text4", C:Orange("PR"), "child_justify4", "RIGHT"
  ):AddLine(
    "text", "",
    "text2", C:White(string.format("%d", ep_median)),
    "text3", C:White(string.format("%d", sepgp:calculateMedian(raid_table, 5))),
    "text4", C:White(string.format("%.4g", sepgp:calculateMedian(raid_table, 6)))
  )

  local tm_min, tm_need, tm_allin = self:BuildBidsTable()

  local maincat_all_in = self:CreateBidCat(C:Red(string.format("MainSpec %s Bids", "ALLIN")))
  self:Addlines(maincat_all_in, tm_allin, ep_median)
  local maincat_need = self:CreateBidCat(C:Orange(string.format("MainSpec %s Bids", "NEED")))
  self:Addlines(maincat_need, tm_need)
  local maincat_min = self:CreateBidCat(C:Yellow(string.format("MainSpec %s Bids", "MIN")))
  self:Addlines(maincat_min, tm_min)


  local offcatHeader = T:AddCategory(
    "columns", 1,
    "text", C:Green("OffSpec Bids")
  ):AddLine("text", "")
  local offcat = T:AddCategory(
    "columns", 5,
    "text", C:Orange("Name"), "child_textR", 1, "child_textG", 1, "child_textB", 1, "child_justify", "LEFT",
    "text2", C:Orange("EP"), "child_text2R", 1, "child_text2G", 1, "child_text2B", 1, "child_justify2", "RIGHT",
    "text3", C:Orange("GP"), "child_text3R", 1, "child_text3G", 1, "child_text3B", 1, "child_justify3", "RIGHT",
    "text4", C:Orange("PR"), "child_text4R", 1, "child_text4G", 1, "child_text4B", 0, "child_justify4", "RIGHT",
    "text5", C:Orange("Main"), "child_text5R", 1, "child_text5G", 1, "child_text5B", 0, "child_justify5", "RIGHT",
    "hideBlankLine", true
  )
  local _, _, _, to = self:BuildBidsTable()
  for i = 1, table.getn(to) do
    local name, class, ep, gp, pr, main = unpack(to[i])
    local namedesc
    if (main) then
      namedesc = string.format("%s%(%s%)", C:Colorize(BC:GetHexColor(class), name), L["Alt"])
    else
      namedesc = C:Colorize(BC:GetHexColor(class), name)
    end
    local text2, text4
    if sepgp_minep > 0 and ep < sepgp_minep then
      text2 = C:Red(string.format("%.4g", ep))
      text4 = C:Red(string.format("%.4g", pr))
    else
      text2 = string.format("%.4g", ep)
      text4 = string.format("%.4g", pr)
    end
    offcat:AddLine(
      "text", namedesc,
      "text2", text2,
      "text3", string.format("%.4g", gp),
      "text4", text4,
      "text5", (main or ""),
      "func", "announceWinnerOS", "arg1", self, "arg2", name, "arg3", pr
    )
  end
end

-- GLOBALS: sepgp_saychannel,sepgp_groupbyclass,sepgp_groupbyarmor,sepgp_groupbyrole,sepgp_raidonly,sepgp_decay,sepgp_minep,sepgp_reservechannel,sepgp_main,sepgp_progress,sepgp_discount,sepgp_log,sepgp_dbver,sepgp_looted
-- GLOBALS: sepgp,sepgp_prices,sepgp_standings,sepgp_bids,sepgp_loot,sepgp_reserves,sepgp_alts,sepgp_logs
