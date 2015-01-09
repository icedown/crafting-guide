###
Crafting Guide - crafting_plan.test.coffee

Copyright (c) 2014-2015 by Redwood Labs
All rights reserved.
###

ModPack      = require '../src/scripts/models/mod_pack'
CraftingPlan = require '../src/scripts/models/crafting_plan'

########################################################################################################################

modPack = plan = null

########################################################################################################################

describe 'CraftingPlan', ->

    beforeEach ->
        modPack = new ModPack
        modPack.loadModVersionData {
            dataVersion: 1
            name: 'Minecraft'
            version: '1.7.10'
            recipes: [
                { input:'Oak Log',                                              output:[[4, 'Oak Plank']] }
                { input:[[2, 'Oak Plank']],                                     output:[[4, 'Stick']] }
                { input:[[4, 'Oak Plank']],                                     output:'Crafting Table' }
                { input:[[8, 'Cobblestone']],           tools:'Crafting Table', output:'Furnace' }
                { input:['Iron Ore', 'furnace fuel'], tools:'Furnace',        output:'Iron Ingot' }
                { input:[[2, 'Iron Ingot'], 'Stick'],   tools:'Crafting Table', output:'Iron Sword' }
            ]
        }

        plan = new CraftingPlan modPack:modPack

    describe 'craft', ->

        describe 'under the simplest conditions', ->

            it 'can craft a single step recipe', ->
                plan.want.add 'oak_plank'
                plan.craft()
                plan.need.toList().should.eql ['oak_log']
                plan.result.toList().should.eql [[4, 'oak_plank']]

            it 'can craft a multi-step recipe', ->
                plan.want.add 'crafting_table'
                plan.craft()
                plan.need.toList().should.eql ['oak_log']
                plan.result.toList().should.eql ['crafting_table']

            it 'can craft a multi-step recipe using tools', ->
                plan.want.add 'furnace'
                plan.craft()
                plan.need.toList().should.eql [[8, 'cobblestone']]
                plan.result.toList().should.eql ['furnace']

            it 'can craft a multi-step recipe re-using tools', ->
                plan.want.add 'iron_sword'
                plan.craft()
                plan.need.toList().should.eql [[2, 'furnace_fuel'], [2, 'iron_ore'], 'oak_log']
                plan.result.toList().should.eql ['iron_sword', [2, 'oak_plank'], [3, 'stick']]

        describe 'with building tools', ->

            it 'can craft a multi-step recipe using tools', ->
                plan.includingTools = true
                plan.want.add 'furnace'
                plan.craft()
                plan.need.toList().should.eql [[8, 'cobblestone'], 'oak_log']
                plan.result.toList().should.eql ['crafting_table', 'furnace']

            it 'can craft a multi-step recipe re-using tools', ->
                plan.includingTools = true
                plan.want.add 'iron_sword'
                plan.craft()
                plan.need.toList().should.eql [
                    [8, 'cobblestone'], [2, 'furnace_fuel'], [2, 'iron_ore'], [2, 'oak_log']
                ]
                plan.result.toList().should.eql [
                    'crafting_table', 'furnace', 'iron_sword', [2, 'oak_plank'], [3, 'stick']
                ]

        describe 'using existing inventory', ->
