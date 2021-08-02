--[[

Graphical tree generator in Lua.

Dependencies: lua-sdl2 (installation: `luarocks install lua-sdl2`)

Copyright (c) 2021 Imre Törteli

--]]


local sdl = require "SDL"
math.randomseed(os.time())

------------------------------------ CONFIG ------------------------------------
local WINDOW_W          = 1500
local WINDOW_H          = 1000
local MAX_BRANCH_DEPTH  = 15
local MAX_BRANCH_LENGTH = 150
local MAX_REL_ROT_DEG   = 30
--------------------------------------------------------------------------------

local WINDOW_CENTER_X    = WINDOW_W/2
local MAX_REL_ROT = MAX_REL_ROT_DEG/360*(math.pi*2)

local status, _ = sdl.init()
if not status then error(_) end

local window, _ = sdl.createWindow({title="Tree", width=WINDOW_W, height=WINDOW_H})
if not window then error(_) end

local renderer, _ = sdl.createRenderer(window, -1, 0)
if not renderer then error(_) end


local TreeNode = {}
TreeNode.__index = TreeNode
setmetatable(TreeNode, {__call=function(c) return c.new() end})
function TreeNode.new()
    local self = setmetatable({}, TreeNode)
    self.children = {}
    self.startPos = {x=WINDOW_CENTER_X, y=WINDOW_H}
    self.endPos = {x=WINDOW_CENTER_X, y=WINDOW_H}
    self.rot = -math.pi/2
    self.depth = 0
    return self
end

local function genTree(node)
    local numOfChildren = math.random(3)
    for _ = 1, numOfChildren do
        if node.depth > math.random(5, MAX_BRANCH_DEPTH) then
            return
        end
        local child = TreeNode()
        child.startPos = {x=node.endPos.x, y=node.endPos.y}
        child.rot = node.rot + math.random(-MAX_REL_ROT*10000//1, MAX_REL_ROT*10000//1)/10000
        local length = math.random(1, MAX_BRANCH_LENGTH)
        child.endPos = {
            x=child.startPos.x + math.cos(child.rot) * length // 1,
            y=child.startPos.y + math.sin(child.rot) * length // 1
        }
        child.depth = node.depth + 1
        renderer:setDrawColor(
            child.endPos.x%256 << 16 |
            child.rot/(math.pi*2)*255//1 << 8 |
            child.endPos.y%256)
        renderer:drawLine({
            x1=child.startPos.x,
            y1=child.startPos.y,
            x2=child.endPos.x,
            y2=child.endPos.y,
        })
        table.insert(node.children, child)
        genTree(child)
        renderer:present()
    end
end

local rootNode = TreeNode()
while true do
    for e in sdl.pollEvent() do
        if e.type == sdl.event.Quit then
            goto quit
        elseif e.type == sdl.event.KeyUp then
            goto quit
        end
    end

    -- Draw a gradient
    for i=0, WINDOW_H do
        renderer:setDrawColor((255 - i/WINDOW_H*255//1) | 0x333300)
        renderer:drawLine({x1=0, y1=i, x2=WINDOW_W, y2=i})
    end

    genTree(rootNode)

    sdl.delay(1000)
    rootNode.children = {} -- Reset the tree
end

::quit::
sdl.quit()

