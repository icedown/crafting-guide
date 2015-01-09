###
Crafting Guide - mod_pack.coffee

Copyright (c) 2014-2015 by Redwood Labs
All rights reserved.
###

BaseModel        = require './base_model'
{Event}          = require '../constants'
ModVersionParser = require './mod_version_parser'
{RequiredMods}   = require '../constants'
{Url}            = require '../constants'

########################################################################################################################

module.exports = class ModPack extends BaseModel

    constructor: (attributes={}, options={})->
        attributes.modVersions ?= []
        super attributes, options

        @_parser = new ModVersionParser

    # Public Methods ###############################################################################

    enableModsForItem: (name)->
        for modVersion in @modVersions
            continue if modVersion.enabled
            if modVersion.hasRecipe name
                modVersion.enabled = true

    findItem: (itemSlug, options={})->
        options.includeDisabled ?= false

        for modVersion in @modVersions
            continue unless modVersion.enabled or options.includeDisabled
            item = modVersion.items[itemSlug]
            return item if item?

        return null

    findItemByName: (name, options={})->
        options.includeDisabled ?= false

        for modVersion in @modVersions
            continue unless modVersion.enabled or options.includeDisabled
            item = modVersion.findItemByName name
            return item if item?

        return null

    findName: (slug, options={})->
        options.includeDisabled ?= false

        for modVersion in @modVersions
            continue unless modVersion.enabled or options.includeDisabled
            name = modVersion.findName slug
            return name if name

        return slug

    findItemDisplay: (slug)->
        result = {}
        item = @findItem slug, includeDisabled:true
        if item?
            result.modSlug  = item.modVersion.slug
            result.itemSlug = item.slug
            result.itemName = item.name
        else
            result.modSlug  = _.slugify RequiredMods[0]
            result.itemSlug = slug
            result.itemName = @findName slug, includeDisabled:true

        result.iconUrl = Url.itemIcon result
        result.itemUrl = Url.item result
        return result

    gatherRecipeNames: (options={})->
        options.includeDisabled ?= false

        nameData = {}
        for modVersion in @modVersions
            continue unless modVersion.enabled or options.includeDisabled
            modVersion.gatherRecipeNames nameData

        result = []
        names = _.keys(nameData).sort()
        for name in names
            result.push nameData[name]
        return result

    hasRecipe: (name, options={})->
        options.includeDisabled ?= false

        for modVersion in @modVersions
            continue unless modVersion.enabled or options.includeDisabled
            return true if modVersion.hasRecipe name

        return false

    loadModVersion: (url)->
        w.promise (resolve, reject)=>
            @trigger Event.load.started, this, url
            $.ajax
                url: url
                dataType: 'json'
                success: (data, status, xhr)=>
                    resolve @onModVersionLoaded(url, data, status, xhr)
                error: (xhr, status, error)=>
                    reject @onModVersionLoadFailed(url, error, status, xhr)

    loadModVersionData: (data)->
        modVersion = @_parser.parse data
        @modVersions.push modVersion
        @modVersions.sort (a, b)-> a.compareTo b
        modVersion.on Event.change, => @trigger Event.change, this

        return modVersion

    loadAllModVersions: (urlList)->
        promises = (@loadModVersion(url) for url in urlList)
        return w.settle promises

    # Event Methods ################################################################################

    onModVersionLoaded: (url, data, status, xhr)->
        try
            modVersion = @loadModVersionData data
            modVersion.enabled = true

            logger.info "loaded ModVersion from #{url}: #{modVersion}"
            @trigger Event.load.succeeded, this, modVersion
            @trigger Event.load.finished, this
            @trigger Event.change, this

            return modVersion
        catch e
            @onModVersionLoadFailed url, e, status, xhr

    onModVersionLoadFailed: (url, error, status, xhr)->
        message = if error.stack? then error.stack else error
        logger.error "failed to load ModVersion from #{url}: #{message}"
        @trigger Event.load.failed, this, error.message
        @trigger Event.load.finished, this
        return error

    # Object Overrides #############################################################################

    toString: ->
        return "ModPack (#{@cid}) {modVersions:#{@modVersions.length} items}"
